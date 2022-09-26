FROM node:16.17-slim as node-dependencies

WORKDIR /app

COPY yarn.lock .
COPY package.json .
COPY tsconfig.json .

# copy only package.json files
COPY packages/build/package.json /app/packages/build/
COPY packages/design/package.json /app/packages/design/
COPY packages/shared/package.json /app/packages/shared/
COPY packages/teleport/package.json /app/packages/teleport/
COPY packages/teleterm/package.json /app/packages/teleterm/

# copy enterprise package.json files if present
COPY README.md packages/webapps.e/telepor[t]/package.json /app/packages/webapps.e/teleport/

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
