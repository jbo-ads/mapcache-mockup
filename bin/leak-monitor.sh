#!/bin/bash

period=5
if [ "0$1" -gt 0 ]
then
  period="${1}"
fi

while true
do
  /share/bin/progress --colors 255 231 \
    $(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{print a,t}' /proc/meminfo) \
    60 $(date +%T)
  sleep $period
done
