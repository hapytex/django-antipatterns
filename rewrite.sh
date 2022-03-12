#!/bin/bash

sed -E 's# \[([A-Za-z0-9.\-]+)\]\]\(#&nbsp;<sup>[\1]](#g'  # rewrite references to Wikipedia-style
