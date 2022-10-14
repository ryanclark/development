FROM golang:1.19 as build

ENV GOPATH "/go"
ENV GOROOT "/usr/local/go"
ENV GOOS "linux"
ENV CGO_ENABLED 1
ENV GOARCH "arm64"

WORKDIR /app

RUN apt update && apt install tree gcc -y

COPY development/certs/server.key /var/lib/teleport-certs/server.key
COPY development/certs/server.crt /var/lib/teleport-certs/server.crt

RUN cp /var/lib/teleport-certs/server.crt /usr/local/share/ca-certificates/teleport.crt && update-ca-certificates

COPY teleport/go.mod go.mod
COPY teleport/go.sum go.sum

COPY teleport/api/go.mod api/go.mod
COPY teleport/api/go.sum api/go.sum

COPY teleport/api api
COPY teleport/lib lib
COPY teleport/tool tool

COPY teleport/e e

COPY teleport/*.go .

ARG TOOL_FOLDER

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o bin/tctl -ldflags '-w -s' ./${TOOL_FOLDER}/tctl

ENV DEBUG "1"

FROM build as live-reload

RUN go install github.com/cosmtrek/air@latest

ENTRYPOINT ["/go/bin/air"]

FROM build as static

COPY teleport/api api
COPY teleport/lib lib
COPY teleport/tool tool

COPY teleport/e e

COPY teleport/*.go .

COPY teleport/webassets webassets

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o bin/teleport -ldflags '-w -s' -tags 'webassets_embed' ./${TOOL_FOLDER}/teleport

ENTRYPOINT ["/app/bin/teleport", "start", "-d"]
