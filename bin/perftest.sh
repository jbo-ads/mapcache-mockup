#!/bin/bash


clearlog() {
  cp /dev/null /var/log/apache2/error.log
}

gettile() {
  z=$1 x=$2 y=$3 p=$4 l=$5 n=$6
  dim="$7"
  for i in $(seq 1 $n)
  do
    curl -s "http://localhost:80/$p/wmts/1.0.0/$l/default/$dim/GoogleMapsCompatible/$z/$x/$y" > /tmp/tile
    if ! file /tmp/tile | grep -q -E '(JPEG|PNG)'
    then
      echo
      if file /tmp/tile | grep -q 'XML'
      then
        xmllint --format /tmp/tile
      else
        cat /tmp/tile
      fi
      exit 1
    fi
  done
}

getmap() {
  z=$1 x=$2 y=$3 p=$4 l=$5 n=$6
  dim="$7"
  r="20037508.342"
  ntiles=$(dc <<< "2 $z ^pq")
  tilesize=$(dc <<< "5k $r 2 * $ntiles / pq")
  minx=$(dc <<< "5k 0 $r - $x $tilesize *+pq")
  miny=$(dc <<< "5k 0 $r - $ntiles $y 4+ - $tilesize *+pq")
  maxx=$(dc <<< "5k 0 $r - $x 4+ $tilesize *+pq")
  maxy=$(dc <<< "5k 0 $r - $ntiles $y - $tilesize *+pq")
  req="http://localhost:80/$p?SERVICE=WMS&REQUEST=GetMap"
  req="$req&LAYERS=${l}&SRS=EPSG:3857"
  req="$req&BBOX=${minx},${miny},${maxx},${maxy}"
  req="$req&WIDTH=1024&HEIGHT=1024"
  for i in $(seq 1 $n)
  do
    curl -s "$req" > /tmp/map
    if ! file /tmp/map | grep -q -E '(JPEG|PNG)'
    then
      echo
      if file /tmp/map | grep -q 'XML'
      then
        xmllint --format /tmp/map
      else
        cat /tmp/map
      fi
      exit 1
    fi
  done
}

# GET A SINGLE TILE FROM A DISK CACHE
tile_from_disk() {
  clearlog
  gettile 0 0 0 catalog base 100 || exit 1
  /share/bin/parselog.py --nolog < /var/log/apache2/error.log
}

# GET A SINGLE TILE FROM A SQLITE CACHE
tile_from_sqlite() {
  clearlog
  gettile 0 0 0 osm wikimedia 100 || exit 1
  /share/bin/parselog.py --nolog < /var/log/apache2/error.log
}

# GET A SINGLE TILE FROM THE CATALOG OF PRODUCTS
tile_from_catalog() {
  clearlog
  gettile 0 0 0 catalog catalog 100 _ || exit 1
  /share/bin/parselog.py --nolog < /var/log/apache2/error.log
}

# GET A 16x16 MAP FROM DISK WITH ONE THREAD
map_from_disk_monothread() {
  clearlog
  getmap 2 0 0 world world 100 || exit 1
  /share/bin/parselog.py --nolog < /var/log/apache2/error.log
}

# GET A 16x16 MAP FROM DISK WITH MULTIPLE THREADS
map_from_disk_multithread() {
  clearlog
  getmap 2 0 0 catalog base 100 || exit 1
  /share/bin/parselog.py --nolog < /var/log/apache2/error.log
}

# GET A 16x16 MAP FROM SQLITE WITH ONE THREAD
map_from_sqlite_monothread() {
  clearlog
  getmap 2 0 0 osm wikimedia 100 || exit 1
  /share/bin/parselog.py --nolog < /var/log/apache2/error.log
}

# GET A 16x16 MAP FROM SQLITE WITH MULTIPLE THREADS
map_from_sqlite_multithread() {
  clearlog
  getmap 2 0 0 heigit osm 100 || exit 1
  /share/bin/parselog.py --nolog < /var/log/apache2/error.log
}

# GET A 16x16 MAP FROM CATALOG WITH MULTIPLE THREADS
map_from_catalog_multithread() {
  clearlog
  getmap 2 0 0 catalog catalog 100 || exit 1
  /share/bin/parselog.py --nolog < /var/log/apache2/error.log
}

printf "%30s: " tile_from_disk
tile_from_disk
printf "%30s: " tile_from_sqlite
tile_from_sqlite
printf "%30s: " tile_from_catalog
tile_from_catalog
printf "%30s: " map_from_disk_monothread
map_from_disk_monothread
printf "%30s: " map_from_disk_multithread
map_from_disk_multithread
printf "%30s: " map_from_sqlite_monothread
map_from_sqlite_monothread
printf "%30s: " map_from_sqlite_multithread
map_from_sqlite_multithread
printf "%30s: " map_from_catalog_multithread
map_from_catalog_multithread
