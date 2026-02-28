# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: amejia <amejia@student.42.fr>              +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2023/07/31 00:30:51 by amejia            #+#    #+#              #
#    Updated: 2023/07/31 00:46:17 by amejia           ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

FROM debian:stable-slim



RUN apt-get update && apt-get install -y mariadb-server mariadb-client
COPY 50-server.conf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY setupdb.sh /usr/src/app/setupdb.sh
RUN chmod +x /usr/src/app/setupdb.sh
ARG MYSQL_USER
ENV MYSQL_USER=$MYSQL_USER
ARG MYSQL_PASSWORD  
ENV MYSQL_PASSWORD=$MYSQL_PASSWORD
ARG MYSQL_ADMIN_USER
ENV MYSQL_ADMIN_USER=$MYSQL_ADMIN_USER
ARG MYSQL_ADMIN_PASSWORD
ENV MYSQL_ADMIN_PASSWORD=$MYSQL_ADMIN_PASSWORD
ARG MYSQL_ROOT_PASSWORD
ENV MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
RUN /usr/src/app/setupdb.sh
ENV MYSQL_USER=
ENV MYSQL_PASSWORD=
ENV MYSQL_ADMIN_USER=
ENV MYSQL_ADMIN_PASSWORD=
ENV MYSQL_ROOT_PASSWORD=
EXPOSE 3306


ENTRYPOINT [ "mysqld_safe" ] 
