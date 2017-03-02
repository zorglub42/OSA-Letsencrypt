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


require_once "../include/Localization.php";
?>
					<div id="LEgenerate">
						<div id="leSettings" >
							<hr>
							<label><?php echo Localization::getString("label.current-config")?></label>
							<div class="row">
								<div class="col-md-3">
									<label><?php echo Localization::getString("label.contact")?></label></label>
								</div>
								<div class="col-md-9">
									<input class="form-control" id="leContact">
								</div>
							</div>
							<div class="row" class="display: none" id="leDomainsGroup">
								<div class="col-md-3">
									<label><?php echo Localization::getString("label.domains")?></label></label>
								</div>
								<div class="col-md-9" id="leDomains"></div>
							</div>
						</div>
						<button id="btnCreateLEConf" type="button" class="btn btn-info" onclick="createLEConf()">
							<span><?php echo Localization::getString("button.generateLE")?></span>
						</button>
						<button id="btnRemoveLEConf" type="button" class="btn btn-info" onclick="removeLEConf()">
							<span><?php echo Localization::getString("button.removeLE")?></span>
						</button>
						<div><?php echo Localization::getString("label.warning")?></div>
						<hr>
					</div>
