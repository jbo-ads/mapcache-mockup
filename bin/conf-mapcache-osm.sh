#!/bin/bash

cfgdir=/usr/local/etc/mapcache
mkdir -p ${cfgdir}

cat <<-EOF > ${cfgdir}/osm.xml
	<?xml version="1.0" encoding="UTF-8"?>
	<mapcache>
		<cache name="remote-openstreetmap" type="rest">
			<url>https://tile.openstreetmap.org/{z}/{x}/{inv_y}.png</url>
			<headers><User-Agent>mod_mapcache/1.9dev</User-Agent></headers>
		</cache>
		<tileset name="remote-openstreetmap">
			<cache>remote-openstreetmap</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>
		<source name="openstreetmap" type="wms">
			<http><url>http://localhost:80/osm?</url></http>
			<getmap><params>
				<format>image/png</format>
				<layers>remote-openstreetmap</layers>
			</params></getmap>
		</source>
		<cache name="openstreetmap" type="sqlite3">
			<dbfile>/share/caches/osm/openstreetmap.sqlite3</dbfile>
		</cache>
		<tileset name="openstreetmap">
			<source>openstreetmap</source>
			<format>PNG</format>
			<cache>openstreetmap</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>

		<cache name="remote-openstreetmapde" type="rest">
			<url>https://tile.openstreetmap.de/{z}/{x}/{inv_y}.png</url>
			<headers><User-Agent>mod_mapcache/1.9dev</User-Agent></headers>
		</cache>
		<tileset name="remote-openstreetmapde">
			<cache>remote-openstreetmapde</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>
		<source name="openstreetmapde" type="wms">
			<http><url>http://localhost:80/osm?</url></http>
			<getmap><params>
				<format>image/png</format>
				<layers>remote-openstreetmapde</layers>
			</params></getmap>
		</source>
		<cache name="openstreetmapde" type="sqlite3">
			<dbfile>/share/caches/osm/openstreetmapde.sqlite3</dbfile>
		</cache>
		<tileset name="openstreetmapde">
			<source>openstreetmapde</source>
			<format>PNG</format>
			<cache>openstreetmapde</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>

		<cache name="remote-openstreetmapfr" type="rest">
			<url>https://a.tile.openstreetmap.fr/osmfr/{z}/{x}/{inv_y}.png</url>
			<headers><User-Agent>mod_mapcache/1.9dev</User-Agent></headers>
		</cache>
		<tileset name="remote-openstreetmapfr">
			<cache>remote-openstreetmapfr</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>
		<source name="openstreetmapfr" type="wms">
			<http><url>http://localhost:80/osm?</url></http>
			<getmap><params>
				<format>image/png</format>
				<layers>remote-openstreetmapfr</layers>
			</params></getmap>
		</source>
		<cache name="openstreetmapfr" type="sqlite3">
			<dbfile>/share/caches/osm/openstreetmapfr.sqlite3</dbfile>
		</cache>
		<tileset name="openstreetmapfr">
			<source>openstreetmapfr</source>
			<format>PNG</format>
			<cache>openstreetmapfr</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>

		<cache name="remote-wikimedia" type="rest">
			<url>https://maps.wikimedia.org/osm-intl/{z}/{x}/{inv_y}.png</url>
			<headers><User-Agent>mod_mapcache/1.9dev</User-Agent></headers>
		</cache>
		<tileset name="remote-wikimedia">
			<cache>remote-wikimedia</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>
		<source name="wikimedia" type="wms">
			<http><url>http://localhost:80/osm?</url></http>
			<getmap><params>
				<format>image/png</format>
				<layers>remote-wikimedia</layers>
			</params></getmap>
		</source>
		<cache name="wikimedia" type="sqlite3">
			<dbfile>/share/caches/osm/wikimedia.sqlite3</dbfile>
		</cache>
		<tileset name="wikimedia">
			<source>wikimedia</source>
			<format>PNG</format>
			<cache>wikimedia</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>

		<cache name="remote-opentopomap" type="rest">
			<url>https://tile.opentopomap.org/{z}/{x}/{inv_y}.png</url>
			<headers><User-Agent>mod_mapcache/1.9dev</User-Agent></headers>
		</cache>
		<tileset name="remote-opentopomap">
			<cache>remote-opentopomap</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>
		<source name="opentopomap" type="wms">
			<http><url>http://localhost:80/osm?</url></http>
			<getmap><params>
				<format>image/png</format>
				<layers>remote-opentopomap</layers>
			</params></getmap>
		</source>
		<cache name="opentopomap-z1-7" type="sqlite3">
			<dbfile>/share/caches/osm/opentopomap/z0-0-0.sqlite3</dbfile>
		</cache>
		<cache name="opentopomap-z8" type="sqlite3">
			<top>8</top>
			<dbfile>/share/caches/osm/opentopomap/z{top}-{top_x}-{inv_top_y}.sqlite3</dbfile>
		</cache>
		<cache name="opentopomap" type="composite">
			<cache min-zoom="0" max-zoom="7">opentopomap-z1-7</cache>
			<cache min-zoom="8">opentopomap-z8</cache>
		</cache>
		<tileset name="opentopomap">
			<source>opentopomap</source>
			<format>PNG</format>
			<cache>opentopomap</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>

		<service type="wmts" enabled="true"/>
		<service type="wms" enabled="true">
			<maxsize>4096</maxsize>
		</service>
	</mapcache>
	EOF

sed '$s:^:<threaded_fetching>true</threaded_fetching>\n:' ${cfgdir}/osm.xml > ${cfgdir}/osm-mt.xml

cat <<-EOF > /etc/apache2/conf-enabled/osm.conf
	<IfModule mapcache_module>
		MapCacheAlias "/osm" "${cfgdir}/osm.xml"
		MapCacheAlias "/osm-mt" "${cfgdir}/osm-mt.xml"
	</IfModule>
	EOF

cat <<-EOF > /var/www/html/ol/osm.js
	var openstreetmap = new ol.layer.Tile({
		title: 'OpenStreetMap by OpenStreetMap.org',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/osm?',
			params: {'LAYERS': 'openstreetmap', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(openstreetmap)

	var openstreetmapde = new ol.layer.Tile({
		title: 'OpenStreetMap by OpenStreetMap.de',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/osm?',
			params: {'LAYERS': 'openstreetmapde', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(openstreetmapde)

	var openstreetmapfr = new ol.layer.Tile({
		title: 'OpenStreetMap by OpenStreetMap.fr',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/osm?',
			params: {'LAYERS': 'openstreetmapfr', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(openstreetmapfr)

	var wikimedia = new ol.layer.Tile({
		title: 'Wikimedia by Wikimedia.org',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/osm?',
			params: {'LAYERS': 'wikimedia', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(wikimedia)

	var opentopomap = new ol.layer.Tile({
		title: 'OpenTopoMap by OpenTopoMap.org',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/osm?',
			params: {'LAYERS': 'opentopomap', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(opentopomap)

	EOF

if ! grep -q "osm.js" /var/www/html/ol/index.html
then
	gawk -i inplace '/anchor/{print l};{print}' \
		l='<script src="osm.js"></script>' \
		/var/www/html/ol/index.html
fi
