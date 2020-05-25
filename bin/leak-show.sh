#!/bin/bash

sudo apachectl -k stop
sleep 2

sudo sed -E -i '/MaxConnectionsPerChild/s/[0-9]+/0/' /etc/apache2/mods-enabled/mpm_event.conf
sudo sed -E -i '/StartServers/s/[0-9]+/4/' /etc/apache2/mods-enabled/mpm_event.conf

sudo apachectl -k start

