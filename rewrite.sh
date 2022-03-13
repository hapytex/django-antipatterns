#!/bin/bash

if [ "$#" -lt '1' ]; then
  echo &>2 'Should contain one parameter: the file to modify'
  exit 1
fi

file="$1"

sed -i -E 's#\[([A-Za-z\-]+)\]\]\(#<sup>[\1]</sup>](#g' "$@"  # rewrite references to Wikipedia-style
