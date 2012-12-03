<%@page pageEncoding="UTF-8"%>

<%@page contentType="text/html; charset=UTF-8" %>

<%@ page import="com.adobe.rtc.account.*" %>
<%@ page import="java.net.URLEncoder" %>

<%!
  String title = "LCCS External Authentication Sample";

  //
  // Enter your authentication details below:
  //
  static String account = "sdkaccount";
  static String room    = "sdkroom";
  static String devuser = "sdkuser";
  static String devpass = "sdkpassword";
  static String secret  = "sdkaccountsharedsecret";
  
  static String host  = "http://connectnow.acrobat.com";
  static String accountURL = host + "/" + account;
  static String roomURL = accountURL + "/" + room;

  static AccountManager am = null;
  static Session authSession = null;

  String user = null;
  String role = null;
  String token = null; 

  String select(int r) {
    return Integer.toString(r).equals(role) ? "selected" : "";
  }
%>

<%
  if (null == am) {
      am = new AccountManager(accountURL);
      am.login(devuser, devpass);
      authSession = am.getSession(room);
  }

  user = request.getParameter("user");
  role = request.getParameter("role");

  if (user != null && role != null) {
    token = authSession.getAuthenticationToken(secret, user, user, Integer.parseInt(role));
  } else {
    user = "bob";
    role = "100";
  }
%>

<html>
  <head>
    <title><%= title %></title>
    <script type="text/javascript">
      function loaded() {
	<%
	  if (token != null) {
        %>
            win = window.open(
              'Flexternal.html?roomURL=<%= URLEncoder.encode(roomURL) %>&authToken=<%= URLEncoder.encode(token) %>',
              '_blank',
              'left=20,top=20,width=800,height=600,toolbar=1,resizable=1');
        <%
	  }
        %>
      }
    </script>
  </head>
  <body onload="loaded()">
    <h2><%= title %></h2>
    <h4>Connecting to room <%= roomURL %></h4>
    <form method="POST">
      <b>User Name</b>
      <input type="text" name="user" value="<%= user %>">
      <b>User Role</b>
      <select name="role">
	<option value="100" <%= select(100) %>>100 - Owner</option>
	<option value="50" <%= select(50) %>>50 - Publisher</option>
	<option value="5" <%= select(5) %>>5 - Guest</option>
	<option value="0" <%= select(0) %>>0 - None</option>
      </select>
      <input type="submit" value="Enter Room"></td>
    </form>
  </body>
</html>
