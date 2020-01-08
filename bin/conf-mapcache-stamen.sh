#!/bin/bash

cfgdir=/usr/local/etc/mapcache
srcdir=/usr/local/src
mkdir -p ${cfgdir}

cat <<-EOF > ${cfgdir}/stamen.xml
	<?xml version="1.0" encoding="UTF-8"?>
	<mapcache>
		<cache name="remote-watercolor" type="rest">
			<url>http://tile.stamen.com/watercolor/{z}/{x}/{inv_y}.jpg</url>
		</cache>
		<tileset name="remote-watercolor">
			<cache>remote-watercolor</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>
		<source name="watercolor" type="wms">
			<http><url>http://localhost:80/stamen?</url></http>
			<getmap><params>
				<format>image/png</format>
				<layers>remote-watercolor</layers>
			</params></getmap>
		</source>
		<cache name="watercolor" type="sqlite3">
			<dbfile>/share/caches/stamen/watercolor.sqlite3</dbfile>
		</cache>
		<tileset name="watercolor">
			<source>watercolor</source>
			<format>PNG</format>
			<cache>watercolor</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>

		<cache name="remote-terrain" type="rest">
			<url>http://tile.stamen.com/terrain/{z}/{x}/{inv_y}.png</url>
		</cache>
		<tileset name="remote-terrain">
			<cache>remote-terrain</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>
		<source name="terrain" type="wms">
			<http><url>http://localhost:80/stamen?</url></http>
			<getmap><params>
				<format>image/png</format>
				<layers>remote-terrain</layers>
			</params></getmap>
		</source>
		<cache name="terrain" type="sqlite3">
			<dbfile>/share/caches/stamen/terrain.sqlite3</dbfile>
		</cache>
		<tileset name="terrain">
			<source>terrain</source>
			<format>PNG</format>
			<cache>terrain</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>

		<cache name="remote-toner-lite" type="rest">
			<url>http://tile.stamen.com/toner-lite/{z}/{x}/{inv_y}.png</url>
		</cache>
		<tileset name="remote-toner-lite">
			<cache>remote-toner-lite</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>
		<source name="toner-lite" type="wms">
			<http><url>http://localhost:80/stamen?</url></http>
			<getmap><params>
				<format>image/png</format>
				<layers>remote-toner-lite</layers>
			</params></getmap>
		</source>
		<cache name="toner-lite" type="sqlite3">
			<dbfile>/share/caches/stamen/toner-lite.sqlite3</dbfile>
		</cache>
		<tileset name="toner-lite">
			<source>toner-lite</source>
			<format>PNG</format>
			<cache>toner-lite</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>

		<service type="wmts" enabled="true"/>
		<service type="wms" enabled="true">
			<maxsize>4096</maxsize>
		</service>
	</mapcache>
	EOF

cat <<-EOF > /etc/apache2/conf-enabled/stamen.conf
	<IfModule mapcache_module>
		MapCacheAlias "/stamen" "${cfgdir}/stamen.xml"
	</IfModule>
	EOF

cat <<-EOF > /var/www/html/ol/stamen.js
	var watercolor = new ol.layer.Tile({
		title: 'Watercolor by Stamen',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/stamen?',
			params: {'LAYERS': 'watercolor', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(watercolor)

	var terrain = new ol.layer.Tile({
		title: 'Terrain by Stamen',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/stamen?',
			params: {'LAYERS': 'terrain', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(terrain)

	var tonerlite = new ol.layer.Tile({
		title: 'Toner Lite by Stamen',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/stamen?',
			params: {'LAYERS': 'toner-lite', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(tonerlite)

	EOF

if ! grep -q "stamen.js" /var/www/html/ol/index.html
then
	gawk -i inplace '/anchor/{print l};{print}' \
		l='<script src="stamen.js"></script>' \
		/var/www/html/ol/index.html
fi
