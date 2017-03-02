#!/bin/bash
##--------------------------------------------------------
 # Module Name : OSA-Letsencrypt
 # Version : 1.0.0
 #
 #
 # Copyright (c) 2017 Zorglub42
 # This software is distributed under the Apache 2 license
 # <http://www.apache.org/licenses/LICENSE-2.0.html>
 #
 #--------------------------------------------------------
 # File Name   : install.sh
 #
 # Created     : 2017-03
 # Authors     : zorglub42 <contact(at)zorglub42.fr>
 #
 # Description :
 #      OSA-Letsencrypt installer
 #--------------------------------------------------------
 # History     :
 # 1.0.0 - 2017-03-01 : Release of the file
##
######################################################################
# configureCron
######################################################################
# Contfigure cron jobs (logrotate)
######################################################################
function configureCron(){
	
	crontab -l | grep -v "$INSTALL_DIR/bin/cronRenew.sh"  > /tmp/$$.crontab
	echo "0 1 * * * $INSTALL_DIR/bin/cronRenew.sh" >>/tmp/$$.crontab

	crontab /tmp/$$.crontab

}
######################################################################
# changeProperty
######################################################################
# Change the value of a particular propertie in a properties file
#	$1: file
#	$2: property name
#   $3: property value
######################################################################
function changeProperty(){
	PROP=`echo $2| sed 's/\./\\\./g'`
	PROP_VALUE=`echo $3| sed 's/\./\\\./g'`
	
	egrep ".*$PROP.*=.*" $1 > /dev/null
	if [ $? -eq 0 ] ; then
		cat $1 | sed "s|^\(.*\)$PROP=.*|\1$PROP=$PROP_VALUE|g" > /tmp/$$.tmp
		:>$1
		cat /tmp/$$.tmp > $1
	fi
}

cd `dirname $0`
INSTALL_DIR=`pwd|sed 's/\/bin//'` 
[ ! -f /etc/ApplianceManager/Settings.ini.php ] && echo "It seems that there's not OSA here..... exiting....." && exit 1
OSA_INSTALL_DIR=`grep '"runtimeApplianceConfigScript"' /etc/ApplianceManager/Settings.ini.php |awk -F '"' '{print $4}'  | sed 's|/RunTimeAppliance/shell/doAppliance.sh||'`


[ ! -d $OSA_INSTALL_DIR -o ! -d $OSA_INSTALL_DIR/ApplianceManager.php -o ! -d $OSA_INSTALL_DIR/ApplianceManager.php/addons -o ! -d $OSA_INSTALL_DIR/RunTimeAppliance  ] && echo "OSA Not found at $OSA_INSTALL_DIR" && exit 1

configureCron
changeProperty $INSTALL_DIR/web/include/Settings.php OSALEInstallDir "'"$INSTALL_DIR"'"
[ -L $OSA_INSTALL_DIR/ApplianceManager.php/addons/letsencrypt ] && rm $OSA_INSTALL_DIR/ApplianceManager.php/addons/letsencrypt
ln -s $INSTALL_DIR/web $OSA_INSTALL_DIR/ApplianceManager.php/addons/letsencrypt
chmod 777 $INSTALL_DIR/data

cd $INSTALL_DIR/bin
curl -s  https://dl.eff.org/certbot-auto -o certbot-auto
chmod u+x certbot-auto
sudo -H ./certbot-auto -n --os-packages-only
sudo -H ./certbot-auto certificates

