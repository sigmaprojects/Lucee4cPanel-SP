#!/bin/bash
#
###############################################################################
#
# Purpose:      This script builds the self-extracting tar.gz file out of the
#               lucee4cpanel directory and extract.sh script.
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

version=0.1;
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

# set creation variables
myInstallerVersion="0.1.01"


###############################################################################
# BEGIN FUNCTION LIST
###############################################################################

function check_executing_dir {
	if [[ ! -d lucee4cpanel/ ]]; then
		echo "* [FATAL] Can't find lucee4cpanel/ directory!";
		echo "Exiting...";
		exit 1;
	fi
}

function check_existing_tgz {
	if [[ -f lucee4cpanel.tgz ]]; then
		echo -n "* Removing previous lucee4cpanel.tgz...";
		rm -rf lucee4cpanel.tgz;
		echo "[DONE]";
	fi
}

function create_manifest {
	echo -n "* Building new MD5 File Manifest...";
	# create the manifest
	find lucee4cpanel/ -type f -print0 | xargs -0 md5sum >> manifest.md5
	# move the manifest to the directory to be zipped up with the package
	mv manifest.md5 lucee4cpanel/
	echo "[DONE]";
}

function create_tgz {
	echo -n "* Creating new lucee4cpanel.tgz file...";
	tar -czf lucee4cpanel.tgz lucee4cpanel/
	echo "[DONE]";
}

function create_selfextractor {
	echo -n "* Building Self-Extractor...";
	cat extract.sh lucee4cpanel.tgz > lucee4cpanel-${myInstallerVersion}-installer.run
	chmod 744 lucee4cpanel-${myInstallerVersion}-installer.run
	echo "[DONE]";
}

function cleanup {
	echo -n "* Cleaning up...";
	rm -rf lucee4cpanel.tgz;
	rm -f lucee4cpanel/manifest.md5;
	echo "[DONE]";
}

###############################################################################
# END FUNCTION LIST
###############################################################################

check_executing_dir;
check_existing_tgz;
create_manifest;
create_tgz;
create_selfextractor;
cleanup;
