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
 # File Name   : bin/revokeCerts.sh
 #
 # Created     : 2017-03
 # Authors     : zorglub42 <contact(at)zorglub42.fr>
 #
 # Description :
 #      revoke and delete certificates for a node
 #--------------------------------------------------------
 # History     :
 # 1.0.0 - 2017-03-01 : Release of the file
##

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


cd `dirname $0`
. ./conf.sh


(
	[ "$1" == "" ] && usage
	[ ! -x ../data/$1 ] && echo "Configuration for node $1 does not exists.... exiting" && exit 2
	. ../data/$1

	
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
		./certbot-auto revoke $CERTBOT_OPTS --cert-path /etc/letsencrypt/live/$ROOT_DOMAIN/fullchain.pem  --agree-tos --email $LE_MAIL  -n   2>&1 |tee -a $$.log 
		./certbot-auto delete $CERTBOT_OPTS --cert-name $ROOT_DOMAIN  --agree-tos --email $LE_MAIL  -n   2>&1 |tee -a $$.log 
	else
		echo "Can't find any certificates for $1"  
		exit 1
	fi
	if [ ${PIPESTATUS[0]} -eq 0 ] ; then
		SUCCESS=1
	else
		
		echo "******************* SOMETHING GONE WRONG WITH LETSENCRYPT ************************"
		cat $$.log
		echo "******************* SOMETHING GONE WRONG WITH LETSENCRYPT ************************"
	fi
	rm $$.log


	cleanCerts $1 
	rm -rf /etc/letsencrypt/archive/$ROOT_DOMAIN
	rm -rf /etc/letsencrypt/live/$ROOT_DOMAIN
	rm -rf /etc/letsencrypt/renewal/$ROOT_DOMAIN.conf
		
	curl -i -s -X POST -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/virtualhost >/dev/null
	
) 2>&1|tee -a $OSA_LOG_DIR/OSA-Letsencrypt.log
exit ${PIPESTATUS[0]}
