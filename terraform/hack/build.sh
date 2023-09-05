##!/bin/bash
set -eu

MANGOS_SERVER_PUBLIC_IP=${MANGOS_SERVER_PUBLIC_IP:-}

# template docker compose
echo $MANGOS_SERVER_PUBLIC_IP

cat << EOF > docker-compose.yml
version: '3'
services:

  mysql:
    image: 'mysql:5.7'
    restart: always
    ports:
      - 3306
    environment:
      MYSQL_ROOT_PASSWORD: 'changeme'

  server:
    depends_on:
      - mysql
    image: 'cbrgm/cmangos:wotlk'
    ports:
      - '8085:8085'
      - '3724:3724'
    restart: always
    environment:
      MYSQL_HOST: 'mysql'
      MYSQL_PORT: '3306'
      MYSQL_USER: 'root'
      MYSQL_PWD: 'changeme'
      MYSQL_MANGOS_USER: 'mangos'
      MYSQL_MANGOS_PWD: 'mangos'
      MANGOS_GAMETYPE: 6
      MANGOS_MOTD: 'Welcome!'
      MANGOS_REALM_NAME: 'MyNewServer'
      MANGOS_SERVER_PUBLIC_IP: '${MANGOS_SERVER_PUBLIC_IP}'
      MANGOS_DISABLE_PLAYERBOTS: 0
      MANGOS_AUCTIONBOT_SELL_CHANCE: 10
      MANGOS_AUCTIONBOT_BUY_CHANCE: 10
    volumes:
      - ./resources/maps:/opt/mangos/maps
      - ./resources/vmaps:/opt/mangos/vmaps
      - ./resources/mmaps:/opt/mangos/mmaps
      - ./resources/dbc:/opt/mangos/dbc

  phpmyadmin:
    image: 'phpmyadmin/phpmyadmin:latest'
    restart: always
    depends_on:
      - mysql
    ports:
      - '8080:80'
    environment:
       PMA_HOST: "mysql"
EOF

docker-compose up -d
