package flex.samples.LCCS;

import com.adobe.rtc.account.*;
import flex.messaging.FlexContext;
import flex.messaging.FlexSession;

public class MySessionHandler {

	private FlexSession mySession;
	
	public MySessionHandler()
	{
		
	}
	
	public void createLCCSAccountManager(String url) throws Exception
	{
		AccountManager am = new AccountManager(url);	
		mySession= FlexContext.getFlexSession();
		mySession.setAttribute("LCCS", am);	
	}

	public boolean login(String username, String password) throws Exception
	{
		AccountManager am = (AccountManager)FlexContext.getFlexSession().getAttribute("LCCS");
		return am.login(username, password);
	}

	public void registerHook(String endpoint, String token) throws Exception
	{
		AccountManager am = (AccountManager)FlexContext.getFlexSession().getAttribute("LCCS");
                am.registerHook(endpoint, token);
	}
	
	public String getHookInfo() throws Exception
        {
                AccountManager am = (AccountManager)FlexContext.getFlexSession().getAttribute("LCCS");
				HookInfo myhookinfo = am.getHookInfo();
				if (myhookinfo != null)
					return myhookinfo.toString();
			
                return "";
        }
	public void subscribeCollection(String room, String collection) throws Exception
	{
		AccountManager am = (AccountManager)FlexContext.getFlexSession().getAttribute("LCCS");
                am.subscribeCollection(room, collection);
	}

}
