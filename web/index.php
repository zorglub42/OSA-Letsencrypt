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
 #      OSA-Letsencrypt REST API Restler gateway
 #--------------------------------------------------------
 # History     :
 # 1.0.0 - 2017-03-01 : Release of the file
*/
require_once 'include/restler3/restler.php';
use Luracast\Restler\Restler;


Resources::$useFormatAsExtension = false;

//CORS Compliancy
header("Access-Control-Allow-Credentials : true");
header("Access-Control-Allow-Headers: X-Requested-With, Depth, Authorization");
header("Access-Control-Allow-Methods: OPTIONS, GET, HEAD, DELETE, PROPFIND, PUT, PROPPATCH, COPY, MOVE, REPORT, LOCK, UNLOCK");
header("Access-Control-Allow-Origin: *");


$r = new Restler();
if (isset(getallheaders()["Public-Root-URI"])){
	$r->setBaseUrl(getallheaders()["Public-Root-URI"] . "/addons/letsencrypt");
}

$r->setSupportedFormats('JsonFormat' ,'UrlEncodedFormat');
$r->addAPIClass('Luracast\\Restler\\Resources');  //this creates resources.json at API root 

$r->addAPIClass('Certbot');
$r->handle();
