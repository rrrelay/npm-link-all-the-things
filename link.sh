#! /usr/bin/env bash

##### WOMM!!! osx and bunch of stuff installed
##### crazy slow and horrible.... but still faster than doing it by hand


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

oldDir="$PWD";
scriptLocation="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
j="$scriptLocation/node_modules/.bin/json"
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

echo "Found $(echo "$module_names_to_link" | wc -l |sed -e 's/[ \t]//g') modules that should be link.";
echo "$module_names_to_link";

read;
# linking is a two step process
# step 1
while read m; do
	name="$(cat "$m" | "$j" name)";
	if echo "$module_names_to_link" | ack "^$name$" > /dev/null; then
		ooldDir="$PWD";
		currDir="${m%package.json}"
		echo "linking in $currDir";
		cd "$currDir";
		sudo npm link > /dev/null;
		cd "$ooldDir";

	fi
done < <(echo "$all_module_locations")



# step 2

results='';
while read m; do
	lll="${m%package.json}"
	cd "$lll"

	while read dep; do
		if echo "$module_names_to_link" | ack "^$dep$" > /dev/null; then
			npm link "$dep" > /dev/null;
			results="$results $lll: $dep"$'\n';
		fi
	done < <(getDependencyNames "package.json")
	cd "$oldDir"
done < <(echo "$all_module_locations")

echo "--------------------";
echo "$results";
