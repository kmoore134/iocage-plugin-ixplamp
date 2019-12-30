#!/bin/sh

# Enable the service
sysrc -f /etc/rc.conf postgresql_enable="YES"
sysrc -f /etc/rc.conf nginx_enable=YES

# Start the service
service postgresql initdb
service postgresql start

USER="pgadmin"
DB="production"

# Save the config values
echo "$DB" > /root/dbname
echo "$USER" > /root/dbuser
export LC_ALL=C
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 > /root/dbpassword
PASS=`cat /root/dbpassword`

# create user
psql -d template1 -U postgres -c "CREATE USER ${USER} CREATEDB SUPERUSER;"

# Create production database & grant all privileges on database
psql -d template1 -U postgres -c "CREATE DATABASE ${DB} OWNER ${USER};"

# Set a password on the postgres account
psql -d template1 -U postgres -c "ALTER USER ${USER} WITH PASSWORD '${PASS}';"

# Connect as superuser and enable pg_trgm extension
psql -U postgres -d ${DB} -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

# Fix permission for postgres 
echo "listen_addresses = '*'" >> /var/db/postgres/data11/postgresql.conf
echo "host  all  all 0.0.0.0/0 md5" >> /var/db/postgres/data11/pg_hba.conf

# Restart postgresql after config change
service postgresql restart

#Create pgadmin4 env
virtualenv-3.6 pgadmin4

#Use the the own version easier to hack the configs
cd pgadmin4/bin

#install deps
echo "Install Deps..."
./pip3 install pyopenssl cryptography pyasn1 ndg-httpsclient > /dev/null 2>&1
echo "Install pgAdmin4"
./pip3 install https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v4.1/pip/pgadmin4-4.1-py2.py3-none-any.whl > /dev/null 2>&1

# Run in CSH
/usr/local/bin/setup_pgadmin.csh

#Sed magic to open up the server on any ip
sed -i '' "s|127.0.0.1|0.0.0.0|g" /pgadmin4/lib/python3.6/site-packages/pgadmin4/config.py
cp /pgadmin4/lib/python3.6/site-packages/pgadmin4/config.py /pgadmin4/lib/python3.6/site-packages/pgadmin4/config_local.py

mkdir -p /var/log/pgadmin/ /var/lib/pgadmin
chmod a+wrx /var/log/pgadmin/ /var/lib/pgadmin


echo "Database Name: $DB" > /root/PLUGIN_INFO
echo "Database User: $USER" >> /root/PLUGIN_INFO
echo "Database Password: $PASS" >> /root/PLUGIN_INFO
echo "Please open the URL to set your password, Login Name is root." >> /root/PLUGIN_INFO
