# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: amejia <amejia@student.42.fr>              +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2023/07/31 00:03:16 by amejia            #+#    #+#              #
#    Updated: 2023/10/22 18:56:47 by amejia           ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

build:
	docker compose -f srcs/docker-compose.yml build

up:
	docker compose -f srcs/docker-compose.yml up 

down:
	docker compose -f srcs/docker-compose.yml down

re: oblivion build up

oblivion: full_stop image_del volume_del network_del

full_stop:
	-docker ps -qa | xargs -r docker stop 
	-docker ps -qa | xargs -r docker rm 

image_del:
	-docker images -qa | xargs -r docker rmi -f 
	

volume_del:
	-docker volume ls -q | xargs -r docker volume rm 

network_del:
	-docker network ls -q | xargs -r docker network rm

.PHONY: build up down oblivion image_del volume_del network_del full_stop
