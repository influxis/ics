<?php
/*
 * Created on Jan 25, 2010
 *
 * To change the template for this generated file go to
 * Window - Preferences - PHPeclipse - PHP - Code Templates
 */
 

//Include framework
include "../lccs.php";
	
session_start();
$action = $_POST["action"];
$lccs = null;

if($action == "registerHook") {
	$meetingurl = $_POST["meetingurl"];
	$username = $_POST["username"];
	$password = $_POST["password"];
	$hookurl = $_POST["hookurl"];
	$token = $_POST["token"];
	
	if(isSet($_session['RTCAccount'])) {
		//login to lccs only require once
		$lccs = unserialize($_SESSION['RTCAccount']);
		$lccs->keepalive();
	}
	else {
		// Login once, do the handshake once for your account and then call multiple API
		$lccs = new RTCAccount($meetingurl);
        	$lccs->login($username, $password);
 		$_SESSION['RTCAccount'] = serialize($lccs);
	}

  	$lccs->registerHook($hookurl, $token);

	echo "<h1> Register Hook Sent, Use Get Hook Info To See Registration SuccessFul </h1> ";
	
}
else if($action == "subscribeCollection") {
 	$meetingurl = $_POST["meetingurl"];
	$username = $_POST["username"];
	$password = $_POST["password"];
	$roomname = $_POST["roomname"];
	$collectionname = $_POST["collectionname"];

	if(isSet($_session['RTCAccount'])) {
                //login to lccs only require once
                $lccs = unserialize($_SESSION['RTCAccount']);
                $lccs->keepalive();
        }
        else {
                // Login once, do the handshake once for your account and then call multiple API
                $lccs = new RTCAccount($meetingurl);
                $lccs->login($username, $password);
                $_SESSION['RTCAccount'] = serialize($lccs);
        }

        $lccs->subscribeCollection($roomname, $collectionname);

	echo "<h1> subscribeCollection sent, check yoursite/upload directory for incoming data </h1> ";
}
else if($action == "createNode") {
        $meetingurl = $_POST["meetingurl"];
        $username = $_POST["username"];
        $password = $_POST["password"];
        $roomname = $_POST["roomname"];
        $collectionname = $_POST["collectionname"];
        $nodename= $_POST["nodename"];
        $persistItem= $_POST["persistItem"];
        $userDependentItems= $_POST["userDependentItems"];
        $publishmodel= $_POST["publishmodel"];
        $lazySubscription= $_POST["lazySubscription"];
        $allowPrivateMessages= $_POST["allowPrivateMessages"];
        $modifyAnyItem= $_POST["modifyAnyItem"];
        $accessModel= $_POST["accessModel"];
        $itemStorageScheme= $_POST["itemStorageScheme"];
        $sessionDependentItems= $_POST["sessionDependentItems"];
        $p2pDataMessaging= $_POST["p2pDataMessaging"];

        if(isSet($_session['RTCAccount'])) {
                //login to lccs only require once
                $lccs = unserialize($_SESSION['RTCAccount']);
                $lccs->keepalive();
        }
        else {
                // Login once, do the handshake once for your account and then call multiple API
                $lccs = new RTCAccount($meetingurl);
                $lccs->login($username, $password);
                $_SESSION['RTCAccount'] = serialize($lccs);
        }

	$configuration = array("persistItems"=>$persistItem, 
				"userDependentItems"=>$userDependentItems, 
				"publishModel"=>$publishmodel,
				"allowPrivateMessages"=>$allowPrivateMessages,
				"lazySubscription"=>$lazySubscription,
				"allowPrivateMessages"=> $allowPrivateMessages,
				"accessModel"=>$accessModel, 
				"modifyAnyItem"=>$modifyAnyItem, 
				"itemStorageScheme"=>$itemStorageScheme, 
				"sessionDependentItems"=>$sessionDependentItems,
				"p2pDataMessaging"=>$p2pDataMessaging);

        $lccs->createNode($roomname, $collectionname, $nodename, $configuration);

        echo "<h1> Create Node Sent </h1> ";
}
else if($action == "getnodeconfiguration") {
        $meetingurl = $_POST["meetingurl"];
        $username = $_POST["username"];
        $password = $_POST["password"];
        $roomname = $_POST["roomname"];
        $collectionname = $_POST["collectionname"];
        $nodename= $_POST["nodename"];

        if(isSet($_session['RTCAccount'])) {
                //login to lccs only require once
                $lccs = unserialize($_SESSION['RTCAccount']);
                $lccs->keepalive();
        }
        else {
                // Login once, do the handshake once for your account and then call multiple API
                $lccs = new RTCAccount($meetingurl);
                $lccs->login($username, $password);
                $_SESSION['RTCAccount'] = serialize($lccs);
        }

	header("Content-type: text/xml");
        echo $lccs->getNodeConfiguration($roomname, $collectionname, $nodename);

}
else if($action == "gethookinfo") {
	$meetingurl = $_POST["meetingurl"];
        $username = $_POST["username"];
        $password = $_POST["password"];

	if($_SESSION['RTCAccount'] != null && $lccs == null) {
                //login to lccs only require once
                $lccs = unserialize($_SESSION['RTCAccount']);
                $lccs->keepalive();
        }
        else {
                // Login once, do the handshake once for your account and then call multiple API
                $lccs = new RTCAccount($meetingurl);
                $lccs->login($username, $password);
                $_SESSION['RTCAccount'] = serialize($lccs);
        }

	header("Content-type: text/xml");
	echo $lccs->getHookInfo();
}

else if($action == "updateChatFilter") {	
	echo "<h1> Update Chat Filter Success </h1> "  . $_POST["chatfilter"];
	$data= $_POST["chatfilter"];
	
	$fh = FALSE;
	$filename = "chatfilter.txt";
	$target = "../../upload/";
	$target .= $filename;

	$fh = fopen($target, 'w+');
	fseek($fh, 0, SEEK_SET);
	
	if (!feof($fh)) {
		fwrite($fh, $data);
		fclose($fh);
	}
} 


?>
