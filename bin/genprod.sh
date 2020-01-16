#!/bin/bash


# FUNCTIONS DECLARATIONS

# Get width, height and bbox from center and format
imageparams() {
  x=$(tr '-' '_' <<< $1) y=$(tr '-' '_' <<< $2) fmt=$3
  l=9783.94
  if   [ ${fmt} == "horizontal" ]; then w=12;h=8;
  elif [ ${fmt} == "vertical" ];   then w=8 ;h=12;
  elif [ ${fmt} == "square" ];     then w=10;h=10;
  else                                  w=6 ;h=6;
  fi
  dc  <<< "256 $w *n[ ]n         # width
           256 $h *n[ ]n         # height
           2k $x $l $w 2/*-n[ ]n # minx
           2k $y $l $h 2/*-n[ ]n # miny
           2k $x $l $w 2/*+n[ ]n # maxx
           2k $y $l $h 2/*+n[ ]n # maxy
           []pq"
}

# Get JPEG map from WMS server
getjpeg() {
  name=$1 width=$2 height=$3 bbox=$4 provider=$5 layer=$6
  http="http://localhost:80"
  if ! curl -s "${http}" > /dev/null 2>&1
  then
    printf "Error: MapCache server has failed\n" >&2
    exit 1
  fi
  req="${http}/${provider}?SERVICE=WMS&REQUEST=GetMap&SRS=EPSG:3857"
  req="${req}&LAYERS=${layer}&WIDTH=${width}&HEIGHT=${height}"
  req="${req}&BBOX=${bbox}"
  retry=0
  echo "${req}"
  if [ ! -f /share/caches/product/image/${name}.jpg ]
  then
    mkdir -p /share/caches/product/image
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
        printf "Failed to download image \"${name}\"\n" >&2
        exit 1
      fi
    done
  fi
}

# Convert JPEG map to GEOTIFF
jpeg2geotiff() {
  name=$1 minx=$2 miny=$3 maxx=$4 maxy=$5
  if [ ! -f /share/caches/product/image/${name}.tif ]
  then
    gdal_translate -a_srs EPSG:3857 -a_ullr ${minx} ${maxy} ${maxx} ${miny} \
      /share/caches/product/image/${name}.jpg \
      /share/caches/product/image/${name}.tif
  fi
}

# Convert GEOTIFF to SQLite cache
geotiff2tiles() {
  name=$1
  read minx miny \
    < <(awk -F'[ (),]+' '/Lower Left/{print$3,$4}' \
          < <(gdalinfo /share/caches/product/image/${name}.tif))
  read maxx maxy \
    < <(awk -F'[ (),]+' '/Upper Right/{print$3,$4}' \
          < <(gdalinfo /share/caches/product/image/${name}.tif))
  if [ ! -f /share/caches/product/${name}.sqlite3 ]
  then
    cat <<-EOF > /share/caches/temp-${name}.xml
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
		<service type="wms" enabled="true"/>
	</mapcache>
	EOF

    mapcache_seed -c /share/caches/temp-${name}.xml \
                  -e ${minx},${miny},${maxx},${maxy} \
                  -g GoogleMapsCompatible \
                  -t ${name} \
                  -z 0,13 \
    && rm /share/caches/temp-${name}.xml \
    || exit 1

    cp /share/caches/product/${name}.sqlite3 \
       /share/caches/product/${name}_i.sqlite3
    sqlite3 /share/caches/product/${name}_i.sqlite3 \
            'CREATE UNIQUE INDEX xyz ON tiles(x,y,z);'
  fi
}

# Append entry to catalog
appendtocatalog() {
  name=$1 minx=$2 miny=$3 maxx=$4 maxy=$5
  catalog="/share/caches/product/catalog.sqlite"
  if [ ! -f "${catalog}" ]
  then
    sqlite3 "${catalog}" \
      "CREATE TABLE catalog(
          name TEXT,
          minx REAL,
          miny REAL,
          maxx REAL,
          maxy REAL,
          keywords TEXT);"
  fi
  sqlite3 "${catalog}" \
    "INSERT OR IGNORE INTO catalog(name,minx,miny,maxx,maxy,keywords)
     VALUES(\"${name}\",${minx},${miny},${maxx},${maxy},\"${keywords}\");"
}

# Generate a single simulated product
generateproduct() {
  name=$1 x=$2 y=$3 fmt=$4 provider=$5 layer=$6
  read -r width height minx miny maxx maxy < <(imageparams $x $y $fmt)
  getjpeg $name $width $height $minx,$miny,$maxx,$maxy $provider $layer || exit 1
  jpeg2geotiff $name $minx $miny $maxx $maxy
  geotiff2tiles $name || exit 1
  appendtocatalog $name $minx $miny $maxx $maxy $keywords
}


# ARGUMENTS

if [ $# -ne 7 ]
then
  printf "Error: Need 7 arguments\n" >&2
  printf "Usage: $0 name center-x center-y format provider layer keywords\n" >&2
  printf "  alt: $0 --random nprod name,keywords xmin ymin xmax ymax\n" >&2
  exit 1
fi

if [ "x$1" == "x--random" ]
then
  israndom=true
  nprod=${2}
  keywords=${3}
  IFS=, read prefix other <<< ${keywords}
  xmin=$(tr '-' '_' <<< ${4})
  ymin=$(tr '-' '_' <<< ${5})
  xmax=$(tr '-' '_' <<< ${6})
  ymax=$(tr '-' '_' <<< ${7})
  fmts=(horizontal vertical square)
  srcs=(stamen:terrain stamen:toner-lite osm:openstreetmap osm:wikimedia osm:opentopomap)
else
  israndom=false
  nprod=1
  name=${1}
  x=${2}
  y=${3}
  fmt=${4}
  provider=${5}
  layer=${6}
  keywords=${7}
fi

for i in $(seq 1 $nprod)
do
  echo
  if ${israndom}
  then
    name=${prefix}_$(cat /proc/sys/kernel/random/uuid | tr '-' '_')
    x=$(dc <<< "20k ${xmax} ${xmin} - $RANDOM 32768/* ${xmin}+p")
    y=$(dc <<< "20k ${ymax} ${ymin} - $RANDOM 32768/* ${ymin}+p")
    fmt=${fmts[$((RANDOM*${#fmts[@]}/32768))]}
    IFS=: read provider layer <<< "${srcs[$((RANDOM*${#srcs[@]}/32768))]}"
    printf "$i: "
  fi
  echo $name $x $y $fmt $provider $layer $keywords
  generateproduct $name $x $y $fmt $provider $layer $keywords
done
