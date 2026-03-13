FROM golang:1.25 AS base

WORKDIR /app

ENV GOPATH "/go"
ENV GOROOT "/usr/local/go"
ENV GOOS "linux"
ENV CGO_ENABLED 1
ENV GOARCH "amd64"

COPY development/certs/server.key /var/lib/teleport-certs/server.key
COPY development/certs/server.crt /var/lib/teleport-certs/server.crt

RUN cp /var/lib/teleport-certs/server.crt /usr/local/share/ca-certificates/teleport.crt && update-ca-certificates

COPY teleport/go.mod go.mod
COPY teleport/go.sum go.sum

COPY teleport/api/go.mod api/go.mod
COPY teleport/api/go.sum api/go.sum

RUN go mod download

ARG TOOL_FOLDER

# --- Rust/RDP client build stage ---
FROM base AS rdpclient-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gcc pkg-config libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    --default-toolchain stable \
    --target x86_64-unknown-linux-gnu

ENV PATH="/root/.cargo/bin:${PATH}"

COPY teleport/lib/srv/desktop/rdp/rdpclient lib/srv/desktop/rdp/rdpclient
COPY teleport/lib/srv/desktop/rdp/decoder lib/srv/desktop/rdp/decoder
COPY teleport/web/packages/shared/libs/ironrdp web/packages/shared/libs/ironrdp
COPY teleport/web/packages/shared/player web/packages/shared/player
COPY teleport/Cargo.toml Cargo.toml
COPY teleport/Cargo.lock Cargo.lock

RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo build --release --target x86_64-unknown-linux-gnu \
    && mkdir -p /out \
    && cp target/x86_64-unknown-linux-gnu/release/librdp_client.a /out/ \
    && cp lib/srv/desktop/rdp/rdpclient/librdpclient.h /out/

FROM base AS tctl

#RUN dpkg --add-architecture amd64 \
#    && apt-get update \
#    && apt-get install -y --no-install-recommends gcc-x86-64-linux-gnu libc6-dev-amd64-cross

ENV GOPATH "/go"
ENV GOROOT "/usr/local/go"
ENV GOOS "linux"
ENV CGO_ENABLED 1
ENV GOARCH "amd64"

COPY teleport/api api
COPY teleport/entitlements entitlements
COPY teleport/lib lib
COPY teleport/integrations integrations
COPY teleport/tool tool
COPY teleport/gen gen

COPY teleport/e e

COPY teleport/*.go .

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o /bin/tctl -ldflags '-w -s' ./tool/tctl

FROM golang:1.25 AS live-reload

COPY development/certs/server.key /var/lib/teleport-certs/server.key
COPY development/certs/server.crt /var/lib/teleport-certs/server.crt

RUN cp /var/lib/teleport-certs/server.crt /usr/local/share/ca-certificates/teleport.crt && update-ca-certificates

RUN go install github.com/air-verse/air@latest

COPY access-graph/keys/server.crt /var/lib/teleport-certs/access-graph.crt
COPY access-graph/keys/ca.crt /var/lib/teleport-certs/access-graph-ca.crt

RUN cp /var/lib/teleport-certs/access-graph.crt /usr/local/share/ca-certificates/access-graph.crt && update-ca-certificates
RUN cp /var/lib/teleport-certs/access-graph-ca.crt /usr/local/share/ca-certificates/access-graph-ca.crt && update-ca-certificates

COPY --from=tctl /bin/tctl /bin/tctl
COPY --from=rdpclient-builder /out/librdp_client.a /usr/local/lib/librdp_client.a
COPY --from=rdpclient-builder /out/librdpclient.h /usr/local/lib/librdpclient.h

ENV DEBUG "1"

ENTRYPOINT ["sh", "-c", "mkdir -p /app/target/x86_64-unknown-linux-gnu/release && cp /usr/local/lib/librdp_client.a /app/target/x86_64-unknown-linux-gnu/release/librdp_client.a && cp /usr/local/lib/librdpclient.h /app/lib/srv/desktop/rdp/rdpclient/librdpclient.h && exec /go/bin/air \"$@\"", "--"]

FROM base AS teleport

ENV GOPATH "/go"
ENV GOROOT "/usr/local/go"
ENV GOOS "linux"
ENV CGO_ENABLED 1
ENV GOARCH "amd64"

COPY teleport/api api
COPY teleport/entitlements entitlements
COPY teleport/lib lib
COPY teleport/integrations integrations
COPY teleport/tool tool
COPY teleport/gen gen

COPY teleport/e e

COPY teleport/*.go .

COPY teleport/webassets webassets

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o /bin/teleport -ldflags '-w -s' -tags 'webassets_embed' ./${TOOL_FOLDER}/teleport

FROM base AS static

COPY --from=tctl /bin/tctl /bin/tctl
COPY --from=teleport /bin/teleport /bin/teleport

ENV DEBUG "1"

ENTRYPOINT ["/bin/teleport", "start", "-d"]
