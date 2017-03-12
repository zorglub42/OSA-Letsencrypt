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
require_once 'include/DataModel.php';


class Certbot{

	/**
	 * Get all conf
	 * 
	 * Get all existings configs
	 * 
	 * @url GET
	 * 
	 * @return array {@type OSAConfig} config
	 */
	 function get(){
		 
		include 'include/Settings.php';
		$rc=array();
		foreach (scandir($OSALEInstallDir . "/data/") as $file){
			if (preg_match("/.*\.conf/", $file)){
				try{
					$conf=$this->getConf($withoutExt = preg_replace('/\\.[^.\\s]{3,4}$/', '', $file));
					array_push($rc, $conf);
				}catch (Exception $e){
				}
			}
		}
		if (count($rc)==0){
			throw new RestException(404, "Can't find any configuration");
		}
		return $rc;
	}

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
		include 'include/Settings.php';

		if (file_exists($OSALEInstallDir . "/data/$node.conf")){
			$content=file_get_contents($OSALEInstallDir . "/data/$node.conf");
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
					

				}elseif (preg_match("/LE_CERT_ISSUING=.*/", $line)){
					$lineData=explode("=", $line);
					$rc->issuing=str_replace('"', '', $lineData[1]);
				}
			}
				
		}else{
			throw new RestException(404,"Required configuration does not exists");
		}
		return $rc;

	}

   	/**
   	 * Create or update a config
   	 *
   	 * Create or update configuration for a node, including letsencrypt domain validation process, certificates (re)generation, node certificates update, node deployment
   	 *
	 * @url POST /:node
	 *
	 * @param string $node node name for which configuration is requested {@required true}
	 * @param email $contact contact email for letsencrypt {@required true}
	 * @param array of string  $domains domains to validate and include in server certificate {@required true}
   	 *
	 * @return OSALEConfig config definition
	 */
	function generateConfAndCerts( $node, $contact, $domains){
		include 'include/Settings.php';

		$bashDomains="\"";
		foreach ($domains as $d){
			if ($bashDomains !="\""){
				$bashDomains=$bashDomains . " ";
			}
			$bashDomains=$bashDomains . "-d " . $d;
		}
		$bashDomains=$bashDomains . "\"";
		file_put_contents($OSALEInstallDir . "/data/$node.conf", "#!/bin/bash\nLE_MAIL=$contact\nLE_CERT_DOMAIN=$bashDomains\n");
		chmod($OSALEInstallDir . "/data/$node.conf", 0766);
		$rc=new OSALEConfig();
		$rc->node=$node;
		$rc->contact=$contact;
		$rc->domains=$domains;
		exec("sudo -H " . $OSALEInstallDir . "/bin/generateCerts.sh " . $node, $out, $execRc);
		if ($execRc != 0 ){
			unlink($OSALEInstallDir . "/data/$node.conf");
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
		include 'include/Settings.php';

		$rc=$this->getConf($node);

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
		unlink($OSALEInstallDir . "/data/$node.conf");
		return $rc;
	}
}
