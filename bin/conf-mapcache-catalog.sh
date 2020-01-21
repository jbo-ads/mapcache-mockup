#!/bin/bash

cfgdir=/usr/local/etc/mapcache
mkdir -p ${cfgdir}

cat <<-EOF > ${cfgdir}/catalog.xml
	<?xml version="1.0" encoding="UTF-8"?>
	<mapcache>
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
				<dimension name="product" default="%" type="sqlite">
					<dbfile>/share/caches/product/catalog.sqlite</dbfile>
					<validate_query>
						select distinct(name) from catalog
						where keywords like "%" || :dim || "%"
					</validate_query>
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

sed '/assembly_type/s:^:<assembly_threaded_fetching>true</assembly_threaded_fetching>\n:' ${cfgdir}/catalog.xml > ${cfgdir}/catalog-amt.xml

sed '$s:^:<threaded_fetching>true</threaded_fetching>\n:' ${cfgdir}/catalog.xml > ${cfgdir}/catalog-mt.xml
sed '$s:^:<threaded_fetching>true</threaded_fetching>\n:' ${cfgdir}/catalog-amt.xml > ${cfgdir}/catalog-mtamt.xml

sed '/<\/validate_query>/s#^#AND miny \&lt;= :maxy AND maxy \&gt;= :miny AND minx \&lt;= :maxx AND maxx \&gt;= :minx\n#' ${cfgdir}/catalog.xml > ${cfgdir}/catalog-geo.xml
sed '/assembly_type/s:^:<assembly_threaded_fetching>true</assembly_threaded_fetching>\n:' ${cfgdir}/catalog-geo.xml > ${cfgdir}/catalog-amtgeo.xml
sed '$s:^:<threaded_fetching>true</threaded_fetching>\n:' ${cfgdir}/catalog-geo.xml > ${cfgdir}/catalog-mtgeo.xml
sed '$s:^:<threaded_fetching>true</threaded_fetching>\n:' ${cfgdir}/catalog-amtgeo.xml > ${cfgdir}/catalog-mtamtgeo.xml

sed '/assembly_type/s:^:<wms_querybymap>true</wms_querybymap>\n:' ${cfgdir}/catalog.xml > ${cfgdir}/catalog-qbm.xml
sed '/assembly_type/s:^:<wms_querybymap>true</wms_querybymap>\n:' ${cfgdir}/catalog-geo.xml > ${cfgdir}/catalog-qbmgeo.xml
sed '$s:^:<threaded_fetching>true</threaded_fetching>\n:' ${cfgdir}/catalog-qbm.xml > ${cfgdir}/catalog-mtqbm.xml
sed '$s:^:<threaded_fetching>true</threaded_fetching>\n:' ${cfgdir}/catalog-qbmgeo.xml > ${cfgdir}/catalog-mtqbmgeo.xml
sed '/assembly_type/s:^:<wms_querybymap>true</wms_querybymap>\n:' ${cfgdir}/catalog-amt.xml > ${cfgdir}/catalog-amtqbm.xml
sed '/assembly_type/s:^:<wms_querybymap>true</wms_querybymap>\n:' ${cfgdir}/catalog-amtgeo.xml > ${cfgdir}/catalog-amtqbmgeo.xml
sed '$s:^:<threaded_fetching>true</threaded_fetching>\n:' ${cfgdir}/catalog-amtqbm.xml > ${cfgdir}/catalog-mtamtqbm.xml
sed '$s:^:<threaded_fetching>true</threaded_fetching>\n:' ${cfgdir}/catalog-amtqbmgeo.xml > ${cfgdir}/catalog-mtamtqbmgeo.xml

cat <<-EOF > /etc/apache2/conf-enabled/catalog.conf
	<IfModule mapcache_module>
		MapCacheAlias "/catalog" "${cfgdir}/catalog.xml"
		MapCacheAlias "/catalog-amt" "${cfgdir}/catalog-amt.xml"
		MapCacheAlias "/catalog-mt" "${cfgdir}/catalog-mt.xml"
		MapCacheAlias "/catalog-mtamt" "${cfgdir}/catalog-mtamt.xml"
		MapCacheAlias "/catalog-geo" "${cfgdir}/catalog-geo.xml"
		MapCacheAlias "/catalog-mtgeo" "${cfgdir}/catalog-mtgeo.xml"
		MapCacheAlias "/catalog-amtgeo" "${cfgdir}/catalog-amtgeo.xml"
		MapCacheAlias "/catalog-mtamtgeo" "${cfgdir}/catalog-mtamtgeo.xml"
		MapCacheAlias "/catalog-qbm" "${cfgdir}/catalog-qbm.xml"
		MapCacheAlias "/catalog-mtqbm" "${cfgdir}/catalog-mtqbm.xml"
		MapCacheAlias "/catalog-qbmgeo" "${cfgdir}/catalog-qbmgeo.xml"
		MapCacheAlias "/catalog-mtqbmgeo" "${cfgdir}/catalog-mtqbmgeo.xml"
		MapCacheAlias "/catalog-amtqbm" "${cfgdir}/catalog-amtqbm.xml"
		MapCacheAlias "/catalog-mtamtqbm" "${cfgdir}/catalog-mtamtqbm.xml"
		MapCacheAlias "/catalog-amtqbmgeo" "${cfgdir}/catalog-amtqbmgeo.xml"
		MapCacheAlias "/catalog-mtamtqbmgeo" "${cfgdir}/catalog-mtamtqbmgeo.xml"
	</IfModule>
	EOF

cat <<-EOF > /var/www/html/ol/catalog.js
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
	var catalogbmmtgeo = new ol.layer.Tile({
		title: 'Image Catalog (with basemap) [geographical filter]',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/catalog-mtgeo?',
			params: {'LAYERS': 'base,catalog', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(catalogbmmtgeo)
	var catalogbmamt = new ol.layer.Tile({
		title: 'Image Catalog (with basemap) [multi-threaded subtiles]',
		type: 'base',
		visible: false,
		source: new ol.source.TileWMS({
			url: 'http://'+location.host+'/catalog-amt?',
			params: {'LAYERS': 'base,catalog', 'VERSION': '1.1.1'}
		})
	});
	layers.unshift(catalogbmamt)
	EOF

if ! grep -q "catalog.js" /var/www/html/ol/index.html
then
	gawk -i inplace '/anchor/{print l};{print}' \
		l='<script src="catalog.js"></script>' \
		/var/www/html/ol/index.html
fi

