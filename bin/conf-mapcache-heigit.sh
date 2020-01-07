#!/bin/bash

cfgdir=/usr/local/etc/mapcache
srcdir=/usr/local/src
mkdir -p ${cfgdir}

cat <<-EOF > ${cfgdir}/heigit.xml
	<?xml version="1.0" encoding="UTF-8"?>
	<mapcache>
		<source name="osm" type="wms">
			<http><url>https://maps.heigit.org/osm-wms/service?</url></http>
			<getmap><params>
				<format>image/png</format>
				<layers>osm_auto:all</layers>
			</params></getmap>
		</source>
		<cache name="osm" type="sqlite3">
			<dbfile>/share/caches/heigit/osm.sqlite3</dbfile>
		</cache>
		<tileset name="osm">
			<source>osm</source>
			<format>PNG</format>
			<cache>osm</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>
		<service type="wmts" enabled="true"/>
		<service type="wms" enabled="true"/>
	</mapcache>
	EOF

cat <<-EOF > /etc/apache2/conf-enabled/heigit.conf
	<IfModule mapcache_module>
		MapCacheAlias "/heigit" "${cfgdir}/heigit.xml"
	</IfModule>
	EOF

cat <<-EOF > /var/www/html/ol/heigit.js
	var osm = new ol.layer.Tile({
		title: 'OpenStreetMap by Heigit',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/heigit?',
			params: {'LAYERS': 'osm', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(osm)
	EOF

if ! grep -q "heigit.js" /var/www/html/ol/index.html
then
	gawk -i inplace '/anchor/{print l};{print}' \
		l='<script src="heigit.js"></script>' \
		/var/www/html/ol/index.html
fi

