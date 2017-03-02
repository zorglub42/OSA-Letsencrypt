
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
 # File Name   : web/js/osa-letsencrypt.js
 #
 # Created     : 2017-03
 # Authors     : zorglub42 <contact(at)zorglub42.fr>
 #
 # Description :
 #      JS functions used by OSA-Letsencrypt addon 
 #--------------------------------------------------------
 # History     :
 # 1.0.0 - 2017-03-01 : Release of the file
*/
function showConf(conf){
	$("#leContact").val(conf.contact);
	$('#leContact').prop('readonly', true);
	

	$("#leDomains").html(conf.domains.toString());
	$("#leDomainsGroup").show();
	$("#btnCreateLEConf").hide();
	$("#btnRemoveLEConf").show();
	$("#osa").hide();
}


function addLEButton(){
	if (currentNode != null){
		$.get( "addons/letsencrypt/templates/nodeSSLSettings.php", function( data ) {
			curHTML=$("#tabs-SSL").html();
			curHTML="<div id=\"osa-le\">" + data + "</div><div id=\"osa\">" + curHTML + "<div>";
			$("#tabs-SSL").html(curHTML);
			
			$("#leDomainsGroup").hide();
			$("#btnCreateLEConf").show();
			$("#btnRemoveLEConf").hide();
			$.get("addons/letsencrypt/certbot/" + currentNode.nodeName, showConf);
		});
	}else{
		$.get( "addons/letsencrypt/templates/nodeSSLSaveFirst.php", function( data ) {
			curHTML=$("#tabs-SSL").html();
			curHTML=data+curHTML;
			$("#tabs-SSL").html(curHTML);
		});
	}
}

function removeLEConf(){
	setNodeModified(true);
	showWait();
	$.ajax({
		  url: "addons/letsencrypt/certbot/" + currentNode.nodeName,
		  dataType: 'json',
		  type:'DELETE',
		  success: function (conf){
						hideWait();
						$("#leDomainsGroup").hide();
						$("#btnCreateLEConf").show();
						$("#btnRemoveLEConf").hide();
						$("#osa").show();
						$("#leContact").val("");
						$('#leContact').prop('readonly', false);
					},
		  error: displayErrorV2
		});

}
function createLEConf(){
	setNodeModified(true);
	domains=[];
	
	domains.push($("#serverFQDN").val());
	
	xtraConfLines=$("#additionalConfiguration").val().split('\n');
	for (i=0;i<xtraConfLines.length; i++){
		if (xtraConfLines[i].indexOf("ServerAlias")>=0){
			alias=xtraConfLines[i].split(" ");
			domains.push(alias[1]);
		}
	}
	 data= {
					"contact": $("#leContact").val(),
					"domains": domains
	};

	showWait();
	$.ajax({
		  url: "addons/letsencrypt/certbot/" + currentNode.nodeName,
		  dataType: 'json',
		  type:'PUT',
		  data: data,
		  success: function (conf){
						hideWait();
						showConf(conf);
					},
		  error: displayErrorV2
		});
	
	
}

addOSADivHook("tabs-SSL", addLEButton);

