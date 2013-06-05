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
	 * @private
	 * This event is thrown by the com.adobe.rtc.addin.AddinLauncher class.
	 * 
	 * 
	 */
	
   public class  AddInLauncherEvent extends Event
	{
		public static const LAUNCH:String = "launch";
		public static const FAIL:String = "fail";
		public static const STOP:String = "stop";
		
		/**
		 * in case of a LAUNCH event, this variable holds the version of the addin that was launched.<br/>
		 * in case of a FAIL event, this can be null if no addin is installed or it can hold the version 
		 * of the addin that was downloaded (you'll get a FAIL if the downloaded version is < minVersion)
		 */
		public var version:String;
		
		public function AddInLauncherEvent(p_type:String, p_version:String="")
		{
			super(p_type);
			if (p_version!="") {
				version = p_version;
			}
		}
		
		/**
		 * @private
		 */
		override public function toString():String
		{
			var s:String = super.toString();
			return s + ".version="+version;
		}
		
		override public function clone():Event
		{
			return new AddInLauncherEvent(type, version);
		}
	}
}