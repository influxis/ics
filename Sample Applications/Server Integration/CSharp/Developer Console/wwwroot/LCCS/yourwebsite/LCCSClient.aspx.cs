using System;
using System.Data;
using System.Configuration;
using System.Collections;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;
using System.Collections.Generic;
using LCCS;

public partial class LCCSClient : System.Web.UI.Page
{
    AccountManager am;
    protected void Page_Load(object sender, EventArgs e)
    {
        am = (AccountManager)Session["LCCSAccount"] ;
        if (am == null)
        {
            Response.Redirect("Login.aspx");
        }
    }

    protected void Register_Hook(object sender, EventArgs e)
    {
        try
        {
            string tmp = "No Data";
            am.registerHook(hookurl.Text, token.Text);
            tmp = "registered hook on server submitted";
            result.Text = tmp;
        }
        catch (Exception ex)
        {
            result.Text = "registered hook on server failed " + ex.Message;
        }
    }

    protected void Get_HookInfo(object sender, EventArgs e)
    {
        try
        {
            string tmp = "No Data";
            HookInfo info = am.getHookInfo();
            tmp = info.ToString();
            result.Text = tmp;
        }
        catch (Exception ex)
        {
            result.Text = "getHookInfo failed " + ex.Message;
        }

    }

    protected void Subscribe_Collection(object sender, EventArgs e)
    {
        try
        {
            am.subscribeCollection(roomname.Text, collectionname.Text);
            result.Text = "subscribeCollection on server submitted";
        }
        catch (Exception ex)
        {
            result.Text = "subscribeCollection on server failed " + ex.Message;
        }
    }

    protected void UnSubscribe_Collection(object sender, EventArgs e)
    {
        try
        {
            am.unsubscribeCollection(roomname.Text, collectionname.Text);
            result.Text = "UnSubscribeCollection on server submitted";
        }
        catch (Exception ex)
        {
            result.Text = "UnSubscribeCollection on server failed " + ex.Message;
        }
    }

    protected void Get_NodeConfiguration(object sender, EventArgs e)
    {
        try
        {
            string tmp = "";
            Dictionary<string, object> data = am.getNodeConfiguration(roomname_getnodeconf.Text, collectionname_getnodeconf.Text, nodename_getnodeconf.Text);
            IDictionaryEnumerator myEnumerator = data.GetEnumerator();
            while ( myEnumerator.MoveNext() ) {
                tmp += "<br />" + myEnumerator.Key+": "+ myEnumerator.Value;
            }

            result.Text = tmp.Length == 0 ? "No Data": tmp;
      
        }
        catch (Exception ex)
        {
            result.Text = "Get NodeConfiguration on server failed " + ex.Message;
        }
    }

    protected void Fetch_Items(object sender, EventArgs e)
    {
        string tmp="";
        List<Dictionary<string, object>> data = ( List<Dictionary<string, object>>)am.fetchItems(roomname_fetchitems.Text, collectionname_fetchitems.Text, nodename_fetchitems.Text);
        IEnumerator myEnumerator = data.GetEnumerator();
        while ( myEnumerator.MoveNext() ) {
                tmp += "<br/>Item:<br/>";
                Dictionary<string, object> data2 = (Dictionary<string, object>)myEnumerator.Current;
                IDictionaryEnumerator myEnumerator2 = data2.GetEnumerator();
                while (myEnumerator2.MoveNext())
                {
                    tmp += "<br />" + myEnumerator2.Key + ": " + myEnumerator2.Value;
                }
         }

         result.Text = tmp.Length == 0 ? "No Data" : tmp;
    }

    protected void Create_Node(object sender, EventArgs e)
    {
        try
        {
            Dictionary<string, object> configuration = new Dictionary<string, object>();
            configuration.Add("persistItems", persistItems_configuration_createnode_true.Checked ? true : false);
            configuration.Add("userDependentItems", userDependentItems_true.Checked ? true : false);
            configuration.Add("publishmodel", int.Parse(publishmodel.Text.Trim()));
            configuration.Add("lazySubscription", lazySubscription_true.Checked? true: false);
            configuration.Add("allowPrivateMessages", allowPrivateMessages_true.Checked ? true : false);
            configuration.Add("modifyAnyItem", modifyAnyItem_true.Checked ? true : false);
            configuration.Add("accessModel", int.Parse(accessModel.Text.Trim()));
            configuration.Add("itemStorageScheme", int.Parse(itemStorageScheme.Text.Trim()));
            configuration.Add("sessionDependentItems", sessionDependentItems_true.Checked ? true : false);
            configuration.Add("p2pDataMessaging", p2pDataMessaging_true.Checked ? true : false);

            am.createNode(roomname_createnode.Text, collectionname_createnode.Text, nodename_createnode.Text, configuration);
            result.Text = "Create Node on server submitted";
        }
        catch (Exception ex)
        {
            result.Text = "Create Node on server failed " + ex.Message;
        }
    }

    protected void Remove_Node(object sender, EventArgs e)
    {
        try
        {
            am.removeNode(roomname_removenode.Text, collectionname_removenode.Text, nodename_removenode.Text);
            result.Text = "Remove Node on server submitted";
        }
        catch (Exception ex)
        {
            result.Text = "Remove Node on server failed " + ex.Message;
        }
    }


    protected void Publish_Item(object sender, EventArgs e)
    {
        try
        {
            Dictionary<string, object>itemVO = new Dictionary<string,object>();
            itemVO.Add("publisherID", publisherid_publishitem.Text);
            Dictionary<string, object>msg = new Dictionary<string,object>();
            msg.Add("msg", body_publishitem.Text);
            itemVO.Add("body", msg);
            bool overwrite = false;
            if (overwrite_publishitem.Text.Equals("true", StringComparison.OrdinalIgnoreCase))
                overwrite = true;

            am.publishItem(roomname_publishitem.Text, collectionname_publishitem.Text, nodename_publishitem.Text, itemVO, overwrite);
            result.Text = "Publish Item on server submitted";
        }
        catch (Exception ex)
        {
            result.Text = "Publish Item on server failed " + ex.Message;
        }
    }

    protected void Retract_Item(object sender, EventArgs e)
    {
        try
        {
            am.retractItem(roomname_retractitem.Text, collectionname_retractitem.Text, nodename_retractitem.Text, itemid_retractitem.Text);
            result.Text = "Retract Item on server submitted";

        }catch (Exception ex)
        {
            result.Text = "Retract Item on server failed " + ex.Message;
        }
    }

    protected void Set_UserRole(object sender, EventArgs e)
    {
        try
        {
            am.setUserRole(roomname_setuserrole.Text, userid_setuserrole.Text, int.Parse(role_setuserrole.Text));
            result.Text = "Set User Role on server submitted";

        }catch (Exception ex)
        {
            result.Text = "Set User Role on server failed " + ex.Message;
        }
    }

}
