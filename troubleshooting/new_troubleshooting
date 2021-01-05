#!/bin/bash

if [ "$#" -lt '1' ]; then
  echo 'You should provide the name of the template, you can make use of multiple arguments for a space separated name'
  exit 1
fi

name=$(echo "$@")

# conversion to a slug-like filename based on:
# https://gist.github.com/oneohthree/f528c7ae1e701ad990e6
file=$(iconv -t ascii//TRANSLIT <<<$name | sed -r 's/[^a-zA-Z0-9]+/-/g' | sed -r 's/^-+\|-+$//g' | tr A-Z a-z)

if [ ! -f "$file" ]; then
  printf "$(< 'template.md.tmp')" "$name" > "$file.md"
fi

editor "$file.md"

git add "$file.md"
