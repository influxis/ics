<h1>LCCS AccountManager</h1>
<body>
<cfif not isDefined("Session.isLogIn") and IsDefined("Form.username") and Form.formaction eq "login">
	 <!--- configure your account here --->
    	<cfset accounturl="#Form.roomurl#">
    	<cfset username="#Form.username#">
    	<cfset password="#Form.password#">

    <cftry>
      <!--- initialize account object --->
      <cfset Session.accountManager = createObject("java", "com.adobe.rtc.account.AccountManager").init(accounturl)>
      <cfcatch>
        <cfoutput>Cannot connect to account #accounturl#</cfoutput>
        <br/>
        <cfoutput>type: #cfcatch.Type#</cfoutput>
        <br/>
        <cfoutput>message: #cfcatch.Message#</cfoutput>
        <br/>
        <cfoutput>detail: #cfcatch.Detail#</cfoutput>
        <br/>
        <cfabort>
      </cfcatch>
    </cftry>

    <cftry>
      <!--- login (with developer credentials --->
      <cfset result = Session.accountManager.login(username, password)>

      <cfif result equal "YES">
	<cfset Session.isLogIn=true>
      <cfelse>
	<cflock timeout="5" throwontimeout="No" type="exclusive" scope="session">
	<cfset tmp = StructDelete(Session, "isLogIn")>
	<cfset tmp = StructDelete(Session, "accountManager")>
	</cflock>
	<cflocation url="login.cfm">
      </cfif>
      <cfcatch>
        <cfoutput>Cannot login to account #accounturl#</cfoutput>
        <br/>
        <cfoutput>type: #cfcatch.Type#</cfoutput>
        <br/>
        <cfoutput>message: #cfcatch.Message#</cfoutput>
        <br/>
        <cfoutput>detail: #cfcatch.Detail#</cfoutput>
        <br/>
        <cfabort>
      </cfcatch>
    </cftry>

</cfif>

<cfif isDefined("Session.isLogIn") and Session.isLogIn equal true>
	<cfif Form.formaction eq "registerhook">
		<cftry>		
		<cfset result = Session.accountManager.registerHook(Form.hookurl, Form.hookurltoken)>
		<cfoutput> registerHook result: successful</cfoutput>
		<cfcatch>
			<cfoutput> registerHook result: failed</cfoutput>
			<br/>
			        <cfoutput>type: #cfcatch.Type#</cfoutput>
        		<br/>
        			<cfoutput>message: #cfcatch.Message#</cfoutput>
        		<br/>
        			<cfoutput>detail: #cfcatch.Detail#</cfoutput>
        		<br/>
        		<cfabort>
		</cfcatch>
		</cftry>
	<cfelseif Form.formaction eq "gethookinfo">
		<cftry>		
		<cfset result = Session.accountManager.getHookInfo()>
		<cfoutput>endpoint: #result.endpoint#<br></cfoutput>
		<cfoutput>token: #result.token#</cfoutput>
		<cfcatch>
			<cfoutput> getHookInfo failed</cfoutput>
			<br/>
			        <cfoutput>type: #cfcatch.Type#</cfoutput>
        		<br/>
        			<cfoutput>message: #cfcatch.Message#</cfoutput>
        		<br/>
        			<cfoutput>detail: #cfcatch.Detail#</cfoutput>
        		<br/>
        		<cfabort>
		</cfcatch>
		</cftry>
	<cfelseif Form.formaction eq "subscribecollection">
		<cftry>		
		<cfset result = Session.accountManager.subscribeCollection(Form.roomname, Form.collectionname)>
		<cfoutput>Subscribe Collection: sucessful</cfoutput>
		<cfcatch>
			<cfoutput> Subscribe Collection failed</cfoutput>
			<br/>
			        <cfoutput>type: #cfcatch.Type#</cfoutput>
        		<br/>
        			<cfoutput>message: #cfcatch.Message#</cfoutput>
        		<br/>
        			<cfoutput>detail: #cfcatch.Detail#</cfoutput>
        		<br/>
        		<cfabort>
		</cfcatch>
		</cftry>
	<cfelseif Form.formaction eq "createnode">
		<cftry>		
      		<cfset configuration = createObject("java", "com.adobe.rtc.messaging.NodeConfiguration").init()>
		<cfset configuration.persistItems = Form.persistItems>
		<cfset configuration.userDependentItems= Form.userDependentItems>
		<cfset configuration.publishModel = Form.publishModel>
		<cfset configuration.lazySubscription = Form.lazySubscription>
		<cfset configuration.allowPrivateMessages = Form.allowPrivateMessages>
		<cfset configuration.modifyAnyItem= Form.modifyAnyItem>
		<cfset configuration.accessModel= Form.accessModel>
		<cfset configuration.itemStorageScheme= Form.itemStorageScheme>
		<cfset configuration.sessionDependentItems= Form.sessionDependentItems>
		<cfset configuration.p2pDataMessaging= Form.p2pDataMessaging>


		<cfset Session.accountManager.createNode(Form.roomname, Form.collectionname, Form.nodename, configuration)>
		<cfoutput>Create Node Success</cfoutput>
		<cfcatch>
			<cfoutput> Create Node failed</cfoutput>
			<br/>
			        <cfoutput>type: #cfcatch.Type#</cfoutput>
        		<br/>
        			<cfoutput>message: #cfcatch.Message#</cfoutput>
        		<br/>
        			<cfoutput>detail: #cfcatch.Detail#</cfoutput>
        		<br/>
        		<cfabort>
		</cfcatch>
		</cftry>
	</cfif>

		<br>
		<br>

	<b>register hook:</b><br>
	<cfform name="registerHook" action="LCCSClient.cfm">
		hook url:  <cfinput type="text" name="hookurl" value="http://<coldfusionserver>/flex2gateway/" size="50" required="yes"><br>
		token:  <cfinput type="text" name="hookurltoken" value="secret12345" required="yes"><br>
		<cfinput type="hidden" name="formaction" value="registerhook">
		<cfinput type="Submit" name="submitbt">
	</cfform>
	<b>gethookinfo:</b><br>
	<cfform name="getHookInfo" action="LCCSClient.cfm">
		<cfinput type="hidden" name="formaction" value="gethookinfo">
		<cfinput type="Submit" name="submitbt">
	</cfform>
	
	<b>subscribe collection:</b><br>
	<cfform name="subscribecollection" action="LCCSClient.cfm">
		room name:  <cfinput type="text" name="roomname" value="myfirstroom" size="50" required="yes"><br>
		collection name:  <cfinput type="text" name="collectionname" value="UserManager" required="yes"><br>
		<cfinput type="hidden" name="formaction" value="subscribecollection">
		<cfinput type="Submit" name="submitbt">
	</cfform>
	<b>Create Node:</b><br>
	<cfform name="createnode" action="LCCSClient.cfm">
		room name:  <cfinput type="text" name="roomname" value="myfirstroom" size="50" required="yes"><br>
		collection name:  <cfinput type="text" name="collectionname" value="UserManager" required="yes"><br>
		node name:  <cfinput type="text" name="nodename" value="MySillyNode" required="yes"><br>
		<b>configuration: </b><br>
		persistitems: <cfinput type="text" name="persistitems" value="true" required="yes"><br>
		userdependentitems: <cfinput type="text" name="userdependentitems" value="false" required="yes"><br>
		publishmodel: <cfinput type="text" name="publishmodel" value="10" required="yes"><br>
		lazySubscription: <cfinput type="text" name="lazySubscription" value="false" required="yes"><br>
		allowPrivateMessages: <cfinput type="text" name="allowPrivateMessages" value="false" required="yes"><br>
		modifyAnyItem: <cfinput type="text" name="modifyAnyItem" value="false" required="yes"><br>
		accessModel: <cfinput type="text" name="accessModel" value="100" required="yes"><br>
		itemStorageScheme: <cfinput type="text" name="itemStorageScheme" value="1" required="yes"><br>
		sessionDependentItems: <cfinput type="text" name="sessionDependentItems" value="false" required="yes"><br>
		p2pDataMessaging: <cfinput type="text" name="p2pDataMessaging" value="false" required="yes"><br>
			
		
		<cfinput type="hidden" name="formaction" value="createnode">
		<cfinput type="Submit" name="submitbt">
	</cfform>

</cfif>
