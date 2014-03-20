
function runOnNodePackages(){
	oldDir="$PWD";

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

