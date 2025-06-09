#!/bin/bash

fl=$(git branch | grep '^[*]' | cut -d' ' -f 2-)

file="$fl.md"

if [ ! -f "$file" ]; then
  echo 'not actively writing'
  exit 1
fi

editor "$file"
hunspell -H "$file"

# commit the work to the branch
git add "$file"
git commit -am "Work on the \"$name\" $typ"
