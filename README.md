# OSA-Letsencrypt
Addons for Open Services Access (OSA)

OSA-Letsencrypt is an add for OSA (https://github.com/zorglub42/OSA) to manage HTTPS nodes certificates with Letsencrypt (https://letsencrypt.org/) 

##Install
Install scripts are developped for debian, but, with few changes, should be compliant with RedHat too...

To install some prerequisite are needed

**IMPORTANT NOTE:** To have OSA-LEtsencrypt working properly o n your box, it must satisfy the following pre-requisites.
  - OSA Installed and running
  - Direct access to internet (no proxies)
  - 80 tcp port  reachable from Internet


Installation process:
  - connect as root
  - goto to wished install dir (Ex.) 

    		cd /usr/local/src

  - clone git repo

		git clone https://github.com/zorglub42/OSA-Letsencrypt
  - Go to OSA-Letsencrypt/bin folder
  
		cd OSA-Letsencrypt/bin

Then run install.sh  

		./install.sh
		
Congratulations! 
You may now use OSA-Letsencrypt addon from OSA GUI

## Update
To deploy a new version of OSA-Letsencrypt addon from github do the folowing
  - connect as root
  - goto to wished install dir (Ex.) 
	
		Ex:
			cd /usr/local/src/OSA-Letsencrypt
			git pull

Thats all!

