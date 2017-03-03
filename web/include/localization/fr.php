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
 #      French language labels 
 #--------------------------------------------------------
 # History     :
 # 1.0.0 - 2017-03-01 : Release of the file
*/

$strings["label.warning"]="<br><b>Note</b> L'addon OSA-Letsencrypt utilise les informations \"FQDN du serveur\" de l'onglet \"Général\" et les directives apache \"ServerAllias\" de l'onglet \"Avancé\" pour déterminer le ou les domaines à inclure dans le certificat.<br>Veillez à mettre le domaine le plus précis dans \"FQDN du serveur\" (qui sert pour identifier ce certificat auprès de Letsencrypt).<br>Utiliser ici un domaine utilisé sur d'autres noeuds gérés avec Letsencrypt compromettra les certificats concernés";
$strings["label.contact"]="Contact";
$strings["label.current-config"]="Configuration pour letsencrypt";
$strings["label.domains"]="Domaine(s)";
$strings["label.save-first"]="Pourrez gérer les certificats avec Letsencrypt il faut d'abord sauvegarder le noeud";
$strings["button.generateLE"]="Générer des certificats avec Letsencryt";
$strings["button.removeLE"]="Supprimer les certificats Letsencryt";
