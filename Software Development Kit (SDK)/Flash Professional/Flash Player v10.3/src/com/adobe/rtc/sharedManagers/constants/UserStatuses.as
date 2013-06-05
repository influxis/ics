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
   public class  UserStatuses
	{
		public static const NORMAL:String = null;
		public static const RAISING_HAND:String = "raisingHand";
		public static const TOO_FAST:String = "tooFast";
		public static const TOO_SLOW:String = "tooSlow";
		public static const LAUGHTER:String = "laughter";
		public static const APPLAUSE:String = "applause";
		public static const YES:String = "yes";
		public static const NO:String = "no";
		public static const AWAY:String = "away";
		
		public function UserStatus():void
		{
			throw new Error("UserStatus(): Cannot be instantiated.");
		}
		
		public static function isValidStatus(p_value:String):Boolean
		{
			if(p_value == NORMAL ||
				p_value == RAISING_HAND ||
				p_value == TOO_FAST ||
				p_value == TOO_SLOW ||
				p_value == LAUGHTER ||
				p_value == APPLAUSE ||
				p_value == YES ||
				p_value == NO ||
				p_value == AWAY) {
					return true;
				}
				
			return false;
		}
	}
}