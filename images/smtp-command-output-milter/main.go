package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net"
	"net/textproto"
	"os"
	"strings"

	"github.com/emersion/go-milter"
)

type LogEntry struct {
	IP   string `json:"ip"`
	Mode string `json:"mode"`
	Data string `json:"data"`
}

func logJSON(ip, mode, data string) {
	entry := LogEntry{
		IP:   ip,
		Mode: mode,
		Data: strings.TrimSpace(data),
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

type SMTPLoggerMilter struct {
	milter.NoOpMilter
	from     string
	to       []string
	hostname string
	clientIP string
}

var serverHostname string

func (m *SMTPLoggerMilter) Connect(host string, family string, port uint16, addr net.IP, mod *milter.Modifier) (milter.Response, error) {
	m.clientIP = addr.String()
	logJSON(m.clientIP, "S", fmt.Sprintf("220 %s ESMTP", serverHostname))
	logJSON(m.clientIP, "R", fmt.Sprintf("CONNECT from %s [%s]", host, addr.String()))
	return milter.RespContinue, nil
}

func (m *SMTPLoggerMilter) Helo(name string, mod *milter.Modifier) (milter.Response, error) {
	logJSON(m.clientIP, "R", fmt.Sprintf("EHLO %s", name))
	logJSON(m.clientIP, "S", fmt.Sprintf("250 %s", serverHostname))
	return milter.RespContinue, nil
}

func (m *SMTPLoggerMilter) MailFrom(from string, mod *milter.Modifier) (milter.Response, error) {
	m.from = from
	logJSON(m.clientIP, "R", fmt.Sprintf("MAIL FROM:<%s>", from))
	logJSON(m.clientIP, "S", "250 2.1.0 Ok")
	return milter.RespContinue, nil
}

func (m *SMTPLoggerMilter) RcptTo(rcptTo string, mod *milter.Modifier) (milter.Response, error) {
	m.to = append(m.to, rcptTo)
	logJSON(m.clientIP, "R", fmt.Sprintf("RCPT TO:<%s>", rcptTo))
	logJSON(m.clientIP, "S", "250 2.1.5 Ok")
	return milter.RespContinue, nil
}

func (m *SMTPLoggerMilter) Header(name, value string, mod *milter.Modifier) (milter.Response, error) {
	logJSON(m.clientIP, "R", fmt.Sprintf("HEADER %s: %s", name, value))
	return milter.RespContinue, nil
}

func (m *SMTPLoggerMilter) Headers(headers textproto.MIMEHeader, mod *milter.Modifier) (milter.Response, error) {
	logJSON(m.clientIP, "R", "DATA")
	logJSON(m.clientIP, "S", "354 End data with <CR><LF>.<CR><LF>")
	return milter.RespContinue, nil
}

func (m *SMTPLoggerMilter) Body(mod *milter.Modifier) (milter.Response, error) {
	logJSON(m.clientIP, "R", ".")
	logJSON(m.clientIP, "S", "250 2.0.0 Ok: queued")
	return milter.RespAccept, nil
}

func (m *SMTPLoggerMilter) BodyChunk(chunk []byte, mod *milter.Modifier) (milter.Response, error) {
	return milter.RespContinue, nil
}

func (m *SMTPLoggerMilter) Abort(mod *milter.Modifier) error {
	logJSON(m.clientIP, "R", "ABORT")
	m.from = ""
	m.to = nil
	return nil
}

func main() {
	listenAddr := flag.String("listen", "inet:10025@0.0.0.0", "Listen address (unix:/path or inet:port@host)")
	hostname := flag.String("hostname", "localhost", "Server hostname for responses")
	flag.Parse()

	serverHostname = *hostname

	log.SetOutput(os.Stderr)
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	server := milter.Server{
		NewMilter: func() milter.Milter {
			return &SMTPLoggerMilter{}
		},
		Actions:  milter.OptAddHeader | milter.OptChangeHeader,
		Protocol: 0,
	}

	var listener net.Listener
	var err error

	if strings.HasPrefix(*listenAddr, "unix:") {
		socketPath := strings.TrimPrefix(*listenAddr, "unix:")
		os.Remove(socketPath)
		listener, err = net.Listen("unix", socketPath)
		if err != nil {
			log.Fatalf("Failed to listen on unix socket %s: %v", socketPath, err)
		}
		os.Chmod(socketPath, 0666)
		log.Printf("Listening on unix:%s", socketPath)
	} else if strings.HasPrefix(*listenAddr, "inet:") {
		addrPart := strings.TrimPrefix(*listenAddr, "inet:")
		parts := strings.Split(addrPart, "@")
		var addr string
		if len(parts) == 2 {
			addr = fmt.Sprintf("%s:%s", parts[1], parts[0])
		} else {
			addr = fmt.Sprintf("0.0.0.0:%s", parts[0])
		}
		listener, err = net.Listen("tcp", addr)
		if err != nil {
			log.Fatalf("Failed to listen on %s: %v", addr, err)
		}
		log.Printf("Listening on %s", addr)
	} else {
		log.Fatalf("Invalid listen address format: %s", *listenAddr)
	}

	defer listener.Close()

	log.Println("SMTP Command Logger Milter started")

	if err := server.Serve(listener); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}
