
/************************************************
 *  ADOBE SYSTEMS INCORPORATED
 *    Copyright 2010-2011 Adobe Systems Incorporated
 *    All Rights Reserved.
 *
 *  NOTICE: Adobe permits you to use, modify, and distribute this file in accordance with the 
 *  terms of the Adobe license agreement accompanying it.  If you have received this file from a 
 *  source other than Adobe, then your use, modification, or distribution of it requires the prior 
 *  written permission of Adobe.
 *
 * This README file shows how to install JAVA AMF third party library that will allow the LCCS server
 * to invoke http hooks in your Java Application server and your application to receive LCCS real time events 
 * as Adobe Flash AMF packages. 
 *
 *************************************************/

Invoking LCCS server APIs:

There are different AMF application gateways available for Java available from
different vendors. Adobe provides two different products: LiveCycle Data Services and BlazeDS.

This document refers specifically to BlazeDS, but the instructions can easily be
adapted to use LiveCycle Data Services instead.
    
1) Download BlazeDS from http://opensource.adobe.com/wiki/display/blazeds/download+blazeds+3

2) BlazeDS development guide: http://livedocs.adobe.com/blazeds/1/blazeds_devguide/

3) If you have tomcat server setup or any Java application server installation, copy the file blazeds.war
   under your deployment directory. BlazeDS also came with samples.war and you can also copy that
   and use it as an experimental deployment.
   
   Our gateway example was tested under the samples directory.

4) Copy LCCS.jar from serverIntegeration/java to the WEB-INF/lib directory

5) From your application's initialization code create an instance of AccountManager
   and register your HTTP endpoint (note that the URL must be "accessible from the Internet"
   (i.e. not behind a firewall)

	Sequence of calling:
    
	AccountManager am = new AccountManager(meetingurl);
	am.login(username, password);
	am.registerHook(endpoint, token);
	am.subscribeCollection(room, collection);
	
Setting Web Hooks:

1) create an LCCS directory under the blazeds or samples directory.  (e.g. tomcat/webapps/samples/WEB-INF/src/flex/samples/LCCS)

5) copy RTCHOOKS.java from serverIntergration/java  

6) compile RTCHOOKS.java into your WEB_INF/classes directory. You will need the flex-messaging-core.jar
   that comes with the BlazeDS setup:
  
   javac -d WEB-INF/classes/ WEB-INF/src/flex/samples/LCCS/*.java -classpath WEB-INF/lib/LCCS.jar:WEB-INF/lib/flex-messaging-core.jar

7) update remote-config.xml with following: (id="RTCHOOKS" is required)

    <destination id="RTCHOOKS">
        <properties>
            <source>flex.samples.LCCS.RTCHOOKS</source>
        </properties>
    </destination>

    <destination id="LCCS" channels="my-amf">
        <properties>
            <source>com.adobe.rtc.account.AccountManager</source>
        </properties>
    </destination>

   <destination id="MySessionHandler: channels="my-amf">
        <properties>
            <source>flex.samples.LCCS.MySessionHandler</source>
        </properties>
        <adapter ref=java-object/>
    </destination>

   (find all the configuration for AMFEndpoint at WEB_INF/flex directory, e.g. tomcat/webapp/samples/WEB-INF/flex)
    

8) Call AccountManager registerHook with callback url (e.g. hook info: http://<hostname>:8400/samples/messagebroker/amf);
9) Call AccountManager subscribeCollection with collection name you are interested.

 (see code in previous section)

This should be all it takes to create hooks for LCCS using BlazeDS.
Please see the sampleApps/Server2Server/BlazeDSGateway_Java for a more detailed example.



