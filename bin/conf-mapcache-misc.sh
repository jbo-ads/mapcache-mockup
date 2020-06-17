#!/bin/bash

cfgdir=/usr/local/etc/mapcache
mkdir -p ${cfgdir}

cat <<-EOF > ${cfgdir}/misc.xml
	<?xml version="1.0" encoding="UTF-8"?>
	<mapcache>
		<cache name="remote-s2maps" type="rest">
			<url>http://a.s2maps-tiles.eu/wmts/1.0.0/s2cloudless-2019_3857/default/GoogleMapsCompatible/{z}/{inv_y}/{x}.jpg</url>
		</cache>
		<tileset name="remote-s2maps">
			<cache>remote-s2maps</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>
		<source name="s2maps" type="wms">
			<http><url>http://localhost:80/misc?</url></http>
			<getmap><params>
				<format>image/png</format>
				<layers>remote-s2maps</layers>
			</params></getmap>
		</source>
		<cache name="s2maps" type="sqlite3">
			<dbfile>/share/caches/misc/s2maps.sqlite3</dbfile>
		</cache>
		<tileset name="s2maps">
			<source>s2maps</source>
			<format>PNG</format>
			<cache>s2maps</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>

		<cache name="remote-esri" type="rest">
			<url>https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{inv_y}/{x}</url>
		</cache>
		<tileset name="remote-esri">
			<cache>remote-esri</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>
		<source name="esri" type="wms">
			<http><url>http://localhost:80/misc?</url></http>
			<getmap><params>
				<format>image/png</format>
				<layers>remote-esri</layers>
			</params></getmap>
		</source>
                <cache name="esri-z0-7" type="sqlite3">
			<dbfile>/share/caches/misc/esri/z0-0-0.sqlite3</dbfile>
		</cache>
		<cache name="esri-z8" type="sqlite3">
			<top>8</top>
			<dbfile>/share/caches/misc/esri/z{top}-{top_x}-{top_y}.sqlite3</dbfile>
		</cache>
		<cache name="esri" type="composite">
			<cache min-zoom="0" max-zoom="7">esri-z0-7</cache>
			<cache min-zoom="8">esri-z8</cache>
		</cache>
		<tileset name="esri">
			<source>esri</source>
			<format>PNG</format>
			<cache>esri</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>

		<cache name="remote-pirate" type="rest">
			<url>http://d.tiles.mapbox.com/v3/aj.Sketchy2/{z}/{x}/{inv_y}.png</url>
		</cache>
		<tileset name="remote-pirate">
			<cache>remote-pirate</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>
		<source name="pirate" type="wms">
			<http><url>http://localhost:80/misc?</url></http>
			<getmap><params>
				<format>image/png</format>
				<layers>remote-pirate</layers>
			</params></getmap>
		</source>
		<cache name="pirate" type="sqlite3">
			<dbfile>/share/caches/misc/pirate.sqlite3</dbfile>
		</cache>
		<tileset name="pirate">
			<source>pirate</source>
			<format>PNG</format>
			<cache>pirate</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>

		<source name="gibs" type="wms">
			<http><url>https://gibs.earthdata.nasa.gov/wms/epsg3857/best/wms.cgi?</url></http>
			<getmap><params>
				<format>image/png</format>
				<layers>BlueMarble_ShadedRelief_Bathymetry</layers>
			</params></getmap>
		</source>
		<cache name="gibs" type="sqlite3">
			<dbfile>/share/caches/misc/gibs.sqlite3</dbfile>
		</cache>
		<tileset name="gibs">
			<source>gibs</source>
			<format>PNG</format>
			<cache>gibs</cache>
			<grid>GoogleMapsCompatible</grid>
		</tileset>

		<service type="wmts" enabled="true"/>
		<service type="wms" enabled="true">
			<maxsize>10000</maxsize>
		</service>
	</mapcache>
	EOF

cat <<-EOF > /etc/apache2/conf-enabled/misc.conf
	<IfModule mapcache_module>
		MapCacheAlias "/misc" "${cfgdir}/misc.xml"
	</IfModule>
	EOF

cat <<-EOF > /var/www/html/ol/misc.js
	var s2maps = new ol.layer.Tile({
		title: 'Sentinel 2 by S2Maps',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/misc?',
			params: {'LAYERS': 's2maps', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(s2maps)

	var esri = new ol.layer.Tile({
		title: 'World Imagery by ESRI',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/misc?',
			params: {'LAYERS': 'esri', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(esri)

	var pirate = new ol.layer.Tile({
		title: 'Pirate Map by AJ Aston',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/misc?',
			params: {'LAYERS': 'pirate', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(pirate)

	var gibs = new ol.layer.Tile({
		title: 'Blue Marble by Gibs',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/misc?',
			params: {'LAYERS': 'gibs', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(gibs)

	EOF

if ! grep -q "misc.js" /var/www/html/ol/index.html
then
	gawk -i inplace '/anchor/{print l};{print}' \
		l='<script src="misc.js"></script>' \
		/var/www/html/ol/index.html
fi
