package flex.samples.LCCS;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class RTCHOOKS {

	public void receiveNode(String token, String roomName, String collectionName, String nodeName, Map config) {
		
		System.out.println("ReceiveNode: " + token + " " + roomName + " " + collectionName + " " + nodeName);
		
		

	}

	public void receiveNodeDeletion(String token, String roomName, String collectionName, String nodeName) {
		
		System.out.println("receiveNodeDeletion: " + token + " " + roomName + " " + collectionName + " " + nodeName);
		
	}
	
	public void receiveItem(String token, String roomName, String collectionName, Map itemObj) {

		System.out.println("receiveItem: " + token + " " + roomName + " " + collectionName);
	}

	public void receiveItemRetraction(String token, String roomName, String collectionName, String nodeName, Map itemObj){
		
		System.out.println("receiveItemRetraction: " + token + " " + roomName + " " + collectionName + " " + nodeName);
		
	
	}

	public void receiveNodeConfiguration(String token, String roomName, String collectionName, String nodeName, Map config) {

		System.out.println("receiveNodeConfiguration: " + token + " " + roomName + " " + collectionName + " " + nodeName);
		
	}
	
	public void receiveUserRole(String token, String roomName, String collectionName, String nodeName, String userID, int role) {
		
		System.out.println("receiveUserRole: " + token + " " + roomName + " " + collectionName + " " + nodeName + " " + userID + " " + role);
	}

}
