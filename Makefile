all: up

up:
	@cd srcs && docker-compose up --build -d

down:
	@cd srcs && docker-compose down

clean: down
	@docker system prune -af

fclean: clean
	@docker volume rm srcs_mariadb_data srcs_wordpress_data 2>/dev/null || true

eval_clean:
	@echo "Cleaning all Docker resources for evaluation..."
	@docker stop $$(docker ps -qa) 2>/dev/null || true
	@docker rm $$(docker ps -qa) 2>/dev/null || true
	@docker rmi -f $$(docker images -qa) 2>/dev/null || true
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@docker network rm $$(docker network ls -q) 2>/dev/null || true
	@echo "Docker cleanup complete!"

re: fclean all

.PHONY: all up down clean fclean re eval_clean