FROM node:20-slim as configs

WORKDIR /app

RUN mkdir -p /app/web

COPY access-graph/package.json /app
COPY access-graph/yarn.lock /app
COPY access-graph/tsconfig.json /app
COPY access-graph/tsconfig.node.json /app

COPY access-graph/web/package.json /app/web

FROM configs as node-dependencies

# download and install npm dependencies
ARG YARN_FROZEN_LOCKFILE
RUN yarn install --ignore-scripts

RUN yarn $NPM_SCRIPT $([ -z $OUTPUT ] || echo --output-path=$OUTPUT)

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
