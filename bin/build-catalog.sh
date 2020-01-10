#!/bin/bash

bindir="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

# Generate simulated products over cities where UN agencies are located
for prod in \
  bern:828195:5933741:horizontal:osm:openstreetmap:un,europe \
  geneva:685269:5813644:horizontal:osm:openstreetmap:un,europe \
  london:-8439:6711752:square:osm:openstreetmap:un,europe \
  madrid:-410918:4925262:vertical:osm:openstreetmap:un,europe \
  montreal:-8197998:5702978:vertical:osm:openstreetmap:un,america \
  nairobi:4099769:-143816:square:osm:openstreetmap:un,africa \
  newyork:-8233564:4979863:vertical:osm:openstreetmap:un,america \
  paris:260025:6251309:square:osm:openstreetmap:un,europe \
  rome:1389633:5146158:vertical:osm:openstreetmap:un,europe \
  thehague:481406:6814756:square:osm:openstreetmap:un,europe \
  vienna:1822648:6141611:horizontal:osm:openstreetmap:un,europe \
  washington:-8575669:4707022:vertical:osm:openstreetmap:un,america \
; do
  IFS=: read name x y format provider layer keywords <<< $prod
  ${bindir}/genprod.sh $name $x $y $format $provider $layer $keywords
done
