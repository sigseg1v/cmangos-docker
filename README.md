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
- MANGOS_SERVER_PUBLIC_IP

Set it to the public IP of your server hosting mangosd and realmd. You can get your public IP by searching google for "what is my ip address". For example, if the IP is 1.2.3.4 then make sure the file has:

```
- MANGOS_SERVER_PUBLIC_IP: '1.2.3.4'
```

## Build and run container

Navigate to this directory, then build the mangos server

```
docker build -t "cmangos:wotlk" ./mangos
```

then, run the container.

```
docker-compose up
```

If you want to run in the background, use `docker-compose up -d` instead, and `docker-compose stop` to pause the service.

To delete the containers (deletes database unless using volume mount on msql in docker-compose) use `docker-compose down`.

## Manage accounts

The first thing to do is overwrite the administrator account with a different password.

To connect to mangosd, have the server running and then in a separate terminal run the following:

```
docker-compose exec server telnet 127.0.0.1 3443
```

Enter username "administrator" and password "administrator" to log in.

To set the admin password, run the following (but replace "newpw" with the new password you want). Make sure to remember the admin password because you'll need it to create new accounts.

```
account password administrator newpw newpw
```

To add a new account named bob with password hunter2, run the following while connected to mangosd (but replace the account name and password with something else, obviously):

```
account create bob hunter2
account set addon bob 2
account set gmlevel bob 3
```

A general list of mangosd commands are here: https://github.com/dkpminus/mangos-gm-commands

Type `quit` to exit the mangosd telnet session.


## Connecting to server

Find the public IP of your server hosting mangosd and realmd, which you should have already put into MANGOS_SERVER_PUBLIC_IP in the docker-compose file before you stated the server.

Forward the following ports on that server:
  - 8085 tcp and udp
  - 3724 tcp and udp

Then, in the `Data/enUS/realmlist.wtf` file in your WoW client folder, add the same IP that you put in MANGOS_SERVER_PUBLIC_IP.
For example, if the IP is 1.2.3.4 then make sure the file has:

```
set realmlist 1.2.3.4
```

## Environment vars (set in docker-compose.yml):

* `MYSQL_HOST`: MySQL database host ip/dns name
* `MYSQL_PORT`: MySQL database port
* `MYSQL_USER`: MySQL database user
* `MYSQL_PWD`: MySQL database password
* `MYSQL_MANGOS_USER`: MySQL database user used for connections from server (Default: mangos)
* `MYSQL_MANGOS_PWD`: MySQL database user password used for connections from server (Default: mangos)
* `MANGOS_GAMETYPE`: Realm Gametype (Default: 1 (PVP))
* `MANGOS_MOTD`: Message of the Day (Default: "Welcome!")
* `MANGOS_REALM_NAME`: Name of your realm (Default: MyNewServer)
* `MANGOS_SERVER_IP`: IP for mangosd and realmd port binding (Default 0.0.0.0)
* `MANGOS_SERVER_PUBLIC_IP`: Public IP for your mangos server (Default 127.0.0.1)
* `MANGOS_OVERRIDE_CONF_URL`: External mangosd.conf download
* `MANGOS_DISABLE_PLAYERBOTS`: Disable PlayerbotAI commands (Default: 0)
* `MANGOS_AUCTIONBOT_SELL_CHANCE`: Chance the AuctionBot will sell items (Default: 10; Range: 0-100)
* `MANGOS_AUCTIONBOT_BUY_CHANCE`: Chance the AuctionBot will buy items (Default: 10; Range: 0-100)

## Debugging

To get a shell on one of the containers (eg. the server), run the following in a separate terminal while it's running, where `server` is the service name in docker-compose.yml:

```
docker-compose exec server /bin/bash
```

If you are on the `server` container and want to execute queries directly, you can get a mysql prompt by using

```
mysql -umangos -pmangos -h mysql -Dwotlkmangos
```

To run commands on the mangosd directly:
```
docker-compose exec server telnet 127.0.0.1 3443
```

To get last 2k lines of server log file (run in another terminal while docker is already running)
```
docker-compose exec server tail -n 2000 /opt/mangos/bin/Server.log
```

Other relevant log files you can use above:
- Char.log
- EventAIErrors.log
- SD2Errors.log
- DBErrors.log
- Realmd.log
- Server.log