/*
*
* ADOBE CONFIDENTIAL
* ___________________
*
* Copyright [2007-2010] Adobe Systems Incorporated
* All Rights Reserved.
*
* NOTICE:  All information contained herein is, and remains
* the property of Adobe Systems Incorporated and its suppliers,
* if any.  The intellectual and technical concepts contained
* herein are proprietary to Adobe Systems Incorporated and its
* suppliers and are protected by trade secret or copyright law.
* Dissemination of this information or reproduction of this material
* is strictly forbidden unless prior written permission is obtained
* from Adobe Systems Incorporated.
*/
package com.adobe.rtc.authentication
{
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.session.managers.SessionManagerAdobeHostedServices;
	import com.adobe.rtc.util.DebugUtil;
	
	import flash.events.*;
	import flash.net.*;
	
	import mx.utils.Base64Encoder;
	
	/**
	 * 
	 * AdobeHSAuthenticator is used to log users into a LCCS hosted room with the 
	 * requisite parameters for the given log in scenario. When you supply this component 
	 * to an IConnectSession's <code class="property">authenticator</code> property, 
	 * the IConnectSession manages the rest.
	 * 
	 * AdobeHSAuthenticator takes one of the following sets of input parameters depending on 
	 * how the user is logging in. There are several possible scenarios: 
	 * <ul>
	 * <li><strong>The application is under development</strong>: Required parameters: <code class="property">
	 * userName</code> and <code class="property">password</code>. Developers may find it expedient
	 * to hard code their Adobe ID during development and testing so that their application 
	 * will communicate directly with the service. In this case, pass the Adobe ID username, password, and
	 * the room's URL. It should be obvious that authentication details should never be hard coded anywhere, 
	 * including deployed SWFs. See <b>Example 1</b> below for a simple development-only use case.
	 * 	
	 * <li><strong>Users log in as a guest</strong>: Required parameter: 
	 * <code class="property">userName</code>. Users may only want to enter as a guest or the developer 
	 * may want to limit room members to a guest role. In this case, only <code class="property">username</code>
	 * is required, and that name is used only as a display name. For more information on managing guest users,
	 * see the <code>autoPromote()</code> and <code>guestsHaveToKnock()</code> in the RoomManager class.

	 * <li><b>Users authenticate via external authentication</b>: Required parameter: <code class="property">
	 * authenticationKey</code>. In most production scenarios, developers will want automatically authenticate 
	 * users on their organization's existing systems. Production LCCS applications are usually designed to 
	 * rely on external authentication mechanisms so that their client users do not have to 
	 * have an Adobe ID, so the developer can leverage existing infrastructure, and so they can take advantage
	 * of a host of other benefits as described in the <i>LCCS Developer Guide</i>. See <b>Example 2</b> below. 
 	 * </ul> 
	 *
	 * <blockquote>
     * <b>Note</b>: It's possible to develop offline without a connection to the LCCS service. Simply 
	 * change <code>rtc:AdobeHSAuthenticator</code> to <code>rtc:LocalAuthenticator</code> and use any 
	 * arbitrary username. Then start the SDK's LocalConnectionServer.air and your applications will automatically
	 * detect the local server. For details, refer to the <i>LCCS Developer Guide</i> or the 
	 * LocalConnectionServer demo in the SDK's examples directory.
	 * </blockqoute><p></p>
	 * 
 	 * <h6>Example 1: Simple, development-only authentication</h6>
 	 *	<listing>
	 * &lt;rtc:AdobeHSAuthenticator 
	 * 			// Deployed applications DO NOT hard code username and password here.
	 * 			userName="AdobeIDusername&#64;example.com" 
	 * 			password="AdobeIDpassword" 
	 * 			id="auth"/&gt;	
	 *  &lt;session:ConnectSessionContainer 
	 * 			roomURL="http://connect.acrobat.com/exampleAccount/exampleRoom" 
	 * 			authenticator="{auth}"&gt;
	 * 			&lt;pods:WebCamera width="100%" height="100%"/&gt;
	 * &lt;/session:ConnectSessionContainer&gt;</listing>
	 * 
	 * <blockquote>
	 * <b>Note</b>: For more information about external authentication, refer to the 
	 * <i>LCCS Developer Guide</i> and the scripts in the SDK's "extras/scripts" directory. 
	 * <b>Example 2</b> assumes that <code class="properties">authenticationKey</code> and 
	 * <code class="properties">roomURL</code> are being passed to the SWF via <code>flashvars</code>.
	 * </blockquote>
	 * 
	 * <h6>Example 2: Production authentication method using external authentication</h6>
	 * <listing>
	 * &lt;mx:Script&gt;
  	 * &lt;![CDATA[
  	 *  		[Bindable]
  	 *		private var roomURL:String;
  	 *		[Bindable]
  	 * 		// Use external authentication to create a property to authenticationKey.
  	 *		private var authToken:String;
     *  
  	 *  		private function init():void {
  	 *			roomURL = Application.application.parameters["roomURL"];
  	 * 			// authToken is created by the developer's server from the developer's 
  	 * 			// shared secret as well as the users's authentication information.
  	 *			authToken = Application.application.parameters["authToken"];  		
  	 *			cSession.login();	
  	 * 		}
  	 *  	]]&gt;
  	 * &lt;/mx:Script&gt; 
  	 * // Pass the authToken to authenticationKey.
  	 * &lt;rtc:AdobeHSAuthenticator authenticationKey="{authToken}" id="auth"/&gt;</listing>
	 * 
	 * @see com.adobe.rtc.session.IConnectSession
	 * @see com.adobe.rtc.messaging.UserRoles
	 * @see com.adobe.rtc.sharedManagers.descriptors.UserDescriptor
	 * @see com.adobe.rtc.sharedManagers.RoomManager#autoPromote
	 * @see com.adobe.rtc.sharedManagers.RoomManager#guestsHaveToKnock
	 * 
	 */
	
   public class  AdobeHSAuthenticator extends AbstractAuthenticator
	{
		public function AdobeHSAuthenticator()
		{
			session_internal::sessionManager = new SessionManagerAdobeHostedServices();
		}
		
		override public function getAuthenticationRequestParameters():String
		{
			//
			// Trick the server to drop the current session and return the authenticatio URL.
			//
			// This is an half baked authentication token, good enough to invalidate the current session,
			// but not good enough to allow access.
			//
			return "glt=g:";	
		}
		
		/**
		 * @private
		 */
		override protected function doLogin():void
		{
			//
			// Scenario one: The client provides the authentication key.
			//
			if (authenticationKey != null) {
				onLoginSuccess();
			}
			
			//
			// Scenario two: Send the username and password to the authentication server.
			//
			else if (password != null) {
				var req:URLRequest = new URLRequest(authenticationURL);
				req.method = URLRequestMethod.POST;
				req.contentType = "text/xml";
				req.data = <request>
							<username>{userName}</username>
							<password>{password}</password>
						</request>;
				var loader:URLLoader = new URLLoader();
				loader.addEventListener(Event.COMPLETE, onComplete);
				loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
				loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onStatus);			
				try {
			    	loader.load(req);
				} catch (error:Error) {
					onLoginFailure();
				}
			} 
			
			//
			// Scenario three: The user is logging in as a guest. Send the username to the authentication server.
			//
			else {
				var guestId:String = "g:" + userName + ":" /* + email */;
				
				if (false) {
					// in clear
					authenticationKey="glt=" + guestId;
				}
				
				else {			
					// base64 encoded
					var encoder:Base64Encoder = new Base64Encoder();
					encoder.encodeUTFBytes(guestId);
					authenticationKey="guk=" + encoder.flush().replace(/[\n\r ]/g, "").replace(/\+/g, "%2B");
				}
				
				onLoginSuccess();
			}
		}

		/**
		 * @private
		 */
		override protected function doLogout():void
		{
            //
            // If userName is null, external authentication is being used so don't touch authenticationKey.
            // If userName is not null, make the authenticationKey null and reauthenticate on login.
            //
            if (userName != null)
                authenticationKey = null;
        }
        
		/**
		 * @private
		 */
		protected function onComplete(event:Event):void {
			DebugUtil.debugTrace("authentication request complete");

			var result:XML = XML(event.target.data);
			if (result.@status != "ok") {
				DebugUtil.debugTrace("authentication error");
				DebugUtil.debugTrace(result);
				onLoginFailure();
			}
			
			else {
				var encoder:Base64Encoder = new Base64Encoder();
				var authToken:String = result.authtoken.toString();
				encoder.encodeUTFBytes(authToken);
				authenticationKey="gak=" + encoder.flush().replace(/[\n\r ]/g, "").replace(/\+/g, "%2B");
				onLoginSuccess();
			}
		}

		/**
		 * @private
		 */
		protected function onStatus(event:HTTPStatusEvent):void {
			DebugUtil.debugTrace("authentication status: " + event.status);
			
			if ((event.status < 200 || event.status >= 300) && event.status!=0) { // real error
				onLoginFailure();			
			}
		}
		
		/**
		 * @private
		 */
		protected function onError(event:Event):void {
			DebugUtil.debugTrace("authentication request error:" + event);
			onLoginFailure();
		}
	}
}
