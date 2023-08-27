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

## Build container

```
docker build -t "cmangos:wotlk" ./mangos
```

## Run container

Copy `maps`, `mmaps`, `vmaps`, `dbc` and `Cameras` folders that were generated in your client directory into this directory under a a new folder called `resources`, and then run the container.

```
docker-compose up
```

If you want to run in the background, use `docker-compose up -d` instead, and `docker-compose down` to stop the background server.

## Manage accounts

To create a new account
```sql
INSERT INTO `account` (`username`,`sha_pass_hash`,`expansion`) VALUES ('username', SHA1(CONCAT(UPPER('username'),':',UPPER('password'))),2);
```

To change a username

```sql
UPDATE `account` SET `username` = 'new_username', `sha_pass_hash` = SHA1(CONCAT(UPPER('new_username'),':',UPPER('passwordxyz'))) WHERE `id` = x;
```

To change an account password

```sql
UPDATE `account` SET `sha_pass_hash` = SHA1(CONCAT(UPPER(`username`),':',UPPER('passwordxyz'))) WHERE `id` = x;
```

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
* `MANGOS_ALLOW_PLAYERBOTS`: Allow PlayerbotAI commands (Default: 0)
* `MANGOS_ALLOW_AUCTIONBOT_SELLER`: Allow AuctionHouseBot seller (Default: 0)
* `MANGOS_ALLOW_AUCTIONBOT_BUYER`: Allow AuctionHouseBot buyer (Default: 0)