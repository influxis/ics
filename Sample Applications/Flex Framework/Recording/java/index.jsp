<%@page pageEncoding="UTF-8"%>

<%@page contentType="text/html; charset=UTF-8" %>

<%@ page import="com.adobe.rtc.account.*" %>
<%@ page import="java.net.URLEncoder" %>

<%!
  String title = "LCCS Archive Playback Sample";

  //
  // Enter your authentication details below:
  //
  static String account = "sdkaccount";
  static String devuser = "sdkuser";
  static String devpass = "sdkpassword";
  static String secret  = "sdkaccountsharedsecret";
  
  static String host  = "http://localhost:8080";
      
  static String accountURL = host + "/" + account;

  static AccountManager am = null;
  static Session authSession = null;

  String roomURL = null;
  String room = null;
  String user = null;
  String token = null; 
  String archiveID = null;
%>

<%
  if (null == am) {
      am = new AccountManager(accountURL);
      am.login(devuser, devpass);
  }

  room = request.getParameter("room");
  user = request.getParameter("user");
  archiveID = request.getParameter("archiveID");
  
  if (room != null && null != archiveID) {
      roomURL = accountURL + "/" + room;
      String archive = room + '/' + archiveID;
      authSession = am.getSession(archive);
  }
  
  if (authSession != null && user != null) {
    token = authSession.getAuthenticationToken(secret, user, user, Integer.parseInt("10"));
  } else {
    room = "myfirstroom";  
    user = "bob";  
    archiveID = "__defaultArchive__";
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
              'Playback.html?roomURL=<%= URLEncoder.encode(roomURL) %>&authToken=<%= URLEncoder.encode(token) %>&archiveID=<%= URLEncoder.encode(archiveID) %>',
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
    <h4>Playback archive</h4>
    <form method="POST">
      <b>Room</b>
      <input type="text" name="room" value="<%= room %>">
      <b>User Name</b>
      <input type="text" name="user" value="<%= user %>">
      <b>Archive</b>
      <input type="text" name="archiveID" value="<%= archiveID %>"> 
      <input type="submit" value="Launch playback"></td>
    </form>
  </body>
</html>
