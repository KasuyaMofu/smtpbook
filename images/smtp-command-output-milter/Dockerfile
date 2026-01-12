FROM golang:1.22-alpine AS builder

WORKDIR /app

COPY go.mod go.sum* ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -o smtp-command-output-milter .

FROM alpine:latest

COPY --from=builder /app/smtp-command-output-milter /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/smtp-command-output-milter"]
CMD ["-listen", "inet:10025@0.0.0.0"]
