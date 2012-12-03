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
package com.adobe.rtc.events
{
	import flash.events.Event;
	/**
	 * Event class sent by com.adobe.rtc.authentication classes (such as AdobeHSAuthenticator) to indicate 
	 * login success or failure.
	 * 
	 * @see com.adobe.rtc.authentication.AdobeHSAuthenticator
	 */
	
   public class  AuthenticationEvent extends Event
	{
		/**
		 * Event sent to indicate login success.
		 */
		public static const AUTHENTICATION_SUCCESS:String = "authenticationSuccess";

		/**
		 * Event sent to indicate login failure.
		 */
		public static const AUTHENTICATION_FAILURE:String = "authenticationFailure";
		
		public function AuthenticationEvent(p_type:String)
		{
			super(p_type);
		}

		/**
		 * @private
		 */
		public override function clone():Event
		{
			return new AuthenticationEvent(type);
		}		

	}
}