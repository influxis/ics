/************************************************
* Adobe LCCS 2010-2011 
* Server To Server CSharp Interface and Example
* Version 1.0
* 
* This release aims at providing server to server integration with Adobe LCCS solution.
* 
* This README file shows how to install AMF to C# third party library that will allow LCCS server
* to invoke http hooks on your .NET server and allowing your application to receive LCCS real time events 
* as Adobe Flash AMF packages.  It also demonstrate how your C# .NET application invoking LCCS server APIs.   
*
* To get more information on the LCCS HTTP Server to Server API, visit ****
*************************************************/

Invoking LCCS server APIs:

1) LCCS provides .NET developer with LCCS.cs file in this directory.  Copy this file and move it 
to your server directory (e.g. /wwwroot/LCCS/ServiceLibraryFiles)

2) update your .NET files (*.cs, *.aspx) to include LCCS.cs (e.g. "using LCCS", see example: sampleApps/Server2Server/DevConsole_CSHARP/wwwroot/LCCS/yourwebsite/Login.aspx.cs) 

3) create LCCS instance and invoke service routine or create AccountManager and invoke its sub routines.

	    AccountManager am = new AccountManager(account_url);
            bool res = am.login(username, password);
	    Session["LCCSAccount"] = am; //store in session for reuse

Setting Web Hooks:

1) LCCS Server send AMF data to your .NET application server in a way of similar to Flash Remoting call.  
Therefore, you will need translating between AMF package to C# native data types.  We recommend 
downloading third party AMF to C# library from FluorineFx - http://www.fluorinefx.com/ (select download). Follow instruction i
to install FluorineFx (http://www.fluorinefx.com/docs/fluorine/index.html).

2) After installing the FluorineFX, copy LCCS.cs and RTCHOOKS.cs to the installed service library directory (e.g. C:\Inetpub\wwwroot\LCCS\FluorineFXServiceLibrary1)

4) Modify RTCHOOKS.cs functions to handle incoming events, currently it is outputting to the Console.

5) invoke LCCSAccount instance to login, register hooks and subscribeCollection
	AccountManager am = new AccountManager(account_url);
        bool res = am.login(username, password);
	am.registerHook(hookurl, token);
	am.subscribeCollection(roomname, collectionname);

6) This is all it takes to create hooks in C# for LCCS to send you events.  (see DevConsole_CSHARP for detailed example)




