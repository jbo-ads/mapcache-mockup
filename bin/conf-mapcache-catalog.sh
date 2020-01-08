#!/bin/bash

cfgdir=/usr/local/etc/mapcache
srcdir=/usr/local/src
mkdir -p ${cfgdir}

cat <<-EOF > ${cfgdir}/catalog.xml
	<?xml version="1.0" encoding="UTF-8"?>
	<mapcache>
		<format name="PNG16" type="RAW">
			<extension>png</extension>
			<mime_type>image/png</mime_type>
		</format>
		<cache name="catalog" type="sqlite3">
			<dbfile>/share/caches/product/{dim:product}.sqlite3</dbfile>
			<queries><get>select data from tiles where x=:x and y=:y and z=:z</get></queries>
		</cache>
		<tileset name="catalog">
			<format>PNG</format>
			<cache>catalog</cache>
			<grid>GoogleMapsCompatible</grid>
			<dimensions>
				<assembly_type>stack</assembly_type>
				<store_assemblies>false</store_assemblies>
				<dimension name="product" default="all" type="sqlite">
					<dbfile>/share/caches/product/catalog.sqlite</dbfile>
					<validate_query>select distinct(name) from catalog</validate_query>
					<list_query>select distinct(name) from catalog</list_query>
				</dimension>
			</dimensions>
		</tileset>
		<source name="world" type="gdal">
			<data>${cfgdir}/world.tif</data>
		</source>
		<cache name="world" type="disk" layout="template">
			<template>/share/caches/world/{z}/{inv_y}/{x}.jpg</template>
		</cache>
		<tileset name="base">
			<source>world</source>
			<cache>world</cache>
			<grid>GoogleMapsCompatible</grid>
			<format>JPEG</format>
			<metatile>1 1</metatile>
		</tileset>
		<service type="wmts" enabled="true"/>
		<service type="wms" enabled="true"/>
	</mapcache>
	EOF

cat <<-EOF > /etc/apache2/conf-enabled/catalog.conf
	<IfModule mapcache_module>
		MapCacheAlias "/catalog" "${cfgdir}/catalog.xml"
	</IfModule>
	EOF

cat <<-EOF > /var/www/html/ol/catalog.js
	var catalogbm = new ol.layer.Tile({
		title: 'Image Catalog (with basemap)',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/catalog?',
			params: {'LAYERS': 'base,catalog', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(catalogbm)
	var catalog = new ol.layer.Tile({
		title: 'Image Catalog (raw)',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/catalog?',
			params: {'LAYERS': 'catalog', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(catalog)
	EOF

if ! grep -q "catalog.js" /var/www/html/ol/index.html
then
	gawk -i inplace '/anchor/{print l};{print}' \
		l='<script src="catalog.js"></script>' \
		/var/www/html/ol/index.html
fi

