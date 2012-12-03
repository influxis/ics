/************************************************
* Adobe LCCS 2010-2011
* Server To Server ColdFusion Interface and Example
* Version 1.0
*
* This release aims at providing server to server integration with Adobe LCCS solution.
*
* This README file shows how to install Adobe ColdFusion third party library that will allow LCCS server
* to invoke http hooks on your ColdFusion Application server and allowing your ColdFusion application to receive LCCS real time events         
* as Adobe Flash AMF packages.  It also demonstrate how your ColdFusion application invoking LCCS server APIs.
*
* To get more information on the LCCS HTTP Server to Server API, visit ****
*************************************************/

Invoking LCCS server APIs:

1) This version of Server To Server works with any version of ColdFusion server that support flash remoting and java object invocation.

2) copy LCCS.jar from serverIntegration/java in your ColdFusion class path(e.g. wwwroot/WEB-INF/lib). Or you can map the java under the ColdFusion Admin Java and JVM menu classpath.

3) create session persistence for LCCS account manager (e.g. add session management in application.cfm)

4) Create AccountManager object and store in session object (e.g. <cfset Session.accountmanager = createObject("java", "com.adobe.rtc.account.AccountManager").init(accounturl)>)

5) You are ready to invoke LCCS actions (e.g.  login, registerhook, gethookinfo, subscribecollection, createnode etc.)

	Sequence of calling:
	<cfset Session.accountmanager = createObject("java", "com.adobe.rtc.account.AccountManager").init(accounturl)>
	<cfset result = Session.accountManager.login(username, password)>
	<cfset result = Session.accountManager.registerHook(Form.hookurl, Form.hookurltoken)>
	<cfset result = Session.accountManager.subscribeCollection(Form.roomname, Form.collectionname)>



Setting Web Hooks:

1) Create LCCS directory under the web root (e.g. wwwroot/LCCS) add RTCHOOKS.cfc in the same directory (can change directory-in webroot subdirectory, but need to update config xml below)
(LCCS.RTCHOOKS translate to wwwroot/LCCS/RTCHOOKS.cfc)

update WEB-INF/flex/remoting-config.xml as below

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

