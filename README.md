# OSA-Letsencrypt
Addons for Open Services Access (OSA)

OSA-Letsencrypt is an addon for OSA (https://github.com/zorglub42/OSA) to manage HTTPS nodes certificates with Letsencrypt (https://letsencrypt.org/) 

This feature is available from SSL Setting tab on node properties. **NOTE:** it's available only existing nodes. When you create a node and plan to use it, first save the node.


The certificate name used as identifier to revoke or delete certs in letsencrypt is the "Server FQDN" field of the concerned node.
All "ServerAlias" found in advance settings are also included in the certificate.
As result, take care to always set the most restrictive domain name in FQDN field to avoid too hudge side effects in case of revokation.

Ex:
 - FQDN: www.mydomain.com
 - Advance configuration: ServerAlias mydomain.com
and not the opposite ;-)

##Install
Install scripts are developped for debian, but, with few changes, should be compliant with RedHat too...


**IMPORTANT NOTE:** To have OSA-LEtsencrypt working properly o n your box, it must satisfy the following pre-requisites.
  - OSA Installed and running
  - Direct access to internet (no proxies) from runtime box
  - 80 tcp port of runtime box reachable from Internet


Installation process:
  - connect as root
  - install certbot:
	```
	apt install certbot
	```
  - goto to wished install dir (Ex.) 

		Ex:
	    		cd /usr/local/src

  - clone git repo

		git clone https://github.com/zorglub42/OSA-Letsencrypt
  - Go to OSA-Letsencrypt/bin folder
  
		cd OSA-Letsencrypt/bin

Then, run the installer  

		./install.sh
		
Congratulations! 
You may now use OSA-Letsencrypt addon from OSA GUI.

## Update
To deploy a new version of OSA-Letsencrypt addon from github do the following
  - connect as root
  - goto to install dir 
	
		Ex:
			cd /usr/local/src/OSA-Letsencrypt
			./bin/update.sh

Enjoy!

## Try and debug
It's possible to run OSA-Letsencrypt addon on letsencrypt staging server.
For this :
- connect as root
- goto to bin folder in installation dir (Ex.)
	
		Ex:
			cd /usr/local/src/OSA-Letsencrypt/bin
			
- edit conf.sh file and add wished flags to certbot (see certbot documentation at https://certbot.eff.org/docs/using.html).
For example you can use:

	- --test-cert: to use letsencrypt staging servers
	- --dry-run: to test addon on client side only
	- --force-renewal: force certificate renewal even if not issued
	
			
To entirely reset the Letsencrypt environnement like on a blank box, remove /etc/letsencrypt folder (if you already have one with existing live certificates, don't forget to backup it before removing)
