#!/usr/bin/env bash
#shellcheck disable=SC2206

# This script will read all explicitly installed packages from pacman
# and if they are required by any other package, set them to
# installed as a dependency.
# If they are only optionally required, it will show those packages
# and ask if you want to mark them as a dependency.

# This script is meant to only run interactively
if [[ ! -t 1 ]]; then
	myname=$(echo "$0" | rev | cut -d'/' -f1 | rev)
	notify-send -t 6000 -i error -a "$myname" "This script can only be run interactively in a terminal."
	exit 2
fi

# Set up formatting escape sequences
bold=$(tput bold)
normal=$(tput sgr0)

# Set up array to save modified package names to
packagesRequiredMarkedList=()
packagesOptionallyRequiredMarkedList=()

# Read current list of orphan packages as a baseline to compare after the script has run
orphanPackagesPre=("$(pacman -Qdtq)")
orphanPackagesPreCount=$(pacman -Qdtq | wc -l)
orphanPackages=()
orphanPackagesCount=0
newOrphans=()

# Set up current time for file names
scriptRunDateTime="$(date -Iseconds)"

# Set up output log file names
outputFileRequired="depMark-$scriptRunDateTime-RequiredAndMarked.txt"
outputFileOptional="depMark-$scriptRunDateTime-OptionalAndMarked.txt"
outputFileNewOrphans="depMark-$scriptRunDateTime-NewOrphans.txt"

# Function to ask for user confirmation
function yes_or_no {
	while true; do
		read -rp "$* [y/N]: " yn
		case $yn in
		[Yy]*) return 0 ;;
		*) return 1 ;;
		esac
	done
}

# Function to print number of explicitly installed packages before and after the script ran
# as well as saving the list of modified packages to their respecitve log files
function print_changes {
	echo "Explicitly installed packages before: ${bold}$explicitlyInstalledPackagesPre${normal}"
	echo "Explicitly installed packages after:  ${bold}$(pacman -Qe | wc -l)${normal}"
	echo ""
	if ((${#packagesRequiredMarkedList[@]} != 0)); then
		printf "%s\n" "${packagesRequiredMarkedList[@]}" >"$outputFileRequired"
	fi

	if ((${#packagesOptionallyRequiredMarkedList[@]} != 0)); then
		printf "%s\n" "${packagesOptionallyRequiredMarkedList[@]}" >"$outputFileOptional"
	fi

	echo ""
	orphanPackages=("$(pacman -Qdtq)")
	orphanPackagesCount=$(pacman -Qdtq | wc -l)
	newOrphans=("$(echo "${orphanPackagesPre[@]}" "${orphanPackages[@]}" | tr ' ' '\n' | sort | uniq -u | tr '\n' ' ')")
	echo "Orphan packages before: ${bold}$orphanPackagesPreCount${normal}"
	echo "Orphan packages after: ${bold}$orphanPackagesCount${normal}"
	if [[ -z "${newOrphans[0]}" ]]; then
		true
	else
		echo "New orphans detected:"
		printf "%s\n" "${newOrphans[@]}"
		printf "%s\n" "${newOrphans[@]}" >"$outputFileNewOrphans"
	fi

}

# Function to apply all changes simultaneously at the end of data collection
function apply_package_changes {
	sudo pacman -D --asdeps "${packagesRequiredMarkedList[@]}" "${packagesOptionallyRequiredMarkedList[@]}"
}

# Start of user-facing output
echo "Disclaimer: Dependency cycles are not detected by this script.
Potentially necessary packages may be marked as dependencies as a result.
You may review changes in
${bold}$outputFileRequired${normal}
${bold}$outputFileOptional${normal}
${bold}$outputFileNewOrphans${normal}
after the script is finished.
User discretion is advised."
yes_or_no "Continue?" || exit 1

# Read explicitly installed packages from pacman
echo "Reading explicitly installed packages from pacman"
packages=$(pacman -Qeq | tr '\n' ' ')
packages=($packages)
explicitlyInstalledPackagesPre=$(pacman -Qe | wc -l)
# Debug option
#packages=(wget yad yay)

# Loop for every package
for package in "${packages[@]}"; do {
	# Check if package is hard required by any other package, if yes, mark as dependency
	if [[ ! $(pacman -Qi "$package" | grep "Required By" | cut -d':' -f2) = " None" ]]; then {
		echo "${bold}$package${normal}: required by ${bold}$(pacman -Qi "$package" | grep "Required By" | cut -d':' -f2)${normal}"
		packagesRequiredMarkedList+=("$package")
	}; else {
		# Check if package is optionally required by any package, if yes, ask user if to mark as dependency or not
		if [[ ! $(pacman -Qi "$package" | grep "Optional For" | cut -d':' -f2) = " None" ]]; then {
			echo "${bold}$package${normal}: optionally required by${bold}$(pacman -Qi "$package" | grep "Optional For" | cut -d':' -f2)${normal}"
			yes_or_no "Mark package ${bold}$package${normal} as dependency?" && packagesOptionallyRequiredMarkedList+=("$package") || echo "Package $package not marked"

		}; else {
			# Package is not hard required or optionally required by any other package, so do nothing
			echo "${bold}$package${normal}: not required by any other installed package"
		}; fi
	}; fi

}; done

# Print changes to be done and ask for final confirmation
echo "
End of package list reached.
"

todo=0

# Print information
if ((${#packagesRequiredMarkedList[@]} != 0)); then
	echo "${#packagesRequiredMarkedList[@]} packages to be marked as dependency because they are required:"
	echo "${packagesRequiredMarkedList[@]}"
	echo ""
	((todo += 1))
fi

if ((${#packagesOptionallyRequiredMarkedList[@]} != 0)); then
	echo "${#packagesOptionallyRequiredMarkedList[@]} packages to be marked as dependency because they are optionally required:"
	echo "${packagesOptionallyRequiredMarkedList[@]}"
	echo ""
	((todo += 1))
fi

if ((todo == 0)); then
	echo "Nothing do to"
	exit 0
else
	yes_or_no "Continue?" && apply_package_changes || exit 1
fi

echo ""
print_changes
exit 0
