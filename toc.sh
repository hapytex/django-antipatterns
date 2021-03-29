#!/bin/bash

sep=$(echo -e ". \n")

function make_toc() {
  fl=$(ls $1/*.md)
  echo '<div class="twocolumns"><ol>'
  head -q -n 1 $fl | cut -c 2- | paste -d ':' - <(echo "$fl") | sed -E 's#^.(.*)[:](.*)[.]md# [\1](/\2.html)#;s/^/<li>/;s#$#</li>#'
  echo '</ol></div>'
}

if [ "$#" -gt '1' ]; then
  echo -e "% $2\n"
  make_toc "$1"
else
  echo -e "% Django (anti)patterns\n"
  
  echo -e '<h1 class="patterntype"><a href="/antipattern.html">Antipatterns</a></h1>\n'
  make_toc antipattern
  
  echo -e '\n\n<h1 class="patterntype"><a href="/pattern.html">Patterns</a></h1>\n'
  make_toc pattern
  
  echo -e '\n\n<h1 class="patterntype"><a href="/troubleshooting.html">Troubleshooting</a></h1>\n'
  make_toc troubleshooting
  
  echo -e '\n\n<h1 class="patterntype">Packages</h1>\n'
  make_toc package
fi
