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
using LCCS;

public partial class Login : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {

    }

    protected void loginToServer(object sender, EventArgs e)
    {
        try
        {
            AccountManager am = new AccountManager(account_url.Text);
            bool res = am.login(username.Text, password.Text);

            if (res == true)
            {
                Session["LCCSAccount"] = am;
                Response.Redirect("LCCSClient.aspx");
            }
            else
            {
                outputtext.Text = "login failed";
            }

        }
        catch (Exception ex)
        {
            LCCS.Utils.printException(ex);
            throw new Error(ex.Message);
        }
    }
}
