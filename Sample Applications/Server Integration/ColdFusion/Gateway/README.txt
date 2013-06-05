/************************************************
* Adobe LCCS 2010
* Server To Server ColdFusion Interface and Example
* Version 1.0
*
* The example shows how to use LCCS Server to Server API to invoke LCCS commands.  It also shows how to receive messages coming from LCCS room.
*
* following is the list of actions it can perform 
* 1) login  (e.g. http://<hostname>/samples/LCCS/LCCS.html)
* 2) register hook 
* 3) subscribe collection 
*
* To recieve room notifications:
*  When events are recieved, RTCHOOKS.java will print out those message via standard output. 
* 
* To get more information on the LCCS HTTP Server to Server API, visit ****
*************************************************/

Setup procedure:

1) This version of Server To Server works with any version of ColdFusion server that support flash remoting and java object invokation.

2) copy LCCS.jar from serverIntegration/java in your ColdFusion class path(e.g. wwwroot/WEB-INF/lib). Or you can map the java under the ColdFusion Admin Java and JVM menu classpath.

3) create LCCS directory under your webroot (e.g. wwwroot/LCCS) and copy application.cfm, login.cfm and LCCSClient.cfm to this directory.

4) To improve performance, create AccountManager object and store in sessoin object (e.g. <cfset Session.accountmanager = createObject("java", "com.adobe.rtc.account.AccountManager").init(accounturl)>)

5) run login.cfm from your webbrowser and specify your LCCS account information and account url.  

6) You are ready to invoke LCCS actions (e.g.  login, registerhook, gethookinfo, subscribecollection, createnode etc.) from LCCSClient.cfm

AccountManager APIs:

* login
* registerhook
* gethookinfo
* subscribecollection
* createnode

setup hook:
1) add RTCHOOKS.cfc in the same directory as login.cfm and AccountManager.cfm (can change directory-in webroot subdirectory, but need to update config xml below)
(LCCS.RTCHOOKS translate to wwwroot/LCCS/RTCHOOKS.cfc)

 WARNING: RTCHOOKS.cfc has example code embedded, it is different from the RTCHOOKS.cfc file under 
   the serverIntegration/coldfusion directory which is a more generic interface (do not use this copy, use the copy from the example directory)


update WEB-INF/flex/remoting-config.xml

	<destination id="RTCHOOKS">
                <channels>
                        <channel ref="my-cfamf"/>
                </channels>
                <properties>
                <source>LCCS.RTCHOOKS</source>
                <!-- define the resolution rules and access level of the cfc being invoked -->
                <access>
                <!-- Use the ColdFusion mappings to find CFCs, by default only CFC files under your webroot can be found. -->
                        <use-mappings>false</use-mappings>
                        <!-- allow "public and remote" or just "remote" methods to be invoked -->
                        <method-access-level>remote</method-access-level>
                </access>
                <property-case>
                        <!-- cfc property names -->
                        <force-cfc-lowercase>false</force-cfc-lowercase>
                        <!-- Query column names -->
                        <force-query-lowercase>false</force-query-lowercase>
                        <!-- struct keys -->
                        <force-struct-lowercase>false</force-struct-lowercase>
                </property-case>
                </properties>

        </destination>

2) invoke above register hook with hook url (e.g. "http://<coldfusionserver>/flex2gateway/").  If you want to change this url you need to update the channels within services-config.xml and remoting-config.xml files. 
(currently this LCCS hook use default remoting channel of "my-cfamf")

3) In case of logging issues, log in to the coldfusion administrative panel and see your logging properties.You might need to update some logging parameters based on your default settings. You should see the logs in LCCS.log file under logs folder.
