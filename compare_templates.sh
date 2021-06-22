#!/bin/bash

for f in antipattern pattern troubleshooting; do
  fa=".github/ISSUE_TEMPLATE/$f.md"
  fb="$f/template.md.tmp"
  diff -y "$fa" "$fb"
  read
  vim -p "$fa" "$fb"
done
