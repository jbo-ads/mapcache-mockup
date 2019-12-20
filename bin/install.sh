#!/bin/bash

bindir=/share/bin
if [ ! -e ${bindir} ]
then
  bindir="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
fi

for component in dependencies openlayers mapcache
do
  ${bindir}/install-${component}.sh
done
