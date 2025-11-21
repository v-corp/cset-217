#!/usr/bin/bash

# for i in {1..5}; do
#   for j in {5..1}; do
#     echo "* "
#   done
#   echo ""
# done
#

rows=5

for ((i = 1; i <= rows; i++)); do
  for ((j = 1; j <= i; j++)); do
    printf "* "
  done
  printf "\n"
done

echo "======"

for ((i = rows; i >= 0; i++)); do
  for ((j = i; j >= 0; j--)); do
    printf "* "
  done
  printf "\n"
done
