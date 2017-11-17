#!/bin/bash

# This script run on test host.

base=${1:-"http://100.100.100.200/latest/meta-data/"}

function show_item()
{
	# input: metadata url
	echo "$1"
	curl $1 2>/dev/null
	echo ""
}

item_list=$(curl $base 2>/dev/null)

for item in $item_list; do
	if [[ "$item" = */ ]]; then
		# get sub items
		$0 ${base}${item}
	else
		# show item / content
		show_item ${base}${item}
	fi
done

exit 0
