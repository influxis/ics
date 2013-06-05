/************************************************
* Adobe LCCS 2010
* Server To Server PHP Interface and Example
* Version 1.0
*
* The ChatModerator example shows how Server to Server API used to filter chat messages between two LCCS clients. 
*
* The idea is use LCCS messaging structure create a new collection node "myChat_ModeratedChatModel".  Within this collection node
* there are two sets of nodes.  One set of nodes for outgoing message from client to server (outgoing_message_everyone, outgoing_message_participants, outgoing_message_hosts). 
* These nodes have nodeconfigurations that allowing everyone to publish to it (e.g. publishItem), but only owner of the room can read from it (receiveItem).  Here the 
* server will act as owner of these message receiving all the chat messages and modifying them.
* The other sets of nodes (HISTORY_NODE_EVERYONE, HISTORY_NODE_PARTICIPANTS, HISTORY_NODE_HOSTS) is designed for chat history so that all clients can read from (receiveItem) 
* but only owner can publish (e.g. publishItem). This way, server can publish the filtered chat message back to the clients. 
*
*
* To get more information on the LCCS HTTP Server to Server API, visit ****
*************************************************/

Setup Procedure:

1) install AMFPHP from http://www.amfphp.org/

2) the directory setup of the amfphp like following:

	WebSite/ - html files
	WebSite/flashservices - copy lccs.php here
	WebSite/flashservices (browser, core etc.) - afmphp libraries  
	WebStie/flashservices/services - where you put your custom services

2) cp server/setupChatModerator.html to your php root directory (e.g. WebSite).

   cp lccs.php from serverIntegrations/php to WebSite/flashservices directory

   cp files under server/flashservices/services to WebSite/flashservices/services directory

   WARNING: RTCHOOKS.php has moderator chat example code embedded, it is different from the RTCHOOKS.php file under 
   the serverIntegration/php directory which is a more generic interface (do not use this copy, use the copy from the example directory)


3) update client/src/ModeratedChatClient.mxml and ModeratedChatClientReceipient.mxml to point to your LCCS room.

    e.g. <rtc:AdobeHSAuthenticator
                id="auth"
                userName="root"
                password="root"  />

   e.g. <rtc:ConnectSessionContainer roomURL="http://localhost:8080/UNDEF-ROOT" id="cSession" authenticator="{auth}" width="100%" height="100%">


   Use mxmlc or Flex builder to build the ModeratedChatClient.swf and ModeratedChatClientReceipient.swf.  Open both with your browser or flash standalone player 

4) use your browser open the setupChatModerator.html from your php WebSite, update appropriate fields to reflect your account on LCCS.  

   For register hook, you need to provide the hook url for LCCS to call back on, (e.g. http://<myserver>/flashservices/gateway.php) and 
	a security token for you to verify that when http call is invoked on your php handler that it is the same one you registered ( security token is something that php developer can use to verify if the http call back comes from the right source, it is optional and any string value will suffice).  
	You can update this often to minimize compromise of token.

   For subscribing collection, here the example calls for subcribe to myChat_ModeratedChatModel collection name for all its events.  The required attribute is roomName and collectionName, 
	however you can also specify array of nodename under the collection.

   This web page also allows you setup list of filter words from the default.

(e.g. ChatModerator("http://localhost:8080", "MyAccountName", "myusername", "mypassword", "myroomname", "myChat_ModeratedChatModel")).
Here "myChat_ModeratedChatModel" is the collection name for ModeratedChat Example.  If you wish to change it, please also update the flex client code
sampleApps/Server2Server/ModeratedChat_PHP/client/src/ModeratedChatClient.mxml and ModeratedChatClientReceipient.mxml

5) used filter string php library downloaded from http://www.bitrepository.com/advanced-word-filter.html and name it Filter_String.php

6) Once all above is set, launch both ModeratedChatClient.swf and ModeratedChatClientReceipient.swf.  Start chating with message that contained filtered language
 (this program also tracks all the item downloaded in xml format and stored at your WebSite/upload directory)

USE php logs and webserver log files as debugging aid.

   


