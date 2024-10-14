FROM node:20-slim AS configs

RUN apt-get update

RUN apt-get install -y \
    build-essential \
    curl

RUN apt-get update

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

ENV PATH="/root/.cargo/bin:${PATH}"

RUN cargo install wasm-pack

WORKDIR /app

COPY Cargo.toml .
COPY Cargo.lock .

COPY pnpm-lock.yaml .
COPY pnpm-workspace.yaml .
COPY package.json .

COPY tsconfig.json /app/
COPY package.json /app/
COPY tsconfig.node.json /app/

COPY web/packages/build/package.json /app/web/packages/build/
COPY web/packages/design/package.json /app/web/packages/design/
COPY web/packages/shared/package.json /app/web/packages/shared/
COPY web/packages/teleport/package.json /app/web/packages/teleport/
COPY web/packages/teleterm/package.json /app/web/packages/teleterm/

COPY README.md e/web/telepor[t]/package.json /app/e/web/teleport/

RUN corepack enable

RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --ignore-scripts
