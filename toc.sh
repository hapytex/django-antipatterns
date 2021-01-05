#!/bin/bash

sep=$(echo -e ". \n")

function make_toc() {
  fl=$(ls $1/*.md)
  head -q -n 1 $fl | cut -c 2- | paste -d ':' - <(echo "$fl") | sed -E 's/^.(.*)[:](.*)[.]md/ [\1](\2.html)/g' | paste -d '.' <(seq $(wc -l <<<"$fl")) -
}

echo -e "% Django (anti)patterns\n"

echo -e "# Antipatterns\n"

make_toc antipatterns

echo -e "\n\n# Patterns\n"

make_toc patterns

echo -e "\n\n# Troubleshooting\n"

make_toc troubleshooting
