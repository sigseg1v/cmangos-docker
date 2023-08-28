FROM ubuntu:20.04 as build

RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && echo $CONTAINER_TIMEZONE > /etc/timezone
RUN apt update
RUN apt-get install -y tzdata

RUN apt-get update -qq \
	&& apt-get install build-essential gcc g++ automake git-core autoconf make patch libmysql++-dev mysql-server libtool libssl-dev grep binutils zlibc libc6 libbz2-dev cmake subversion libboost-all-dev -y \
	&& git clone https://github.com/cmangos/mangos-wotlk.git -b master --recursive server \
	&& mkdir -p server/build \
	&& cd server/build \
	&& cmake .. -DCMAKE_INSTALL_PREFIX=/server -DBUILD_GAME_SERVER=1 -DBUILD_LOGIN_SERVER=1 -DBUILD_EXTRACTORS=0 -DPCH=1 -DBUILD_PLAYERBOT=1 \
	&& make -j4 \
	&& make install -j4

FROM ubuntu:20.04 as image
LABEL title="cmangos docker" \
	url1="https://cbrgm.net" \
	twitter="@chrisbargmann" \
	maintainer="Christian Bargmann" \
	version="1.0"

# need to set args and envs this way to get default values that are still able to be overidden via docker-compose
# see: https://stackoverflow.com/a/56356911/19017508
ARG MYSQL_DATABASE_REALM=wotlkrealmd
ARG MYSQL_DATABASE_WORLD=wotlkmangos
ARG MYSQL_DATABASE_CHARACTER=wotlkcharacters
ARG MYSQL_DATABASE_LOGS=wotlklogs
ARG MYSQL_MANGOS_USER=mangos
ARG MYSQL_MANGOS_PWD=mangos
ARG MANGOS_GAMETYPE=1
ARG MANGOS_MOTD="Welcome!"
ARG MANGOS_REALM_NAME=MyNewServer
ARG MANGOS_SERVER_IP=0.0.0.0
ARG MANGOS_SERVER_PUBLIC_IP=127.0.0.1
ARG MANGOS_DISABLE_PLAYERBOTS=0
ARG MANGOS_ALLOW_AUCTIONBOT_SELLER=0
ARG MANGOS_ALLOW_AUCTIONBOT_BUYER=0
ARG MANGOS_REV=master
ARG DB_REV=master

ENV MYSQL_DATABASE_REALM=${MYSQL_DATABASE_REALM}
ENV MYSQL_DATABASE_WORLD=${MYSQL_DATABASE_WORLD}
ENV MYSQL_DATABASE_CHARACTER=${MYSQL_DATABASE_CHARACTER}
ENV MYSQL_DATABASE_LOGS=${MYSQL_DATABASE_LOGS}
ENV MYSQL_MANGOS_USER=${MYSQL_MANGOS_USER}
ENV MYSQL_MANGOS_PWD=${MYSQL_MANGOS_PWD}
ENV MANGOS_GAMETYPE=${MANGOS_GAMETYPE}
ENV MANGOS_MOTD=${MANGOS_MOTD}
ENV MANGOS_REALM_NAME=${MANGOS_REALM_NAME}
ENV MANGOS_SERVER_IP=${MANGOS_SERVER_IP}
ENV MANGOS_SERVER_PUBLIC_IP=${MANGOS_SERVER_PUBLIC_IP}
ENV MANGOS_DISABLE_PLAYERBOTS=${MANGOS_DISABLE_PLAYERBOTS}
ENV MANGOS_ALLOW_AUCTIONBOT_SELLER=${MANGOS_ALLOW_AUCTIONBOT_SELLER}
ENV MANGOS_ALLOW_AUCTIONBOT_BUYER=${MANGOS_ALLOW_AUCTIONBOT_BUYER}
ENV MANGOS_REV=${MANGOS_REV}
ENV DB_REV=${DB_REV}

WORKDIR /opt/mangos

COPY --from=build /server/bin bin
COPY --from=build /server/etc etc
COPY --from=build /server/src/game/AuctionHouseBot/ahbot.conf.dist.in etc/ahbot.conf.dist
COPY entrypoint.sh /usr/local/bin
COPY supervisord.conf /etc/

RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && echo $CONTAINER_TIMEZONE > /etc/timezone
RUN apt update
RUN apt-get install -y tzdata telnet

RUN mkdir -p /opt/mangos \
	&& apt-get update -y \
	&& apt-get upgrade -y \
	&& apt-get install wget git mariadb-client libmariadbclient-dev supervisor -y \
	&& mv etc/mangosd.conf.dist etc/mangosd.conf \
	&& mv etc/realmd.conf.dist etc/realmd.conf \
	&& mv etc/ahbot.conf.dist etc/ahbot.conf \
	&& mv etc/playerbot.conf.dist etc/playerbot.conf \
	&& mv etc/anticheat.conf.dist etc/anticheat.conf \
	&& mkdir -p /var/log/supervisor/ \
	&& touch /var/log/supervisord.log \
	&& useradd -m -s /bin/bash mangos \
	&& chmod a+x bin/* \
	&& chown -R mangos:mangos . \
	&& chown -R mangos:mangos /var/log/supervisord.log \
	&& chown -R mangos:mangos /var/log/supervisor

USER mangos
EXPOSE 8085/tcp 8085/udp
EXPOSE 3724/tcp 3724/udp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]
