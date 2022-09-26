FROM cosmtrek/air:latest as development

WORKDIR /app

RUN apt update && apt install tree gcc -y

COPY development/certs/server.key /var/lib/teleport-certs/server.key
COPY development/certs/server.crt /var/lib/teleport-certs/server.crt

RUN cp /var/lib/teleport-certs/server.crt /usr/local/share/ca-certificates/teleport.crt && update-ca-certificates

ENV GOPATH "/go"
ENV GOROOT "/usr/local/go"
ENV GOOS "linux"
ENV CGO_ENABLED 1
ENV GOARCH "arm64"

COPY teleport/go.mod go.mod
COPY teleport/go.sum go.sum

COPY teleport/api/go.mod api/go.mod
COPY teleport/api/go.sum api/go.sum

COPY teleport/api api
COPY teleport/lib lib
COPY teleport/tool tool
COPY teleport/e e

COPY teleport/constants.go constants.go
COPY teleport/metrics.go metrics.go
COPY teleport/version.go version.go

RUN go build -o build/tctl -ldflags '-w -s' ./e/tool/tctl

ENV DEBUG "1"
