FROM cosmtrek/air:latest as development

WORKDIR /app

RUN apt update && apt install tree gcc -y

COPY skaffold/certs/server.key /var/lib/teleport-certs/server.key
COPY skaffold/certs/server.crt /var/lib/teleport-certs/server.crt

RUN cp /var/lib/teleport-certs/server.crt /usr/local/share/ca-certificates/teleport.crt && update-ca-certificates

ENV GOPATH "/go"
ENV GOROOT "/usr/local/go"
ENV GOOS "linux"
ENV CGO_ENABLED 1
ENV GOARCH "arm64"

COPY go.mod go.mod
COPY go.sum go.sum

COPY api/go.mod api/go.mod
COPY api/go.sum api/go.sum

COPY api api
COPY lib lib
COPY tool tool
COPY e e

COPY constants.go constants.go
COPY metrics.go metrics.go
COPY version.go version.go

RUN go build -o build/tctl -ldflags '-w -s' ./e/tool/tctl

ENV DEBUG "1"
