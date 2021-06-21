#!/bin/bash

for f in antipattern pattern troubleshooting; do
  vim -p ".github/ISSUE_TEMPLATE/$f.md" "$f/template.md.tmp"
done
