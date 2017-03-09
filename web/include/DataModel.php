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
 # File Name   : web/include/DataModel.php
 #
 # Created     : 2017-03
 # Authors     : zorglub42 <contact(at)zorglub42.fr>
 #
 # Description :
 #      OSA-Letsencrypt objets definitions
 #--------------------------------------------------------
 # History     :
 # 1.0.0 - 2017-03-01 : Release of the file
*/
class OSALEConfig{
	
	/**
	 * @var string 
	 * Node name {@required true}
	 */
	 public  $node;
	/**
	 * @var email 
	 * Contact email for letsencrypt {@required true}
	 */
	 public  $contact;
	/**
	 * @var array of string 
	 * List of domains {@required true}
	 */
	 public  $domains;
	/**
	 * @var  string 
	 * Comment about last event {@required true}
	 */
	 public  $lastEventComment;
	 /**
	  * @var string
	  * Issuing date is in ISO 8601 full format
	  */
	 public $issuing;
}
