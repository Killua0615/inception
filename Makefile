COMPOSE_FILE := srcs/docker-compose.yml
ENV_FILE := srcs/.env
LOGIN ?= $(shell whoami)
DATA_DIR := /home/$(LOGIN)/data

all: up

up:
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) up -d --build

down:
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) down

rebuild:
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) build --no-cache

clean:
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) down

fclean:
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) down -v --rmi all --remove-orphans
	@sudo rm -rf $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress

status:
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) ps

logs:
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) logs -f

re: fclean up

.PHONY: all up down rebuild clean fclean status logs re
