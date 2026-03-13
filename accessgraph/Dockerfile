# First stage: Build the Go application
FROM golang:1.25 AS builder

# Set the Current Working Directory inside the container
WORKDIR /app

ENV GOPATH "/go"
ENV GOROOT "/usr/local/go"
ENV GOOS "linux"
ENV CGO_ENABLED 1
ENV GOARCH "amd64"

COPY development/certs/server.key /var/lib/teleport-certs/server.key
COPY development/certs/server.crt /var/lib/teleport-certs/server.crt

RUN cp /var/lib/teleport-certs/server.crt /usr/local/share/ca-certificates/teleport.crt && update-ca-certificates

RUN go install github.com/air-verse/air@latest

ENTRYPOINT ["/go/bin/air"]
