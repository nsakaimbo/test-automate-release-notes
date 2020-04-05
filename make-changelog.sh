#!/bin/sh

# fetch all tags in descending lexicographical order
tags=$(git tag --sort=-v:refname | awk '{if(NR>1)print}')

# get the last stable tag
last_stable_tag=$(for tag in $tags; do if [[ ! "$tag" == *"-"* ]]; then echo "$tag"; break; fi; done)

echo "$last_stable_tag"
