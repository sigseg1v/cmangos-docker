# Mangos Docker

## Extract map files from client

Build the extractor from this repository directory.

```
docker build -t cmangos-extractor extractors/
```

Then, change directory to the wotlk client and run the following:

Note 1: Ensure the path to the wotlk client does not contain any spaces.

Note 2: This can take a long time to run unless you have a SSD, or if you run in WSL (several hours).

```
docker run --rm -it -v "$(pwd)":/output cmangos-extractor
```

## Setup directories for resources and database

Make a `resources` folder to hold the extracted data.

```
mkdir resources
```

Copy `maps`, `mmaps`, `vmaps`, `dbc` and `Cameras` folders that were generated in your client directory into this `resources` directory.

Also make an empty folder for hosting the database data called `database`.

```
mkdir database
```

## Set important options

In docker-compose.yml set:
- MANGOS_GM_ACCOUNT
- MANGOS_GM_PWD
- MANGOS_SERVER_PUBLIC_IP

## Build and run container

Navigate to this directory, then build the mangos server

```
docker build -t "cmangos:wotlk" ./mangos
```

then, run the container.

```
docker-compose up
```

If you want to run in the background, use `docker-compose up -d` instead.

To stop the service and delete the containers (deletes database unless using volume mount on msql in docker-compose) use `docker-compose down`.

## Manage accounts

TODO

## Environment vars (set in docker-compose.yml):

* `MYSQL_HOST`: MySQL database host ip/dns name
* `MYSQL_PORT`: MySQL database port
* `MYSQL_USER`: MySQL database user
* `MYSQL_PWD`: MySQL database password
* `MYSQL_MANGOS_USER`: MySQL database user used for connections from server (Default: mangos)
* `MYSQL_MANGOS_PWD`: MySQL database user password used for connections from server (Default: mangos)
* `MANGOS_GM_ACCOUNT`: Gamemaster account name (Default: admin)
* `MANGOS_GM_PWD`: Gamemaster account password (Default: changeme)
* `MANGOS_GAMETYPE`: Realm Gametype (Default: 1 (PVP))
* `MANGOS_MOTD`: Message of the Day (Default: "Welcome!")
* `MANGOS_REALM_NAME`: Name of your realm (Default: MyNewServer)
* `MANGOS_SERVER_IP`: IP for mangosd and realmd port binding (Default 0.0.0.0)
* `MANGOS_SERVER_PUBLIC_IP`: Public IP for your mangos server (Default 127.0.0.1)
* `MANGOS_OVERRIDE_CONF_URL`: External mangosd.conf download
* `MANGOS_DISABLE_PLAYERBOTS`: Disable PlayerbotAI commands (Default: 0)
* `MANGOS_ALLOW_AUCTIONBOT_SELLER`: Allow AuctionHouseBot seller (Default: 0)
* `MANGOS_ALLOW_AUCTIONBOT_BUYER`: Allow AuctionHouseBot buyer (Default: 0)

## Debugging

To get a shell on one of the containers (eg. the server), run the following in a separate terminal while it's running, where `server` is the service name in docker-compose.yml:

```
docker-compose exec server /bin/bash
```

If you are on the `server` container and want to execute queries directly, you can get a mysql prompt by using

```
mysql -umangos -pmangos -h mysql -Dwotlkmangos
```