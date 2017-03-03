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
 # File Name   : bin/generateCerts.sh
 #
 # Created     : 2017-03
 # Authors     : zorglub42 <contact(at)zorglub42.fr>
 #
 # Description :
 #      generate and renew certificates for a node
 #--------------------------------------------------------
 # History     :
 # 1.0.0 - 2017-03-01 : Release of the file
##
function usage(){
	echo $0 node-name
	exit 1
}


function uploadCerts(){
	curl -i -s -X POST -k   --form "files[]=@/etc/letsencrypt/live/$2/cert.pem" --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/cert >/dev/null
	curl -i -s -X POST -k   --form "files[]=@/etc/letsencrypt/live/$2/privkey.pem" --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/privateKey >/dev/null
	curl -i -s -X POST -k   --form "files[]=@/etc/letsencrypt/live/$2/chain.pem" --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/chain >/dev/null

	echo "Upload done"
}

function enableDisableNode(){
	curl  -i -X POST -s -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"   -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'Accept: application/json, text/javascript, */*; q=0.01'  "$OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/status" --data "published=$2&reload=no" >/tmp/$$.txt
	if [ $? -eq 0 ] ; then
		echo "Node $1 successfully paused/restarted ($2) ";
	else
		echo "Failed to pause/start node $1 ($2)";
		cat /tmp/$$.txt
	fi
	rm /tmp/$$.txt
}


function getConflictingNodes(){
	
	[ -f listening-ok ] && rm listening-ok
 	curl -s -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  "$OSA_LOCAL_SERVER/ApplianceManager/nodes/?order=nodeName&nodeNameFilter=&nodeDescriptionFilter=&localIPFilter=&portFilter=80&serverFQDNFilter="|sed 's/\\n/\n/g'|(
		NODE_NAME="";
		IP="";
		MATCH=0
		while read -r l ; do
			echo $l | grep "nodeName">/dev/null
			if [ $? -eq 0 ] ; then
				NODE_NAME=`echo $l| awk -F ":" '{print $2}'|awk -F '"' '{print $2}'`
				MATCH=0
			fi
			echo $l | grep "localIP">/dev/null
			if [ $? -eq 0 ] ; then
				IP=`echo $l| awk -F ":" '{print $2}'|awk -F '"' '{print $2}'`
			fi
			echo $l | grep "serverFQDN">/dev/null
			if [ $? -eq 0 ] ; then
				for d in $DOMAINS ; do
					echo $l | tr '[:upper:]' '[:lower:]'| grep $d >/dev/null
					if [ $? -eq 0 ] ; then
						MATCH=1
					fi
				done
			fi
			echo $l| grep "ServerAlias" >/dev/null
			if [ $? -eq 0 ] ; then
				for d in $DOMAINS ; do
					echo $l | tr '[:upper:]' '[:lower:]'| egrep "serveralias[ |\t]*$d[\n| |\t]*" >/dev/null
					if [ $? -eq 0 ] ; then
						MATCH=1
					fi
				done
			fi
			
			
			echo $l | grep "isPublished">/dev/null
			if [ $? -eq 0 ] ; then
				PUBLISHED=`echo $l| awk -F ":" '{print $2}'|awk -F ',' '{print $1}'|sed 's/"//g'`
			fi
			echo $l | grep "}" >/dev/null
			if [ $? -eq 0 ] ; then
				if [ $PUBLISHED -eq 1 -a $MATCH -eq 1 ] ; then
					echo $NODE_NAME
					if  [[ $IP == '*' ]] ; then
						touch 'listening-ok'
					fi
				fi
				NODE_NAME="";
				IP="";
				MATCH=0
			fi
		done
	)

}

function checkRestring(){
	find  /etc/letsencrypt/accounts/acme-v01.api.letsencrypt.org/directory/ -name "regr.json"| xargs grep "$LE_MAIL">/dev/null
	if [ $? -ne 0 ] ; then
		./certbot-auto register -m "$LE_MAIL" --agree-tos -n
	fi
}

cd `dirname $0`
. ./conf.sh

(

	[ "$1" == "" ] && usage
	[ ! -x ../data/$1 ] && echo "Configuration for node $1 does not exists.... exiting" && exit 2
	. ../data/$1

	if [ "$2" == "renew" ] ; then
		LE_ACTION="renew"
	else
		LE_ACTION="create"
	fi


	if [ -f /etc/redhat-release ] ; then
		echo "RedHat system"

		APACHE_INITD_FILE=/etc/init.d/httpd

		APACHE_SITES_ENABLED_DIR=/etc/httpd/conf.d
	elif [ -f /etc/debian_version ] ; then
		echo "Debian system"

		APACHE_INITD_FILE=/etc/init.d/apache2
		APACHE_SITES_ENABLED_DIR=/etc/apache2/sites-enabled
	fi


	#Register (if needed )to letsenscrypt
	#checkRestring
	
	#Get FQDN dor required node
	NODE_FQDN=`curl -s -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1| grep serverFQDN| awk -F ":" '{print $2}'|awk -F '"' '{print $2}'`
	#Raw domain list for validation
	DOMAINS=""
	for p in $LE_CERT_DOMAIN ; do
		if [ "$p" != "-d" ] ; then
			lowerDomain=`echo $p| tr '[:upper:]' '[:lower:]'`
			DOMAINS="$DOMAINS $lowerDomain"
		fi
	done
	ROOT_DOMAIN=`echo "$DOMAINS"|awk '{print $1}'`

	#Find nodes using same FQDN and port 80
	CONFLICTING_NODES=`getConflictingNodes`
	#Stop those node while letsencrypt try domain validation
	for node in $CONFLICTING_NODES ; do
		enableDisableNode $node 0
	done

	mkdir -p /var/www/le-domain-validation
	LISTEN_DIRECTIVE=""										#Assume that there a Listening VHost on *80
	[ ! -f listening-ok ] && LISTEN_DIRECTIVE="Listen *:80" 	#In fact not, we didn't find a node listening on port 80 and * in getConflictingNodes
	cat > $APACHE_SITES_ENABLED_DIR/le-domain-validation.conf <<EOF
$LISTEN_DIRECTIVE
<VirtualHost *:80>
        # This virtualhost is created for letsencrypt domain validation process. If you see this file, somethings is probably gone wrong......
        ServerName $NODE_FQDN
EOF
	for d in $DOMAINS ; do
		if [ $d != $NODE_FQDN ] ; then
			echo "	ServerAlias $d">>$APACHE_SITES_ENABLED_DIR/le-domain-validation.conf
		fi
	done
	
	cat >> $APACHE_SITES_ENABLED_DIR/le-domain-validation.conf <<EOF	

        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/le-domain-validation

        ErrorLog \${APACHE_LOG_DIR}/error-le-domain-validation.log
        CustomLog \${APACHE_LOG_DIR}/access-le-domain-validation.log combined

</VirtualHost>
EOF


	$APACHE_INITD_FILE reload

	SUCCESS=0
	
	if [ "$LE_ACTION" == "create" ] ; then
		./certbot-auto certonly $CERTBOT_OPTS -n --webroot -w /var/www/le-domain-validation $LE_CERT_DOMAIN --agree-tos  --email $LE_MAIL 2>&1 |tee -a $$.log 
	elif [ "$LE_ACTION" == "renew" ] ; then
		./certbot-auto renew $CERTBOT_OPTS -n --cert-name $ROOT_DOMAIN 2>&1 |tee -a $$.log
	else
		false
	fi
	if [ ${PIPESTATUS[0]} -eq 0 ] ; then
		SUCCESS=1
		cat $$.log
	else
		SUCCESS=0
		echo "******************* SOMETHING GONE WRONG WITH LETSENCRYPT ************************"
		cat $$.log
		echo "******************* SOMETHING GONE WRONG WITH LETSENCRYPT ************************"
	fi

	rm $APACHE_SITES_ENABLED_DIR/le-domain-validation.conf
	rm -rf  /var/www/le-domain-validation
	[ -f listening-ok ] && rm listening-ok

	
	


	#restart stoped node for letsencrypt domain validation
	for node in $CONFLICTING_NODES ; do
		enableDisableNode $node 1
	done
	$APACHE_INITD_FILE reload

	if [ $SUCCESS -eq 1 ] ; then
		grep "Cert not yet due for renewal" $$.log>/dev/null
		renew=$?
		
		if [ "$LE_ACTION" == "create" -o $renew -ne 0 ] ; then
			uploadCerts $1 $ROOT_DOMAIN
			
			curl -i -s -X POST -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/virtualhost >/dev/null
		fi
		rm $$.log
		exit 0
	else
		rm $$.log
		exit 1
	fi
) 2>&1|tee -a $OSA_LOG_DIR/OSA-Letsencrypt.log 
exit ${PIPESTATUS[0]}
