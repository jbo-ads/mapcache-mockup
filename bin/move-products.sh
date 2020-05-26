#!/bin/bash

sudo apachectl -k stop
sleep 2

# Copy products to their own folders
basedir=/share/caches/product
sqlite3 /share/caches/product/catalog.sqlite 'select * from catalog' \
| while IFS='|' read name path others
do
  pathdir=${basedir}/$(dirname ${path})
  for m in "" "_i"
  do
    f=${basedir}/${name}${m}.sqlite3
    b=$(basename ${f})
    n=${pathdir}/${b}
    echo $f $n
    if [ ! -f $n ]
    then
      mkdir -p $pathdir
      mv $f $n
    fi
  done
done

# Update MapCache configurations accordingly
sudo sed -i 's/distinct(name)/distinct(path)/' /usr/local/etc/mapcache/*.xml
sudo sed -i 's/\(cache name="catalog"\)/\1 allow_path_in_dim="yes"/' /usr/local/etc/mapcache/*.xml

sudo apachectl -k start
