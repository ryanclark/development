ifeq ($(wildcard .e),)
export VITE_CONFIG_DIRECTORY = /app/teleport/web/packages/teleport
export TOOL_FOLDER = tool
export LICENSE_FILE = ../teleport/empty.pem
else
export VITE_CONFIG_DIRECTORY = /app/web
export TOOL_FOLDER = e/tool
export LICENSE_FILE = ../../teleport/e/fixtures/license-enterprise.pem
endif

## -- 🛟  Lifecycle --

.PHONY: start start-attach stop

## Starts all the Docker containers in detached mode % it waits for all containers to be running & healthy before finishing
start:
	docker compose up --remove-orphans -d --wait

## Starts all Docker containers and attaches to them
start-attach:
	docker compose up --remove-orphans

## Stops all the running Docker containers
stop:
	docker compose stop


## -- 🧹 Building & cleaning --

.PHONY: build clean down

## Builds the Docker images
build:
	docker compose build

## Removes all Docker containers and volumes
clean:
	docker compose down -v --remove-orphans --rmi all

## Removes all the containers
down:
	docker compose down

build-pull:
	docker compose build --pull

## -- 🔧 Setup --

.PHONY: build-rdp cert setup

## Creates a local self signed certificate % for `beast` and `*.teleport` via `mkcert`
cert:
	mkdir -p certs && mkcert -cert-file certs/server.crt -key-file certs/server.key beast "*.teleport" "*.beast"

## Creates the initial admin user % alias for `make tctl users add admin --roles=editor,access --logins=root,ubuntu,ec2-user`
setup: TCTL_ARGS="users add admin --roles=editor,access --logins=root,ubuntu,ec2-user"
setup:
	$(MAKE) tctl TCTL_ARGS=$(TCTL_ARGS)

build-rdp:
	docker buildx build --no-cache-filter rdpclient-builder -f build/Dockerfile ..

## -- 📟 Commands --

.PHONY: logs tctl teleport-logs teleport-shell

ifeq (logs,$(firstword $(MAKECMDGOALS)))
LOGS_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(LOGS_ARGS):;@:)
endif
## Runs `docker compose logs <command>` % if passing a flag such as `-f`, use `--`, such as `make logs -- -f frontend`
logs:
	docker compose logs $(LOGS_ARGS)

ifeq (tctl,$(firstword $(MAKECMDGOALS)))
TCTL_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(TCTL_ARGS):;@:)
endif
## Runs `tctl <command>` inside the Teleport container
tctl:
	docker compose exec beast /bin/tctl $(TCTL_ARGS)

## Shows and follows the logs from the Teleport container % alias for `make logs -- -f beast`
teleport-logs: LOGS_ARGS="-f beast"
teleport-logs:
	$(MAKE) logs LOGS_ARGS=$(LOGS_ARGS)

## Opens an interactive shell inside the Teleport container
teleport-shell:
	docker compose exec -it beast /bin/bash


.PHONY: delete-db-volume
delete-db-volume:
	docker compose down db -v

## -- ☁️  AWS --

.PHONY: aws-credentials

## Writes current AWS credentials to `aws.env` % exports AWS_* vars from your shell (works with SSO, assume-role, etc.)
aws-credentials:
	@env | grep '^AWS_' | grep -v 'AWS_PROFILE' > aws.env || \
		(echo "No AWS_* environment variables found. Export them first." && exit 1)
	@echo "AWS credentials written to aws.env"

## -- 🔧 Misc --

.PHONY: help
## Shows this help menu
help:
	@echo "🚀 \033[94mTeleport Development Environment\033[39m"
	@echo ''
	@echo "Usage: \033[92mmake\033[39m \033[93m<target>\033[39m \033[2m[command]\033[22m"
	@awk '{ \
			if ($$0 ~ /^[a-zA-Z\-\_0-9.]+:/) { \
				helpCommand = substr($$0, 0, index($$0, ":") - 1); \
				if (helpMessage) { \
					printf "\033[96m%-20s\033[0m \033[97m%s\033[2m%s\033[22m\n", \
						helpCommand, helpMessage, description; \
					helpMessage = ""; \
					description = ""; \
				} \
			} else if ($$0 ~ /^## --/) { \
				if (helpMessage) { \
					helpMessage = helpMessage"\n                     "substr($$0, 5); \
				} else { \
					headerTitle = substr($$0, 7); \
					headerTitle = substr(headerTitle, 0, index(headerTitle, "-") - 1); \
					print "\n\033[1m"headerTitle"\033[22m\n" \
				} \
			} else if ($$0 ~ /^##/) { \
				if (helpMessage) { \
					helpMessage = helpMessage"\n                     "substr($$0, 5); \
				} else { \
					helpMessage = substr($$0, 3); \
					if (helpMessage ~ /%/) { \
						helpMessage = substr(helpMessage, 0, index($$0, "%") - 3); \
						description = substr($$0, index($$0, "%") + 2, length($$0)); \
						description = "("description")"; \
					} \
				} \
			} else { \
				if (helpMessage) { \
					print "\n                     "helpMessage"\n" \
				} \
				helpMessage = ""; \
				description = ""; \
			} \
		}' \
		$(MAKEFILE_LIST)
