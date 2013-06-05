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
package com.adobe.rtc.sharedManagers.constants
{
	/**
	 * @private 
	 */
   public class  UserVoiceStatuses
	{
		public static const OFF:String = null;
		public static const ON_SILENT:String = "onSilent";
		public static const ON_SPEAKING:String = "onSpeaking";
				
		public function UserVoiceStatuses():void
		{
			throw new Error("UserVoiceStatuses(): Cannot be instantiated.");
		}
		
		public static function isValidStatus(p_value:String):Boolean
		{
			if(p_value == OFF ||
				p_value == ON_SILENT ||
				p_value == ON_SPEAKING) {
					return true;
				}
				
			return false;
		}
	}
}