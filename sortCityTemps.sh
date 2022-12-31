#!/bin/bash
cities=("Paris" "London" "Berlin")
> temperatures.txt

for city in ${cities[@]}
do
  sleep 1
  ./weather.sh -s $city | sed 's/+//' |\
  sed 's/°C//' \
  >> temperatures.txt
done

sort -k2 temperatures.txt \
> sorted_temperatures.txt
