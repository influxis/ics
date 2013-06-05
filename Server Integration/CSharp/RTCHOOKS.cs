using System;
using System.Collections.Generic;
using System.Text;

//if you using FluorineFx, make sure include the package and indicae remotingservice
//using FluorineFx; [RemotingService("RTCHOOKS")]

public class RTCHOOKS
{
    public void receiveNode(string token, string roomName, string collectionName, string nodeName, Dictionary<string, object> config)
    {
        Console.WriteLine("ReceiveNode: " + token + " " + roomName + " " + collectionName + " " + nodeName);
    }

    public void receiveNodeDeletion(string token, string roomName, string collectionName, string nodeName) 
    {
        Console.WriteLine("receiveNodeDeletion: " + token + " " + roomName + " " + collectionName + " " + nodeName);
    }

    public void receiveItem(string token, string roomName, string collectionName, Dictionary<string, object> itemObj) 
    {
        Console.WriteLine("receiveItem: " + token + " " + roomName + " " + collectionName);
    }

    public void receiveItemRetraction(string token, string roomName, string collectionName, string nodeName, Dictionary<string, object> itemObj)
    {
        Console.WriteLine("receiveItemRetraction: " + token + " " + roomName + " " + collectionName + " " + nodeName);
    }

    public void receiveNodeConfiguration(string token, string roomName, string collectionName, string nodeName, Dictionary<string, object> config) 
    {
        Console.WriteLine("receiveNodeConfiguration: " + token + " " + roomName + " " + collectionName + " " + nodeName);
    }

    public void receiveUserRole(string token, string roomName, string collectionName, string nodeName, string userID, int role) 
    {
        Console.WriteLine("receiveUserRole: " + token + " " + roomName + " " + collectionName + " " + nodeName + " " + userID + " " + role);
    }
}

