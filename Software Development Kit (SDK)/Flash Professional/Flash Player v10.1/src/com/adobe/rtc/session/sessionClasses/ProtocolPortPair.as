/*
*
* ADOBE CONFIDENTIAL
* ___________________
*
* Copyright 2009 Adobe Systems Incorporated
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
package com.adobe.rtc.session.sessionClasses
{	
	/**
	 * @private
	 * Use this little object to pass protocol/port pairs to FMSConnector.
	 * 
	 */
   public class  ProtocolPortPair extends Object
	{
		//include "../core/Version.as";
		
		/**
		 * @default "rtmp"
		 */
		public var protocol:String = "rtmp";

		/**
		 * @default 1935
		 */
		public var port:Number = 1935;
		
		/**
		 * Pass the protocol (for instance "rtmp" or "rtmpt" or "rtmps") and the port number (for instance 1935, 443, 80)
		 * to create the pair.
		 * 
		 * @author Peldi Guilizzoni
		 */
		function ProtocolPortPair(p_proto:String, p_port:Number):void
		{
			protocol = p_proto;
			port = p_port;
		}		
	}
}