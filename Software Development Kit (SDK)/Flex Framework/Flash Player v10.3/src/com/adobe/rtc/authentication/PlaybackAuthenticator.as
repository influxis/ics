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
	import com.adobe.rtc.session.managers.SessionManagerPlayback;
	import com.adobe.rtc.util.Base64Encoder;
	
	/**
	 * This class extends AdobeHSAuthenticator and allows only external authentication.
	 * @see com.adobe.rtc.authentication.AdobeHSAuthenticator
	 */

	public class PlaybackAuthenticator extends AdobeHSAuthenticator
	{
		public function PlaybackAuthenticator()
		{			
			super();
			session_internal::sessionManager = new SessionManagerPlayback();			
		}
	
		/**
		 * @private
		 * Archive playback supports external authentication or guest access.
		 */
		override protected function doLogin():void
		{
			//
			// Scenario one: The client provides the authentication key.
			//
			if (authenticationKey != null) 
			{
				onLoginSuccess();
			}	
			//
			// Scenario two: The user is logging in as a guest. Send the guest token to the authentication server.
			//
			else 
			{
				// guest token, just to allow access to Acorn APIs
				var guestId:String = "g:playback";
				
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
	}	
}
