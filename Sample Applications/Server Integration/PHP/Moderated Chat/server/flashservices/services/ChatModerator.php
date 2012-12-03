<?php
/*
 * Created on Jan 18, 2010
 *
 * To change the template for this generated file go to
 * Window - Preferences - PHPeclipse - PHP - Code Templates
 */
 include_once "../lccs.php";
 include_once 'Filter_String.php';

class ChatModerator 
{
	var $host ="";
	var $account = "";
	var $username= "";
	var $password = "";
	var $room = "";
	var $collectionNodeName = "";
	var $am;
	
	var $HISTORY_NODE_EVERYONE = "history";
	var $HISTORY_NODE_PARTICIPANTS = "history_participants";
	var $HISTORY_NODE_HOSTS = "history_hosts";
	
	var $OUTGOING_MESSAGE_NODE_EVERYONE = "outgoing_message_everyone";
	var $OUTGOING_MESSAGE_NODE_PARTICIPANTS = "outgoing_message_participants";
	var $OUTGOING_MESSAGE_NODE_HOSTS = "outgoing_message_hosts";
	
	var $shareID = "myChat_ModeratedChatModel";
	
	var $filter; 

	function ChatModerator($p_host, $p_account, $p_username, $p_password, $p_room, $p_collectionNodeName) {
		
		$this->host = $p_host;
		$this->account = $p_account;
		$this->username = $p_username;
		$this->password = $p_password;
		$this->room = $p_room;
		$this->collectionNodeName = $p_collectionNodeName;
		$this->filter = new Filter_String;
		$chatFilterText = $this->readChatFilter();
		
		if( $chatFilterText != null && $chatFilterText != "") { 
			
			if(strpos($chatFilterText, ',') === false) {
				$filterarray = array();
				$filterarray[0] = $chatFilterText;
			}else { 
				$filterarray = preg_split("/,/", $chatFilterText);
			}
			
			$this->filter->strings = $filterarray;  
		}else {
			$this->writeToFile("no filter set using default");
			$this->filter->strings = array('consectetuer','consequat','turpis', 'fuge');  //update this
		}
		
		$accountURL = "{$this->host}/{$this->account}";

		try {
			//The problem with using a singleton in a server-side language like PHP is scope.  
			//Scope in PHP is based upon requests, which rules out using a singleton pattern 
			//if your application is trying to access the persistent
			if($_SESSION['RTCAccount'] != null && $this->am == null) { 
				$this->am = unserialize($_SESSION['RTCAccount']);
				$this->writeToFile(" \n >> After Deserilize ChatModerator " . print_r($this->am, true) . "\n");
				$this->am->keepalive();
				
			}else {
				$this->writeToFile(" >RTCAccount login \n");
				$this->am = new RTCAccount($accountURL);
				$this->am->login($this->username, $this->password);
				$_SESSION['RTCAccount'] = serialize($this->am);
			}
			
			
		} catch (RTCError $e) {
			echo "Error: $e";
		}
		
	}
	
	function getRoomName() {
		return $this->room;
	}
	
	function getCollectionName() {
		return $this->collectionNodeName;
	}
	
	
	function serviceReceiveItem($roomName, $collectionName, $item) {
		/*check for item content*/
	
		/*call filter message*/
		$nodeName = $item["nodeName"];
		$intentedNodeName = "";
	
		if($nodeName == $this->OUTGOING_MESSAGE_NODE_EVERYONE) {
			$intentedNodeName = $this->HISTORY_NODE_EVERYONE;
		}else if($nodeName == $this->OUTGOING_MESSAGE_NODE_PARTICIPANTS) {
			$intentedNodeName = $this->HISTORY_NODE_PARTICIPANTS;
		}else if($nodeName == $this->OUTGOING_MESSAGE_NODE_HOSTS) {
			$intentedNodeName = $this->HISTORY_NODE_HOSTS;
		}else {
			return; //this is message we send out, so don't send it again.
		}
	            
		$item["nodeName"] = $intentedNodeName;
		$publisherID = $item["publisherID"];
		$prefilterMsg = $item["body"]["msg"];
		$this->writeToFile("prefiltered message: " . $prefilterMsg);
		$msg = $this->filterMessasge($prefilterMsg);
		$this->writeToFile("after filter: " . $msg);
		
		$item["body"]["msg"] = $msg;
		
		unset($item["itemID"]);
		
		$this->am->publishItem($roomName, $collectionName, $intentedNodeName, $item);
		
		$this->writeToFile(print_r($item, true));
		
		
	}
	
	function filterMessasge($msg){
	
		$this->filter->text = $msg;
		$this->filter->keep_first_last = true;
		$this->filter->replace_matches_inside_words = true;

		$new_text = $this->filter->filter();
		
		return $new_text;	
	}
	
	function writeToFile($data) {
		$directory = "./log/";

		if (file_exists($directory) == false) {
			mkdir($directory);	
		}

		$fh = FALSE;
		$filename = "myModeratedChat.log";
		$target = $directory;
		$target .= $filename;

		if (file_exists($target)) {
			$fh = fopen($target, 'a+');
		} else {
			$fh = fopen($target, 'w+');
			fseek($fh, 0, SEEK_SET);
		}

		if (!feof($fh)) {
			fwrite($fh, $data);
			fclose($fh);
			return TRUE;
		} else {
			return FALSE;
		}

	}
	
	function readChatFilter() {
		$directory = "./log/";

		if (file_exists($directory) == false) {
			mkdir($directory);	
		}
		$fh = FALSE;
		$filename = "chatfilter.log";
		$target = $directory;
		$target .= $filename;
		$chatfilter = "";

		if (file_exists($target)) {
			$fh = fopen($target, 'r+');
			if (!feof($fh)) {
				$chatfilter = fread($fh, filesize($target));
				fclose($fh);
			}
		}
		
		return $chatfilter;
	}
	
			
}
?>
