<?php
/*--------------------------------------------------------
 # Module Name : OSA-Letsencrypt
 # Version : 1.0.0
 #
 #
 # Copyright (c) 2017 Zorglub42
 # This software is distributed under the Apache 2 license
 # <http://www.apache.org/licenses/LICENSE-2.0.html>
 #
 #--------------------------------------------------------
 # File Name   : web/Certbot.php
 #
 # Created     : 2017-03
 # Authors     : zorglub42 <contact(at)zorglub42.fr>
 #
 # Description :
 #      OSA-Letsencrypt REST API handler
 #--------------------------------------------------------
 # History     :
 # 1.0.0 - 2017-03-01 : Release of the file
*/
require_once 'include/Settings.php';
require_once 'include/DataModel.php';


class Certbot{


   	/**
   	 * Get config
   	 *
   	 * Get existing configuration for a node
   	 *
	 * @url GET /:node
	 *
	 * @param string $node node name for which configuration is requested {@required true}
   	 *
	 * @return OSALEConfig config definition
	 */
	function getConf( $node){

		if (file_exists($OSALEInstallDir . "/data/$node")){
			$content=file_get_contents($OSALEInstallDir . "/data/$node");
			$lines=explode("\n", $content);
			$rc=new OSALEConfig();
			$rc->node=$node;
			foreach($lines as $line){
				if (preg_match("/LE_MAIL=.*/", $line)){
					$lineData=explode("=", $line);
					$rc->contact=$lineData[1];
				}elseif (preg_match("/LE_CERT_DOMAIN=.*/", $line)){
					$lineData=explode("=", $line);
					$rc->domains=explode("  ", str_replace("-d","", str_replace("\"", "", $lineData[1])));
					for ($i=0;$i<count($rc->domains);$i++){
						$rc->domains[$i]=trim($rc->domains[$i]);
					}
					

				}
			}
				
		}else{
			throw new RestException(404,"Required configuration does not exists");
		}
		return $rc;

	}

   	/**
   	 * Create config
   	 *
   	 * Create configuration for a node, including letsencrypt domain validation process and node certificates update
   	 *
	 * @url PUT /:node
	 *
	 * @param string $node node name for which configuration is requested {@required true}
	 * @param email $contact contact email for letsencrypt {@required true}
	 * @param array of string  $domains domains to validate and include in server certificate {@required true}
   	 *
	 * @return OSALEConfig config definition
	 */
	function createConf( $node, $contact, $domains){

		if (file_exists($OSALEInstallDir . "/data/$node")){
			throw new RestException(409,"Configuration already exists");
		}
		$bashDomains="\"";
		foreach ($domains as $d){
			if ($bashDomains !="\""){
				$bashDomains=$bashDomains . " ";
			}
			$bashDomains=$bashDomains . "-d " . $d;
		}
		$bashDomains=$bashDomains . "\"";
		file_put_contents($OSALEInstallDir . "/data/$node", "#!/bin/bash\nLE_MAIL=$contact\nLE_CERT_DOMAIN=$bashDomains\n");
		chmod($OSALEInstallDir . "/data/$node", 0766);
		$rc=new OSALEConfig();
		$rc->node=$node;
		$rc->contact=$contact;
		$rc->domains=$domains;
		exec("sudo -H " . $OSALEInstallDir . "/bin/generateCerts.sh " . $node, $out, $execRc);
		if ($execRc != 0 ){
			unlink($OSALEInstallDir . "/data/$node");
			$leErr="";
			$dump=False;
			foreach($out as $line){
				if ($line == "******************* SOMETHING GONE WRONG WITH LETSENCRYPT ************************"){
					$dump=!$dump;
				}elseif ($dump){
					$leErr=$leErr . $line . "\n";
				}
			}
			throw new RestException(500, "Error while callng letsencrypt =>" .$leErr);
		}
		return $rc;
	}

   	/**
   	 * Delete config
   	 *
   	 * Delete configuration for a node, including letsencrypt certificates revokation, node certificates cleanning
   	 *
	 * @url DELETE /:node
	 *
	 * @param string $node node name for which configuration is requested {@required true}
   	 *
	 * @return OSALEConfig config definition
	 */
	function deleteConf( $node){

		$rc=$this->getConf($node);

		//file_put_contents($OSALEInstallDir . "/data/$node", "#!/bin/bash\nLE_MAIL=$contact\nLE_CERT_DOMAIN=$bashDomains\n");
		exec("sudo -H " . $OSALEInstallDir . "/bin/revokeCerts.sh " . $node, $out, $execRc);
		if ($execRc != 0 ){
			$leErr="";
			$dump=False;
			foreach($out as $line){
				if ($line == "******************* SOMETHING GONE WRONG WITH LETSENCRYPT ************************"){
					$dump=!$dump;
				}elseif ($dump){
					$leErr=$leErr . $line . "\n";
				}
			}
			$rc->lastEventComment= $leErr;
		}
		unlink($OSALEInstallDir . "/data/$node");
		return $rc;
	}
}
