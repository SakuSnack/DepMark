# DepMark for Arch Linux
Semi-automatic script for Arch Linux to mark needlessly marked-explicit packages as dependencies

### Who is this for?
I created this script for myself and other Arch Linux users who wish to thin their installed packages.

If you have a long list of explicitly installed packages, and have either on accident, through laziness, or knowledge gaps installed (optional) dependencies as explicit, and now the list has grown so large that sifting through them one by one is keeping you from cleaning your installed package list, then this script is for you!

### What this script does
This script will go through your list of explicitly installed packages, and if that package is required by another package, it will be collected in an array, to be marked as a dependecy instead. If it is only optionally required, the script will ask you if you wish it marked as a dependency or not.

When the end of the package list is reached, you will have the chance to review the list of packages that will be marked dependencies.

If you confirm, pacman will be called to mark all collected packages as dependencies, and txt files logging the changes will be created in the same directoy as the script. You will also be notified of new orphan packages after pacman has been called, if there are any.

### What this script does not do
This script will not detect dependency cycles and thus might mark two or more packages as dependencies of each other, and, if they are not required by any other package, turn them into orphans. You will be notified if any orphans are created, but will have to resolve such a situation manually.

It also does not uninstall any packages, merely prepare the list of explicitly installed packages to be shorter and therefore easier to manage manually.

### How to use
Clone the repository, cd into it, mark the script as executable, then run it

```
git clone https://github.com/SakuSnack/DepMark
cd DepMark
chmod +x DepMark.sh
./DepMark.sh
```

There are no environment variables or command line options to configure and all input is intended to be done interactively by the user.

## Disclaimer
While I created, tested, debugged, and finally directly ran this script on my machine to help clean my own list of installed packages, I provide this script as is with no warranty, as mentioned in the [LICENSE](LICENSE)
