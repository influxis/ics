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
	import com.adobe.rtc.session.managers.SessionManagerLocalConnection;
	
	/**
	 * LocalAuthenticator is a development-only authenticator for use with the Local Server tool
	 * which enables offline development of LCCS applications. With the exception of streaming 
	 * components (i.e. Audio and Webcam components), most LCCS components work with the Local Server.
	 * <p>This tool has the following features: </p> 
	 * <ul>
	 * <li>Applications connect automatically to the running server. No configuration is required.
     * <li>All non-streaming components are supported. (excludes Webcam and Audio streaming components). 
     * <li>The room URL is not used and does not need to be changed.
     * <li>Because username and password is not used for authentication, any valid string may be used.
     * <li>The server stores no data, so stopping the server cleans the application of data.
     * <li>All users are treated as hosts.
     * <li>Users can change the roles of others at runtime.
	 * </ul>
	 * 
	 * <h6>Starting the local server</h6>
	 * <img src="../../../../devimages/localconnectionserver.png" alt="Local Connection Server">
	 * <p>
	 * <p>
	 * To use this class replace <code class="property">AdobeHSAuthenticator</code> with <code class="property">LocalAuthenticator</code>. 
	 * Start the local server by opening the LCCS SDK Navigator, selecting the tools tab, and choosing Local
	 * For a working example, see LocalConnection in the SDK's "sampleApps" directory.
	 * 
	 * <p></p>
 	 * <h6>Using LocalAuthenticator to develop applications with the local server tool</h6>
 	 * <listing>
	 * &lt;rtc:LocalAuthenticator id="auth" userName="AnyArbitraryName"  />
	 *	 	&lt;rtc:ConnectSessionContainer id="cSession" authenticator="{auth}" width="100%" height="100%" >
	 *			&lt;mx:VBox width="100%" height="100%" >
	 *				&lt;rtc:Note width="100%" height="100%" />
	 *				&lt;rtc:SimpleChat width="100%" height="100%" />
	 *			&lt;/mx:VBox>
	 * &lt;/rtc:ConnectSessionContainer></listing>
	 * 
	 * 
	 * @see com.adobe.rtc.session.IConnectSession
	 */
	
   public class  LocalAuthenticator extends AbstractAuthenticator
	{
		public function LocalAuthenticator()
		{
			super();
			session_internal::sessionManager = new SessionManagerLocalConnection();
		}
		
	}
}