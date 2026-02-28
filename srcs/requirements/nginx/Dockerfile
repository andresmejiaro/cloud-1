
FROM debian:stable-slim

RUN apt-get update && apt-get install -y nginx curl && mkdir -p /etc/nginx/certs

COPY ngnix.conf /etc/nginx/conf.d/default.conf
COPY sitesEnabled-Default.conf /etc/nginx/sites-enabled/default
COPY localhost.crt /etc/nginx/certs/localhost.crt
COPY localhost.key /etc/nginx/certs/localhost.key

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]