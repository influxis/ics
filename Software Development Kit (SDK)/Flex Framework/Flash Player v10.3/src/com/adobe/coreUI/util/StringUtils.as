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
package com.adobe.coreUI.util
{
	/**
	 * @private
	 */
   public class  StringUtils extends Object
	{
		
		//takes an HTML string and returns another HTML string
		public static function highLightURLs(p_str:String):String
		{
			if (p_str==null) {
				return null;
			}
			
			//I have to remove all <a href> tags first
			p_str = p_str.replace(/<a href=\".*?\">(.*?)<\/a>/gi, "$1");

			var emailPattern:RegExp = /(\w|[_.\-])+@((\w|-)+\.)+\w{2,4}+/;
			var urlPattern:RegExp = /^((www\.)|((http)s{0,1}:\/\/)).*/;
			var httpExp:RegExp = /(http)s{0,1}:\/\//;

//			var fontPrefix:String = "<font color=\"#0000CC\"><u>";
//			var fontSuffix:String = "</u></font>";
			var fontPrefix:String = "<u>";
			var fontSuffix:String = "</u>";

			var tokens:Array = p_str.split(/\s|\r|\(|\)|\n|\!|,|;|\]|\[|\}|\{|\"|\'|<|>/);
			var newString:String = "";
			var l:uint = tokens.length;
			var currIndex:uint = 0;
			for (var i:uint=0; i<l; i++) {
				var currToken:String = tokens[i];
				currIndex+=currToken.length;
				var currDelimiter:String = p_str.substr(currIndex, 1);

				//parse for emails first
				var emailResult:Object = emailPattern.exec(currToken);
				if (emailResult != null) {
					newString += "<a href=\"mailto:"+currToken+"\">"+fontPrefix+currToken+fontSuffix+"</a>";
					newString+=currDelimiter;
					currIndex++;
					continue;
				} 

				//if no email is found, do the url parsing
				var urlResult:Object = urlPattern.exec(currToken);
				if (urlResult != null) {
					if (httpExp.exec(currToken) != null) {
						newString += "<a href=\""+currToken+"\" target=\"_blank\">"+fontPrefix+currToken+fontSuffix+"</a>";
					} else {
						newString += "<a href=\"http://"+currToken+"\" target=\"_blank\">"+fontPrefix+currToken+fontSuffix+"</a>";
					}
				} else {
					newString += currToken;
				}
				newString+=currDelimiter;
				currIndex++;
			}
			return newString;
		}
		
		public static function isEmpty(p_s:String):Boolean
		{
			return ((p_s == null || p_s.length == 0 || (p_s.replace(/ /g, "").length == 0)));
		}
		
		public static function trim(str:String):String
		{
			if (str == null) return null;
			return str.replace(/^\s*/, '').replace(/\s*$/, '');
		}
	}
}
