#!/bin/bash

set -e # Abort script at first error

cwd=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
install_plugin='/usr/local/cpanel/scripts/install_plugin'
dst='/usr/local/cpanel/base/3rdparty/lucee_plugin'

if [ $EUID -ne 0 ]; then
	echo 'Script requires root privileges, run it as root or with sudo'
	exit 1
fi

if [ ! -f /usr/local/cpanel/version ]; then
	echo 'cPanel installation not found'
	exit 1
fi

if [ ! -x $install_plugin ]; then
	echo 'cPanel version 11.44 or later required'
	exit 1
fi

if [ -d $dst ]; then
	echo "Existing installation found, try running the uninstall script first"
	exit 1
fi

mkdir -v $dst
cp -v ${cwd}/index.live.php $dst

themes=('paper_lantern')

for theme in ${themes[@]}; do
	$install_plugin ${cwd}/plugins/${theme} --theme $theme
done

echo 'Installation finished without errors'
