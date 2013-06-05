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
import java.util.Map;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import org.w3c.dom.Element;

import com.adobe.rtc.util.RTCError;
import com.adobe.rtc.messaging.UserRoles;
import com.adobe.rtc.util.Utils;

/**
 * Authentication Session
 * 
 * @author Raffaele Sena
 */
public class Session {

	public String instance;
	public String account;
	public String room;
	private String secret;

	protected Session(String instance, String account, String room) {

		this.instance = instance.replaceAll("#room#", room);
		this.account = account;
		this.room = room;
	}

	/**
	 * Get an external authentication token for a user
	 * 
	 * @param accountSecret account secret (from DevPortal)
	 * @param name user name
	 * @param id user ID
	 * @param role user role
	 * @return external authentication token as HTTP request parameter
	 * @throws Exception
	 * @see UserRoles
	 */
	public String getAuthenticationToken(String accountSecret, String name, String id, int role) throws Exception {
		if (role < UserRoles.NONE || role > UserRoles.OWNER)
			throw new RTCError("invalid-role");

		String token = "x:" + name + "::" + this.account 
		+ ":" + id + ":" + this.room + ":" + Integer.toString(role);
		String signed = token + ":" + sign(accountSecret, token);

		// unencoded
		//String ext = "ext=" + signed;

		// encoded
		String ext = "exx=" + Utils.base64encode(signed);

		return ext;
	}

	/**
	 * Return the RTC service userID
	 * 
	 * @param id application user ID
	 * @return service userID
	 */
	public String getUserID(String id) {
		return ("EXT-" + this.account + "-" + id).toUpperCase();
	}

	protected void getSecret(String baseURL, String authToken, Map<String,String> authHeaders) throws Exception {
		InputStream data = Utils.http_get(baseURL + "app/session?instance=" + this.instance + "&" + authToken, authHeaders);

		Element response = Utils.parseXML(data);
		if (response == null)
			throw new RTCError("bad-response");

		if (Utils.DEBUG) System.out.println(Utils.printXML(response));

		Element secret = (Element) response.getElementsByTagName("session-secret").item(0);
		if (secret == null)
			throw new RTCError(Utils.printXML(response));

		this.secret = secret.getTextContent().trim();
	}

	protected void invalidate(String baseURL, String authToken, Map<String,String> authHeaders) throws Exception {
		String data = "action=delete&instance=" 
			+ this.instance + "&" + authToken;
		InputStream res = Utils.http_post(baseURL + "app/session", data, authHeaders);

		if (Utils.DEBUG) {
			Element response = Utils.parseXML(res);
			System.out.println(Utils.printXML(response));
		}

		this.instance = null;
		this.account = null;
		this.room = null;
		this.secret = null;
	}

	private String sign(String acctSecret, String data) throws Exception {
		String bigSecret = acctSecret + ":" + this.secret;
		SecretKeySpec sk = new SecretKeySpec(bigSecret.getBytes(), "HmacSHA1");
		Mac mac = Mac.getInstance("HmacSHA1");

		mac.init(sk);
		byte[] hmac = mac.doFinal(data.getBytes());
		return Utils.hexString(hmac);
	}
}
