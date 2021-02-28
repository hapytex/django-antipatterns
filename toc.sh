#!/bin/bash

sep=$(echo -e ". \n")

function make_toc() {
  fl=$(ls $1/*.md)
  echo '<div class="twocolumns"><ol>'
  head -q -n 1 $fl | cut -c 2- | paste -d ':' - <(echo "$fl") | sed -E 's/^.(.*)[:](.*)[.]md/ [\1](\2.html)/;s/^/<li>/;s#$#</li>#'
  echo '</ol></div>'
}

echo -e "% Django (anti)patterns\n"

echo -e '<h1 class="patterntype">Antipatterns</h1>\n'

make_toc antipatterns

echo -e '\n\n<h1 class="patterntype">Patterns</h1>\n'

make_toc patterns

echo -e '\n\n<h1 class="patterntype">Troubleshooting</h1>\n'

make_toc troubleshooting
