#!/bin/bash


# ARGUMENTS

if [ "x$1" == "x--random" ]
then
  shift
  israndom=true
fi

if [ $# -ne 6 ]
then
  printf "Error: Need 6 (alt:7) arguments\n" >&2
  printf "Usage: $0 name center-x center-y format provider layer\n" >&2
  printf "  alt: $0 --random nprod name xmin ymin xmax ymax\n" >&2
  exit 1
fi

if ${israndom}
then
  nprod=${1}
  name=${2}_$(cat /proc/sys/kernel/random/uuid | tr '-' '_')
  xmin=$(tr '-' '_' <<< ${3})
  ymin=$(tr '-' '_' <<< ${4})
  xmax=$(tr '-' '_' <<< ${5})
  ymax=$(tr '-' '_' <<< ${6})
  x=$(dc <<< "20k ${xmax} ${xmin} - $RANDOM 32768/* ${xmin}+p" | tr '-' '_')
  y=$(dc <<< "20k ${ymax} ${ymin} - $RANDOM 32768/* ${ymin}+p" | tr '-' '_')
  fmts=(horizontal vertical square)
  fmt=${fmts[$((RANDOM*${#fmts[@]}/32768))]}
  srcs=(stamen:terrain stamen:toner-lite osm:openstreetmap osm:wikimedia osm:opentopomap)
  IFS=: read provider layer <<< "${srcs[$((RANDOM*${#srcs[@]}/32768))]}"
  echo $name $x $y $fmt $provider $layer
else
  name=${1}
  x=$(tr '-' '_' <<< ${2})
  y=$(tr '-' '_' <<< ${3})
  fmt=${4}
  provider="${5}"
  layer=${6}
fi


# APACHE SERVER

http="http://localhost:80"
if ! curl -s "${http}" > /dev/null 2>&1
then
  printf "Error: MapCache server has failed\n" >&2
  exit 1
fi


# IMAGE PARAMETERS

if   [ ${fmt} == "horizontal" ]; then w=12;h=8;
elif [ ${fmt} == "vertical" ];   then w=8 ;h=12;
elif [ ${fmt} == "square" ];     then w=10;h=10;
else                                  w=6 ;h=6;
fi

l=9783.94
minx=$(echo "2k $x $l $w 2/*-pq" | dc)
miny=$(echo "2k $y $l $h 2/*-pq" | dc)
maxx=$(echo "2k $x $l $w 2/*+pq" | dc)
maxy=$(echo "2k $y $l $h 2/*+pq" | dc)
width=$(echo 256 $w *pq | dc)
height=$(echo 256 $h *pq | dc)


# JPEG IMAGE FROM MAPCACHE WMS

if [ ! -f /share/caches/product/image/${name}.jpg ]
then
  mkdir -p /share/caches/product/image
  req="${http}/${provider}?SERVICE=WMS&REQUEST=GetMap&SRS=EPSG:3857"
  req="${req}&LAYERS=${layer}&WIDTH=${width}&HEIGHT=${height}"
  req="${req}&BBOX=${minx},${miny},${maxx},${maxy}"
  retry=0
  echo "${req}"
  while true
  do
    curl "${req}" > /share/caches/product/image/${name}.jpg 2> /dev/null
    if file /share/caches/product/image/${name}.jpg | grep -q JPEG
    then
      break
    fi
    printf "Error downloading image \"${name}\", retrying\n" >&2
    sleep ${retry}
    retry=$((retry+1))
    if [ ${retry} -ge 10 ]
    then
      rm -f /share/caches/product/image/${name}.jpg
      printf "Failed to download image \"${name}\", terminating\n" >&2
      exit 1
    fi
  done
fi


# GEOTIFF IMAGE FROM JPEG IMAGE USING GDAL_TRANSLATE

if [ ! -f /share/caches/product/image/${name}.tif ]
then
  gdal_translate -a_srs EPSG:3857 -a_ullr ${minx} ${maxy} ${maxx} ${miny} \
    /share/caches/product/image/${name}.jpg \
    /share/caches/product/image/${name}.tif
fi


# SQLITE CACHE FROM GEOTIFF IMAGE USING MAPCACHE_SEED

if [ ! -f /share/caches/product/${name}.sqlite3 ]
then
  cat <<-EOF > /share/caches/mapcache-${name}.xml
	<?xml version="1.0" encoding="UTF-8"?>
	<mapcache>
		<source name="${name}" type="gdal">
			<data>/share/caches/product/image/${name}.tif</data>
		</source>
		<cache name="${name}" type="sqlite3">
			<dbfile>/share/caches/product/${name}.sqlite3</dbfile>
		</cache>
		<tileset name="${name}">
			<source>${name}</source>
			<cache>${name}</cache>
			<grid>GoogleMapsCompatible</grid>
			<format>PNG</format>
		</tileset>
		<service type="wmts" enabled="true"/>
		<service type="wms" enabled="true"/>
		<log_level>debug</log_level>
		<threaded_fetching>true</threaded_fetching>
	</mapcache>
	EOF

  mapcache_seed -c /share/caches/mapcache-${name}.xml \
                -e ${minx},${miny},${maxx},${maxy} \
                -g GoogleMapsCompatible \
                -t ${name} \
                -z 0,13 \
  && rm /share/caches/mapcache-${name}.xml \
  || exit 1

  cp /share/caches/product/${name}.sqlite3 \
     /share/caches/product/${name}_i.sqlite3
  sqlite3 /share/caches/product/${name}_i.sqlite3 \
          'CREATE UNIQUE INDEX xyz ON tiles(x,y,z);'
fi


# CATALOG ENTRY

catalog="/share/caches/product/catalog.sqlite"
if [ ! -f "${catalog}" ]
then
  sqlite3 "${catalog}" \
    "CREATE TABLE catalog(name TEXT, minx REAL, miny REAL, maxx REAL, maxy REAL);"
fi
sqlite3 "${catalog}" \
  "INSERT OR IGNORE INTO catalog(name,minx,miny,maxx,maxy)
   VALUES(\"${name}\",${minx},${miny},${maxx},${maxy});"


