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
 # File Name   : web/include/localization/fr.php
 #
 # Created     : 2017-03
 # Authors     : zorglub42 <contact(at)zorglub42.fr>
 #
 # Description :
 #      English language labels 
 #--------------------------------------------------------
 # History     :
 # 1.0.0 - 2017-03-01 : Release of the file
*/

$strings["label.warning"]="<br><b>Note</b>OSA-Letsencrypt addon use \"Server FQDN\" field on \"General\" tab and \"ServerAllias\" apache configuration directives on \"Advanced\" tab to define domain(s) included in Letsencrypt certificate.<br>Please define the mode restrictive domain in  \"Server FQDN \" (it is used to identify the certificate on Letsencrypt).<br>Using a domain defined on other nodes managed will Letsencrypt will compromize those certificates.";
$strings["label.contact"]="Contact";
$strings["label.current-config"]="Letsencrypt configuration";
$strings["label.domains"]="Domain(s)";
$strings["label.issuing"]="Issuing date";
$strings["label.save-first"]="To manage certificates with Letsencrypt, yu first need to save this node";
$strings["button.generateLE"]="Generate certificates with Letsencryt";
$strings["button.removeLE"]="Remove Letsencryt certificates ";

$strings["date.format.parseexact"]="mm/dd/yyyy hh:MM";
