#!/bin/bash


# MAPCACHE PERFORMANCE TESTING WITH APACHE TRACES
#   Run from within virtual environment


dcmean="3k0sn[ln1+sn+z1<r]sr0lrxsslsn[ms / ]nlnn[ = ]nlsln/n[ms]pq"

clearlog() {
  su -c "cp /dev/null /var/log/apache2/error.log"
}


###############################################################################
WMTS_1() {
  z=$1 x=$2 y=$3 c=$4 l=$5
  f=${FUNCNAME[0]}
  printf "%-10s %4s %6s %6s %-16s %-20s " $f $z $x $y $c $l

  src="http://localhost:80/${c}/wmts"
  req="SERVICE=WMTS&REQUEST=GetTile"
  lay="&LAYER=${l}&TILEMATRIXSET=GoogleMapsCompatible"
  loc="&TILEMATRIX=${z}&TILEROW=${y}&TILECOL=${x}"
  siz=""
  url="${src}?${req}${lay}${loc}${siz}"

  clearlog

  thost=()
  for i in $(seq 1 ${nmes})
  do
    mes=$(
      (time curl -s "${url}" > tile) \
          2> >(awk -F'[\tms]' '/real/{print ($2*60+$3)*1000}'))
    if file tile | grep -q -E '(JPEG|PNG)'
    then
      thost+=(${mes})
    elif file tile | grep -q 'XML'
    then
      echo
      xmllint --format tile
      exit 1
    else
      echo
      cat tile
      exit 1
    fi
  done

  tguest=($(
      grep mapcache_handler /var/log/apache2/error.log \
          | /share/bin/parselog.py \
          | awk -F'[ .{}]*' '/END.*mapcache_handler/{print $4/1000}'
  ))

  printf "%30s " "$(dc <<< "${tguest[@]} ${dcmean}")"
  printf "%30s " "$(dc <<< "${thost[@]} ${dcmean}")"
  printf "\n"
  ### printf "# URL: %s\n" "${url}"
}


###############################################################################
WMS_256() {
  z=$1 x=$2 y=$3 c=$4 l=$5
  f=${FUNCNAME[0]}
  printf "%-10s %4s %6s %6s %-16s %-20s " $f $z $x $y $c $l

  r="20037508.342"
  ntiles=$(dc <<< "2 $z ^pq")
  tilesize=$(dc <<< "5k $r 2 * $ntiles / pq")
  minx=$(dc <<< "5k 0 $r - $x $tilesize *+pq")
  miny=$(dc <<< "5k 0 $r - $ntiles $y 1+ - $tilesize *+pq")
  maxx=$(dc <<< "5k 0 $r - $x 1+ $tilesize *+pq")
  maxy=$(dc <<< "5k 0 $r - $ntiles $y - $tilesize *+pq")

  src="http://localhost:80/${c}"
  req="SERVICE=WMS&REQUEST=GetMap"
  lay="&LAYERS=${l}&SRS=EPSG:3857"
  loc="&BBOX=${minx},${miny},${maxx},${maxy}"
  siz="&WIDTH=256&HEIGHT=256"
  url="${src}?${req}${lay}${loc}${siz}"

  clearlog

  thost=()
  for i in $(seq 1 ${nmes})
  do
    mes=$(
      (time curl -s "${url}" > map) \
          2> >(awk -F'[\tms]' '/real/{print ($2*60+$3)*1000}'))
    if file map | grep -q -E '(JPEG|PNG)'
    then
      thost+=(${mes})
    elif file map | grep -q 'XML'
    then
      printf "\n\nURL: %s\n" "${url}"
      xmllint --format map
      exit 1
    else
      printf "\n\nURL: %s\n" "${url}"
      cat map
      exit 1
    fi
  done

  tguest=($(
      grep mapcache_handler /var/log/apache2/error.log \
          | /share/bin/parselog.py \
          | awk -F'[ .{}]*' '/END.*mapcache_handler/{print $4/1000}'
  ))

  printf "%30s " "$(dc <<< "${tguest[@]} ${dcmean}")"
  printf "%30s " "$(dc <<< "${thost[@]} ${dcmean}")"
  printf "\n"
  ### printf "# URL: %s\n" "${url}"
}


###############################################################################
WMS_1024() {
  z=$1 x=$2 y=$3 c=$4 l=$5
  f=${FUNCNAME[0]}
  printf "%-10s %4s %6s %6s %-16s %-20s " $f $z $x $y $c $l

  r="20037508.342"
  ntiles=$(dc <<< "2 $z ^pq")
  tilesize=$(dc <<< "5k $r 2 * $ntiles / pq")
  minx=$(dc <<< "5k 0 $r - $x $tilesize *+pq")
  miny=$(dc <<< "5k 0 $r - $ntiles $y 4+ - $tilesize *+pq")
  maxx=$(dc <<< "5k 0 $r - $x 4+ $tilesize *+pq")
  maxy=$(dc <<< "5k 0 $r - $ntiles $y - $tilesize *+pq")

  src="http://localhost:80/${c}"
  req="SERVICE=WMS&REQUEST=GetMap"
  lay="&LAYERS=${l}&SRS=EPSG:3857"
  loc="&BBOX=${minx},${miny},${maxx},${maxy}"
  siz="&WIDTH=1024&HEIGHT=1024"
  url="${src}?${req}${lay}${loc}${siz}"

  clearlog

  thost=()
  for i in $(seq 1 ${nmes})
  do
    mes=$(
      (time curl -s "${url}" > map) \
          2> >(awk -F'[\tms]' '/real/{print ($2*60+$3)*1000}'))
    if file map | grep -q -E '(JPEG|PNG)'
    then
      thost+=(${mes})
    elif file map | grep -q 'XML'
    then
      printf "\n\nURL: %s\n" "${url}"
      xmllint --format map
      exit 1
    else
      printf "\n\nURL: %s\n" "${url}"
      cat map
      exit 1
    fi
  done

  tguest=($(
      grep mapcache_handler /var/log/apache2/error.log \
          | /share/bin/parselog.py \
          | awk -F'[ .{}]*' '/END.*mapcache_handler/{print $4/1000}'
  ))

  printf "%30s " "$(dc <<< "${tguest[@]} ${dcmean}")"
  printf "%30s " "$(dc <<< "${thost[@]} ${dcmean}")"
  printf "\n"
  ### printf "# URL: %s\n" "${url}"
}


###############################################################################
WMTS_16() {
  z=$1 x=$2 y=$3 c=$4 l=$5
  f=${FUNCNAME[0]}
  printf "%-10s %4s %6s %6s %-16s %-20s " $f $z $x $y $c $l

  src="http://localhost:80/${c}/wmts"
  req="SERVICE=WMTS&REQUEST=GetTile"
  lay="&LAYER=${l}&TILEMATRIXSET=GoogleMapsCompatible"
  loc="&TILEMATRIX=0&TILEROW=0&TILECOL=0"
  siz=""
  url="${src}?${req}${lay}${loc}${siz}"

  clearlog

  thost=()
  for i in $(seq 1 ${nmes})
  do
    curl -s "${src}?SERVICE=WMTS&REQUEST=MarkStartMap" > /dev/null 2>&1
    cmd="eval "
    for dx in 0 1 2 3
    do
      for dy in 0 1 2 3
      do
        loc="&TILEMATRIX=${z}&TILEROW=$((y+dy))&TILECOL=$((x+dx))"
        url="${src}?${req}${lay}${loc}${siz}"
        cmd="${cmd} curl -s '${url}' > tile${dx}${dy} &"
      done
    done
    mes=$(time ( ${cmd} ; wait ) \
        2> >(awk -F'[\tms]' '/real/{print ($2*60+$3)*1000}'))
    curl -s "${src}?SERVICE=WMTS&REQUEST=MarkStopMap" > /dev/null 2>&1
    for dx in 0 1 2 3
    do
      for dy in 0 1 2 3
      do
        if file tile${dx}${dy} | grep -q -E '(JPEG|PNG)'
        then
          :
        elif file tile${dx}${dy} | grep -q 'XML'
        then
          echo
          xmllint --format tile${dx}${dy}
          exit 1
        else
          echo
          cat tile${dx}${dy}
          exit 1
        fi
      done
    done
    thost+=(${mes})
  done

  rm -f apachelog_*
  csplit --quiet --digits=4 --prefix=apachelog_ /var/log/apache2/error.log '/MarkStartMap/' '{*}'
  rm -f apachelog_0000
  tguest=($(
    for i in apachelog_*
    do
      printf "3p\n\$-4p\n" | ed -s $i
    done \
      | awk -F'[ :]' '{
          t2=(($4*60+$5)*60+$6)*1000;
          if(t1>0){printf"%12g\n",t2-t1;t1=0}else{t1=t2}}'
  ))

  printf "%30s " "$(dc <<< "${tguest[@]} ${dcmean}")"
  printf "%30s " "$(dc <<< "${thost[@]} ${dcmean}")"
  printf "\n"
  montage -geometry 256x256 -background black \
          tile00 tile10 tile20 tile30 \
          tile01 tile11 tile21 tile31 \
          tile02 tile12 tile22 tile32 \
          tile03 tile13 tile23 tile33 \
          tiles.png
}


###############################################################################
printf "\n\n"
printf "# %-8s %4s %6s %6s %-16s %-20s %30s %30s\n" \
    'type' 'zoom' 'minx' 'miny' 'conf.' 'layer' 'total server-side' 'total client-side' \
    '----' '----' '----' '----' '-----' '-----' '-----------------' '-----------------'

if [ $# -eq 0 ]
then

  if false ; then
  printf "\n# World coverage of basemap at zoom levels 0 (1 tile) and 2 (16 tiles)\n"

  nmes=100 WMTS_1    0 0 0 catalog base
  nmes=100 WMS_256   0 0 0 catalog base
  nmes=100 WMS_1024  2 0 0 catalog base
  nmes=100 WMTS_16   2 0 0 catalog base

  printf "\n# World coverage of catalog (400 products) at zoom levels 0 (1 tile) and 2 (16 tiles)\n"

  nmes=10  WMTS_1    0 0 0 catalog       catalog
  nmes=10  WMS_256   0 0 0 catalog       catalog
  nmes=1   WMS_1024  2 0 0 catalog       catalog
  nmes=1   WMS_1024  2 0 0 catalog       catalog
  nmes=1   WMS_1024  2 0 0 catalog       catalog
  nmes=1   WMS_1024  2 0 0 catalog       catalog
  nmes=1   WMS_1024  2 0 0 catalog       catalog
  nmes=1   WMTS_16   2 0 0 catalog       catalog
  nmes=1   WMTS_16   2 0 0 catalog       catalog
  nmes=1   WMTS_16   2 0 0 catalog       catalog
  nmes=1   WMTS_16   2 0 0 catalog       catalog
  nmes=1   WMTS_16   2 0 0 catalog       catalog
  nmes=1   WMS_1024  2 0 0 catalog-mt    catalog
  nmes=1   WMS_1024  2 0 0 catalog-mt    catalog
  nmes=1   WMS_1024  2 0 0 catalog-mt    catalog
  nmes=1   WMS_1024  2 0 0 catalog-mt    catalog
  nmes=1   WMS_1024  2 0 0 catalog-mt    catalog
  nmes=1   WMTS_16   2 0 0 catalog-mt    catalog
  nmes=1   WMTS_16   2 0 0 catalog-mt    catalog
  nmes=1   WMTS_16   2 0 0 catalog-mt    catalog
  nmes=1   WMTS_16   2 0 0 catalog-mt    catalog
  nmes=1   WMTS_16   2 0 0 catalog-mt    catalog
  nmes=1   WMS_1024  2 0 0 catalog-geo   catalog
  nmes=1   WMS_1024  2 0 0 catalog-geo   catalog
  nmes=1   WMS_1024  2 0 0 catalog-geo   catalog
  nmes=1   WMS_1024  2 0 0 catalog-geo   catalog
  nmes=1   WMS_1024  2 0 0 catalog-geo   catalog
  nmes=1   WMTS_16   2 0 0 catalog-geo   catalog
  nmes=1   WMTS_16   2 0 0 catalog-geo   catalog
  nmes=1   WMTS_16   2 0 0 catalog-geo   catalog
  nmes=1   WMTS_16   2 0 0 catalog-geo   catalog
  nmes=1   WMTS_16   2 0 0 catalog-geo   catalog
  nmes=1   WMS_1024  2 0 0 catalog-mtgeo catalog
  nmes=1   WMS_1024  2 0 0 catalog-mtgeo catalog
  nmes=1   WMS_1024  2 0 0 catalog-mtgeo catalog
  nmes=1   WMS_1024  2 0 0 catalog-mtgeo catalog
  nmes=1   WMS_1024  2 0 0 catalog-mtgeo catalog
  nmes=1   WMTS_16   2 0 0 catalog-mtgeo catalog
  nmes=1   WMTS_16   2 0 0 catalog-mtgeo catalog
  nmes=1   WMTS_16   2 0 0 catalog-mtgeo catalog
  nmes=1   WMTS_16   2 0 0 catalog-mtgeo catalog
  nmes=1   WMTS_16   2 0 0 catalog-mtgeo catalog
  fi

  printf "\n# Zoom in on USA with catalog (16 tiles per map)\n"

  nmes=10  WMS_1024  2    0    0  catalog-geo      catalog
  nmes=10  WMS_1024  3    0    1  catalog-geo      catalog
  nmes=10  WMS_1024  4    2    4  catalog-geo      catalog
  nmes=10  WMS_1024  5    5   10  catalog-geo      catalog
  nmes=10  WMS_1024  6   14   22  catalog-geo      catalog
  nmes=10  WMS_1024  7   29   44  catalog-geo      catalog
  nmes=10  WMS_1024  8   60   90  catalog-geo      catalog
  nmes=10  WMS_1024  9  121  181  catalog-geo      catalog
  nmes=10  WMS_1024 10  245  366  catalog-geo      catalog
  nmes=10  WMS_1024 11  493  734  catalog-geo      catalog
  nmes=10  WMS_1024 12  986 1471  catalog-geo      catalog
  nmes=10  WMS_1024 13 1971 2945  catalog-geo      catalog
  nmes=10  WMS_1024  2    0    0  catalog-mtgeo    catalog
  nmes=10  WMS_1024  3    0    1  catalog-mtgeo    catalog
  nmes=10  WMS_1024  4    2    4  catalog-mtgeo    catalog
  nmes=10  WMS_1024  5    5   10  catalog-mtgeo    catalog
  nmes=10  WMS_1024  6   14   22  catalog-mtgeo    catalog
  nmes=10  WMS_1024  7   29   44  catalog-mtgeo    catalog
  nmes=10  WMS_1024  8   60   90  catalog-mtgeo    catalog
  nmes=10  WMS_1024  9  121  181  catalog-mtgeo    catalog
  nmes=10  WMS_1024 10  245  366  catalog-mtgeo    catalog
  nmes=10  WMS_1024 11  493  734  catalog-mtgeo    catalog
  nmes=10  WMS_1024 12  986 1471  catalog-mtgeo    catalog
  nmes=10  WMS_1024 13 1971 2945  catalog-mtgeo    catalog
  nmes=10  WMS_1024  2    0    0  catalog-amtgeo   catalog
  nmes=10  WMS_1024  3    0    1  catalog-amtgeo   catalog
  nmes=10  WMS_1024  4    2    4  catalog-amtgeo   catalog
  nmes=10  WMS_1024  5    5   10  catalog-amtgeo   catalog
  nmes=10  WMS_1024  6   14   22  catalog-amtgeo   catalog
  nmes=10  WMS_1024  7   29   44  catalog-amtgeo   catalog
  nmes=10  WMS_1024  8   60   90  catalog-amtgeo   catalog
  nmes=10  WMS_1024  9  121  181  catalog-amtgeo   catalog
  nmes=10  WMS_1024 10  245  366  catalog-amtgeo   catalog
  nmes=10  WMS_1024 11  493  734  catalog-amtgeo   catalog
  nmes=10  WMS_1024 12  986 1471  catalog-amtgeo   catalog
  nmes=10  WMS_1024 13 1971 2945  catalog-amtgeo   catalog
  nmes=10  WMS_1024  2    0    0  catalog-mtamtgeo catalog
  nmes=10  WMS_1024  3    0    1  catalog-mtamtgeo catalog
  nmes=10  WMS_1024  4    2    4  catalog-mtamtgeo catalog
  nmes=10  WMS_1024  5    5   10  catalog-mtamtgeo catalog
  nmes=10  WMS_1024  6   14   22  catalog-mtamtgeo catalog
  nmes=10  WMS_1024  7   29   44  catalog-mtamtgeo catalog
  nmes=10  WMS_1024  8   60   90  catalog-mtamtgeo catalog
  nmes=10  WMS_1024  9  121  181  catalog-mtamtgeo catalog
  nmes=10  WMS_1024 10  245  366  catalog-mtamtgeo catalog
  nmes=10  WMS_1024 11  493  734  catalog-mtamtgeo catalog
  nmes=10  WMS_1024 12  986 1471  catalog-mtamtgeo catalog
  nmes=10  WMS_1024 13 1971 2945  catalog-mtamtgeo catalog

  exit

  printf "\n# Couverture globale du catalogue des produits: une tuile au niveau 0 et 16 tuiles au niveau 2\n"
  nmes=10  WMTS_1    TEST_004 0 0 0 mapcache-produit produits
  nmes=10  WMTS_1    TEST_004 0 0 0 mapcache-produit produits-geo
  nmes=10  WMTS_1    TEST_004 0 0 0 mapcache-produit produits-i
  nmes=10  WMTS_1    TEST_004 0 0 0 mapcache-produit produits-i-geo
  nmes=2   WMTS_1    TEST_004 0 0 0 mapcache-produit produits-thr
  nmes=2   WMTS_1    TEST_004 0 0 0 mapcache-produit produits-geo-thr
  nmes=2   WMTS_1    TEST_004 0 0 0 mapcache-produit produits-i-thr
  nmes=2   WMTS_1    TEST_004 0 0 0 mapcache-produit produits-i-geo-thr
  nmes=10  WMTS_1    TEST_004 0 0 0 mapcache-produit produits-es
  nmes=10  WMTS_1    TEST_004 0 0 0 mapcache-produit produits-geo-es
  nmes=10  WMTS_1    TEST_004 0 0 0 mapcache-produit produits-i-es
  nmes=10  WMTS_1    TEST_004 0 0 0 mapcache-produit produits-i-geo-es
  nmes=2   WMTS_1    TEST_004 0 0 0 mapcache-produit produits-thr-es
  nmes=2   WMTS_1    TEST_004 0 0 0 mapcache-produit produits-geo-thr-es
  nmes=2   WMTS_1    TEST_004 0 0 0 mapcache-produit produits-i-thr-es
  nmes=2   WMTS_1    TEST_004 0 0 0 mapcache-produit produits-i-geo-thr-es
  nmes=10  WMS_1024  TEST_005 2 0 0 mapcache-produit produits-i-geo
  nmes=10  WMTS_16   TEST_006 2 0 0 mapcache-produit produits-i-geo
  exit

  printf "\n# Couverture par quartiers du catalogue des produits: 4x16 tuiles au niveau 3\n"
  nmes=10 WMS_1024   TEST_007 3 0 0 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 3 4 0 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 3 0 4 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 3 4 4 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 3 0 0 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 3 4 0 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 3 0 4 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 3 4 4 mapcache-produit produits-i-geo

  printf "\n# Couverture par seizièmes du catalogue des produits: 16x16tuiles au niveau 4\n"
  nmes=10 WMS_1024   TEST_007 4  0  0 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 4  4  0 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 4  8  0 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 4 12  0 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 4  0  4 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 4  4  4 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 4  8  4 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 4 12  4 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 4  0  8 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 4  4  8 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 4  8  8 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 4 12  8 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 4  0 12 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 4  4 12 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 4  8 12 mapcache-produit produits-i-geo
  nmes=10 WMS_1024   TEST_007 4 12 12 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 4  0  0 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 4  4  0 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 4  8  0 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 4 12  0 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 4  0  4 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 4  4  4 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 4  8  4 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 4 12  4 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 4  0  8 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 4  4  8 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 4  8  8 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 4 12  8 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 4  0 12 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 4  4 12 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 4  8 12 mapcache-produit produits-i-geo
  nmes=10 WMTS_16    TEST_007 4 12 12 mapcache-produit produits-i-geo

elif [ $# -eq 6 ]
then

  nmes=${nmes:-1} eval $1 $2 $3 $4 $5 $6

elif [ $# -eq 1 ]
then

  case "x$1" in
    xclearlog)
      eval $1
      ;;
  esac

elif [ $# -eq 4 ]
then

  case "x$1" in
    xtilebbox)
      r="20037508.3427892480"
      z=$2
      x=$3
      y=$4
      ntiles=$(dc <<< "2 $z ^pq")
      tilesize=$(dc <<< "10k $r 2 * $ntiles / pq")
      minx=$(dc <<< "10k 0 $r - $x $tilesize *+pq")
      miny=$(dc <<< "10k 0 $r - $ntiles $y 1+ - $tilesize *+pq")
      maxx=$(dc <<< "10k 0 $r - $x 1+ $tilesize *+pq")
      maxy=$(dc <<< "10k 0 $r - $ntiles $y - $tilesize *+pq")
      printf "%s:%s:%s -> [ %s, %s, %s, %s ]\n" $z $x $y $minx $miny $maxx $maxy
      ;;
  esac

fi







