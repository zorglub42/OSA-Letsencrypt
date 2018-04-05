<?php
/**
 * OSA-Letsencrypt
 * 
 * PHP Version 7.0
 * 
 * @category OSA-Addon
 * @package  OSA-Letsencrypt
 * @author   Zorglub42 <contact@zorglub42.fr>
 * @license  http://www.apache.org/licenses/LICENSE-2.0.htm Apache 2 license
 * @link     https://github.com/zorglub42/OSA/
*/
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
/**
 * Plugin config
 * 
 * PHP Version 7.0
 * 
 * @category OSA-Addon
 * @package  OSA-Letsencrypt
 * @author   Zorglub42 <contact@zorglub42.fr>
 * @license  http://www.apache.org/licenses/LICENSE-2.0.htm Apache 2 license
 * @link     https://github.com/zorglub42/OSA/
*/
class OSALEConfig
{
    
    /**
     * Node name {@required true}
     * 
     * @var string 
    */
    public  $node;
    /**
     * Contact email for letsencrypt {@required true}
     * 
     * @var email 
     */
    public  $contact;
    /**
     * List of domains {@required true}
     * 
     * @var array of string 
     */
    public  $domains;
    /**
      * Issuing date is in ISO 8601 full format
      
      * @var string
      */
    public $issuing;
}
