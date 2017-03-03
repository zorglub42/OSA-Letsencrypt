#!/bin/bash

#Generating endpoints entry for HTTP Host
unset http_proxy

# Configuration section #############################################################################
OSA_LOG_DIR=/var/log/OSA
OSA_LOCAL_SERVER="http://127.0.0.1:81"
OSA_LOCAL_USER=""
OSA_LOCAL_PWD=""
# End of Configuration section #############################################################################


function usage(){
	echo $0 node-name
	exit 1
}


function cleanCerts(){
	curl -i -s -X DELETE -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/cert >/dev/null
	curl -i -s -X DELETE -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/privateKey >/dev/null
	curl -i -s -X DELETE -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/chain >/dev/null

	echo "Cleaning done"
}


(
	[ "$1" == "" ] && usage
	cd `dirname $0`
	[ ! -x ../data/$1 ] && echo "Configuration for node $1 does not exists.... exiting" && exit 2
	. ../data/$1
	. ./conf.sh

	
        #Raw domain list for validation
        DOMAINS=""
        for p in $LE_CERT_DOMAIN ; do
                if [ "$p" != "-d" ] ; then
                        DOMAINS="$DOMAINS $p"
                fi
        done
	ROOT_DOMAIN=`echo "$DOMAINS"|awk '{print $1}'`
	
	
	SUCCESS=0
	if [ -f /etc/letsencrypt/live/$ROOT_DOMAIN/fullchain.pem ] ; then
		./certbot-auto revoke $CERTBOT_OPTS --cert-path /etc/letsencrypt/live/$ROOT_DOMAIN/fullchain.pem  --agree-tos --email $LE_MAIL  -n &>$$.log 
	else
		echo "Can't find any certificates for $1"
		true
	fi
	if [ $? -eq 0 ] ; then
		SUCCESS=1
	else
		
		echo "******************* SOMETHING GONE WRONG WITH LETSENCRYPT ************************"
		cat $$.log
		echo "******************* SOMETHING GONE WRONG WITH LETSENCRYPT ************************"
	fi
	rm $$.log


	#if [ $SUCCESS -eq 1 ] ; then
		cleanCerts $1 
		rm -rf /etc/letsencrypt/archive/$ROOT_DOMAIN
		rm -rf /etc/letsencrypt/live/$ROOT_DOMAIN
		rm -rf /etc/letsencrypt/renewal/$ROOT_DOMAIN.conf
		
		curl -i -s -X POST -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/virtualhost >/dev/null
		exit 0
	#else
	#	exit 1
	#fi
	
)
