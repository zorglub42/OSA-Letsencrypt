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


function uploadCerts(){
	curl -i -s -X POST -k   --form "files[]=@/etc/letsencrypt/live/$2/cert.pem" --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/cert >/dev/null
	curl -i -s -X POST -k   --form "files[]=@/etc/letsencrypt/live/$2/privkey.pem" --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/privateKey >/dev/null
	curl -i -s -X POST -k   --form "files[]=@/etc/letsencrypt/live/$2/chain.pem" --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/chain >/dev/null

	echo "Upload done"
}

function enableDisableNode(){
	curl  -i -X POST -s -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"   -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'Accept: application/json, text/javascript, */*; q=0.01'  "$OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/status" --data "published=$2" >/tmp/$$.txt
	if [ $? -eq 0 ] ; then
		echo "Node $1 successfully paused/restarted ($2) ";
	else
		echo "Failed to pause/start node $1 ($2)";
		cat /tmp/$$.txt
	fi
	rm /tmp/$$.txt
}


function getConflictingNodes(){
	
	
 	curl -s -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  "$OSA_LOCAL_SERVER/ApplianceManager/nodes/?order=nodeName&nodeNameFilter=&nodeDescriptionFilter=&localIPFilter=&portFilter=80&serverFQDNFilter="|sed 's/\\n/\n/g'|(
		while read -r l ; do
			echo $l | grep "nodeName">/dev/null
			if [ $? -eq 0 ] ; then
				NODE_NAME=`echo $l| awk -F ":" '{print $2}'|awk -F '"' '{print $2}'`
				MATCH=0
			fi
			echo $l | grep "serverFQDN">/dev/null
			if [ $? -eq 0 ] ; then
				for d in $DOMAINS ; do
					echo $l | grep $d >/dev/null
					if [ $? -eq 0 ] ; then
						MATCH=1
					fi
				done
			fi
			echo $l| grep "ServerAlias" >/dev/null
			if [ $? -eq 0 ] ; then
				for d in $DOMAINS ; do
					echo $l | egrep "ServerAlias[ |\t]*$d[\n| |\t]*" >/dev/null
					if [ $? -eq 0 ] ; then
						MATCH=1
					fi
				done
			fi
			
			
			echo $l | grep "isPublished">/dev/null
			if [ $? -eq 0 ] ; then
				PUBLISHED=`echo $l| awk -F ":" '{print $2}'|awk -F ',' '{print $1}'`
			fi
			echo $l | grep "}" >/dev/null
			if [ $? -eq 0 ] ; then
				if [ $PUBLISHED -eq 1 -a $MATCH -eq 1 ] ; then
					echo $NODE_NAME
				fi
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

(
	[ "$1" == "" ] && usage
	cd `dirname $0`
	[ ! -x ../data/$1 ] && echo "Configuration for node $1 does not exists.... exiting" && exit 2
	. ../data/$1
	. ./conf.sh

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
			DOMAINS="$DOMAINS $p"
		fi
	done
	ROOT_DOMAIN=`echo "$DOMAINS"|awk '{print $1}'`
	
	
	#Find nodes using same FQDN and port 80
	CONFLICTING_NODES=`getConflictingNodes `

	#Stop those node while letsencrypt try domain validation
	for node in $CONFLICTING_NODES ; do
		enableDisableNode $node 0
	done

	mkdir -p /var/www/le-domain-validation
	cat > $APACHE_SITES_ENABLED_DIR/le-domain-validation.conf <<EOF
Listen *:80
<VirtualHost $NODE_FQDN:80>
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
		./certbot-auto certonly $CERTBOT_OPTS -n --webroot -w /var/www/le-domain-validation $LE_CERT_DOMAIN --agree-tos  --email $LE_MAIL  > $$.log 
	elif [ "$LE_ACTION" == "renew" ] ; then
		./certbot-auto renew $CERTBOT_OPTS -n --cert-name $ROOT_DOMAIN
	else
		false
	fi
	if [ $? -eq 0 ] ; then
		SUCCESS=1
		cat $$.log
	else
		echo "******************* SOMETHING GONE WRONG WITH LETSENCRYPT ************************"
		cat $$.log
		echo "******************* SOMETHING GONE WRONG WITH LETSENCRYPT ************************"
	fi
	rm $$.log
	#~ echo "Check conf?"
	#~ read l

	rm $APACHE_SITES_ENABLED_DIR/le-domain-validation.conf
	rm -rf  /var/www/le-domain-validation
	$APACHE_INITD_FILE reload
	


	#restart stoped node for letsencrypt domain validation
	for node in $CONFLICTING_NODES ; do
		enableDisableNode $node 1
	done

	if [ $SUCCESS -eq 1 ] ; then
		uploadCerts $1 $ROOT_DOMAIN
		
		curl -i -s -X POST -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/virtualhost >/dev/null
		exit 0
	else
		exit 1
	fi
	
)
