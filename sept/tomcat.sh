#!/usr/bin/bash

echo "enter the num"
read num

if ! ((num % 15)); then
  echo tomcat
elif ! ((num % 3)); then
  echo tom
elif ! ((num % 5)); then
  echo cat
else
  echo $i
fi
