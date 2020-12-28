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
 # File Name   : bin/install.sh
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

[ ! -f /etc/ApplianceManager/Settings.ini.php ] && echo "It seems that there's not OSA here..... exiting....." && exit 1


cd `dirname $0`
INSTALL_DIR=`pwd|sed 's/\/bin//'` 
OSA_INSTALL_DIR=`grep '"runtimeApplianceConfigScript"' /etc/ApplianceManager/Settings.ini.php |awk -F '"' '{print $4}'  | sed 's|/RunTimeAppliance/shell/doAppliance.sh||'`
[ ! -d $OSA_INSTALL_DIR -o ! -d $OSA_INSTALL_DIR/ApplianceManager.php -o ! -d $OSA_INSTALL_DIR/ApplianceManager.php/addons -o ! -d $OSA_INSTALL_DIR/RunTimeAppliance  ] && echo "OSA Not found at $OSA_INSTALL_DIR" && exit 1

OSA_LOCAL_SERVER=`grep "APPLIANCE_LOCAL_SERVER=" $OSA_INSTALL_DIR/RunTimeAppliance/shell/doAppliance.sh|awk -F "=" '{print $2}'`
OSA_LOCAL_USER=`grep "APPLIANCE_LOCAL_USER=" $OSA_INSTALL_DIR/RunTimeAppliance/shell/doAppliance.sh|awk -F "=" '{print $2}'`
OSA_LOCAL_PWD=`grep "APPLIANCE_LOCAL_PWD=" $OSA_INSTALL_DIR/RunTimeAppliance/shell/doAppliance.sh|awk -F "=" '{print $2}'`
OSA_LOG_DIR=`grep "APPLIANCE_LOG_DIR=" $OSA_INSTALL_DIR/RunTimeAppliance/shell/doAppliance.sh|awk -F "=" '{print $2}'`

#Configure cron for renewal
configureCron

#Configure general settings
changeProperty $INSTALL_DIR/web/include/Settings.php OSALEInstallDir '"'$INSTALL_DIR'";'

#Configure connection settings to OSA
changeProperty $INSTALL_DIR/bin/conf.sh OSA_LOCAL_SERVER $OSA_LOCAL_SERVER
changeProperty $INSTALL_DIR/bin/conf.sh OSA_LOCAL_USER $OSA_LOCAL_USER
changeProperty $INSTALL_DIR/bin/conf.sh OSA_LOCAL_PWD $OSA_LOCAL_PWD
changeProperty $INSTALL_DIR/bin/conf.sh OSA_LOG_DIR $OSA_LOG_DIR


#Add sudo conf to allow apache to run addons scripts
cat >/etc/sudoers.d/OSA-Letsencrypt <<EOF
#OSA-Letsencrypt addon
Defaults:www-data    !requiretty
Cmnd_Alias      OSA_LE_GEN_CERTS_CMD=$INSTALL_DIR/bin/generateCerts.sh
Cmnd_Alias      OSA_LE_REVOKE_CERTS_CMD=$INSTALL_DIR/bin/revokeCerts.sh
User_Alias      OSA_LE_USERS=www-data  OSA_LE_USERS       ALL = NOPASSWD: OSA_LE_GEN_CERTS_CMD, OSA_LE_REVOKE_CERTS_CMD
#OSA-Letsencrypt addon
EOF



#Configure OSA to use ths addon
[ -L $OSA_INSTALL_DIR/ApplianceManager.php/addons/letsencrypt ] && rm $OSA_INSTALL_DIR/ApplianceManager.php/addons/letsencrypt
ln -s $INSTALL_DIR/web $OSA_INSTALL_DIR/ApplianceManager.php/addons/letsencrypt
chmod 777 $INSTALL_DIR/data

#Install certbot-auto and prepare it tu run
#cd $INSTALL_DIR/bin
#curl -s  https://dl.eff.org/certbot-auto -o certbot-auto
#chmod u+x certbot-auto
#sudo -H ./certbot-auto -n --os-packages-only
#sudo -H ./certbot-auto certificates
sudo -H certbot -n --os-packages-only
sudo -H certbot certificates


