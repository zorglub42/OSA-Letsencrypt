
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
var saveNodeHandler;
var originalDomains="";


function setLEContactModified(){
	setNodeModified(true);
	if ($("#leContact").val() == ""){
		$("#osa").show();
	}else{
		$("#osa").hide();
	}
}
function showConf(conf){
	$("#leContact").val(conf.contact);
	$('#leContact').prop('readonly', true);
	

	$("#leDomains").html(conf.domains.toString());
	$("#leDomainsGroup").show();
	$("#leNote").hide();
	$("#btnRemoveLEConf").show();
	$("#osa").hide();
	
	originalDomains=conf.domains.toString();
}

function saveNode4LE(){
	//if ($("#leContact").val() != "" && !$("#leContact").attr("readonly")){
	if (originalDomains != getCurrentDomains().toString() && $("#leContact").val() != ""){
		//Domains have just changed form existing OSA-Letsencrypt configuration or it's a config creation request : generate certs  
		createLEConf();
	}else{
		//Letsencrypt contact is empty or generation already dont, so generation is not required, trigger the OSA handler for save button
		$("#saveNode").attr("onclick",saveNodeHandler)
		$("#saveNode").click();
	}
}

function addLEButton(){
	saveNodeHandler=$("#saveNode").attr("onclick")
	originalDomains="";


	if (currentNode != null){
		$.get( "addons/letsencrypt/templates/nodeSSLSettings.php", function( data ) {
			curHTML=$("#tabs-SSL").html();
			curHTML="<div id=\"osa-le\">" + data + "</div><div id=\"osa\">" + curHTML + "<div>";
			$("#tabs-SSL").html(curHTML);
			
			$("#leDomainsGroup").hide();
			$("#leNote").show();
			$("#btnRemoveLEConf").hide();
			$.get("addons/letsencrypt/certbot/" + currentNode.nodeName, showConf);
		});
		$("#saveNode").attr("onclick","saveNode4LE()")
	
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
						$("#leNote").show();
						$("#btnRemoveLEConf").hide();
						$("#osa").show();
						$("#leContact").val("");
						$('#leContact').prop('readonly', false);
					},
		  error: displayErrorV2
		});

}

function getCurrentDomains(){
	var commentRegExp=/^[ |\t]*#/
	var serverAliasRegExp=/^[ |\t]*ServerAlias[ |\t]+(.+)/

	domains=[];
	
	domains.push($("#serverFQDN").val());
	
	xtraConfLines=$("#additionalConfiguration").val().split('\n');
	for (i=0;i<xtraConfLines.length; i++){
		if (!xtraConfLines[i].match(commentRegExp) &&  xtraConfLines[i].match(serverAliasRegExp)){
			alias=xtraConfLines[i].replace(serverAliasRegExp,"$1")
			domains.push(alias);
		}
	}
	
	return domains
}

function createLEConf(){
	setNodeModified(true);
	domains=getCurrentDomains();
	
	data= {
					"contact": $("#leContact").val(),
					"domains": domains
	};

	showWait();
	$.ajax({
		  url: "addons/letsencrypt/certbot/" + currentNode.nodeName,
		  dataType: 'json',
		  type:'POST',
		  data: data,
		  success: function (conf){
						//trigger the OSA handler for save button
						$("#saveNode").attr("onclick",saveNodeHandler)
						$("#saveNode").click();
					},
		  error: displayErrorV2
		});
	
	
}

addonAddGUIHook("#tabs-SSL", addLEButton);

