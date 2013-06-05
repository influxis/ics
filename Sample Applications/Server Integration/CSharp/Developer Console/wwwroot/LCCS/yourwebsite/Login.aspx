<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Login.aspx.cs" Inherits="Login" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>LCCS Login</title>
</head>
<body>
    <form id="login" runat="server">
    <div>
        <p><asp:Label id="outputtext" runat="server" /></p> 
        Username: <asp:TextBox id="username" runat="server"  Text="root"/><br />
       Password:<asp:TextBox id="password" TextMode="password" runat="server"  Text="root"/><br />
       Account URL:<asp:TextBox id="account_url" Text="http://localhost:8080/UNDEF-ROOT" runat="server" Width="300" /><br />
       <asp:Button ID="submit_bt" OnClick="loginToServer" Text="Submit" runat="server" />
    </div>
    </form>
</body>
</html>
