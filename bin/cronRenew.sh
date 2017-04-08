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
 # File Name   : bin/cronRenew.sh
 #
 # Created     : 2017-03
 # Authors     : zorglub42 <contact(at)zorglub42.fr>
 #
 # Description :
 #      cront task to renew certificates for existings node managed with OSA-Letsencrypt addon
 #--------------------------------------------------------
 # History     :
 # 1.0.0 - 2017-03-01 : Release of the file
##

cd `dirname $0`
. ./conf.sh

(
	echo "*********** $0 IS STARTING *****************************************************************************************"
	# Call certbot to ensure that new version will install with cron rather than calling synchronous WS
	./certbot-auto certificates

	for conf in `ls ../data/*.conf` ; do
		n=`basename $conf |sed 's/\.conf//'`
		curl -i -s -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$n | grep "404 Not Found">/dev/null
		if [ $? -eq 0 ] ; then
			./revokeCerts.sh $n
			echo revoking certs for $n
			rm $conf
		else		
			echo renewing certs for $n
			./generateCerts.sh $n renew
		fi
	done
) 2>&1 |tee -a $OSA_LOG_DIR/OSA-Letsencrypt.log
exit ${PIPESTATUS[0]}
