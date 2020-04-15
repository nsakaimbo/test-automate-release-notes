#!/bin/sh

# fetch all tags in descending lexicographical order
tags=$(git tag --sort=-v:refname | awk '{if(NR>1)print}')

# get tag for last stable release
last_stable_tag=$(for tag in $tags; do if [[ ! "$tag" == *"-"* ]]; then echo "$tag"; break; fi; done)

# get the current tag (or SHA)
current_tag=HEAD

# Include commit message and short hash in parentheses
git_log_format="%s (%h)"

# ignore types: chore, docs, style
# this can be amended based on what types should be included/excluded from the release notes
git_log_incl_types="feat|fix|improvement|refactor|perf|test|build|ci|revert"

# Filter commits that satisfy conventional commit format
# See: https://www.conventionalcommits.org/
commit_filter="^($git_log_incl_types)(\([a-z]+\))?:\s.+"

echo "## Release \\\`$current_tag\\\`\n"
echo "Write your release notes on this line.\n"
echo "### What's Changed"

# Fill and sort changelog
git_log=$(git log --oneline --pretty=format:"$git_log_format" $last_stable_tag...$current_tag \
    | grep -E "$commit_filter" \
    | sort -k1 )

TYPES=(	"feat:New Features"
				"fix:Fixes"
				"improvement:Improvements"
				"refactor:Refactors"
				"perf:Performance Improvements"
				"test:testing"
				"build:Build"
				"ci:Continous Integration"
				"revert:Reverts" )

get_heading() {
  for type in "${TYPES[@]}"; do
    KEY=${type%%:*}
    VALUE=${type#*:}
    if [[ "$KEY" == "$1" ]]; then
      echo "$VALUE"
    fi
  done
}

# capitalize first letter of each word
make_title_case() {
  echo "$1" | awk '{for(i=1;i<=NF;i++){ $i=toupper(substr($i,1,1)) substr($i,2) }}1'
}

# capitalize beginning of string only
make_first_letter_upper() {
  ## note: we can't use ^ syntax which is only available in bash v4.x
  echo "$1" | awk '{for (i=1;i<=1;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1'
}


###: https://www.cylindric.net/git/force-lf

## Print each change by doing the following:
## - parse format 'type(optional scope): description' into type, scope and description components
## - map each type to human-readable heading (as mapped in the TYPES array)
## - use each item scope as a human-readable subheading (formatted as "Title Cased")
## - print each item under its designated heading and subheading (formatted as "Sentence cased")

last_type=""
last_scope=""
echo "$git_log" | while IFS=$'\r' read change; do

	type=$(echo "$change" | grep -o "[^:(]*")
  if [[ "$last_type" != "$type" ]]; then
    last_type=$type
    last_scope=""
		echo "\n#### $(get_heading $type)\n"
  fi;

  scope=$( echo "$change" | grep -o "\(([^)]*)\):" | tr -d '():' ) 
  description=$( echo "$change" | sed 's/.*://' )

  if [[ "$scope" != "$last_scope" ]]; then
    last_scope=$scope
    if [[ -z "$scope" ]]; then
      echo "\n###### General"
    else
      echo "\n###### $( make_title_case "$scope" )"
    fi;
  fi;

  print_prefix='{print "- " $0}'
	echo $( make_first_letter_upper "$description" ) | awk "$print_prefix"

done

