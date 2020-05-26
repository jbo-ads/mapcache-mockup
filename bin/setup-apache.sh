#!/bin/bash

apachectl -k stop
sleep 2

useradd -u $(stat -c '%u' /share) -U apacheuser 2>/dev/null || true
u=$(id -nu $(stat -c '%u' /share))
sed -i "s/www-data/${u}/" /etc/apache2/envvars

sed -E -i '/MaxConnectionsPerChild/s/[0-9]+/400/' /etc/apache2/mods-enabled/mpm_event.conf
sed -E -i '/StartServers/s/[0-9]+/5/' /etc/apache2/mods-enabled/mpm_event.conf

apachectl -k start
sleep 2
