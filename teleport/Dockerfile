FROM cosmtrek/air:latest as live-reload

WORKDIR /app

RUN apt update && apt install tree gcc -y

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

ARG TOOL_FOLDER

RUN --mount=type=cache,target=/root/.cache/go-build \
    go build -o build/tctl -ldflags '-w -s' ./${TOOL_FOLDER}/tctl

COPY development/certs/server.key /var/lib/teleport-certs/server.key
COPY development/certs/server.crt /var/lib/teleport-certs/server.crt

RUN cp /var/lib/teleport-certs/server.crt /usr/local/share/ca-certificates/teleport.crt && update-ca-certificates

ENV DEBUG "1"

RUN --mount=type=cache,target=/tctl-cache \
    tar cf /cache.tar /root/.cache/go-build

FROM live-reload as static

COPY teleport/webassets webassets

RUN --mount=type=cache,target=/root/.cache/go-build \
    go build -o build/teleport -ldflags '-w -s' -tags 'webassets_embed' ./${TOOL_FOLDER}/teleport

ENTRYPOINT ["/app/build/teleport", "start", "-d"]
