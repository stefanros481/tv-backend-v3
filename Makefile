# TV Backend v3 - Makefile for administrative tasks

# Variables
COMPOSE_FILE := docker-compose.yml
ENV_FILE := .env

# Colors for better readability
COLOR_RESET := \033[0m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_BLUE := \033[34m

# Ensure .env file exists by copying .env.example if needed
ifneq ($(wildcard .env),)
    # .env exists
else
    $(shell cp .env.example .env)
endif

.PHONY: help up down restart logs clean ps status test pull update backup

help: ## Show help message
	@echo "$(COLOR_BLUE)TV Backend v3 - Admin Tasks$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_YELLOW)Usage:$(COLOR_RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(COLOR_GREEN)%-15s$(COLOR_RESET) %s\n", $$1, $$2}'
	@echo ""

up: ## Start all services
	@echo "$(COLOR_BLUE)Starting all services...$(COLOR_RESET)"
	docker compose up -d
	@echo "$(COLOR_GREEN)Services started!$(COLOR_RESET)"

up-build: ## Rebuild and start all services
	@echo "$(COLOR_BLUE)Rebuilding and starting all services...$(COLOR_RESET)"
	docker compose up -d --build
	@echo "$(COLOR_GREEN)Services rebuilt and started!$(COLOR_RESET)"

down: ## Stop all services
	@echo "$(COLOR_BLUE)Stopping all services...$(COLOR_RESET)"
	docker compose down
	@echo "$(COLOR_GREEN)Services stopped!$(COLOR_RESET)"

restart: down up ## Restart all services

logs: ## Show logs from all services
	docker compose logs -f

status: ## Check status of all services
	@echo "$(COLOR_BLUE)Checking service status...$(COLOR_RESET)"
	docker compose ps

ps: status ## Alias for status

clean: ## Remove all containers, volumes, and cached images
	@echo "$(COLOR_BLUE)Stopping all services and cleaning up...$(COLOR_RESET)"
	docker compose down -v --remove-orphans
	@echo "$(COLOR_GREEN)Clean-up complete!$(COLOR_RESET)"

test: ## Run tests
	@echo "$(COLOR_BLUE)Running tests...$(COLOR_RESET)"
	@echo "No tests configured yet."
	@echo "$(COLOR_GREEN)Test run complete!$(COLOR_RESET)"

pull: ## Pull latest images
	docker compose pull

update: pull up ## Pull latest images and restart services

db-connect: ## Connect to PostgreSQL CLI
	@echo "$(COLOR_BLUE)Connecting to PostgreSQL...$(COLOR_RESET)"
	docker exec -it tv-backend-postgres psql -U tv_user -d tv_streaming_db

redis-connect: ## Connect to Redis CLI
	@echo "$(COLOR_BLUE)Connecting to Redis...$(COLOR_RESET)"
	docker exec -it tv-backend-redis redis-cli

es-health: ## Check Elasticsearch health
	@echo "$(COLOR_BLUE)Checking Elasticsearch health...$(COLOR_RESET)"
	@if command -v jq >/dev/null 2>&1; then \
		curl -s http://localhost:9200/_cluster/health | jq '.'; \
	else \
		echo "$(COLOR_YELLOW)jq not installed, showing raw JSON:$(COLOR_RESET)"; \
		curl -s http://localhost:9200/_cluster/health; \
	fi

backup: ## Create backup of database
	@echo "$(COLOR_BLUE)Creating backup...$(COLOR_RESET)"
	@mkdir -p ./backups
	@docker exec tv-backend-postgres pg_dump -U tv_user -d tv_streaming_db -F c > ./backups/db_backup_$(shell date +%Y%m%d_%H%M%S).dump
	@echo "$(COLOR_GREEN)Backup created in ./backups directory!$(COLOR_RESET)"
