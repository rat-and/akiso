#!/bin/bash

curl -s -H "Accept:application.json" http://api.icndb.com/jokes/random  | jq '.value.joke'
kitten_url=$(curl -s https://api.thecatapi.com/api/images/get\?format\=json | jq '.[].url' | tr -d "\"")
kitten=$(wget -q -O kitten.jpg  $kitten_url )

width=$(tput cols)
echo $(img2txt -H 50 -W $width kitten.jpg > kit.txt)
echo $(cat kit.txt)

echo $(rm kitten.jpg)
echo $(rm kit.txt)
exit 0




