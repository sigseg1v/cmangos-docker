#!/bin/bash
echo "cbrgm/cmangos written by Christian Bargmann (c) 2019"
echo "https://cbrgm.net/"
echo ""
echo "Initializing docker container..."

setup_init () {
    setup_mysql_config
    setup_config
}

check_database_exists () {
    RESULT=`mysqlshow --user=${MYSQL_USER} --password=${MYSQL_PWD} --host=${MYSQL_HOST} ${MYSQL_DATABASE_WORLD} | grep -v Wildcard | grep -o ${MYSQL_DATABASE_WORLD} | tail -n 1`
    if [ "$RESULT" == "${MYSQL_DATABASE_WORLD}" ]; then
        return 0;
    else
        return 1;
    fi
}

setup_mysql_config () {
    echo "###### MySQL config setup ######"
    if [ -z "${MYSQL_HOST}" ]; then echo "Missing MYSQL_HOST environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_USER}" ]; then echo "Missing MYSQL_USER environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_PWD}" ]; then echo "Missing MYSQL_PWD environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_MANGOS_USER}" ]; then echo "Missing MYSQL_MANGOS_USER environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_MANGOS_PWD}" ]; then echo "Missing MYSQL_MANGOS_PWD environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_DATABASE_CHARACTER}" ]; then echo "Missing MYSQL_DATABASE_CHARACTER environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_DATABASE_LOGS}" ]; then echo "Missing MYSQL_DATABASE_LOGS environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_DATABASE_REALM}" ]; then echo "Missing MYSQL_DATABASE_REALM environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_DATABASE_WORLD}" ]; then echo "Missing MYSQL_DATABASE_WORLD environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MANGOS_REALM_NAME}" ]; then echo "Missing MANGOS_REALM_NAME environment variable. Unable to continue."; exit 1; fi

    echo "Checking if databases already exists..."
    if  ! check_database_exists; then
        echo "Setting up MySQL config..."

        # Clone latest wotlk-db into database folder
        echo "Cloning latest database files..."
        git clone https://github.com/cmangos/mangos-wotlk -b master --recursive mangos
        cd mangos
        git checkout ${MANGOS_REV}
        cd ..
        git clone https://github.com/cmangos/wotlk-db -b master --recursive mangos/db
        cd mangos/db
        git checkout ${DB_REV}
        cd ../..

        echo "[STEP 1/7] General database setup"
        echo "Creating databases..."

cat > mangos/sql/create/db_create_mysql.sql <<EOF
CREATE DATABASE wotlkmangos DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE wotlkcharacters DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE wotlkrealmd DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE wotlklogs DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER IF NOT EXISTS '${MYSQL_MANGOS_USER}'@'localhost' IDENTIFIED BY '${MYSQL_MANGOS_PWD}';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON wotlkmangos.* TO '${MYSQL_MANGOS_USER}'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON wotlkcharacters.* TO '${MYSQL_MANGOS_USER}'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON wotlkrealmd.* TO '${MYSQL_MANGOS_USER}'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON wotlklogs.* TO '${MYSQL_MANGOS_USER}'@'localhost';
CREATE USER IF NOT EXISTS '${MYSQL_MANGOS_USER}'@'%' IDENTIFIED BY '${MYSQL_MANGOS_PWD}';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON wotlkmangos.* TO '${MYSQL_MANGOS_USER}'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON wotlkcharacters.* TO '${MYSQL_MANGOS_USER}'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON wotlkrealmd.* TO '${MYSQL_MANGOS_USER}'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON wotlklogs.* TO '${MYSQL_MANGOS_USER}'@'%';
FLUSH PRIVILEGES;
EOF

        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} < mangos/sql/create/db_create_mysql.sql

        echo "[STEP 2/7] World database setup"
        echo "Initialize mangos database..."
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_WORLD} < mangos/sql/base/mangos.sql

        echo "Initialize dbc data..."

        cat mangos/sql/base/dbc/original_data/*.sql > mangos/sql/base/dbc/original_data/import.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_WORLD} < mangos/sql/base/dbc/original_data/import.sql

        # Already covered by db install helper?
        # cat mangos/sql/base/dbc/cmangos_fixes/*.sql > mangos/sql/base/dbc/cmangos_fixes/import.sql
        # mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_WORLD} < mangos/sql/base/dbc/cmangos_fixes/import.sql

        echo "[STEP 3/7] Characters database setup"
        echo "Initialize characters database..."
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_CHARACTER} < mangos/sql/base/characters.sql

        echo "[STEP 4/7] Logs database setup"
        echo "Initialize logs database..."
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_LOGS} < mangos/sql/base/logs.sql

        echo "[STEP 5/7] Realmd database setup"
        echo "Initialize realmd database..."
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_REALM} < mangos/sql/base/realmd.sql

        echo "[STEP 6/7] Filling world database"
        echo "Filling up world database..."
        cd mangos/db

# Below can be cleaned up, some of the config options were already here but seem unused on current version, see InstallFullDB.config docs
cat << EOF > InstallFullDB.config
MYSQL_HOST="${MYSQL_HOST}"
MYSQL_USERIP="%"
MANGOS_DBHOST="${MYSQL_HOST}"
DB_PORT="${MYSQL_PORT}"
MYSQL_PORT="${MYSQL_PORT}"
MANGOS_DBNAME="${MYSQL_DATABASE_WORLD}"
MANGOS_DBUSER="${MYSQL_MANGOS_USER}"
MYSQL_USERNAME="${MYSQL_MANGOS_USER}"
MANGOS_DBPASS="${MYSQL_MANGOS_PWD}"
MYSQL_PASSWORD="${MYSQL_MANGOS_PWD}"
CORE_PATH="/opt/mangos/mangos"
MYSQL_PATH="/usr/bin/mysql"
MYSQL="mysql"
FORCE_WAIT="NO"
DEV_UPDATES="NO"
AHBOT="YES"
EOF
        chmod a+x InstallFullDB.sh
        # TODO: Can the above db setup steps be removed if this script initializes everything?
        ./InstallFullDB.sh -InstallAll "${MYSQL_USER}" "${MYSQL_PWD}" DeleteAll
        cd ../..

        echo "[STEP 7/7] Configure realmlist and gamemaster accounts"
        # Adding entry to realmlist
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_REALM} -e "DELETE FROM realmlist WHERE id=1;"
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_REALM} -e "INSERT INTO realmlist (id, name, address, port, icon, realmflags, timezone, allowedSecurityLevel) VALUES ('1', '${MANGOS_REALM_NAME}', '${MANGOS_SERVER_PUBLIC_IP}', '8085', '1', '0', '1', '0');"

        # Deleting all example entries from accounts db except administrator
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_REALM} -e "DELETE FROM account WHERE username != 'administrator';"
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_REALM} -e "UPDATE account SET gmlevel = 4 where username = 'administrator';"

        # Cleanup
        rm -rf /opt/mangos/mangos
    fi
}

setup_config() {
  echo "Mangos config setup..."

  # /opt/mangos/etc/mangosd.conf configuration
  echo "Configuring /opt/mangos/etc/mangosd.conf..."
  sed -i "s/^LoginDatabaseInfo.*/LoginDatabaseInfo = ${MYSQL_HOST};${MYSQL_PORT};${MYSQL_MANGOS_USER};${MYSQL_MANGOS_PWD};${MYSQL_DATABASE_REALM}/" /opt/mangos/etc/mangosd.conf
  sed -i "s/^WorldDatabaseInfo.*/WorldDatabaseInfo = ${MYSQL_HOST};${MYSQL_PORT};${MYSQL_MANGOS_USER};${MYSQL_MANGOS_PWD};${MYSQL_DATABASE_WORLD}/" /opt/mangos/etc/mangosd.conf
  sed -i "s/^CharacterDatabaseInfo.*/CharacterDatabaseInfo = ${MYSQL_HOST};${MYSQL_PORT};${MYSQL_MANGOS_USER};${MYSQL_MANGOS_PWD};${MYSQL_DATABASE_CHARACTER}/" /opt/mangos/etc/mangosd.conf
  sed -i "s/^LogsDatabaseInfo.*/LogsDatabaseInfo = ${MYSQL_HOST};${MYSQL_PORT};${MYSQL_MANGOS_USER};${MYSQL_MANGOS_PWD};${MYSQL_DATABASE_LOGS}/" /opt/mangos/etc/mangosd.conf
  sed -i "s/^BindIP.*/BindIP = ${MANGOS_SERVER_IP}/" /opt/mangos/etc/mangosd.conf
  sed -i 's/^DataDir.*/DataDir = ".."/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Ra.Enable.*/Ra.Enable = 1/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Ra.Ip.*/Ra.Ip = 0.0.0.0/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Ra.Port.*/Ra.Port = 3443/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Ra.MinLevel.*/Ra.MinLevel = 3/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Ra.Secure.*/Ra.Secure = 1/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Ra.Restricted.*/Ra.Restricted = 1/' /opt/mangos/etc/mangosd.conf

  # xp rates
  sed -i 's/^Rate.Pet.XP.Kill.*/Rate.Pet.XP.Kill = 3/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Rate.XP.Kill.*/Rate.XP.Kill = 3/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Rate.XP.Quest.*/Rate.XP.Quest = 3/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Rate.XP.Explore.*/Rate.XP.Explore = 10/' /opt/mangos/etc/mangosd.conf

  # regen rates
  sed -i 's/^Rate.Health.*/Rate.Health = 10/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Rate.Mana.*/Rate.Mana = 20/' /opt/mangos/etc/mangosd.conf

  # drop rates
  sed -i 's/^Rate.Drop.Item.Poor.*/Rate.Drop.Item.Poor = 1/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Rate.Drop.Item.Normal.*/Rate.Drop.Item.Normal = 1/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Rate.Drop.Item.Uncommon.*/Rate.Drop.Item.Uncommon = 5/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Rate.Drop.Item.Rare.*/Rate.Drop.Item.Rare = 20/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Rate.Drop.Item.Epic.*/Rate.Drop.Item.Epic = 200/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Rate.Drop.Item.Legendary.*/Rate.Drop.Item.Legendary = 1000/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Rate.Drop.Item.Quest.*/Rate.Drop.Item.Quest = 2/' /opt/mangos/etc/mangosd.conf
  sed -i 's/^Rate.Drop.Money.*/Rate.Drop.Money = 10/' /opt/mangos/etc/mangosd.conf

  # opt/mangos/etc/realmd.conf configuration
  echo "Configuring /opt/mangos/conf/realmd.conf..."
  sed -i "s/^LoginDatabaseInfo.*/LoginDatabaseInfo = ${MYSQL_HOST};${MYSQL_PORT};${MYSQL_MANGOS_USER};${MYSQL_MANGOS_PWD};${MYSQL_DATABASE_REALM}/" /opt/mangos/etc/realmd.conf
  sed -i "s/^BindIP.*/BindIP = ${MANGOS_SERVER_IP}/" /opt/mangos/etc/realmd.conf

  # opt/mangos/etc/playerbot.conf configuration
  echo "Configuring /opt/mangos/etc/playerbot.conf..."
  sed -i "s/^PlayerbotAI.DisableBots.*/PlayerbotAI.DisableBots = ${MANGOS_DISABLE_PLAYERBOTS}/" /opt/mangos/etc/playerbot.conf
  sed -i "s/^PlayerbotAI.FollowDistanceMin.*/PlayerbotAI.FollowDistanceMin = 1/" /opt/mangos/etc/playerbot.conf
  sed -i "s/^PlayerbotAI.FollowDistanceMax.*/PlayerbotAI.FollowDistanceMax = 2/" /opt/mangos/etc/playerbot.conf

  # opt/mangos/etc/ahconf.conf configuration
  echo "Configuring /opt/mangos/etc/ahconf.conf..."
  sed -i "s/^AuctionHouseBot.Chance.Sell.*/AuctionHouseBot.Chance.Sell = ${MANGOS_AUCTIONBOT_SELL_CHANCE}/" /opt/mangos/etc/ahbot.conf
  sed -i "s/^AuctionHouseBot.Chance.Buy.*/AuctionHouseBot.Chance.Buy = ${MANGOS_AUCTIONBOT_BUY_CHANCE}/" /opt/mangos/etc/ahbot.conf

  # Gameplay specific options...
  if ! [ -z "${MANGOS_GAMETYPE}" ]; then sed -i "s/^GameType.*/GameType = ${MANGOS_GAMETYPE}/" /opt/mangos/etc/mangosd.conf; fi
  if ! [ -z "${MANGOS_MOTD}" ]; then sed -i "s/^Motd.*/Motd = ${MANGOS_MOTD}/" /opt/mangos/etc/mangosd.conf; fi
}

sleep 10

# Download mangosd config from external url if set
# else use default env vars
if ! [ -z ${MANGOS_OVERRIDE_CONF_URL} ]; then
  echo "Downloading external config..."
    wget -q ${MANGOS_OVERRIDE_CONF_URL} -O /opt/mangos/etc/mangosd.conf
    setup_init
else
    setup_init
fi

# debug: exec "bin/mangosd" -c conf/mangosd.conf
# debug: exec "bin/realmd" -c conf/realmd.conf
exec "$@"
