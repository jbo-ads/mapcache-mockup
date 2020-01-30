#!/bin/bash

cfgdir=/usr/local/etc/mapcache
mkdir -p ${cfgdir}

cat <<-EOF > ${cfgdir}/osm.xml
	<?xml version="1.0" encoding="UTF-8"?>
	<mapcache>
		<grid name="GoogleMaps">
			<extent>-20037508.3427892480 -20037508.3427892480 20037508.3427892480 20037508.3427892480</extent>
			<srs>EPSG:3857</srs>
			<srsalias>EPSG:900913</srsalias>
			<units>m</units>
			<size>256 256</size>
			<origin>top-left</origin>
			<resolutions>
				156543.0339280410
				78271.51696402048
				39135.75848201023
				19567.87924100512
				9783.939620502561
				4891.969810251280
				2445.984905125640
				1222.992452562820
				611.4962262814100
				305.7481131407048
				152.8740565703525
				76.43702828517624
				38.21851414258813
				19.10925707129406
				9.554628535647032
				4.777314267823516
				2.388657133911758
				1.194328566955879
				0.5971642834779395
			</resolutions>
		</grid>
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
		<cache name="openstreetmapde-z0-7" type="sqlite3">
			<dbfile>/share/caches/osm/openstreetmapde/z0-0-0.sqlite3</dbfile>
		</cache>
		<cache name="openstreetmapde-z8" type="sqlite3">
			<top>8</top>
			<dbfile>/share/caches/osm/openstreetmapde/z{top}-{top_x}-{top_y}.sqlite3</dbfile>
		</cache>
		<cache name="openstreetmapde" type="composite">
			<cache min-zoom="0" max-zoom="7">openstreetmapde-z0-7</cache>
			<cache min-zoom="8">openstreetmapde-z8</cache>
		</cache>
		<tileset name="openstreetmapde">
			<source>openstreetmapde</source>
			<format>PNG</format>
			<cache>openstreetmapde</cache>
			<grid>GoogleMaps</grid>
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
		<cache name="openstreetmapfr-z0-10" type="sqlite3">
			<dbfile>/share/caches/osm/openstreetmapfr/z0-0-0.sqlite3</dbfile>
		</cache>
		<cache name="openstreetmapfr-z11" type="sqlite3">
			<xcount>500</xcount>
			<ycount>500</ycount>
			<dbfile>/share/caches/osm/openstreetmapfr/z{z}-{div_x}-{inv_div_y}.sqlite3</dbfile>
		</cache>
		<cache name="openstreetmapfr" type="composite">
			<cache min-zoom="0" max-zoom="10">openstreetmapfr-z0-10</cache>
			<cache min-zoom="11">openstreetmapfr-z11</cache>
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
		<cache name="wikimedia-z0-10" type="sqlite3">
			<dbfile>/share/caches/osm/wikimedia/z0-0-0.sqlite3</dbfile>
		</cache>
		<cache name="wikimedia-z11" type="sqlite3">
			<xcount>500</xcount>
			<ycount>500</ycount>
			<dbfile>/share/caches/osm/wikimedia/z{z}-{div_x}-{div_y}.sqlite3</dbfile>
		</cache>
		<cache name="wikimedia" type="composite">
			<cache min-zoom="0" max-zoom="10">wikimedia-z0-10</cache>
			<cache min-zoom="11">wikimedia-z11</cache>
		</cache>
		<tileset name="wikimedia">
			<source>wikimedia</source>
			<format>PNG</format>
			<cache>wikimedia</cache>
			<grid>GoogleMaps</grid>
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
		<cache name="opentopomap-z0-7" type="sqlite3">
			<dbfile>/share/caches/osm/opentopomap/z0-0-0.sqlite3</dbfile>
		</cache>
		<cache name="opentopomap-z8" type="sqlite3">
			<top>8</top>
			<dbfile>/share/caches/osm/opentopomap/z{top}-{top_x}-{inv_top_y}.sqlite3</dbfile>
		</cache>
		<cache name="opentopomap" type="composite">
			<cache min-zoom="0" max-zoom="7">opentopomap-z0-7</cache>
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
