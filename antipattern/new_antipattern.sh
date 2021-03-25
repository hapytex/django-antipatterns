#!/bin/bash

# cd to the directory of the shell script
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

../new-item "antipattern" "$@"
