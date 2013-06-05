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
package com.adobe.rtc.util
{
	/**
	 * @private
	 *
	 *
	 *
	 */
   public class  URLParser 
	{		
		public static function getTokenValue(urlStr:String, token:String):String
		{			
			var value:String = null;
			var startIndex:int = urlStr.indexOf(token + "=");
			if(startIndex != -1) {
				var endIndex:int = urlStr.indexOf("&", startIndex);
				if (endIndex == -1) {
					endIndex=urlStr.length;
				}
				value = urlStr.substring(startIndex+token.length+1, endIndex);	
			}
			
			return value;
		}	
		
		public static function appendToken(urlStr:String, token:String, value:String):String
		{
			var newUrl:String = urlStr;
			
			if(token != null && value != null) {
				if(urlStr.indexOf("?") != -1) {
					newUrl = newUrl + "&" + token + "=" + value;
				}
				else {
					newUrl = newUrl + "?" + token + "=" + value;
				}
			}
			return newUrl;
		}	
        
		/**
		 * The older version of the Flash Player (found with 9.0.47)
		 * does not like port numbers even if they are the default
		 * port numbers for the protocol.
		 *
		 * @return <code>inputURL</code> without default port numbers.
		 */
		public static function cleanupURL(urlStr:String):String
		{
		    var l:int = urlStr.length;
	 
				if (urlStr.substr(-1) == "/")
					urlStr = urlStr.substr(0, l-1);
	 
				if (urlStr.substr(0, 5) == "http:"
					&& urlStr.substr(-3) == ":80")
					urlStr = urlStr.substr(0, l-4);
		    
				else if (urlStr.substr(0, 6) == "https:"
					&& urlStr.substr(-4) == ":443")
					urlStr = urlStr.substr(0, l-5);
		    
		    return urlStr;
		}

            private static var URL_PATTERN:RegExp = 
		new RegExp("((\\w+)://([^:/?]+)(:(\\d+))?)?([^?]*)([?](.*))?");

		/**
		 * parse a URL and returns its components
		 *
		 * schema://server:port/path?queryString
		 *
		 * Note: this method doesn't support mailto: or
		 * other URLs not in the form of schema://server
		 */
            public static function parseURL(url:String):Object
            {
                    var parts:Array = url.match(URL_PATTERN);
                    if (parts == null)
			return null;

		    return {
			serverURL: parts[1],
			schema: parts[2],
			server: parts[3],
			port: parts[5],
			path: parts[6],
			queryString: parts[8]
		    };
            }
	}
}
