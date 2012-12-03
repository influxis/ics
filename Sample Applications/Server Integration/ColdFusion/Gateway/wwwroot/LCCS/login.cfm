<h1>LCCS Login</h1>
  <cflock timeout="5" throwontimeout="No" type="exclusive" scope="session">
        <cfset tmp = StructDelete(Session, "isLogIn")>
  </cflock>

<cfform name="loginform" id="loginform" action="LCCSClient.cfm" method="post">
User Name:  <cfinput type="text" name="username" value="root" required="yes"><br>
Password:  <cfinput type="password" name="password" value="root" required="yes"><br>
Room URL:  <cfinput type="text" name="roomurl" value="https://<servername>/<accountname>/<roomname>" size="100" required="yes"><br>
<cfinput type="hidden" name="formaction" value="login">
<cfinput type="Submit" name="submitbt">
</cfform>

