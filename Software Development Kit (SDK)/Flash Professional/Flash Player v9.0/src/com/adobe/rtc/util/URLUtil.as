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
	 * Stripped down version of com.adobe.rtc.util.URLUtil. 
	 */ 
   public class  URLUtil
	{
		public function URLUtil()
		{
		}
		
		/**
	     *  Converts a potentially relative URL to a fully-qualified URL.
	     *  If the URL is not relative, it is returned as is.
	     *  If the URL starts with a slash, the host and port
	     *  from the root URL are prepended.
	     *  Otherwise, the host, port, and path are prepended.
	     *
	     *  @param rootURL URL used to resolve the URL specified by the <code>url</code> parameter, if <code>url</code> is relative.
	     *  @param url URL to convert.
	     *
	     *  @return Fully-qualified URL.
	     */
	    public static function getFullURL(rootURL:String, url:String):String
	    {
	        if (url != null && !URLUtil.isHttpURL(url))
	        {
	            if (url.indexOf("./") == 0)
	            {
	                url = url.substring(2);
	            }
	            if (URLUtil.isHttpURL(rootURL))
	            {
	                var slashPos:Number;
	
	                if (url.charAt(0) == '/')
	                {
	                    // non-relative path, "/dev/foo.bar".
	                    slashPos = rootURL.indexOf("/", 8);
	                    if (slashPos == -1)
	                        slashPos = rootURL.length;
	                }
	                else
	                {
	                    // relative path, "dev/foo.bar".
	                    slashPos = rootURL.lastIndexOf("/") + 1;
	                    if (slashPos <= 8)
	                    {
	                        rootURL += "/";
	                        slashPos = rootURL.length;
	                    }
	                }
	
	                if (slashPos > 0)
	                    url = rootURL.substring(0, slashPos) + url;
	            }
	        }
	
	        return url;
	    }
	    
		 /**
	     *  Determines if the URL uses the HTTP, HTTPS, or RTMP protocol. 
	     *
	     *  @param url The URL to analyze.
	     * 
	     *  @return <code>true</code> if the URL starts with "http://", "https://", or "rtmp://".
	     */
	    public static function isHttpURL(url:String):Boolean
	    {
	        return url != null &&
	               (url.indexOf("http://") == 0 ||
	                url.indexOf("https://") == 0);
	    }
	}
}