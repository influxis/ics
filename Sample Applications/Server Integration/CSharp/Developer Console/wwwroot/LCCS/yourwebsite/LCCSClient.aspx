<%@ Page Language="C#" AutoEventWireup="true" CodeFile="LCCSClient.aspx.cs" Inherits="LCCSClient" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>Account Manager</title>
</head>
<body>
    <form id="accountmanagerform" runat="server">
    
    <div>
   <b>Register Hooks</b> 
   <p><asp:Label id="result" runat="server" /></p>  
    hook url: <asp:TextBox id="hookurl" runat="server"  Text="http://localhost:2337/WebSite1/Gateway.aspx" Width="300"/><br />
    security token:<asp:TextBox id="token" runat="server"  Text="secret12345" Width="300"/><br />
   <asp:Button ID="submit_bt" OnClick="Register_Hook" Text="Submit" runat="server" /> 
    </div>
   <div>
   <br />
   </div> 
   <div>
  <b>Get Hook's Info</b> 
  <p><asp:Label id="result_hookinfo" runat="server" /></p>   
  Retrieve:<asp:Button ID="submit_bt3" OnClick="Get_HookInfo" Text="Submit" runat="server" />
   </div> 
   <div>
   <br />
   </div> 
    <div>
   <b>Subscribe Collection</b> 
   <p><asp:Label id="result2" runat="server" /></p>  
    room name: <asp:TextBox id="roomname" runat="server"  Text="mymeeting" Width="300"/><br />
    collectioname:<asp:TextBox id="collectionname" runat="server"  Text="UserManager" Width="300"/><br />
   <asp:Button ID="submit_bt2" OnClick="Subscribe_Collection" Text="Submit" runat="server" /> 
    </div>
      <div>
   <br />
   </div> 
    <div>
   <br />
   </div> 
    <div>
   <b>UnSubscribe Collection</b> 
   <p><asp:Label id="Label3" runat="server" /></p>  
    room name: <asp:TextBox id="roomname_unsubscribecollection" runat="server"  Text="mymeeting" Width="300"/><br />
    collection name:<asp:TextBox id="collectionname_unsubscribecollection" runat="server"  Text="UserManager" Width="300"/><br />
   <asp:Button ID="Button3" OnClick="UnSubscribe_Collection" Text="Submit" runat="server" /> 
    </div>
      <div>
   <br />
   </div> 
   <div>
   <br />
   </div> 
    <div>
   <b>GetNodeConfigration </b> 
   <p><asp:Label id="Label1" runat="server" /></p>  
    room name: <asp:TextBox id="roomname_getnodeconf" runat="server"  Text="mymeeting" Width="300"/><br />
    collection name:<asp:TextBox id="collectionname_getnodeconf" runat="server"  Text="UserManager" Width="300"/><br />
    node name:<asp:TextBox id="nodename_getnodeconf" runat="server"  Text="UserList" Width="300"/><br /> 
   <asp:Button ID="Button1" OnClick="Get_NodeConfiguration" Text="Submit" runat="server" /> 
    </div>
      <div>
   <br />
   </div> 
   <div>
   <br />
   </div> 
    <div>
   <b>Fetch Items </b> 
   <p><asp:Label id="Label2" runat="server" /></p>  
    room name: <asp:TextBox id="roomname_fetchitems" runat="server"  Text="mymeeting" Width="300"/><br />
    collection name:<asp:TextBox id="collectionname_fetchitems" runat="server"  Text="UserManager" Width="300"/><br />
    node name:<asp:TextBox id="nodename_fetchitems" runat="server"  Text="UserList" Width="300"/><br /> 
   <asp:Button ID="Button2" OnClick="Fetch_Items" Text="Submit" runat="server" /> 
    </div>
      <div>
   <br />
   </div> 
   <div>
   <br />
   </div> 
    <div>
   <b>Create Node </b> 
   <p><asp:Label id="Label5" runat="server" /></p>  
    room name: <asp:TextBox id="roomname_createnode" runat="server"  Text="mymeeting" Width="300"/><br />
    collection name:<asp:TextBox id="collectionname_createnode" runat="server"  Text="UserManager" Width="300"/><br /> 
    node name:<asp:TextBox id="nodename_createnode" runat="server"  Text="MyTestNode" Width="300"/><br /> 
   configuration:
     <table border="1" cellpadding="1">
              <tr>
                  <td>persisItems</td>
                  <td>
                 <asp:RadioButton id="persistItems_configuration_createnode_true" runat="server" GroupName="persistItem" Checked="true" Text="true"></asp:RadioButton>
                <asp:RadioButton id="persistItems_configuration_createnode_false" runat="server" GroupName="persistItem" Text="false"></asp:RadioButton>
                  </td>
              </tr>
               <tr>
                  <td>userDependentItems</td>
                  <td>
                 <asp:RadioButton id="userDependentItems_true" runat="server" GroupName="userDependentItems" Checked="true" Text="true"></asp:RadioButton>
                <asp:RadioButton id="userDependentItems_false" runat="server" GroupName="userDependentItems" Text="false"></asp:RadioButton>
                  </td>
              </tr>
              <tr>
                  <td>publishModel
                    <asp:TextBox id="publishmodel" runat="server"  Text="10" Width="300"/>
                  </td>
              </tr>
               <tr>
                  <td>lazySubscription</td>
                  <td>
                    <asp:RadioButton id="lazySubscription_true" runat="server" GroupName="lazySubscription" Text="true"/>
                    <asp:RadioButton id="lazySubscription_false" runat="server" GroupName="lazySubscription"   Checked="true" Text="false"/>
                  </td>
              </tr>
               <tr>
                  <td>allowPrivateMessages</td>
                   <td>
                     <asp:RadioButton id="allowPrivateMessages_true" runat="server" GroupName="allowPrivateMessages" Text="true"></asp:RadioButton>
                <asp:RadioButton id="allowPrivateMessages_false" runat="server" GroupName="allowPrivateMessages"   Checked="true" Text="false"></asp:RadioButton>
                  </td>
              </tr>
              <tr>
                  <td>modifyAnyItem</td>
                   <td>
                <asp:RadioButton id="modifyAnyItem_true" runat="server" GroupName="modifyAnyItem" Text="true"></asp:RadioButton>
                <asp:RadioButton id="modifyAnyItem_false" runat="server" GroupName="modifyAnyItem"   Checked="true" Text="false"></asp:RadioButton>
                  </td>
              </tr>
              <tr>
                  <td>accessModel
                  <asp:TextBox id="accessModel" runat="server"  Text="20" Width="300"/>
                 </td> 
              </tr>
              <tr>
                  <td>itemStorageScheme
                 <asp:TextBox id="itemStorageScheme" runat="server"  Text="1" Width="300"/> 
               </td>
              </tr>
               <tr>
                  <td>sessionDependentItems</td>
                  <td>
                   <asp:RadioButton id="sessionDependentItems_true" runat="server" GroupName="sessionDependentItems" Text="true"></asp:RadioButton>
                    <asp:RadioButton id="sessionDependentItems_false" runat="server" GroupName="sessionDependentItems"   Checked="true" Text="false"></asp:RadioButton> 
                  </td>
              </tr>
              <tr>
                <td>p2pDataMessaging</td>
                   <td>
                   <asp:RadioButton id="p2pDataMessaging_true" runat="server" GroupName="p2pDataMessaging" Text="true"></asp:RadioButton>
                    <asp:RadioButton id="p2pDataMessaging_false" runat="server" GroupName="p2pDataMessaging"   Checked="true" Text="false"></asp:RadioButton>  
                  </td>
              </tr>
            </table>

    <asp:Button ID="Button5" OnClick="Create_Node" Text="Submit" runat="server" /> 
    </div>
      <div>
   <br />
   </div> 
    <div>
   <br />
   </div> 
    <div>
   <b>Remove Node </b> 
   <p><asp:Label id="Label6" runat="server" /></p>  
    room name: <asp:TextBox id="roomname_removenode" runat="server"  Text="mymeeting" Width="300"/><br />
    collection name:<asp:TextBox id="collectionname_removenode" runat="server"  Text="UserManager" Width="300"/><br /> 
    node name:<asp:TextBox id="nodename_removenode" runat="server"  Text="MyTestNode" Width="300"/><br />      
   <asp:Button ID="Button6" OnClick="Remove_Node" Text="Submit" runat="server" /> 
    </div>
      <div>
   <br />
   </div> 
    <div>
   <br />
   </div> 
    <div>
   <b>Publish Item </b> 
   <p><asp:Label id="Label4" runat="server" /></p>  
    room name: <asp:TextBox id="roomname_publishitem" runat="server"  Text="mymeeting" Width="300"/><br />
    collection name:<asp:TextBox id="collectionname_publishitem" runat="server"  Text="UserManager" Width="300"/><br /> 
    node name:<asp:TextBox id="nodename_publishitem" runat="server"  Text="MyTestNode" Width="300"/><br /> 
    publisher id:<asp:TextBox id="publisherid_publishitem" runat="server"  Text="na2-sdk-f623f25e-c017-4ed3-87e3-00ec2b91a52d" Width="300"/><br /> 
    overwrite:<asp:TextBox id="overwrite_publishitem" runat="server"  Text="true" Width="300"/><br />   
    body text (example):<asp:TextBox id="body_publishitem" runat="server"  Text="This is a publishItem test" Width="300"/><br />   
     
   <asp:Button ID="Button4" OnClick="Publish_Item" Text="Submit" runat="server" /> 
    </div>
      <div>
   <br />
   </div> 
    <div>
   <br />
   </div> 
    <div>
   <b>Retract Item </b> 
   <p><asp:Label id="Label7" runat="server" /></p>  
    room name: <asp:TextBox id="roomname_retractitem" runat="server"  Text="mymeeting" Width="300"/><br />
    collection name:<asp:TextBox id="collectionname_retractitem" runat="server"  Text="UserManager" Width="300"/><br /> 
    node name:<asp:TextBox id="nodename_retractitem" runat="server"  Text="MyTestNode" Width="300"/><br /> 
    itemID:<asp:TextBox id="itemid_retractitem" runat="server"  Text="" Width="300"/><br /> 
    
   <asp:Button ID="Button7" OnClick="Retract_Item" Text="Submit" runat="server" /> 
    </div>
      <div>
   <br />
   </div> 
    <div>
   <br />
   </div> 
    <div>
   <b>Set User Role </b> 
   <p><asp:Label id="Label8" runat="server" /></p>  
    room name: <asp:TextBox id="roomname_setuserrole" runat="server"  Text="mymeeting" Width="300"/><br />
    user id:<asp:TextBox id="userid_setuserrole" runat="server"  Text="" Width="300"/><br /> 
    role:<asp:TextBox id="role_setuserrole" runat="server"  Text="" Width="300"/><br /> 
   
   <asp:Button ID="Button8" OnClick="Set_UserRole" Text="Submit" runat="server" /> 
    </div>
      <div>
   <br />
   </div> 
    </form>
</body>
</html>
