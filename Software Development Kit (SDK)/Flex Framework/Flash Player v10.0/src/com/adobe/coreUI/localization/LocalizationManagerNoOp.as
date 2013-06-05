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
package com.adobe.coreUI.localization
{
	import flash.events.EventDispatcher;

	/**
	 * @private
	 */
   public class  LocalizationManagerNoOp extends EventDispatcher implements ILocalizationManager
	{
		public function formatString(p_inStr:String, ...args):String
		{
			return p_inStr;
		}
		
		public function getString(p_inStr:String):String
		{
			return p_inStr;
		}
		
	}
}