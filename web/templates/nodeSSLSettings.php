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
 * 
 * @codingStandardsIgnoreStart
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
 # File Name   : web/templates/nodeSSLSettings.php
 #
 # Created     : 2017-03
 # Authors     : zorglub42 <contact(at)zorglub42.fr>
 #
 # Description :
 #      Letsencrypt GUI hooked in SSL Node tab
 #--------------------------------------------------------
 # History     :
 # 1.0.0 - 2017-03-01 : Release of the file
*/


require_once "../include/LE_Localization.php";
?>
					<div id="LEgenerate">
						<div id="leSettings" >
							<hr>
							<label><?php echo LE_Localization::getString("label.current-config")?></label>
							<div class="row">
								<div class="col-md-3">
									<label><?php echo LE_Localization::getString("label.contact")?></label></label>
								</div>
								<div class="col-md-9">
									<input class="form-control" id="leContact" onchange="setLEContactModified()">
								</div>
							</div>
							<div class="row" class="display: none" id="leDomainsGroup">
								<div class="col-md-3">
									<label><?php echo LE_Localization::getString("label.domains")?></label></label>
								</div>
								<div class="col-md-9" id="leDomains"></div>
							</div>
							<div class="row" class="display: none" id="leIssuingDateGroup">
								<div class="col-md-3">
									<label><?php echo LE_Localization::getString("label.issuing")?></label></label>
								</div>
								<div class="col-md-9" id="leIssuing"></div>
							</div>
						</div>
						<button id="btnRemoveLEConf" type="button" class="btn btn-info" onclick="removeLEConf()">
							<span><?php echo LE_Localization::getString("button.removeLE")?></span>
						</button>
						<div id="leNote"><?php echo LE_Localization::getString("label.warning")?></div>
						<hr>
					</div>
