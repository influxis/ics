/************************************************
* Adobe LCCS 2010-2011 
* Server To Server PHP Interface and Example
* Version 1.0
* 
* This release aims at providing server to server integration with Adobe LCCS solution.
* 
* This README file shows how to install PHP AMF third party library that will allow LCCS server
* to invoke http hooks on your PHP server and allowing your application to receive LCCS real time events 
* as Adobe Flash AMF packages.  It also demonstrate how your PHP application invoking LCCS server APIs.   
*
* To get more information on the LCCS HTTP Server to Server API, visit ****
*************************************************/

Invoking LCCS server APIs:

1) LCCS provides PHP developer with lccs.php file in this directory.  Copy this file and move it 
to your server directory (e.g. /usr/local/php/flashservices)

2) update your php to include lccs.php (see example: sampleApps/Server2Server/ModeratedChat_PHP/server/flashservices/services/webHookManager.php) 

3) create RTC instance and invoke service routine or create AccountManager and invoke its sub routines.

Setting Web Hooks:

1) LCCS Server send AMF data to your application server in a way of similar to Flash Remoting call.  
Therefore, you will need translating between AMF package to PHP native data types.  We recommend 
downloading third party AMFPHP library from http://www.amfphp.org/ (select download). Follow instruction i
to install AMFPHP (http://www.amfphp.org/docs/installingamfphp.html)

2) copy lccs.php to flashservices directory (above step) 

3) copy RTCHOOKS.php to the flashservices/services  

4) Modify RTCHOOKS.php functions to handle incoming events.

5) invoke RTCAccount instance to login, register hooks and subscribeCollection
	(e.g. $rtc = new RTCAccount($accounturl); $rtc->login($username, $password);)

6) This is all it takes to create hooks in php for LCCS to send you events.  (see ModeratedChat_PHP for detailed example)




