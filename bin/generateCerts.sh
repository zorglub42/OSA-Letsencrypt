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

##---------------------------------------------------------
# Display usage help message
#----------------------------------------------------------
# No params
##---------------------------------------------------------
function usage(){
	echo $0 node-name
	exit 1
}


##---------------------------------------------------------
# Upload certs generated by certbot to OSA
#----------------------------------------------------------
# $1: nodeName
# $2: certificates directory
##---------------------------------------------------------
function uploadCerts(){
	ls -l $2/cert.pem
	ls -l $2/privkey.pem
	ls -l $2/chain.pem
	curl -i -s -X POST -k   --form "files[]=@$2/cert.pem" --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/cert >/dev/null
	curl -i -s -X POST -k   --form "files[]=@$2/privkey.pem" --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/privateKey >/dev/null
	curl -i -s -X POST -k   --form "files[]=@$2/chain.pem" --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/chain >/dev/null

	echo "Upload done"
}

##---------------------------------------------------------
# Stop or start an OSA Node
#----------------------------------------------------------
# $1: nodeName
# $2: State
#		0: disable
#		1: enable
##---------------------------------------------------------
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


##---------------------------------------------------------
# Display OSA nodes responding to a list of domains
#----------------------------------------------------------
# No Params
# Uses $DOMAINS global as lsit of domains to check
##---------------------------------------------------------
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
				if [ $PUBLISHED -eq 1 ] ; then
					if [ $MATCH -eq 1 ] ; then
						# Current node is published and it's FQDN match FQDN to validate
						# Return this node as conflicting node
						echo $NODE_NAME
					fi
					if  [ "$IP" == '*' ] ; then
						# Current node is published and is listenning on '*', what ever is FQDN is
						# define "Listening maker"
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


function setCertISOIssueDate(){
	CERT=`grep "cert" /etc/letsencrypt/renewal/$NODE_FQDN.conf |awk -F "= " '{print $2}'`

	CERT_ISSUE_DATE=`openssl x509 -in $CERT -text -noout| grep "Not After" |awk -F "After : "  '{print $2}'`
	CERT_ISSUE_DATE=`date -d "$CERT_ISSUE_DATE" --iso-8601=seconds`


	grep -v "LE_CERT_ISSUING" ../data/$1.conf > $$.tmp

	echo 'LE_CERT_ISSUING="'$CERT_ISSUE_DATE'"'>> $$.tmp
	:> ../data/$1.conf
	cat $$.tmp>> ../data/$1.conf
	rm $$.tmp
}

##---------------------------------------------------------
# Ckeck if renew is required for a conf
# Exit with succes iff not
#----------------------------------------------------------
# No params
##---------------------------------------------------------
function isRenewRequired(){
	if [ $LE_ACTION == "renew" ] ; then

		echo "$CERTBOT_OPTS" | grep "\-\-force-renewal"
		if [ $? -ne 0 ] ; then

			CERT=`grep "cert" /etc/letsencrypt/renewal/$NODE_FQDN.conf |awk -F "= " '{print $2}'`

			CERT_ISSUE_DATE=`openssl x509 -in $CERT -text -noout| grep "Not After" |awk -F "After : "  '{print $2}'`
			CERT_ISSUE_DATE=`date -d "$CERT_ISSUE_DATE" '+%Y%m%d'`


			RENEW_FROM=`date --date "$RENEW_LIMIT days" '+%Y%m%d'`

			echo "RENEW LIMIT=$RENEW_LIMIT RENEW_COMPARAISON=$RENEW_FROM ISSUE=$CERT_ISSUE_DATE"
			if [ "$RENEW_FROM" \> "$CERT_ISSUE_DATE" ] ; then
				echo "Renewal is required"
			else
				echo "Renewal is not required"
				exit 0
			fi
		fi
	fi
}
##---------------------------------------------------------
# Main prog
#----------------------------------------------------------
# $1: nodeName
# $2: Optional
#		renew: certificates renewal
##---------------------------------------------------------
cd `dirname $0`
. ./conf.sh

(
	echo "*********** $0 IS STARTING *****************************************************************************************"

	[ "$1" == "" ] && usage
	[ ! -x ../data/$1.conf ] && echo "Configuration for node $1 does not exists.... exiting" && exit 2
	. ../data/$1.conf

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
	echo curl -s -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1
	NODE_FQDN=`curl -s -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1| grep serverFQDN| awk -F ":" '{print $2}'|awk -F '"' '{print $2}'`
	if [ "$NODE_FQDN" == "" ] ; then
		echo "Can't find node FQDN from $1.... exiting...."
		exit 1
	fi
	isRenewRequired

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
		echo disabling $node
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
		certbot certonly $CERTBOT_OPTS -n --expand --webroot -w /var/www/le-domain-validation $LE_CERT_DOMAIN --agree-tos  --email $LE_MAIL 2>&1 |tee -a $$.log
	elif [ "$LE_ACTION" == "renew" ] ; then
		certbot renew $CERTBOT_OPTS -n --cert-name $ROOT_DOMAIN 2>&1 |tee -a $$.log
	else
		false
	fi
	if [ ${PIPESTATUS[0]} -eq 0 ] ; then
		SUCCESS=1
		egrep "/etc/letsencrypt/live/$ROOT_DOMAIN.*/fullchain.pem" $$.log >/dev/null
		if [ $? -eq 0 ] ; then
			PEM=`egrep "/etc/letsencrypt/live/$ROOT_DOMAIN.*/fullchain.pem" $$.log|sort -u |awk  '{print $1}'|sed 's/.$//'`
			PEM_DIR=`dirname $PEM`
			SUCCESS=2
		fi
		grep "certs are not due for renewal yet" $$.log >/dev/null
		if [ $? -eq 0 ] ; then
			echo "Renewal requested for $1 for certs are not due for renewal yet"
			SUCCESS=1
		fi
	else
		SUCCESS=0
		echo "******************* SOMETHING WENT WRONG WITH LETSENCRYPT ************************"
		cat $$.log
		echo "******************* SOMETHING WENT WRONG WITH LETSENCRYPT ************************"
	fi

	rm $APACHE_SITES_ENABLED_DIR/le-domain-validation.conf
	rm -rf  /var/www/le-domain-validation
	[ -f listening-ok ] && rm listening-ok





	#restart stoped node for letsencrypt domain validation
	for node in $CONFLICTING_NODES ; do
		enableDisableNode $node 1
	done
	$APACHE_INITD_FILE status > /dev/null
	if [ $? -eq 0 ] ; then
		$APACHE_INITD_FILE reload
	else
		$APACHE_INITD_FILE restart
	fi
	case $SUCCESS in
		0)
			echo "Something goes wrong with letsencrypt certbot"
			RC=1
		;;
		1)
			echo "certbot was OK but no certs generetated (renewal not required OR certs not re-generated)"
			setCertISOIssueDate $1
			RC=0
		;;
		2)

			echo "Some new certs have been generated. Uploading them to OSA and updating node conf"
			echo $PEM_DIR
			uploadCerts $1 $PEM_DIR
			setCertISOIssueDate $1

			curl -i -s -X POST -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$1/virtualhost >/dev/null
			RC=0
		;;
	esac
	rm $$.log
	exit $RC
) 2>&1|tee -a $OSA_LOG_DIR/OSA-Letsencrypt.log
exit ${PIPESTATUS[0]}
