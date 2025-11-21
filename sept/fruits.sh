#!/usr/bin/bash
fruits=("apple" "mango" "banana" "cherry" "berry")

for fruit in "${fruits[@]}"; do
  echo "scanning inventory..... found $fruit"
  echo "$fruit is fresh and ready"
  echo "  "
  sleep 1
done
