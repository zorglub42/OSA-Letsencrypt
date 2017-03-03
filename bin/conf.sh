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
 # File Name   : bin/conf.sh
 #
 # Created     : 2017-03
 # Authors     : zorglub42 <contact(at)zorglub42.fr>
 #
 # Description :
 #      OSA-Letsencrypt shell scripts common config
 #--------------------------------------------------------
 # History     :
 # 1.0.0 - 2017-03-01 : Release of the file
##

# Connection to OSA local server
OSA_LOCAL_SERVER="http://127.0.0.1:81"
OSA_LOCAL_USER=""
OSA_LOCAL_PWD=""

#Logs destination
OSA_LOG_DIR=/var/log/OSA


#certbot-auto tweakin
#
#	See https://certbot.eff.org/docs/using.html for allowed tags
#		usefully for testing and debug
#			--test-cert: use letsencrypt staging servers
#			--dry-run: test only client side
#			--force-renewal: force certificates renewal even if not issued
CERTBOT_OPTS=""
