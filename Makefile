.PHONY: help
help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: clean
clean: ## Remove the headscale server
	@docker compose down -v

.PHONY: build
build: ## Build the headscale server
	@docker compose build

.PHONY: up
up: ## Start the headscale server
	@docker compose up -d
	@docker compose exec headscale headscale users create headscale --force

.PHONY: down
down: ## Stop the headscale server
	@docker compose down

.PHONY: restart
restart: down up ## Restart the headscale server

.PHONY: logs
logs: ## Show the headscale server logs
	@docker compose logs -f

.PHONY: shell
shell: ## Open a shell in the headscale server container
	@docker compose exec headscale /bin/bash

.PHONY: info
info: ## Show the headscale server info
	@echo "Headscale server info:"
	@docker compose exec tor cat /var/lib/tor/hidden_service/hostname

.PHONY: status
status: ## Show the headscale networks status
	@docker compose exec headscale headscale nodes list

TAILSCALE_CONNECT:=$(shell openssl rand -hex 4 | tr -d '\n')
.PHONY: connect
connect: ## Generate a new connection string
	@cat scripts/bootstrap.sh | sed "s/^Environment=SOCAT_REMOTE=/Environment=SOCAT_REMOTE=$(shell docker compose exec tor cat /var/lib/tor/hidden_service/hostname):80/"
	@echo "tailscale up --login-server http://localhost:8514 --auth-key $(shell docker compose exec headscale headscale preauthkeys create -u headscale)"
