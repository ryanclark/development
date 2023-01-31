FROM node:16.17-slim as configs

WORKDIR /app

COPY yarn.lock .
COPY package.json .

COPY tsconfig.json /app/
COPY web/package.json /app/web/

# copy only package.json files
COPY web/packages/build/package.json /app/web/packages/build/
COPY web/packages/design/package.json /app/web/packages/design/
COPY web/packages/shared/package.json /app/web/packages/shared/
COPY web/packages/teleport/package.json /app/web/packages/teleport/
COPY web/packages/teleterm/package.json /app/web/packages/teleterm/

# copy enterprise package.json files if present
COPY README.md e/web/telepor[t]/package.json /app/e/web/teleport/

FROM configs as node-dependencies

# download and install npm dependencies
ARG YARN_FROZEN_LOCKFILE
RUN yarn install --ignore-scripts

# copy the rest of the files and run yarn build command

FROM node-dependencies as teleport-build

COPY packages/ packages/

ARG NPM_SCRIPT=nop
ARG OUTPUT

# run npm script with optional --output-path parameter
RUN yarn $NPM_SCRIPT $([ -z $OUTPUT ] || echo --output-path=$OUTPUT)

FROM node-dependencies as python-git

RUN apt-get update && apt-get install -y python3 git

FROM python-git as term-build

RUN apt-get install -y g++ make

COPY packages/ packages/

RUN yarn install

ARG NPM_SCRIPT=nop
ARG OUTPUT
ARG CONNECT_TSH_BIN_PATH
ENV CONNECT_TSH_BIN_PATH=$CONNECT_TSH_BIN_PATH

# run npm script with optional --output-path parameter
RUN yarn $NPM_SCRIPT $([ -z $OUTPUT ] || echo --output-path=$OUTPUT)

FROM python-git as lint

RUN apt-get install -y python3-pip && pip3 install pre-commit
RUN git init .

COPY packages/ packages/

COPY .eslintignore .
COPY .gitignore .
COPY .eslintrc.js .
COPY .pre-commit-config.yaml .
COPY .prettierignore .
COPY .prettierrc .

RUN git add --all

RUN pre-commit run --show-diff-on-failure --color=always --all-files
