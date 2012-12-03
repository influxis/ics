/************************************************
* Adobe LCCS 2010
* Server To Server CSHARP Interface and Example
* Version 1.0
*
* The example shows how to use LCCS Server to Server API to invoke LCCS commands.  It also shows how to receive messages coming from LCCS room.
*
* following is the list of actions it can perform 
* 1) login  (e.g. http://localhost:2337/WebSite1/Login.aspx)
* 2) register hook 
* 3) subscribe collection / unsubscribe collection
* 4) get hook info
* 5) getNodeConfigration
* 6) fetch items
* 7) create node
* 8) remove node
* 9) publish item
* 10) retract item
* 11) set user role
*
*
* To recieve room notifications:
*  When events are recieved, RTCHOOKS.cs will print out those message via standard output. 
* 
* To get more information on the LCCS HTTP Server to Server API, visit ****
*************************************************/

Setup Procedure:

1) This example use FluorineFX AMF to C# librarion for flash remoting development http://www.fluorinefx.com/, use guid http://www.fluorinefx.com/docs/fluorine/index.html for installation and example using this library.

 	FluorineFX instruction use MS Visual Studio create a .NET project, this example use the name LCCS as the project name
	(FluorineFx Visual Studio Wizard for Visual Studio 2005)
Note: If you are using FluorineFX for remoting, currently the library doesn't support visual studio 2010 (express and enterprise). So, you need to get
2008 or prior visual Studio. Also, you may need to add some references in your visual studio projects if there are compile errors. 

2) After you created an website in your .NET project.  Copy sampleApps\Server2Server\DevConsole_CSHARP\wwwroot\LCCS\yourwebsite *.aspx and *.cs files to your website directory

3) FluorineFX installs flashremoting configuration files in the WEB-INF\flex directory under your website, this is allowing the webhook to invoke your C# objects when event happens on the server.
		
		services-config.xml
		remoting-cofnig.xml
		messaging-config.xml
		data-management-config.xml

In case you are using your custom config files, you should copy relevant parts from these above mentioned files.
		


4) copy LCCS.cs and RTCHOOKS.cs from the  serverIntegration/csharp to the FluorineFX Server library directory (e.g. C:\Inetpub\wwwroot\LCCS\FluorineFXServiceLibrary1)



9) This example use asp client to invoke AccountManager methods (login, registerhook, gethookinfo, subscribeCollection etc.).  

	e.g. http://localhost:2337/WebSite1/Login.aspx, which using login.aspx to invoke login.aspx.cs then calls LCCS.cs


10) launch Login.aspx in your browser and point to the LCCS account url. 

11) after login successful try to register hook and subscribe collection.  The events should go to your server console output.
 e.g. hook info: http://<server>:<port>/<yoursite>/Gateway.aspx. 

12) MS studio is a good debugging tool for setting up break points for any trouble shooting settup for this example.

 




