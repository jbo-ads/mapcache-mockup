#!/bin/bash

nprod=30
if [ "0$1" -gt 0 ]
then
  nprod="${1}"
fi

/share/bin/genprod.sh --random ${nprod} asia 5000000 3000000 17000000 11000000
