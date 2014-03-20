#! /usr/bin/env bash

##### WOMM!!! osx and bunch of stuff installed
##### crazy slow and horrible.... but still faster than doing it by hand

oldDir="$PWD";

function getDependencyNames(){
	cat $1 | "$j" dependencies | gsed  -n '/\w/p;' | gsed  's/[":]//g' | awk '{print $1;}'
}

function runOnNodePackages(){
	while read line; do
		x="${line%package.json}"

		cd "$x";

		if ! eval "$2"; then
			echo "FAILURE in $PWD";
			return 1;
		fi
		cd "$oldDir"
	done < <(echo "$1");
}

j="$PWD/node_modules/.bin/json"
all_module_locations="$(find $1 -iname 'package\.json' | gsed '/node_modules/d')"
all_module_names=$(runOnNodePackages "$all_module_locations" 'echo $(cat package.json | "$j" name);');
all_module_names=$(echo "$all_module_names" | sort | uniq)

modules_to_link=
module_names_to_link=

while read m; do
	while read dep; do
		if echo "$all_module_names" | ack "^$dep$" > /dev/null; then
			module_names_to_link="$module_names_to_link$dep"$'\n';
		fi
	done < <(getDependencyNames $m)
done < <(echo "$all_module_locations")

module_names_to_link=$(echo "$module_names_to_link" | sort | uniq );

# linking is a two step process
# step 1
while read m; do
	name="$(cat "$m" | "$j" name)";
	if echo "$module_names_to_link" | ack "^$name$" > /dev/null; then
		modules_to_link="$modules_to_link"$'\n'"$m"
	fi
done < <(echo "$all_module_locations")


echo "$modules_to_link";
runOnNodePackages "$modules_to_link" "sudo npm link";

# step 2

results='';
while read m; do
	dir="${m%package.json}"
	cd "$dir"

	while read dep; do
		if echo "$module_names_to_link" | ack "^$dep$" > /dev/null; then
			npm link "$dep";
			results="$results $dir: $dep"$'\n';
		fi
	done < <(getDependencyNames $m)
	cd "$oldDir"
done < <(echo "$all_module_locations")

echo "--------------------";
echo "$results";
echo "done.";
