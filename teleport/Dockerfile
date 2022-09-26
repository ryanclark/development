FROM alpine as cache-import

RUN --mount=type=cache,target=/teleport-cache \
    tar xf /cache.tar -C /cache/teleport > /dev/null 2>&1 || mkdir -p /cache/teleport

RUN --mount=type=cache,target=/tctl-cache \
    tar xf /cache.tar -C /cache/tctl > /dev/null 2>&1 || mkdir -p /cache/tctl

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

COPY --from=cache-import /cache/tctl /root/.cache/go-build/

ARG TOOL_FOLDER

RUN ls -al /root/.cache/go-build/ && \
    go build -o build/tctl -ldflags '-w -s' ./${TOOL_FOLDER}/tctl && \
    ls -al /root/.cache/go-build/

COPY development/certs/server.key /var/lib/teleport-certs/server.key
COPY development/certs/server.crt /var/lib/teleport-certs/server.crt

RUN cp /var/lib/teleport-certs/server.crt /usr/local/share/ca-certificates/teleport.crt && update-ca-certificates

ENV DEBUG "1"

RUN --mount=type=cache,target=/tctl-cache \
    tar cf /cache.tar /root/.cache/go-build

FROM live-reload as static

COPY teleport/webassets webassets

COPY --from=cache-import /cache/teleport /root/.cache/go-build/

RUN ls -al /root/.cache/go-build/ && \
    go build -o build/teleport -ldflags '-w -s' -tags 'webassets_embed' ./${TOOL_FOLDER}/teleport && \
    ls -al /root/.cache/go-build/

RUN --mount=type=cache,target=/teleport-cache \
    tar cf /cache.tar /root/.cache/go-build

ENTRYPOINT ["/app/build/teleport", "start", "-d"]
