#!/bin/bash

#Generating endpoints entry for HTTP Host
unset http_proxy

# Configuration section #############################################################################
OSA_LOG_DIR=/var/log/OSA
# End of Configuration section #############################################################################

(
	cd `dirname $0`
	for n in `ls ../data/` ; do
		
		./generateCerts.sh $n renew
		
	done
) 
