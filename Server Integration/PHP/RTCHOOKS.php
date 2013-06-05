<?php

class RTCHOOKS {

	function RTCHOOKS() {
		
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


	/**
	 * String securityToken,
	  String roomName,
	  String collectionName,
	  String nodeName
	  Map config
	 */
	function receiveNode($token, $roomName, $collectionName, $nodeName, $config) {
		$binary = " recieveNode: " . $roomName . " " . $collectionName . " " . $nodeName . "\n";
		$binary .= print_r($config, true);
		//return $this->writeToFile($binary);
	}

	/**
	 * String securityToken,
	  String roomName,
	  String collectionName,
	  String nodeName
	 */
	function receiveNodeDeletion($token, $roomName, $collectionName, $nodeName) {
		$binary = " receiveNodeDeletion: " . $roomName . " " . $collectionName . " " . $nodeName . "\n";
		//return $this->writeToFile($binary);
	}

	/**
	 * String securityToken,
	  String roomName,
	  String collectionName,
	  Object messageItemVO
	 */
	function receiveItem($token, $roomName, $collectionName, $itemObj) {
		$binary = " receiveItem: " . $roomName . " " . $collectionName . "\n";
		$binary .= print_r($itemObj, true);
		//$this->writeToFile($binary . " retrieving Filter \n");
	}

	/*
	 * String securityToken,
	  String roomName,
	  String collectionName,
	  String nodeName,
	  Object messageItemVO
	 */
	function receiveItemRetraction($token, $roomName, $collectionName, $nodeName, $itemObj) {
		$binary = " receiveItemRetraction: " . $roomName . " " . $collectionName . " " . $nodeName . "\n";
		$binary .= print_r($itemObj, true);
		//return $this->writeToFile($binary);
	}

	/*
	 * String securityToken,
	  String roomName,
	  String collectionName,
	  String nodeName,
	  Object nodeconfig
	 */
	function receiveNodeConfiguration($token, $roomName, $collectionName, $nodeName, $config) {
		$binary = " receiveNodeConfiguration: " . $roomName . " " . $collectionName . " " . $nodeName . "\n";
		$binary .= print_r($config, true);
		//return $this->writeToFile($binary);
	}

}
?>



