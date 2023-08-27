FROM debian:12.1

WORKDIR /output

RUN echo "deb http://security.debian.org/debian-security bullseye-security main contrib non-free" > /etc/apt/sources.list

RUN apt-get update

RUN apt-get update -qq \
	&& apt-get install build-essential default-libmysqlclient-dev openssl libssl-dev cmake libboost-all-dev git -y

COPY entrypoint.sh /usr/local/bin
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
