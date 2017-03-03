#!/bin/bash

# Configuration section #############################################################################
OSA_LOCAL_SERVER="http://127.0.0.1:81"
OSA_LOCAL_USER=""
OSA_LOCAL_PWD=""
# End of Configuration section #############################################################################



(
	cd `dirname $0`
	for n in `ls ../data/` ; do
		curl -i -s -k --user "$OSA_USAGE_USER:$OSA_ADMIN_PWD"  $OSA_LOCAL_SERVER/ApplianceManager/nodes/$n | grep "404 Not Found">/dev/null
		if [ $? -eq 0 ] ; then
			./revokeCerts.sh $n
			rm ../data/$n
		else		
			./generateCerts.sh $n renew
		fi
	done
) 
