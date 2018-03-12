#!/bin/bash
#
###############################################################################
#
# Purpose:      This script is meant to automate the installation of the Lucee
#               CFML processing engine on to cPanel-based Hosting Environments.
#
# Copyright:	Copyright (C) 2012-2013
#		by Jordan Michaels (jordan@viviotech.net)
#
# License:	LGPL 3.0
#		http://www.opensource.org/licenses/lgpl-3.0.html
#
#		This program is distributed in the hope that it will be useful, 
# 		but WITHOUT ANY WARRANTY; without even the implied warranty of 
#		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
#		GNU General Public License for more details.
#
# Usage:	Run "install_lucee4cpanel.sh --help" for complete usage info
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

# create the "usage" function to display to improper users
function print_usage {
cat << EOF

Usage: $0 OPTIONS

OPTIONS:
 -v --version		print installer script version
 -h --help		print this help message
 -d --debug		switch to turn debugging mode
 -m --mode		[install|test] (required) set the installation mode
 -p --tomcatpass	(required) set the tomcat admin password
    --tomcatuser	set the tomcat admin username (default: admin)
    --tomcatport	set the tomcat http port (default: 8888)
    --ajpport		set the tomcat ajp port (default: 8809)
    --shutdownport	set the tomcat shutdown port (default: 8805)
    --startatboot	BOOLEAN: set Lucee/Tomcat to start at system boot
			(default: true)
    --bittype		for 64-bit systems, set to "32" to install 32-bit
			JRE for Lucee/Tomcat to use.
Examples:

The most common usage would be just:

    # $0 -m install -p "my password"

If you just want to run the tests, you'll see need use the options:

    # $0 --mode test --tomcatpass "my password"

...the tests will run but this script will not perform the installation
funtions that it would in install mode.

Additional help can be found at: http://getlucee.org/

EOF
}

# commending these out for now as they are a real pain to code for. -JM
#
#    --systemuser        set the system user for tomcat to run under
#                        (default: lucee)
#    --installconn       BOOLEAN: Install Apache Connector, mod_proxy, for
#                        lucee (default: true)
#    --apachecontrol     set "apachectl" location (default:
#                        /usr/local/apache/bin/apachectl)
#    --apacheconfig      set the location of the apache config file
#                        (default: /etc/apache2/conf.d/lucee.conf)





function print_version {
cat << EOF

$progname v. $version
Copyright (C) 2012-2013 Jordan Michaels (jordan@viviotech.net)
Licensed under LGPL 3.0
http://www.opensource.org/licenses/lgpl-3.0.html

This is free software.  You may redistribute copies of it
under the terms of the GNU General Public License
<http://www.gnu.org/licenses/gpl.html>.  There is NO
WARRANTY, to the extent permitted by law.

EOF
}

SHORTOPTS="hvVdm:p:"
LONGOPTS="help,version,debug,mode:,tomcatpass:,tomcatuser:,tomcatport:,ajpport:,shutdownport:,systemuser:,startatboot:,installconn:,apachecontrol:,apacheconfig:,bittype:"

#if $(getopt -T >/dev/null 2>&1) ; [ $? = 4 ] ; then
	# Try to use new longopts
	OPTS=$(getopt -o $SHORTOPTS --long $LONGOPTS -n "$progname" -- "$@") 
#else # Old classic getopt. 
	# Special handling for --help and --version on old getopt. 
#	case $1 in --help) print_help ; exit 0 ;; esac 
#	case $1 in --version) print_version ; exit 0 ;; esac 
#	OPTS=$(getopt $SHORTOPTS "$@") 
#fi

if [ $? -ne 0 ]; then 
	echo "Type '$progname --help' for usage information" 1>&2 
	exit 1 
fi

eval set -- "$OPTS"

# declare initial variables (so we can check them later)
myMode=
myTomcatPass=
myInstallDir=/opt/lucee
myTomcatUser=admin
myTomcatPort=8888
myAJPPort=8809
myShutdownPort=8805
mySystemUser=lucee
myStartAtBoot=true
myInstallConn=false
myApacheControlLoc=/usr/local/apache/bin/apachectl
myApacheConfigLoc=/etc/apache2/conf.d/lucee.conf
# leave the bittype blank to allow the installer funtions to autodetect
myBitType=

while [ $# -gt 0 ]; do 
    case $1 in 
        -h|--help) 
            print_usage 
            exit 0 
            ;; 
        -v|-V|--version) 
            print_version 
            exit 0 
            ;;
	-d|--debug)
	    debug=true
	    shift
	    ;;
        -m|--mode) 
            myMode=$2
            shift 2
            ;; 
        -p|--tomcatpass)
            myTomcatPass=$2
            shift 2
            ;;
	--tomcatuser)
            myTomcatUser=$2
            shift 2
            ;;
	--tomcatport)
            myTomcatPort=$2
            shift 2
            ;;
	--ajpport)
	    myAJPPort=$2
            shift 2
            ;;
	--shutdownport)
	    myShutdownPort=$2
            shift 2
            ;;
	--systemuser)
	    # mySystemUser=$2
            shift 2
            ;;
	--startatboot)
	    if ${2:=true}; then
		myStartAtBoot=true;
	    else
		myStartAtBoot=false;
	    fi
            shift 2
            ;;
	--installconn)
            #if ${2:=true}; then
                # myInstallConn=true;
            #else
                myInstallConn=false;
            #fi
            shift 2
            ;;
	--apachecontrol)
	    #myApacheControlLoc=$2
            shift 2
            ;;
	--apacheconfig)
	    #myApacheConfigLoc=$2
            shift 2
            ;;
	--bittype)
	    myBitType=$2
            shift 2
            ;;
        --) 
            shift 
            break 
            ;; 
        *) 
            echo "Unknown error encounter when processing argument: $1" 1>&2 
            exit 1 
            ;; 
    esac 
done

if [ $debug ]; then
	# debugging turned on, echo our current variables
	echo "* [DEBUG] myMode=${myMode}";
        echo "* [DEBUG] myTomcatPass=${myTomcatPass}";
        echo "* [DEBUG] myInstallDir=${myInstallDir}";
        echo "* [DEBUG] myTomcatUser=${myTomcatUser}";
        echo "* [DEBUG] myTomcatPort=${myTomcatPort}";
        echo "* [DEBUG] myAJPPort=${myAJPPort}";
        echo "* [DEBUG] myShutdownPort=${myShutdownPort}";
        echo "* [DEBUG] mySystemUser=${mySystemUser}";
        echo "* [DEBUG] myStartAtBoot=${myStartAtBoot}";
        echo "* [DEBUG] myInstallConn=${myInstallConn}";
        echo "* [DEBUG] myApacheControlLoc=${myApacheControlLoc}";
        echo "* [DEBUG] myApacheConfigLoc=${myApacheConfigLoc}";
        echo "* [DEBUG] myBitType=${myBitType}";
fi

###############################################################################
# BEGIN FUNCTION LIST
###############################################################################

function print_welcome {
	echo "";
	echo "###############################################################";
	echo "#      Welcome to the Luceee4cPanel Installation Program       #";
	echo "###############################################################";
}

function test_input {
	echo "* Verifying command inputs...";
	# check for a valid install mode
	case $myMode in
		"install")
		if [ $debug ]; then
                	echo "* [DEBUG] install mode checks out.";
	        fi
		;;
		"test")
                if [ $debug ]; then
                        echo "* [DEBUG] test mode checks out.";
                fi
		;;
		*)
		echo "";
		echo "* [FATAL] missing or invalid install mode";
		echo "* Type '$progname --help' for usage information";
		echo "";
		exit 1;
		;;
	esac
	# check for a temcat password
        if [[ -z $myTomcatPass ]]; then
        	echo "";
                echo "* [FATAL] No Tomcat Password was provided!";
                echo "* Type '$progname --help' for usage information";
                echo "";
                exit 1;
        fi
        # check tomcat password length
        myTCPWLength=`echo "${#myTomcatPass}"`;
        if [ $debug ]; then
                echo "* [DEBUG] tomcat password length reported as: $myTCPWLength";
        fi
	if [[ $myTCPWLength -lt 6 ]]; then
		echo "";
                echo "* [FATAL] Lucee/Tomcat Password much be 6 characters or more!";
                echo "* Type '$progname --help' for usage information";
                echo "";
                exit 1;
	fi
	if [[ ! $myTomcatPass =~ ^[A-Za-z0-9_]*$ ]]; then
                echo "";
                echo "* [FATAL] Lucee/Tomcat Password may only contain letters,";
		echo "          numbers, and underscores.";
                echo "* Type '$progname --help' for usage information";
                echo "";
                exit 1;
	fi
	# check tomcat username
	if [[ ! $myTomcatUser =~ ^[A-Za-z][A-Za-z0-9]*$ ]]; then
                echo "";
                echo "* [FATAL] Tomcat username must begin with a letter and be alphanumeric.";
                echo "* Type '$progname --help' for usage information";
                echo "";
                exit 1;
	fi
	# check tomcat web port
        if [[ ! $myTomcatPort =~ ^[0-9]*$ ]]; then
                echo "";
                echo "* [FATAL] Tomcat web port must be numeric.";
                echo "* Type '$progname --help' for usage information";
                echo "";
                exit 1;
        fi
	# see if the port is in use
	myPortInUse=`netstat -lnp | grep -c ":${myTomcatPort} "`;
	if [ $debug ]; then
                echo "* [DEBUG] tomcat web port-in-use returned: ${myPortInUse}";
        fi
	if [[ $myPortInUse -gt 0  ]]; then
                echo "";
                echo "* [FATAL] Port Selection for Tomcat Web Port (${myTomcatPort}) is already in use!";
                echo "* Type '$progname --help' for usage information";
                echo "";
                exit 1;
        fi
        myPortInUse=`netstat -lnp | grep -c ":${myAJPPort} "`;
        if [ $debug ]; then
                echo "* [DEBUG] tomcat AJP port-in-use returned: ${myPortInUse}";
        fi
        if [[ $myPortInUse -gt 0  ]]; then
                echo "";
                echo "* [FATAL] Port Selection for Tomcat AJP Port (${myAJPPort}) is already in use!";
                echo "* Type '$progname --help' for usage information";
                echo "";
                exit 1;
        fi
        myPortInUse=`netstat -lnp | grep -c ":${myShutdownPort} "`;
        if [ $debug ]; then
                echo "* [DEBUG] tomcat shutdown port-in-use returned: ${myPortInUse}";
        fi
        if [[ $myPortInUse -gt 0  ]]; then
                echo "";
                echo "* [FATAL] Port Selection for Tomcat Shutdown Port (${myShutdownPort}) is already in use!";
                echo "* Type '$progname --help' for usage information";
                echo "";
                exit 1;
        fi
        # check system username
        if [[ ! $mySystemUser =~ ^[A-Za-z][A-Za-z0-9]*$ ]]; then
                echo "";
                echo "* [FATAL] System username must begin with a letter and be alphanumeric.";
                echo "* Type '$progname --help' for usage information";
                echo "";
                exit 1;
        fi
	# check the apache control location
	if [[ ! -f ${myApacheControlLoc} ]] || [[ ! -x ${myApacheControlLoc} ]]; then
                echo "";
                echo "* [FATAL] Apache Control Script doesn't exist or cannot be executed.";
		echo "* [FATAL] Checked Location: ${myApacheControlLoc}";
		echo "";
                echo "* Please check the location and make sure this user can execute it.";
                echo "";
                exit 1;
	fi
        # check the apache config file
        touch "${myApacheConfigLoc}";
        if [[ ! -f ${myApacheConfigLoc} ]] || [[ ! -w ${myApacheConfigLoc} ]]; then
                echo "";
                echo "* [FATAL] Apache config doesn't exist or cannot be written to.";
                echo "* [FATAL] Checked Location: ${myApacheConfigLoc}";
                echo "";
                echo "* Please check the location and make sure this user can execute it.";
                echo "";
                exit 1;
        fi
	
	echo "* Command input verification complete.";
}

function test_bittype {
	# see if the machine we're running on it 64-bit or 32-bit
	myBitResult=`uname -m`
	if [ $debug ]; then
		echo "* [DEBUG] uname reports value: $myBitResult";
	fi
	case $myBitResult in
		"x86_64")
		echo "* [TEST] Auto-detected 64-bit OS";
		;;
		*)
		echo "* [TEST] Auto-detected 32-bit OS";
		;;
	esac
}

function test_total_memory {
	# make sure the system has 512MB or more of total memory
	myTotalMemory=$(free|awk '/^Mem:/{print $2}');
	if [ $debug ]; then
                echo -n "* [DEBUG] myTotalMemory: "
                echo -n $((myTotalMemory/1024));
                echo " MB";
        fi
	if [[ ! $myTotalMemory -gt 524288 ]]; then
                echo "";
                echo "* [FATAL] At least 512MB of TOTAL Memory is required to run Lucee server in cPanel";
                echo -n "* [INFO] This server is reporting only "
                echo -n $((myTotalMemory/1024));
                echo " MB TOTAL Memory.";
                echo "";
		exit 1;
        else
                echo -n "* [TEST] "
                echo -n $((myTotalMemory/1024));
                echo " MB TOTAL Memory available (512 MB Required)";
        fi
}

function test_available_memory {
	# get the amount of currently available free memory
	myFreeMemory=$(free|awk '/^Mem:/{print $4}');
	local myBufferMemory=$(free|awk '/^Mem:/{print $6}');
	myFreeMemory=(${myFreeMemory}+${myBufferMemory});
	if [ $debug ]; then
                echo -n "* [DEBUG] myFreeMemory: "
		echo -n $((myFreeMemory/1024));
		echo " MB";
        fi
	if [[ ! $myFreeMemory -gt 262144 ]]; then
                echo "";
                echo "* [FATAL] The Tomcat server Lucee uses requires at least 256 MB of FREE Memory in order";
		echo "* to start. If you try to install now, Lucee's Tomcat instance will fail to start.";
		echo -n "* [INFO] This instance is reporting only "
		echo -n $((myFreeMemory/1024));
		echo " MB FREE Memory.";
		echo "* [INFO] Try rebooting before you install to free up memory or give your server more memory.";
                echo "";
		exit 1;
	else
                echo -n "* [TEST] "
                echo -n $((myFreeMemory/1024));
                echo " MB FREE Memory available (256 MB Required)";
	fi
}

function test_lucee_installer {
	# make sure the installer directory exists
	if [[ ! -d ./lucee-installer/ ]]; then
		echo "";
                echo "* [FATAL] ${PWD}/lucee-installer/ directory does not exist.";
                echo "";
                exit 1;
	else
		if [[ $myMode == "test" ]]; then
			echo "* [TEST] ${PWD}/lucee-installer/ exists as a directory";
		fi
		if [ $debug ]; then
			echo "* [DEBUG] ${PWD}/lucee-installer/ exists as a directory";
		fi
	fi
	
	# test the lucee installer file
	cd ./lucee-installer/
        myLuceeEXE=`ls lucee*.run`;
        cd ..
        myFullinstallerPath="${PWD}/lucee-installer/$myLuceeEXE";
	if [ $debug ]; then
                echo "* [DEBUG] myLuceeEXE: $myLuceeEXE";
                echo "* [DEBUG] myFullinstallerPath: $myFullinstallerPath";
        fi
        if [[ ! -x ${myFullinstallerPath} ]]; then
                echo "";
                echo "* [FATAL] Cannot execute Lucee Installer.";
                echo "* [FATAL] Path: $myFullinstallerPath";
                echo "";
                exit 1;
	else
                if [[ $myMode == "test" ]]; then
                        echo "* [TEST] ${myFullinstallerPath} exists and is executable";
                fi
                if [ $debug ]; then
                        echo "* [DEBUG] ${myFullinstallerPath} exists and is executable";
                fi
        fi
}

function run_lucee_installer {
	echo "* Installing Lucee Server (this can take some time)...";
	
	test_lucee_installer;
	
	# build installer command
	myInstallCommand="$myFullinstallerPath --mode unattended ";
	#myInstallCommand+="--tomcatpass '";
	#myInstallCommand+="${myTomcatPass}' ";
	myInstallCommand+="--installdir ${myInstallDir} ";
	#myInstallCommand+="--tomcatuser $myTomcatUser ";
	myInstallCommand+="--tomcatport $myTomcatPort ";
	myInstallCommand+="--tomcatajpport $myAJPPort ";
	myInstallCommand+="--tomcatshutdownport $myShutdownPort ";
	myInstallCommand+="--systemuser $mySystemUser ";
	myInstallCommand+="--startatboot $myStartAtBoot ";
	myInstallCommand+="--installconn $myInstallConn ";
    # added required `luceepass` argument
    myInstallCommand+="--luceepass '";
    myInstallCommand+="${myTomcatPass}' ";

        if [ $debug ]; then
                echo "* [DEBUG] myInstallCommand: $myInstallCommand ";
        fi

	if [[ $myMode == "test" ]]; then
		echo "* [TEST] Install Command: $myInstallCommand ";
	else
		eval $myInstallCommand;
	fi

	echo "* Lucee Server installation complete.";
}

function test_cpanel_plugin {
	# tests to help verify the integrity of the cPanel Lucee Plugin

	# test files existance	
	mycPanelPluginFile="${basedir}/cpanel/plugins/lucee_plugin.cpanelplugin";
	if [[ ! -f $mycPanelPluginFile ]]; then
		echo "";
		echo "* [FATAL] $mycPanelPluginFile does not exist and cannot be installed.";
		echo "* Please re-extract the installer and try again.";
		echo "";
		exit 1;
	else
		if [[ $myMode == "test" ]]; then
			echo "* [TEST] $mycPanelPluginFile exists as a file. ";
		fi
	fi
	
	mycPanelPluginIndex="${basedir}/cpanel/plugins/lucee_plugin/index.php";
        if [[ ! -f $mycPanelPluginIndex ]]; then
                echo "";
                echo "* [FATAL] $mycPanelPluginIndex does not exist.";
                echo "* Please re-extract the installer and try again.";
                echo "";
                exit 1;
        else
                if [[ $myMode == "test" ]]; then
                        echo "* [TEST] $mycPanelPluginIndex exists as a file. ";
                fi
        fi
	
	# test for needed executables
	mycPanelPluginRegister="/usr/local/cpanel/bin/register_cpanelplugin";
	if [[ ! -f $mycPanelPluginRegister ]] || [[ ! -x $mycPanelPluginRegister ]]; then
                if [ $debug ]; then
                        if [[ ! -f $mycPanelPluginRegister ]]; then
                                echo "* [DEBUG] $mycPanelPluginRegister is failing the file check";
                        fi
                        if [[ ! -x $mycPanelPluginRegister ]]; then
                                echo "* [DEBUG] $mycPanelPluginRegister is failing the executable check";
                        fi
                fi
                echo "";
                echo "* [FATAL] $mycPanelPluginRegister does not exist or is not executable.";
                echo "";
                exit 1;
        else
                if [[ $myMode == "test" ]]; then
                        echo "* [TEST] $mycPanelPluginRegister exists and is executable. ";
                fi
        fi

	# test plugin front-end directory
	mycPanelPluginFEDirectory="/usr/local/cpanel/base/frontend/default/";
        if [[ ! -d $mycPanelPluginFEDirectory ]] || [[ ! -w $mycPanelPluginFEDirectory ]]; then
                if [ $debug ]; then
                        if [[ ! -d $mycPanelPluginFEDirectory ]]; then
                                echo "* [DEBUG] $mycPanelPluginFEDirectory is failing the directory check";
                        fi
                        if [[ ! -w $mycPanelPluginFEDirectory ]]; then
                                echo "* [DEBUG] $mycPanelPluginFEDirectory is failing the writable check";
                        fi
                fi
                echo "";
                echo "* [FATAL] $mycPanelPluginFEDirectory does not exist or is not writable.";
                echo "";
                exit 1;
        else
                if [[ $myMode == "test" ]]; then
                        echo "* [TEST] $mycPanelPluginFEDirectory exists and is writable. ";
                fi
        fi
	
	# test cPanel Plugin storage Directory
	mycPanelPluginStorage="/usr/local/cpanel/bin/";
        if [[ ! -d $mycPanelPluginStorage ]] || [[ ! -w $mycPanelPluginStorage ]]; then
                if [ $debug ]; then
                        if [[ ! -d $mycPanelPluginStorage ]]; then
                                echo "* [DEBUG] $mycPanelPluginStorage is failing the directory check";
                        fi
                        if [[ ! -w $mycPanelPluginStorage ]]; then
                                echo "* [DEBUG] $mycPanelPluginStorage is failing the writable check";
                        fi
                fi
                echo "";
                echo "* [FATAL] $mycPanelPluginStorage does not exist or is not writable.";
                echo "";
                exit 1;
        else
                if [[ $myMode == "test" ]]; then
                        echo "* [TEST] $mycPanelPluginStorage exists and is writable. ";
                fi
        fi

}

function install_cpanel_plugin {
	# this function installs the Lucee cPanel plugin which adds an icon
	# to each cPanel interface which takes a user right to their Lucee
	# Web Administrator URL
	
	test_cpanel_plugin;
	
	# install the front-end to the default theme
	echo -n "* Installing cPanel lucee_plugin front-end...";
	cp -rf ${basedir}/cpanel/plugins/lucee_plugin/ $mycPanelPluginFEDirectory > /dev/null
	local commandSuccessful=$?;
	
	if [ $debug ]; then 
		echo "* [DEBUG] Command: 'cp -rf ${basedir}/cpanel/plugins/lucee_plugin/ $mycPanelPluginFEDirectory > /dev/null'";
		echo "* [DEBUG] Exit Code: ${commandSuccessful}";
	fi
	
	# 0 means command executed just fine
	if [ $commandSuccessful -eq 0 ]; then
		echo "[SUCCESS]";
	else
		echo "[FAIL]";
		echo "";
		echo "* [FATAL] Failed to install cPanel front-end to ${mycPanelPluginFEDirectory}";
		echo "* Script exit code: ${commandSuccessful}";
		echo "";
		exit 1;
	fi
	
	# copy Lucee plugin to cPanel Plugin Storage
	echo -n "* Copying Plugin to cPanel Storage Directory...";
	cp $mycPanelPluginFile $mycPanelPluginStorage > /dev/null;
	local commandSuccessful=$?;

        if [ $debug ]; then
                echo "* [DEBUG] Command: 'cp $mycPanelPluginFile $mycPanelPluginStorage > /dev/null'";
                echo "* [DEBUG] Exit Code: ${commandSuccessful}";
        fi

        # 0 means command executed just fine
        if [ $commandSuccessful -eq 0 ]; then
                echo "[SUCCESS]";
        else
                echo "[FAIL]";
                echo "";
                echo "* [FATAL] Failed to copy to plugin storage directory ${mycPanelPluginStorage}";
                echo "* Script exit code: ${commandSuccessful}";
                echo "";
                exit 1;
        fi

	# install the cPanel plugin for lucee
	echo -n "* Installing cPanel plugin module...";
	$mycPanelPluginRegister $mycPanelPluginFile > /dev/null
	local commandSuccessful=$?;

        if [ $debug ]; then
                echo "* [DEBUG] Command: '$mycPanelPluginRegister $mycPanelPluginFile > /dev/null'";
                echo "* [DEBUG] Exit Code: ${commandSuccessful}";
        fi
	
	# 0 means command executed just fine
        if [ $commandSuccessful -eq 0 ]; then
                echo "[SUCCESS]";
        else
                echo "[FAIL]";
                echo "";
                echo "* [FATAL] Failed to install cPanel plugin.";
                echo "* Command exit code: ${commandSuccessful}";
                echo "";
                exit 1;
        fi

	# rebuilding cpanel sprites so that the Lucee icon shows up as intended
        echo -n "* Rebuilding cPanel Sprites to Install Lucee Icon...";
        /usr/local/cpanel/bin/rebuild_sprites > /dev/null
        local commandSuccessful=$?;

        if [ $debug ]; then
                echo "* [DEBUG] Command: '/usr/local/cpanel/bin/rebuild_sprites > /dev/null'";
                echo "* [DEBUG] Exit Code: ${commandSuccessful}";
        fi

        # 0 means command executed just fine
        if [ $commandSuccessful -eq 0 ]; then
                echo "[SUCCESS]";
        else
                echo "[FAIL]";
                echo "";
                echo "* [FATAL] Failed to run cPanel sprite rebuild command.";
                echo "* Command exit code: ${commandSuccessful}";
                echo "";
                exit 1;
        fi
}

function test_apache_config {
        # test Apache config storage Directory
        myApacheConfigStorage="/usr/local/apache/conf/userdata/";
        if [[ ! -d $myApacheConfigStorage ]] || [[ ! -w $myApacheConfigStorage ]]; then
                if [ $debug ]; then
                        if [[ ! -d $myApacheConfigStorage ]]; then
                                echo "* [DEBUG] $myApacheConfigStorage is failing the directory check";
                        fi
                        if [[ ! -w $mycPanelPluginStorage ]]; then
                                echo "* [DEBUG] $myApacheConfigStorage is failing the writable check";
                        fi
                fi
		# if the directory check is failing, maybe the dir just doesn't exist? Attempt to create
		echo "* [ERROR] $myApacheConfigStorage does not exist or is not writable.";
		echo -n "* Attempting to create $myApacheConfigStorage...";
		mkdir -p /usr/local/apache/conf/userdata/;
		local commandSuccessful=$?;

	        if [ $debug ]; then
	                echo "* [DEBUG] Command: 'mkdir -p /usr/local/apache/conf/userdata/'";
	                echo "* [DEBUG] Exit Code: ${commandSuccessful}";
	        fi

	        # 0 means command executed just fine
	        if [ $commandSuccessful -eq 0 ]; then
	                echo "[SUCCESS]";
	        else
	                echo "[FAIL]";
	                echo "";
	                echo "* [FATAL] $myApacheConfigStorage does not exist or is not writable.";
	                echo "* [FATAL] Attempting to create the directory automatically also failed.";
			echo "";
			echo "* Please create this directory and ensure that it's writable.";
	                echo "";
	                exit 1;
	        fi
        else
                if [[ $myMode == "test" ]]; then
                        echo "* [TEST] $myApacheConfigStorage exists and is writable. ";
                fi
        fi
}

function install_apache_config {
	test_apache_config;
	
	myApacheConfigFile="${basedir}/apache/lucee.conf";
	# copy apache config file to cPanel location
	echo -n "* Installing New Apache Config File for Lucee Server...";
	cp $myApacheConfigFile /etc/apache2/conf.d/ > /dev/null;
        local commandSuccessful=$?;

        if [ $debug ]; then
                echo "* [DEBUG] Command: 'cp $myApacheConfigFile /etc/apache2/conf.d/ > /dev/null'";
                echo "* [DEBUG] Exit Code: ${commandSuccessful}";
        fi

        # 0 means command executed just fine
        if [ $commandSuccessful -eq 0 ]; then
                echo "[SUCCESS]";
        else
                echo "[FAIL]";
                echo "";
                echo "* [FATAL] Failed to install apache config file to /etc/apache2/conf.d/";
                echo "* Script exit code: ${commandSuccessful}";
                echo "";
                exit 1;
        fi

	# use cpanel built-in "ensure" process
	echo -n "* Verifying new Lucee Apache Config...";
	/scripts/ensure_vhost_includes --all-users;
	local commandSuccessful=$?;

        if [ $debug ]; then
                echo "* [DEBUG] Command: '/scripts/ensure_vhost_includes --all-users'";
                echo "* [DEBUG] Exit Code: ${commandSuccessful}";
        fi

        # 0 means command executed just fine
        if [ $commandSuccessful -eq 0 ]; then
                echo "[SUCCESS]";
        else
                echo "[FAIL]";
                echo "";
                echo "* [FATAL] Command Failed: /scripts/ensure_vhost_includes --all-users";
                echo "* Script exit code: ${commandSuccessful}";
                echo "";
                exit 1;
        fi
}

function install_lucee_security {
	# this function applys default security settings to the Lucee Server Administrator
	# <security access_read="protected" access_write="protected" cache="yes" cfx_setting="none" cfx_usage="none" custom_tag="yes" datasource="yes" debugging="yes" direct_java_access="yes" file="local" gateway="yes" mail="yes" mapping="none" orm="yes" remote="none" scheduled_task="yes" search="yes" setting="yes" tag_execute="none" tag_import="none" tag_object="yes" tag_registry="none"/>
	
	# add the security line to the newly installed Lucee
        echo -n "* Creating Default Lucee Security Settings...";
        cmd="sed -i '/<\/lucee-configuration>/i \<security access_read=\"protected\" access_write=\"protected\" cache=\"yes\" cfx_setting=\"none\" cfx_usage=\"none\" custom_tag=\"yes\" datasource=\"yes\" debugging=\"yes\" direct_java_access=\"yes\" file=\"local\" gateway=\"yes\" mail=\"yes\" mapping=\"none\" orm=\"yes\" remote=\"yes\" scheduled_task=\"yes\" search=\"yes\" setting=\"yes\" tag_execute=\"none\" tag_import=\"none\" tag_object=\"yes\" tag_registry=\"none\"\/>' /opt/lucee/tomcat/lucee-server/context/lucee-server.xml";
        eval $cmd;
        local commandSuccessful=$?;

        if [ $debug ]; then
                echo "* [DEBUG] Command: '$cmd'";
                echo "* [DEBUG] Exit Code: ${commandSuccessful}";
        fi

        # 0 means command executed just fine
        if [ $commandSuccessful -eq 0 ]; then
                echo "[SUCCESS]";
        else
                echo "[FAIL]";
                echo "";
                echo "* [FATAL] Command Failed: $cmd";
                echo "* Script exit code: ${commandSuccessful}";
                echo "";
                exit 1;
        fi
}

function install_tomcat_api {
	# this function installs a user account specifically to be used
	# by the postkillacct hook to remove tomcat hosts when they've been
	# removed form the server

	# start by creating a random username and password
	myAPIUN=`< /dev/urandom tr -dc A-Za-z0-9_ | head -c64`;
	myAPIPW=`< /dev/urandom tr -dc A-Za-z0-9_ | head -c64`;
	
	# add the username and password to the tomcat-users.xml file
	echo -n "* Creating Tomcat API User Account...";
	cmd="sed -i '/<\/tomcat-users>/i \<user username=\"${myAPIUN}\" password=\"${myAPIPW}\" roles=\"admin-gui,admin-script\" \/>' /opt/lucee/tomcat/conf/tomcat-users.xml";
	eval $cmd;
        local commandSuccessful=$?;

        if [ $debug ]; then
                echo "* [DEBUG] Command: '$cmd'";
                echo "* [DEBUG] Exit Code: ${commandSuccessful}";
        fi

        # 0 means command executed just fine
        if [ $commandSuccessful -eq 0 ]; then
                echo "[SUCCESS]";
        else
                echo "[FAIL]";
                echo "";
                echo "* [FATAL] Command Failed: $cmd";
                echo "* Script exit code: ${commandSuccessful}";
                echo "";
                exit 1;
        fi
	
	# add the username and password to the postkillacct hook
	# which should be installed after this point
	echo -n "* Adding Tomcat API User Account to PREKILLACCT hook...";
	cmd="sed -i -e 's/tomcat_api_user/${myAPIUN}/g' ./hooks/prekillacct_lucee";
	eval $cmd;
	local commandSuccessful=$?;

        if [ $debug ]; then
                echo "* [DEBUG] Command: '$cmd'";
                echo "* [DEBUG] Exit Code: ${commandSuccessful}";
        fi

        # 0 means command executed just fine
        if [ $commandSuccessful -eq 0 ]; then
                echo "[SUCCESS]";
        else
                echo "[FAIL]";
                echo "";
                echo "* [FATAL] Command Failed: $cmd";
                echo "* Script exit code: ${commandSuccessful}";
                echo "";
                exit 1;
        fi
	
	echo -n "* Adding Tomcat API Password to PREKILLACCT hook...";
	cmd="sed -i -e 's/tomcat_api_pass/${myAPIPW}/g' ./hooks/prekillacct_lucee";
	eval $cmd;
	local commandSuccessful=$?;

        if [ $debug ]; then
                echo "* [DEBUG] Command: '$cmd'";
                echo "* [DEBUG] Exit Code: ${commandSuccessful}";
        fi

        # 0 means command executed just fine
        if [ $commandSuccessful -eq 0 ]; then
                echo "[SUCCESS]";
        else
                echo "[FAIL]";
                echo "";
                echo "* [FATAL] Command Failed: $cmd";
                echo "* Script exit code: ${commandSuccessful}";
                echo "";
                exit 1;
        fi
}

function restart_lucee {
	# restart Tomcat
	echo -n "* Restarting Lucee/Tomcat so changes take effect...";
	cmd="/opt/lucee/lucee_ctl restart";
	eval $cmd;
        local commandSuccessful=$?;

        if [ $debug ]; then
                echo "* [DEBUG] Command: '$cmd'";
                echo "* [DEBUG] Exit Code: ${commandSuccessful}";
        fi

        # 0 means command executed just fine
        if [ $commandSuccessful -eq 0 ]; then
                echo "[SUCCESS]";
        else
                echo "[FAIL]";
                echo "";
                echo "* [FATAL] Command Failed: $cmd";
                echo "* Script exit code: ${commandSuccessful}";
                echo "";
                exit 1;
        fi
}

function test_lucee_hooks {
        # test Apache config storage Directory
        mycPanelScriptDir="/scripts/";
        if [[ ! -d $mycPanelScriptDir ]] || [[ ! -w $mycPanelScriptDir ]]; then
                if [ $debug ]; then
                        if [[ ! -d $mycPanelScriptDir ]]; then
                                echo "* [DEBUG] $mycPanelScriptDir is failing the directory check";
                        fi
                        if [[ ! -w $mycPanelScriptDir ]]; then
                                echo "* [DEBUG] $mycPanelScriptDir is failing the writable check";
                        fi
                fi

		echo "";
                echo "* [FATAL] $mycPanelScriptDir does not exist or is not writable.";
                echo "";
                exit 1;

        else
                if [[ $myMode == "test" ]]; then
                        echo "* [TEST] $myApacheConfigStorage exists and is writable. ";
                fi
        fi
	
	# see if the scripts exist yet
	mycPanelScript="/scripts/prekillacct";
	if [[ ! -f $mycPanelScript ]] || [[ ! -w $mycPanelScript ]]; then
		if [ $debug ]; then
                        if [[ ! -f $mycPanelScript ]]; then
                                echo "* [DEBUG] $mycPanelScript is failing the file check";
                        fi
                        if [[ ! -w $mycPanelScript ]]; then
                                echo "* [DEBUG] $mycPanelScript is failing the writable check";
                        fi
                fi
                # if the file check is failing, maybe the file just doesn't exist? Attempt to create
                echo "* [ERROR] $mycPanelScript does not exist or is not writable.";
                echo -n "* Attempting to create $mycPanelScript ...";
		echo "#!/usr/bin/perl" >> $mycPanelScript;
		chmod +x $mycPanelScript;
                local commandSuccessful=$?;

                if [ $debug ]; then
                        echo "* [DEBUG] Command: 'echo \"#!/usr/bin/perl\" >> $mycPanelScript;'";
                        echo "* [DEBUG] Exit Code: $commandSuccessful ";
                fi

                # 0 means command executed just fine
                if [ $commandSuccessful -eq 0 ]; then
                        echo "[SUCCESS]";
                else
                        echo "[FAIL]";
                        echo "";
                        echo "* [FATAL] $mycPanelScript does not exist or is not writable.";
                        echo "* [FATAL] Attempting to create the file automatically also failed.";
                        echo "";
                        echo "* Please ensure this file exists and is writable.";
                        echo "";
                        exit 1;
                fi
	fi
	
	mycPanelScript="/scripts/postkillacct";
        if [[ ! -f $mycPanelScript ]] || [[ ! -w $mycPanelScript ]]; then
                if [ $debug ]; then
                        if [[ ! -f $mycPanelScript ]]; then
                                echo "* [DEBUG] $mycPanelScript is failing the file check";
                        fi
                        if [[ ! -w $mycPanelScript ]]; then
                                echo "* [DEBUG] $mycPanelScript is failing the writable check";
                        fi
                fi
                # if the file check is failing, maybe the file just doesn't exist? Attempt to create
                echo "* [ERROR] $mycPanelScript does not exist or is not writable.";
                echo -n "* Attempting to create $mycPanelScript ...";
                echo "#!/usr/bin/perl" >> $mycPanelScript;
                chmod +x $mycPanelScript;
                local commandSuccessful=$?;

                if [ $debug ]; then
                        echo "* [DEBUG] Command: 'echo \"#!/usr/bin/perl\" >> $mycPanelScript;'";
                        echo "* [DEBUG] Exit Code: $commandSuccessful ";
                fi

                # 0 means command executed just fine
                if [ $commandSuccessful -eq 0 ]; then
                        echo "[SUCCESS]";
                else
                        echo "[FAIL]";
                        echo "";
                        echo "* [FATAL] $mycPanelScript does not exist or is not writable.";
                        echo "* [FATAL] Attempting to create the file automatically also failed.";
                        echo "";
                        echo "* Please ensure this file exists and is writable.";
                        echo "";
                        exit 1;
                fi
        fi

	mycPanelScript="/scripts/postwwwacct";
	if [[ ! -f $mycPanelScript ]] || [[ ! -w $mycPanelScript ]]; then
                if [ $debug ]; then
                        if [[ ! -f $mycPanelScript ]]; then
                                echo "* [DEBUG] $mycPanelScript is failing the file check";
                        fi
                        if [[ ! -w $mycPanelScript ]]; then
                                echo "* [DEBUG] $mycPanelScript is failing the writable check";
                        fi
                fi
                # if the file check is failing, maybe the file just doesn't exist? Attempt to create
                echo "* [ERROR] $mycPanelScript does not exist or is not writable.";
                echo -n "* Attempting to create $mycPanelScript ...";
		echo "#!/usr/bin/perl" >> $mycPanelScript;
		chmod +x $mycPanelScript;
                local commandSuccessful=$?;

                if [ $debug ]; then
			echo "* [DEBUG] Command: 'echo \"#!/usr/bin/perl\" >> $mycPanelScript;'";
                        echo "* [DEBUG] Exit Code: $commandSuccessful ";
                fi

                # 0 means command executed just fine
                if [ $commandSuccessful -eq 0 ]; then
                        echo "[SUCCESS]";
                else
                        echo "[FAIL]";
                        echo "";
                        echo "* [FATAL] $mycPanelScript does not exist or is not writable.";
                        echo "* [FATAL] Attempting to create the file automatically also failed.";
                        echo "";
                        echo "* Please ensure this file exists and is writable.";
                        echo "";
                        exit 1;
                fi
        fi
}

function install_lucee_hooks {
	# this function adds the lucee hooks to cPanel/WHM

	test_lucee_hooks;
	
	# tests complete, now perform actual work
	echo -n "* Installing Lucee POSTWWWACCT Hook...";
	# set the file name that we're going to add the include to.
	myHookFile="/scripts/postwwwacct";
	# copy our include into the hookfile
	echo "# @BEGINLUCEE" >> $myHookFile;
	cat ${basedir}/hooks/postwwwacct_lucee >> $myHookFile;
	echo "# @ENDLUCEE" >> $myHookFile;
        local commandSuccessful=$?; # this only checks last echo command, but has same effect

        if [ $debug ]; then
                echo "";
                echo "* [DEBUG] Command: 'echo \"# @ENDLUCEE\" >> $myHookFile'";
                echo "* [DEBUG] Exit Code: ${commandSuccessful}";
        fi

        # 0 means command executed just fine
        if [ $commandSuccessful -eq 0 ]; then
                echo "[SUCCESS]";
        else
                echo "[FAIL]";
                echo "";
                echo "* [FATAL] Command Failed: echo \"# @ENDLUCEE\" >> $myHookFile";
                echo "* Script exit code: $commandSuccessful";
                echo "";
                exit 1;
        fi

	# BEGIN INSTALLING PREKILLACCT #

	echo -n "* Installing Lucee PREKILLACCT Hook...";
        # set the file name that we're going to add the include to.
        myHookFile="/scripts/prekillacct";
        # copy our include into the hookfile
        echo "# @BEGINLUCEE" >> $myHookFile;
	cat ${basedir}/hooks/prekillacct_lucee >> $myHookFile;
        echo "# @ENDLUCEE" >> $myHookFile;
        local commandSuccessful=$?; # this only checks last echo command, but has same effect

        if [ $debug ]; then
                echo "";
                echo "* [DEBUG] Command: 'echo \"# @ENDLUCEE\" >> $myHookFile'";
                echo "* [DEBUG] Exit Code: ${commandSuccessful}";
        fi

        # 0 means command executed just fine
        if [ $commandSuccessful -eq 0 ]; then
                echo "[SUCCESS]";
        else
                echo "[FAIL]";
                echo "";
                echo "* [FATAL] Command Failed: echo \"# @ENDLUCEE\" >> $myHookFile";
                echo "* Script exit code: $commandSuccessful";
                echo "";
                exit 1;
        fi
	
        # BEGIN INSTALLING POSTKILLACCT #

        echo -n "* Installing Lucee POSTKILLACCT Hook...";
        # set the file name that we're going to add the include to.
        myHookFile="/scripts/postkillacct";
        # copy our include into the hookfile
        echo "# @BEGINLUCEE" >> $myHookFile;
        cat ${basedir}/hooks/postkillacct_lucee >> $myHookFile;
        echo "# @ENDLUCEE" >> $myHookFile;
        local commandSuccessful=$?; # this only checks last echo command, but has same effect

        if [ $debug ]; then
                echo "";
                echo "* [DEBUG] Command: 'echo \"# @ENDLUCEE\" >> $myHookFile'";
                echo "* [DEBUG] Exit Code: ${commandSuccessful}";
        fi

        # 0 means command executed just fine
        if [ $commandSuccessful -eq 0 ]; then
                echo "[SUCCESS]";
        else
                echo "[FAIL]";
                echo "";
                echo "* [FATAL] Command Failed: echo \"# @ENDLUCEE\" >> $myHookFile";
                echo "* Script exit code: $commandSuccessful";
                echo "";
                exit 1;
        fi
}


function print_install_finish {
        echo "";
        echo "###############################################################";
        echo "#             Lucee4cPanel Installation Complete              #";
        echo "###############################################################";
	echo "";
	echo "* To remove Lucee4cPanel, run the following script:";
	echo "* ${basedir}/remove_lucee4cpenal.sh";
	echo "";
	echo "* To access your Lucee Server Administrator, go to:";
	echo "* http://[servername]:8888/index.cfm";
	echo "";
	echo "* Lucee4cPanel Documentation can be found here:";
	echo "* https://github.com/getlucee/lucee/wiki/Lucee4cPanel";
	echo "";
	echo "";

}

function print_test_finish {
        echo "";
        echo "##  Lucee4cPanel Testing  Complete  ##";
        echo "* If you make it this far without fatal errors, you should be";
        echo "* able to install without problems.";
        echo "";
        while true; do
        	read -p "Did you want to install now? [y/n] " yn
	        case $yn in
	                [Yy]* ) start_install_mode; break;;
	                [Nn]* ) print_install_howto; exit;;
			* ) echo "Please answer yes or no.";;
	        esac
	done
}
        
function print_install_howto {
	echo "";
	echo "* [INFO] To perform a full install, run the following commands:";
	echo "";
	echo "# cd /opt/lucee4cpanel/"
	echo "# ./install_lucee4cpanel.sh -m install -p \"[my password]\"";
	echo "";
	echo "* [INFO] To see a full list of install options, run:";
	echo "";
	echo "# cd /opt/lucee4cpanel/";
	echo "# ./install_lucee4cpanel.sh --help";
	echo "";
	echo "* Enjoy Lucee4Cpanel!";
	echo "";
}

function start_install_mode {
        # prompt for Lucee/Tomcat Password
        while true; do
                read -s -p "Enter desired Tomcat/Lucee Password (6+ characters): " myPassword1;
                echo "";
                local myTCPWLength=`echo "${#myPassword1}"`;
                if [[ ! $myTCPWLength -ge 6 ]] || [[ ! $myPassword1 =~ ^[A-Za-z0-9_]*$ ]]; then
                        echo "Incompatible Password. Please try again.";
                        echo " - Passwords must be 6+ characters.";
                        echo " - Passwords may only contain letters, numbers, and underscores.";
                else
                        read -s -p "Please enter the password once more: " myPassword2;
                        echo "";
                        if [ $myPassword1 = $myPassword2 ]; then
                                cd /opt/lucee4cpanel/;
                                ./install_lucee4cpanel.sh -m install -p "${myPassword1}";
                                exit 0;
                        else
                                echo "Passwords do not match. Please try again.";
                        fi
                fi
        done
}

###############################################################################
# END FUNCTION LIST
###############################################################################

# start by verifying input
test_input;

# functions will depend on the mode
case $myMode in
	"install")
	# run install mode functions
	print_welcome;
	print_version;
	run_lucee_installer;
	install_cpanel_plugin;
	install_apache_config;
	install_lucee_security;
	install_tomcat_api;
	restart_lucee;
	install_lucee_hooks
	print_install_finish;
	;;
	"test")
	# run test mode functions
	test_bittype;
	test_total_memory;
	test_available_memory;
	test_lucee_installer;
	test_cpanel_plugin;
	test_apache_config;
	test_lucee_hooks;
	print_test_finish;
	;;
esac
