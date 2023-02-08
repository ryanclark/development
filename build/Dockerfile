FROM golang:1.19 as base

WORKDIR /app

ENV GOPATH "/go"
ENV GOROOT "/usr/local/go"
ENV GOOS "linux"
ENV CGO_ENABLED 1
ENV GOARCH "arm64"

RUN apt update && apt install tree gcc -y

COPY development/certs/server.key /var/lib/teleport-certs/server.key
COPY development/certs/server.crt /var/lib/teleport-certs/server.crt

RUN cp /var/lib/teleport-certs/server.crt /usr/local/share/ca-certificates/teleport.crt && update-ca-certificates

COPY teleport/go.mod go.mod
COPY teleport/go.sum go.sum

COPY teleport/api/go.mod api/go.mod
COPY teleport/api/go.sum api/go.sum

ARG TOOL_FOLDER

FROM base as tctl

COPY teleport/api api
COPY teleport/lib lib
COPY teleport/tool tool
COPY teleport/gen gen

COPY teleport/e e

COPY teleport/*.go .

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o /bin/tctl -ldflags '-w -s' ./${TOOL_FOLDER}/tctl

FROM base as live-reload

RUN go install github.com/cosmtrek/air@latest

COPY --from=tctl /bin/tctl /bin/tctl

ENV DEBUG "1"

ENTRYPOINT ["/go/bin/air"]

FROM base as teleport

COPY teleport/api api
COPY teleport/lib lib
COPY teleport/tool tool
COPY teleport/gen gen

COPY teleport/e e

COPY teleport/*.go .

COPY teleport/webassets webassets

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o /bin/teleport -ldflags '-w -s' -tags 'webassets_embed' ./${TOOL_FOLDER}/teleport

FROM base as static

COPY --from=tctl /bin/tctl /bin/tctl
COPY --from=teleport /bin/teleport /bin/teleport

ENV DEBUG "1"

ENTRYPOINT ["/bin/teleport", "start", "-d"]
