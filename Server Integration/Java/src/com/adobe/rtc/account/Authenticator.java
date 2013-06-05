package com.adobe.rtc.account;

/*
 *  $File$ $Revision$ $Date$
 *
 *  ADOBE SYSTEMS INCORPORATED
 *    Copyright 2007 Adobe Systems Incorporated
 *    All Rights Reserved.
 *
 *  NOTICE: Adobe permits you to use, modify, and distribute this file in accordance with the 
 *  terms of the Adobe license agreement accompanying it.  If you have received this file from a 
 *  source other than Adobe, then your use, modification, or distribution of it requires the prior 
 *  written permission of Adobe.
 */

import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;

import org.w3c.dom.Element;

import com.adobe.rtc.util.*;

/**
 * Authenticator - generate RTC authentication tokens
 */
public class Authenticator
{
	private String authURL;

	protected Authenticator(String url) {
		authURL = url;
	}

	/*
	 * Get an AFCS authentication token give login and password.
	 */
	public String login(String user, String pw, Map<String, String> retHeaders)
	throws Exception 
	{
		Map<String, String> headers = new HashMap<String, String>();
		headers.put("Content-Type", "text/xml");

		String data = "<request><username>" + user + "</username>"
		+ "<password>" + pw + "</password></request>";

		InputStream resp = Utils.http_post(authURL,data,headers);

		//if (Utils.DEBUG) System.out.println(resp);

		Element result = Utils.parseXML(resp);
		if (result == null)
			throw new RTCError("bad-response");

		if ("ok".equals(result.getAttribute("status"))) {
			Element authtoken = (Element) result.getElementsByTagName("authtoken").item(0);
			if ("COOKIE".equals(authtoken.getAttribute("type"))) {
				retHeaders.put("Cookie", authtoken.getTextContent().trim());
				return null;
			} else {
				String gak = Utils.base64encode(authtoken.getTextContent().trim());
				return "gak=" + gak;
			}
		} else {
			throw new RTCError(Utils.printXML(result));
		}
	}

	/*
	 * Get a guest authentication token.
	 */
	public String guestLogin(String user) {
		String guk = Utils.base64encode("g:" + user);
		return "guk=" + guk;
	}
}
