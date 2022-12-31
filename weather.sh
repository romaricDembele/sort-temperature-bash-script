#!/usr/bin/env bash
# Author: Alexander Epstein https://github.com/alexanderepstein
# Codecademy Edits by Prabhjot Singh https://github.com/Prince25

currentVersion="1.23.0" #This version variable should not have a v but should contain all other characters ex Github release tag is v1.2.4 currentVersion is 1.2.4
LANG="${LANG:-en}"
locale=$(echo "$LANG" | cut -c1-2)
simpleOutput=0 
unset configuredClient
if [[ $(echo "$locale" | grep -Eo "[a-z A-Z]*" | wc -c) != 3 ]]; then locale="en"; fi

## This function determines which http get tool the system has installed and returns an error if there isnt one
getConfiguredClient()
{
  if command -v curl &>/dev/null; then
    configuredClient="curl"
  elif command -v wget &>/dev/null; then
    configuredClient="wget"
  elif command -v http &>/dev/null; then
    configuredClient="httpie"
  elif command -v fetch &>/dev/null; then
    configuredClient="fetch"
  else
    echo "Error: This tool requires either curl, wget, httpie or fetch to be installed\." >&2
    return 1
  fi
}

## Allows to call the users configured client without if statements everywhere
httpGet()
{
  case "$configuredClient" in
    curl)  curl -A curl -s "$@" ;;
    wget)  wget -qO- "$@" ;;
    httpie) http -b GET "$@" ;;
    fetch) fetch -q "$@" ;;
  esac
}

getIPWeather()
{
  country=$(httpGet ipinfo.io/country) > /dev/null ## grab the country
  if [[ $country == "US" ]]; then ## if were in the us id rather not use longitude and latitude so the output is nicer
    city=$(httpGet ipinfo.io/city) > /dev/null
    region=$(httpGet ipinfo.io/region) > /dev/null
    if [[ $(echo "$region" | wc -w) == 2 ]];then
      region=$(echo "$region" | grep -Eo "[A-Z]*" | tr -d "[:space:]")
    fi
    if [ $simpleOutput -eq 0 ]; then 
      httpGet $locale.wttr.in/"$city","$region""$1" 
    else 
      httpGet $locale.wttr.in/"$city","$region""$1"?format=%l+%t 
    fi 
  else ## otherwise we are going to use longitude and latitude
    location=$(httpGet ipinfo.io/loc) > /dev/null
    if [ $simpleOutput -eq 0 ]; then 
      httpGet $locale.wttr.in/"$location""$1" 
    else 
      httpGet $locale.wttr.in/"$location""$1"?format=%l+%t 
    fi 
  fi
  echo
}

getLocationWeather()
{
  args=$(echo "$@" | sed 's/\s*-s\s*//' | tr " " +) 
  if [ $simpleOutput -eq 0 ]; then 
    httpGet $locale.wttr.in/"${args}" 
  else 
    httpGet $locale.wttr.in/"${args}"?format=%l+%t 
  fi 
  echo 
}

checkInternet()
{
  httpGet github.com > /dev/null 2>&1 || { echo "Error: no active internet connection" >&2; return 1; } # query github with a get request
}

usage()
{
  cat <<EOF
Weather
Description: Provides a 3 day forecast or a simple temperature output on your current location or a specified location.
  With no specified location, Weather will default to your current location.
Usage: weather or weather [flag] or weather [-s] [city / country]
  -s  Simple output
  -h  Show the help
  -v  Get the tool version
Examples:
  weather
  weather Paris
  weather -s London
  weather Italy
EOF
}

getConfiguredClient || exit 1

while getopts "uvhs" opt; do
  case "$opt" in
    \?) echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    h)  usage
        exit 0
        ;;
    v)  echo "Version $currentVersion"
        exit 0
        ;;
    s)  simpleOutput=1
        ;;
    :)  echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
  esac
done

if [[ $# == "0" ]]; then
  checkInternet || exit 1
  getIPWeather || exit 1
elif [[ $1 == "help" || $1 == ":help" ]]; then
  usage
else
  checkInternet || exit 1
  getLocationWeather "$@" || exit 1
fi
exit 0