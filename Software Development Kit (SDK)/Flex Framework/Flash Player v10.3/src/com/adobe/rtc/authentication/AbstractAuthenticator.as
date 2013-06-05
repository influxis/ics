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
	import com.adobe.rtc.events.AuthenticationEvent;
	import com.adobe.rtc.session.managers.SessionManagerBase;
	
	import flash.events.EventDispatcher;
	
	import mx.core.IMXMLObject;

	/**
	* Dispatched after user log in succeeds.
	*/
	[Event(name="authenticationSuccess", type="com.adobe.rtc.events.AuthenticationEvent")]
	/**
	* Dispatched if user log in fails.
	*/
	[Event(name="authenticationFailure", type="com.adobe.rtc.events.AuthenticationEvent")]
	
	

	/**
	 * Abstract superclass of any LCCS authenticator.
	 * Classes like AdobeHSAuthenticator or LocalAuthenticator extends it.
	 * 
	 * @see com.adobe.rtc.authentication.AdobeHSAuthenticator
	 * @see com.adobe.rtc.authentication.LocalAuthenticator
	 */
	
   public class  AbstractAuthenticator extends EventDispatcher implements IMXMLObject
	{	
		/**
		 * Allows a developer to specify the URL of a LCCS-compatible authentication service; 
		 * it is <strong>not needed</strong> for many applications.
		 */
		public var authenticationURL:String;
		
		/**
		 * When <code class="property">authenticationKey</code> is not used, <code class="property">
		 * userName</code> is required upon room entry; when a someone enters as a guest, the name 
		 * becomes the user's display name.
		 * <p>
		 * Two cases are supported: 
		 * <ul>
		 * <li><strong>userName is supplied with no password</strong>: The user is logged in as 
		 * viewer and <code>UserDescriptor.displayName</code> is set to the value in 
		 * <code class="property">userName</code>.
		 * 
		 * <li><strong>A username and password are supplied</strong>: <code class="property">password</code>
		 * is only provided when members login with Adobe IDs which is an uncommon case. See below.
		 * </ul>
		 */
		public var userName:String;
		
		
		/**
		 * <code class="property">password</code> is only required when Adobe IDs
		 * are used; therefore, it is likely that only developers would need this parameter except
		 * during development. If used, it is supplied in addition to 
		 * <code class="property">userName</code> and permits admitting users as other than a guest. 
		 * Note that while it is possible for registered Adobe service users to use their Adobe ID, 
		 * applications will likely leverage LCCS's external authentication capabilities so that 
		 * <code class="property">authenticationKey</code> would be used in lieu of a username and
		 * password.  
		 * 
		 */
		public var password:String;
		
		/**
		 * For applications that leverage LCCS's external authentication capabilities, <code 
		 * class="property">authenticationKey</code> is used to receive a unique, signed string created from 
		 * the developer's shared secret and the user's username, password, and role. The key enables users 
		 * to exit and return to an existing session without having to re-login. Once a user has logged in to a session, 
		 * the service returns a valid Adobe <code class="property"> authenticationKey</code> that 
		 * can be used in lieu of <code class="property"> userName</code> and <code class="property">
		 * password</code> upon user reentry.
		 * <p>
		 * Note that external authentication allow the developer to manage user credentials on their 
		 * private, existing infrastructure. End users do not need an Adobe ID, and Acrobat.com doesn't 
		 * need any authentication information other then the <code class="property">authenticationKey</code>.
		 * For details about external authentication, refer to the <i>LCCS Developer Guide</i> and the server scripts
		 * the SDK's "extras" directory.</p>
		 */
		public var authenticationKey:String;

		/**
		 * @private
		 */
		session_internal var sessionManager:SessionManagerBase;
		
		/**
		 * @private
		 */
		public function initialized(p_doc:Object, id:String):void
		{
			
		}
		
		/**
		 * <code class="property">isGuest</code> returns whether or not the supplied parameters 
		 * require that the user be admitted as a guest only. For example, 
		 * if no password is set, <code class="property">isGuest</code> returns true.
		 */
		public function get isGuest():Boolean
		{
			return (authenticationKey==null && password==null);
		}

		/**
		 * @private
		 */
		public function canLogin():Boolean
		{
			if (password == null || password == "") // The user is a guest so extra information isn't needed.
				return true;
				
			if (authenticationURL != null) // Get the URL so login can succeed.
				return true;
				
			if (authenticationKey != null) // Get the authentication key so login can succeed.
				return true;
				
			return false;
		}
        
        public function getAuthenticationRequestParameters():String
        {
            return "";
        }
		

		/**
		 * @private
		 * Not needed. . . should likely be internally namespaced
		 */
		public function login():void
		{
			doLogin();
		}
		
		/**
		 * @private
		 */
		protected function doLogin():void
		{
			// OVERRIDE ME!
		}
		
		/**
		 * @private
		 */
		public function logout():void
		{
			doLogout();
		}
		
		/**
		 * @private
		 */
		protected function doLogout():void
		{
			// OVERRIDE ME!
		}
        
		/**
		 * @private
		 */
		protected function onLoginSuccess():void
		{
			// Notify clients of success.
			dispatchEvent(new AuthenticationEvent(AuthenticationEvent.AUTHENTICATION_SUCCESS));
		}
		
		/**
		 * @private
		 */
		protected function onLoginFailure():void
		{
			// Notify the clients that something went wrong.
			if ( hasEventListener(AuthenticationEvent.AUTHENTICATION_FAILURE) ) {
				dispatchEvent(new AuthenticationEvent(AuthenticationEvent.AUTHENTICATION_FAILURE));
			}else {
				throw new Error("Invalid username or password:Login again");
				dispatchEvent(new AuthenticationEvent(AuthenticationEvent.AUTHENTICATION_FAILURE));
			}
		}
		
		/**
		 * @private
		*/
		public function onAuthorizationFailure():void
		{
		   //
		   // Authentication succeeded (the credentials are valid), but authorization failed 
		   // (access is denied). This case is currently treated as an authentication failure.
		   //

		   onLoginFailure();
		}
	}
}
