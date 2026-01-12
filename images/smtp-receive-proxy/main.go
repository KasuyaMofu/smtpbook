package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"strings"
	"sync"
)

type LogEntry struct {
	From string `json:"from"`
	To   string `json:"to"`
	Mode string `json:"mode"`
	Data string `json:"data"`
}

var (
	logMutex     sync.Mutex
	relayHost    string
	serverIP     string
	outputFormat string
)

func logOutput(from, to, mode, data string) {
	data = strings.TrimSpace(data)
	logMutex.Lock()
	defer logMutex.Unlock()

	if outputFormat == "text" {
		// テキスト形式: 10.255.2.40 > 10.255.1.10: 220 imap.b.test ESMTP Postfix
		if mode == "CONNECT" || mode == "DISCONNECT" {
			fmt.Printf("%s > %s: [%s]\n", from, to, mode)
		} else {
			fmt.Printf("%s > %s: %s\n", from, to, data)
		}
	} else {
		// JSON形式
		entry := LogEntry{
			From: from,
			To:   to,
			Mode: mode,
			Data: data,
		}
		var buf bytes.Buffer
		encoder := json.NewEncoder(&buf)
		encoder.SetEscapeHTML(false)
		if err := encoder.Encode(entry); err != nil {
			log.Printf("JSON marshal error: %v", err)
			return
		}
		fmt.Print(buf.String())
	}
}

// proxyConnection handles bidirectional proxying with logging
func proxyConnection(clientConn net.Conn, serverConn net.Conn, clientIP string, direction string) {
	var wg sync.WaitGroup
	wg.Add(2)

	// Client -> Server (commands)
	go func() {
		defer wg.Done()
		reader := bufio.NewReader(clientConn)
		for {
			line, err := reader.ReadString('\n')
			if err != nil {
				if err != io.EOF {
					log.Printf("Read error from client: %v", err)
				}
				return
			}
			// Log the command (C = Client sending)
			logOutput(clientIP, serverIP, "C", line)
			_, err = serverConn.Write([]byte(line))
			if err != nil {
				log.Printf("Write error to server: %v", err)
				return
			}
		}
	}()

	// Server -> Client (responses)
	go func() {
		defer wg.Done()
		reader := bufio.NewReader(serverConn)
		for {
			line, err := reader.ReadString('\n')
			if err != nil {
				if err != io.EOF {
					log.Printf("Read error from server: %v", err)
				}
				return
			}
			// Log the response (S = Server sending)
			logOutput(serverIP, clientIP, "S", line)
			_, err = clientConn.Write([]byte(line))
			if err != nil {
				log.Printf("Write error to client: %v", err)
				return
			}
		}
	}()

	wg.Wait()
}

// handleIncoming handles incoming SMTP connections (external -> Postfix)
func handleIncoming(clientConn net.Conn, postfixAddr string) {
	clientIP, _, _ := net.SplitHostPort(clientConn.RemoteAddr().String())
	logOutput(clientIP, serverIP, "CONNECT", "")
	defer func() {
		logOutput(clientIP, serverIP, "DISCONNECT", "")
		clientConn.Close()
	}()

	// Connect to Postfix
	serverConn, err := net.Dial("tcp", postfixAddr)
	if err != nil {
		log.Printf("Failed to connect to Postfix: %v", err)
		return
	}
	defer serverConn.Close()

	serverReader := bufio.NewReader(serverConn)
	clientReader := bufio.NewReader(clientConn)

	// Read initial banner from Postfix
	banner, err := serverReader.ReadString('\n')
	if err != nil {
		log.Printf("Failed to read banner: %v", err)
		return
	}

	// Send XCLIENT to Postfix to pass original client IP
	xclient := fmt.Sprintf("XCLIENT ADDR=%s\r\n", clientIP)
	_, err = serverConn.Write([]byte(xclient))
	if err != nil {
		log.Printf("Failed to send XCLIENT: %v", err)
		return
	}

	// Read XCLIENT response
	_, err = serverReader.ReadString('\n')
	if err != nil {
		log.Printf("Failed to read XCLIENT response: %v", err)
		return
	}

	// Send banner to client
	logOutput(serverIP, clientIP, "S", banner)
	_, err = clientConn.Write([]byte(banner))
	if err != nil {
		log.Printf("Failed to send banner to client: %v", err)
		return
	}

	// Proxy the rest of the conversation
	var wg sync.WaitGroup
	wg.Add(2)

	// Client -> Server
	go func() {
		defer wg.Done()
		for {
			line, err := clientReader.ReadString('\n')
			if err != nil {
				return
			}
			logOutput(clientIP, serverIP, "C", line)
			_, err = serverConn.Write([]byte(line))
			if err != nil {
				return
			}
		}
	}()

	// Server -> Client
	go func() {
		defer wg.Done()
		for {
			line, err := serverReader.ReadString('\n')
			if err != nil {
				return
			}
			logOutput(serverIP, clientIP, "S", line)
			_, err = clientConn.Write([]byte(line))
			if err != nil {
				return
			}
		}
	}()

	wg.Wait()
}

// handleOutgoing handles outgoing SMTP connections (Postfix -> external)
func handleOutgoing(clientConn net.Conn) {
	logOutput(serverIP, relayHost, "CONNECT", "")
	defer func() {
		logOutput(serverIP, relayHost, "DISCONNECT", "")
		clientConn.Close()
	}()

	if relayHost == "" {
		log.Printf("No relay host configured, rejecting outgoing connection")
		clientConn.Write([]byte("421 No relay host configured\r\n"))
		return
	}

	// Connect to remote server
	serverConn, err := net.Dial("tcp", relayHost)
	if err != nil {
		log.Printf("Failed to connect to relay %s: %v", relayHost, err)
		clientConn.Write([]byte("421 Cannot connect to relay server\r\n"))
		return
	}
	defer serverConn.Close()

	clientReader := bufio.NewReader(clientConn)
	serverReader := bufio.NewReader(serverConn)

	// Read and forward remote banner to Postfix
	remoteBanner, err := serverReader.ReadString('\n')
	if err != nil {
		log.Printf("Failed to read remote banner: %v", err)
		return
	}
	logOutput(relayHost, serverIP, "S", remoteBanner)
	clientConn.Write([]byte(remoteBanner))

	// Proxy the conversation
	for {
		line, err := clientReader.ReadString('\n')
		if err != nil {
			return
		}

		upperLine := strings.ToUpper(strings.TrimSpace(line))

		// Log and forward command to remote (C = local server sending to relay)
		logOutput(serverIP, relayHost, "C", line)
		serverConn.Write([]byte(line))

		// Handle DATA specially
		if strings.HasPrefix(upperLine, "DATA") {
			resp, err := serverReader.ReadString('\n')
			if err != nil {
				return
			}
			logOutput(relayHost, serverIP, "S", resp)
			clientConn.Write([]byte(resp))

			// If 354, read data until "."
			if strings.HasPrefix(resp, "354") {
				for {
					dataLine, err := clientReader.ReadString('\n')
					if err != nil {
						return
					}
					logOutput(serverIP, relayHost, "C", dataLine)
					serverConn.Write([]byte(dataLine))
					if strings.TrimSpace(dataLine) == "." {
						break
					}
				}
				// Read final response
				finalResp, err := serverReader.ReadString('\n')
				if err != nil {
					return
				}
				logOutput(relayHost, serverIP, "S", finalResp)
				clientConn.Write([]byte(finalResp))
			}
			continue
		}

		// Regular command - read response (may be multi-line)
		for {
			resp, err := serverReader.ReadString('\n')
			if err != nil {
				return
			}
			logOutput(relayHost, serverIP, "S", resp)
			clientConn.Write([]byte(resp))
			if len(resp) >= 4 && resp[3] != '-' {
				break
			}
		}

		// Handle QUIT
		if strings.HasPrefix(upperLine, "QUIT") {
			return
		}
	}
}

func main() {
	incomingPort := flag.String("incoming", ":25", "Port for incoming SMTP (external -> Postfix)")
	outgoingPort := flag.String("outgoing", "", "Port for outgoing SMTP (Postfix -> external), empty to disable")
	postfixAddr := flag.String("postfix", "127.0.0.1:10025", "Postfix address")
	relay := flag.String("relay", "", "Relay host for outgoing mail (e.g., imap.b.test:25)")
	serverIPFlag := flag.String("ip", "", "Server IP address for logging")
	format := flag.String("format", "text", "Output format: json or text")
	flag.Parse()

	relayHost = *relay
	serverIP = *serverIPFlag
	outputFormat = *format

	log.SetOutput(os.Stderr)
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// Start incoming listener
	go func() {
		listener, err := net.Listen("tcp", *incomingPort)
		if err != nil {
			log.Fatalf("Failed to listen on %s: %v", *incomingPort, err)
		}
		log.Printf("Incoming proxy listening on %s", *incomingPort)

		for {
			conn, err := listener.Accept()
			if err != nil {
				log.Printf("Accept error: %v", err)
				continue
			}
			go handleIncoming(conn, *postfixAddr)
		}
	}()

	// Start outgoing listener (if configured)
	if *outgoingPort == "" {
		log.Printf("Outgoing proxy disabled (no -outgoing specified)")
		select {} // Block forever
	}

	listener, err := net.Listen("tcp", *outgoingPort)
	if err != nil {
		log.Fatalf("Failed to listen on %s: %v", *outgoingPort, err)
	}
	log.Printf("Outgoing proxy listening on %s", *outgoingPort)

	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Printf("Accept error: %v", err)
			continue
		}
		go handleOutgoing(conn)
	}
}
