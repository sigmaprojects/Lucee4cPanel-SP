#!/bin/bash
#
###############################################################################
#
# Purpose:      This is the self-extraction that script that runs when the
#               initial lucee4cpanel package is executed.
#
# Copyright:    Copyright (C) 2012-2013
#               by Jordan Michaels (jordan@viviotech.net)
#
# License:      LGPL 3.0
#               http://www.opensource.org/licenses/lgpl-3.0.html
#
#               This program is distributed in the hope that it will be useful, 
#               but WITHOUT ANY WARRANTY; without even the implied warranty of 
#               MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
#               GNU General Public License for more details.
#
###############################################################################

version=1.0;
progname=$(basename $0);
basedir=$( cd "$( dirname "$0" )" && pwd );

# switch the subshell to the basedir so all relative dirs resolve
cd $basedir;

# ensure we're running as root
if [ ! $(id -u) = "0" ]; then
        echo "Error: This installation script needs to be run as root.";
        echo "Exiting...";
        exit;
fi

###############################################################################
# BEGIN FUNCTION LIST
###############################################################################

function show_welcome {
	echo "";
	echo "* [BEGIN] Lucee4cPanel Self-Extraction System";
	echo "";
}

function check_extract_dir {
	if [[ -d /opt/lucee4cpanel ]]; then
	while true; do
		echo "";
		echo "* Directory /opt/lucee4cpanel exists.";
		read -p "* Okay to overwrite? (y/n): " yn;
	        case $yn in
        	        [Yy]* ) break;;
	                [Nn]* ) echo "* ABORTED at user request. Exiting..."; exit 1;;
	                * ) echo "Answer must be 'y' or 'n'";;
	        esac
	done
	else
		mkdir -p /opt/lucee4cpanel
	fi
}

function extract_binary {
	echo -n "* Extracting to /opt/lucee4cpanel...";
	
	# automatically find the number of lines this script takes up...
	myLineNumber=`awk '/^__BINARY__/ { print NR + 1; exit 0; }' $0`;
	
	# pass the binary tar.gz data off to tar to be extracted
	tail -n +$myLineNumber $0 | tar -xz;
	
	#tell the user we're done
	echo "[COMPLETE]";
}

function verify_manifest {
	# use manifest to verify extracted directories
	mv /opt/lucee4cpanel/manifest.md5 /tmp/manifest.md5;
	
	echo -n "* Verifying file integrity...";
	md5sum --quiet --status -c /tmp/manifest.md5;
	local commandSuccessful=$?;
	
	# move the manifest back
	mv /tmp/manifest.md5 /opt/lucee4cpanel/manifest.md5;
	
        # 0 means command executed just fine
        if [ $commandSuccessful -eq 0 ]; then
                echo "[SUCCESS]";
        else
                echo "[FAIL]";
                echo "";
                echo "* [ERROR!] Manifest verification failed!";
                echo "* Please re-download this file and try again.";
		echo "";
		echo "* Run 'cd /opt; md5sum -c lucee4cpanel/manifest.md5' to see";
		echo "* test results for yourself.";
                echo "";
		exit 1;
        fi
}

function run_lucee4cpenel_tests {
	# run the lucee4cpanel install script in test mode to show the user
	# if any problems exist on their system.
	myTestCommand="/opt/lucee4cpanel/install_lucee4cpanel.sh -m test -p test123";
	# echo "* Running Command: ${myTestCommand}";
	echo "* Running Lucee4Cpanel Install Script in \"TEST\" mode: ";
	echo "";
	${myTestCommand};
}

###############################################################################
# END FUNCTION LIST
###############################################################################

show_welcome;
check_extract_dir;
extract_binary;
verify_manifest;
run_lucee4cpenel_tests;

# close the script if we get this far for some reason
echo "";
exit;
__BINARY__
