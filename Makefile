ifeq (yarn,$(firstword $(MAKECMDGOALS)))
YARN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(YARN_ARGS):;@:)
endif

ifeq (tctl,$(firstword $(MAKECMDGOALS)))
TCTL_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(TCTL_ARGS):;@:)
endif


.PHONY: start build yarn tctl frontend-shell teleport-shell setup clean cert

start:
	docker compose up

build:
	docker compose up --build

yarn:
	docker compose exec frontend yarn $(YARN_ARGS)

tctl:
	docker compose exec go.teleport /app/build/tctl $(TCTL_ARGS)

frontend-shell:
	docker compose exec -it frontend /bin/bash

teleport-shell:
	docker compose exec -it go.teleport /bin/bash

setup: TCTL_ARGS="users add admin --roles=editor,access --logins=root,ubuntu,ec2-user"
setup:
	$(MAKE) tctl TCTL_ARGS=$(TCTL_ARGS)

clean:
	docker compose down -v --remove-orphans

cert:
	mkdir -p certs && mkcert -cert-file certs/server.crt -key-file certs/server.key go.teleport "*.teleport"
