all: up

up:
	@cd srcs && docker-compose up --build -d

down:
	@cd srcs && docker-compose down

clean: down
	@docker system prune -af

fclean: clean
	@docker volume rm srcs_mariadb_data srcs_wordpress_data 2>/dev/null || true

re: fclean all

.PHONY: all up down clean fclean re