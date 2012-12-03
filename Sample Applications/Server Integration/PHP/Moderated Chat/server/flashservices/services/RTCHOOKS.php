<?php
include_once "../globals.php";
include_once "ChatModerator.php";
include_once "ServiceFilterManager.php";

class RTCHOOKS {
	private $serviceFilters = array();

	function RTCHOOKS() {
		global $count;
		
		$this->writeToFile("\nRTCHOOKS start\n");
		$this->serviceFilters['chatModeratorFilter'] = new ChatModerator("http://localhost:8080", "UNDEF-ROOT", "root", "root", "mymeeting", "myChat_ModeratedChatModel");
		
		$this->methodTable = array (
			"receiveNode" => array (
				"access" => "remote",
				"description" => "Pings back a message"
			),
			"receiveNodeDeletion" => array (
				"access" => "remote",
				"description" => "Pings back a message"
			),
			"receiveItem" => array (
				"access" => "remote",
				"description" => "Pings back a message"
			),
			"receiveItemRetraction" => array (
				"access" => "remote",
				"description" => "Pings back a message"
			),
			"receiveNodeConfiguration" => array (
				"access" => "remote",
				"description" => "Pings back a message"
			),
			"receiveItems" => array (
				"access" => "remote",
				"description" => "Pings back a message"
			),
			"receiveNodes" => array (
				"access" => "remote",
				"description" => "Pings back a message"
			)
		);

	}

	function receiveNode($token, $roomName, $collectionName, $nodeName, $config) {
		global $count;
		$count = $count +1;
		$this->updateCounter();
		$binary = $count . " recieveNode: " . $roomName . " " . $collectionName . " " . $nodeName . "\n";
		$binary .= print_r($config, true);

		return $this->writeToFile($binary);

	}

	function receiveNodeDeletion($token, $roomName, $collectionName, $nodeName) {
		global $count;
		$count = $count +1;
		$this->updateCounter();
		$binary = $count . " receiveNodeDeletion: " . $roomName . " " . $collectionName . " " . $nodeName . "\n";
		return $this->writeToFile($binary);

	}

	/**
	 * String securityToken,
	  String roomName,
	  String collectionName,
	  Object messageItemVO
	 */
	function receiveItem($token, $roomName, $collectionName, $itemObj) {
		global $count;
		$count = $count +1;
		$this->updateCounter();
		$binary = $count . " receiveItem: " . $roomName . " " . $collectionName . "\n";
		$binary .= print_r($itemObj, true);

		$this->writeToFile($binary . " retrieving Filter \n");

		$filters = $this->retrieveFilters($roomName, $collectionName);

		foreach ($filters as &$filter) {
			$this->writeToFile("\ncalling out to filter serviceReceiveItem  \n");
			$filter->serviceReceiveItem($roomName, $collectionName, $itemObj);
		}

		return; // $this->writeToFile($binary);
	}

	/*
	 * String securityToken,
	  String roomName,
	  String collectionName,
	  String nodeName,
	  Object messageItemVO
	 */
	function receiveItemRetraction($token, $roomName, $collectionName, $nodeName, $itemObj) {
		global $count;
		$count = $count +1;
		$this->updateCounter();
		$binary = $count . " receiveItemRetraction: " . $roomName . " " . $collectionName . " " . $nodeName . "\n";
		$binary .= print_r($itemObj, true);
		return $this->writeToFile($binary);
	}

	function receiveNodeConfiguration($token, $roomName, $collectionName, $nodeName, $config) {
		global $count;
		$count = $count +1;
		$this->updateCounter();
		$binary = $count . " receiveNodeConfiguration: " . $roomName . " " . $collectionName . " " . $nodeName . "\n";
		$binary .= print_r($config, true);
		return $this->writeToFile($binary);

	}

	function retrieveFilters($roomName, $collectionName) {
		$myfilters = array ();
		$i = 0;

	 	foreach ($this->serviceFilters as $filter ) {
		  
		   if($filter->getRoomName() == $roomName && $filter->getCollectionName() == $collectionName) {
		   		$this->writeToFile("getRoomName " . $filter->getRoomName() . " collectionName " . $filter->getCollectionName());
		   		$myfilters[$i] = $filter;
		   		$i = $i + 1;
		   }
		}
		
		return $myfilters;
	}

	function updateCounter() {
		$directory = "./log/";

		if (file_exists($directory) == false) {
			mkdir($directory);	
		}

		$fh = FALSE;
		$filename = "counter.log";
		$target = $directory;
		$target .= $filename;

		if (file_exists($target)) {
			$fh = fopen($target, "r");
			$dat = fread($fh, filesize($target));
			fclose($fh);
			$fh = fopen($target, "w");
			fwrite($fh, $dat +1);
			fclose($fh);
		} else {
			$fh = fopen($target, 'w+');
			fwrite($fh, 1);
			fclose($fh);
		}

	}

	function writeToFile($data) {
		$directory = "./log/";

		if (file_exists($directory) == false) {
			mkdir($directory);	
		}

		$fh = FALSE;
		$filename = "mypayload.log";
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


}
?>



