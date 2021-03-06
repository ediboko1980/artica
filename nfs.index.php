<?php
	header("Pragma: no-cache");	
	header("Expires: 0");
	header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
	header("Cache-Control: no-cache, must-revalidate");
	include_once('ressources/class.templates.inc');
	include_once('ressources/class.ldap.inc');
	include_once('ressources/class.users.menus.inc');
	include_once('ressources/class.nfs.inc');
	include_once('ressources/class.computers.inc');

	
	$user=new usersMenus();
	if($user->AsSambaAdministrator==false){
		$tpl=new templates();
		echo $tpl->_ENGINE_parse_body("{ERROR_NO_PRIVS}");
		die();
	}

	if(isset($_GET["AddUserToFolderNFS"])){AddUserToFolderNFS();exit;}
	if(isset($_GET["AddFreeUserToFolderNFS"])){AddFreeUserToFolderNFS();exit;}
	if(isset($_GET["nfsacl"])){echo nsfacls($_GET["nfsacl"]);exit;}
	if(isset($_GET["NFSComputerDelete"])){NFSComputerDelete();exit;}
	if(isset($_GET["NFSComputerEdit"])){NFSComputerEdit();exit;}
	
if(isset($_GET["share-dir"])){share_dir_js();exit;}
if(isset($_GET["share-dir-popup"])){share_dir_popup();exit;}
if(isset($_GET["UnShareFolderNFS"])){UnShareFolderNFS();exit;}


function share_dir_js(){
$page=CurrentPageName();
	$prefix=str_replace('.','_',$page);
	$tpl=new templates();
	$title=$tpl->_ENGINE_parse_body('{share_this_NFS}','fileshares.index.php');
	$title_computer=$tpl->_ENGINE_parse_body('{give_computer_nameip}','fileshares.index.php');
	$base=basename($_GET["share-dir-popup"]);
	
$html="
	var {$prefix}timeout=0;
	var {$prefix}timerID  = null;
	var {$prefix}tant=0;
	var {$prefix}reste=0;	


	function {$prefix}LoadPage(){
		YahooLogWatcher(550,'$page?share-dir-popup={$_GET["share-dir"]}','$title');
	}

var x_RefreshUserListNFS=function (obj) {
	if(document.getElementById('finduserandgroupsid')){YahooWin5Hide();}
	LoadAjax('nfsacl','$page?nfsacl={$_GET["share-dir"]}');
	}		
	
	
var x_NFSEND=function (obj) {
	YahooLogWatcherHide();
	}	
	
	function AddUserToFolderNFS(uid){
    	var XHR = new XHRConnection();
    	mem_folder_name='{$_GET["share-dir"]}';
    	XHR.appendData('AddUserToFolderNFS',uid);
    	XHR.appendData('folder',mem_folder_name);
    	document.getElementById('nfsacl').innerHTML='<center><img src=\"img/wait_verybig.gif\"></center>';
    	XHR.sendAndLoad('$page', 'GET',x_RefreshUserListNFS);
	}
	
	function NFSFreeComputer(){
		var cmp=prompt('$title_computer');
		mem_folder_name='{$_GET["share-dir"]}';
		if(cmp){
			XHR.appendData('AddFreeUserToFolderNFS',cmp);
			XHR.appendData('folder',mem_folder_name);
			document.getElementById('nfsacl').innerHTML='<center><img src=\"img/wait_verybig.gif\"></center>';
    		XHR.sendAndLoad('$page', 'GET',x_RefreshUserListNFS);			
		}
	}
	
	function NFSComputerDelete(uid){
		var XHR = new XHRConnection();
    	XHR.appendData('NFSComputerDelete',uid);
    	XHR.appendData('folder','{$_GET["share-dir"]}');
    	document.getElementById('nfsacl').innerHTML='<center><img src=\"img/wait_verybig.gif\"></center>';
    	XHR.sendAndLoad('$page', 'GET',x_RefreshUserListNFS);
	}
	
	function SaveAcl(cmp){
		var XHR = new XHRConnection();
    	XHR.appendData('NFSComputerEdit',cmp);
    	XHR.appendData('folder','{$_GET["share-dir"]}');
    	XHR.appendData('NFSComputerAcl',document.getElementById('acl_'+cmp).value);
		document.getElementById('nfsacl').innerHTML='<center><img src=\"img/wait_verybig.gif\"></center>';
    	XHR.sendAndLoad('$page', 'GET',x_RefreshUserListNFS);    	
	}
	
	
	function UnShareFolderNFS(){
		var XHR = new XHRConnection();
		XHR.appendData('UnShareFolderNFS','{$_GET["share-dir"]}');
		document.getElementById('nfsacl').innerHTML='<center><img src=\"img/wait_verybig.gif\"></center>';
    	XHR.sendAndLoad('$page', 'GET',x_NFSEND); 		
		
	}

	

function NFSSecurity(){
		YahooWin5(400,'samba.index.php?security={$_GET["share-dir"]}&nfs=yes','$base');
	}
	
	{$prefix}LoadPage();
	
	";

	echo $html;
	
}

function share_dir_popup(){
	$nfsacl="<div id='nfsacl'>".nsfacls($_GET["share-dir-popup"])."</div>";
	
	$nfsacl=RoundedLightWhite($nfsacl);
	$nfs=new nfs();
	
	if(is_array($nfs->main_array[$_GET["share-dir-popup"]])){
		$delete=imgtootltip('delete-48.png','{delete_share}','UnShareFolderNFS()');
		
	}
	
	$base=basename($_GET["share-dir-popup"]);
	$html="<h1>{$_GET["share-dir-popup"]}</h1>
	<table style='width:100%'>
	<tr>
	<td valign='top'><img src='img/nfs-128.png'><br><br><center>$delete</center></td>
	<td valign='top'>
	<table style='width:100%'>
		<tr>
			<td align='left'><input type='button' OnClick=\"javascript:NFSFreeComputer();\" value='{add_computer_access}&nbsp;&raquo;'></td>
			<td align='right'><input type='button' OnClick=\"javascript:NFSSecurity();\" value='{browse_computers}&nbsp;&raquo;'></td>
		</tr>
	</table>
		$nfsacl
</td>
</tr>
</table>
	
	
	
	";
	
	$tpl=new templates();
	
	echo $tpl->_ENGINE_parse_body($html,"fileshares.index.php");
	
}

function nsfacls($folder){
	$nfs=new nfs();
	$array=$nfs->main_array[$folder]["C"];
	if(!is_array($array)){return "
	<h3>$folder</H3>
	<p class=caption>{share_this_NFS_explain}</p>";}
	
	$arraacls=array("ro"=>"{read}","rw"=>"{write}");
	
	
	$html="<div style='height:250px;overflow:auto;width:100%'>
		<table style='width:100%'>
		<tr>
			<th>&nbsp;</th>
			<th>{computer}</th>
			<th>{access}</th>
			<th>&nbsp;</th>
			<th>&nbsp;</th>
		</tr>";
while (list ($user, $acl) = each ($array) ){
	
	
	
	$html=$html . "<tr ". CellRollOver().">
		<td width=1%><img src='img/base.gif'></td>
		<td><code style='font-size:13px'>$user</td>
		<td width=1%><code style='font-size:13px'>".Field_array_Hash($arraacls,"acl_{$user}",$acl)."</td>
		<td width=1%><input type='button' OnClick=\"javascript:SaveAcl('$user');\" value='{edit}&nbsp;&raquo;'></td>
		<td width=1%>". imgtootltip('ed_delete.gif',"{delete}","NFSComputerDelete('$user')")."</td>
		</tr>
	
	";
}

$html=$html . "</table></div>";
	$tpl=new templates();
	return $tpl->_ENGINE_parse_body($html);;
			
}

function NFSComputerDelete(){
	$uid=$_GET["NFSComputerDelete"];
	$folder=$_GET["folder"];
	$nfs=new nfs();
	unset($nfs->main_array[$folder]["C"][$uid]);
	$nfs->SaveToServer();
}

function NFSComputerEdit(){
	$uid=$_GET["NFSComputerEdit"];
	$folder=$_GET["folder"];
	$acl=$_GET["NFSComputerAcl"];
	$nfs=new nfs();
	$nfs->main_array[$folder]["C"][$uid]=$acl;
	$nfs->SaveToServer();
}

function UnShareFolderNFS(){
	$folder=$_GET["UnShareFolderNFS"];
	$nfs=new nfs();
	unset($nfs->main_array[$folder]);
	$nfs->SaveToServer();	
	
}


function AddUserToFolderNFS(){
	$uid=$_GET["AddUserToFolderNFS"];
	$tpl=new templates();
	
	
	$folder=$_GET["folder"];
	if(strpos($uid,'$')>0){
		$computer=new computers($uid);
		$nfs=new nfs();
		$nfs->AddFolder($folder);
		$nfs->AddACLComputer($folder,$computer->ComputerRealName,true,true);
		$nfs->AddACLComputer($folder,$computer->ComputerIP,true,true);
		echo $tpl->_ENGINE_parse_body('{success}');
		return true;
		
	}
}

function AddFreeUserToFolderNFS(){
	$uid=$_GET["AddFreeUserToFolderNFS"];
	$tpl=new templates();
	$folder=$_GET["folder"];
	$nfs=new nfs();
	$nfs->AddFolder($folder);
	$nfs->AddACLComputer($folder,$uid,true,true);
	echo $tpl->_ENGINE_parse_body('{success}');
	return true;
		
	
}



?>