#!/usr/bin/bash
hh=1
while [ $hh -le 5 ]; do
  echo "Stopwatch: $hh second elapsed!!!"
  hh=$(($hh + 1))
  sleep 1
done
echo "stopwatch complete"
