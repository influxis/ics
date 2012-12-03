package com.adobe.rtc.util;

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
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.net.HttpURLConnection;
import java.net.URL;
import java.text.*;
import java.util.*;
import java.util.regex.*;

import javax.xml.parsers.*;

import org.xml.sax.SAXException;
import org.xml.sax.helpers.*;


import org.w3c.dom.DOMImplementation;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.ls.DOMImplementationLS;

/**
 * Utility methods
 */
public class Utils {

	public static boolean DEBUG = false;

	public static void setDebug(boolean value) {
		DEBUG = value;
	}

	public static InputStream http_get(String url, Map<String, String> headers) 
	throws Exception
	{

		if (DEBUG) {
			System.out.println("http_get: " + url);
			if (headers != null)
				System.out.println(headers);
		}

		URL req = new URL(url);
		HttpURLConnection connection = (HttpURLConnection) req.openConnection();

		if (headers != null) {
			for (Map.Entry<String, String> header : headers.entrySet()) 
				connection.addRequestProperty(header.getKey(), header.getValue());
		}

		int responseCode = connection.getResponseCode();

		if (responseCode == 200) {

			if (Utils.DEBUG) {
				System.out.println("Content-Type: " +  connection.getContentType());
				System.out.println("Content-Length: " +  connection.getContentLength());
			}

			return connection.getInputStream();

		} else if (responseCode == 302) {

			if (Utils.DEBUG)
				System.out.println("Redirecting to " + connection.getHeaderField("Location"));

			return http_get(connection.getHeaderField("Location"), headers);

		} else {

			if (Utils.DEBUG) {
				System.out.println("HTTP error " + responseCode);
				System.out.println(connection.getContent());
			}

			throw new Exception("GET " + url + " failed with status " + responseCode);
		}
	}

	public static InputStream http_post(String url, String data, Map<String, String> headers)
	throws Exception
	{
		if (Utils.DEBUG) {
			System.out.println("http_post: " + url + " " + data);
			if (headers != null)
				System.out.println(headers);
		}

		URL req = new URL(url);
		HttpURLConnection connection = (HttpURLConnection) req.openConnection();

		if (headers != null) {
			for (Map.Entry<String, String> header : headers.entrySet()) 
				connection.addRequestProperty(header.getKey(), header.getValue());
		}

		connection.setRequestMethod("POST");
		connection.setDoOutput(true);
		Writer writer = new OutputStreamWriter(connection.getOutputStream());
		writer.write(data);
		writer.flush();
		writer.close();
		connection.connect();

		int responseCode = connection.getResponseCode();

		if (responseCode == 200) {

			if (Utils.DEBUG) {
				System.out.println("Content-Type: " +  connection.getContentType());
				System.out.println("Content-Length: " +  connection.getContentLength());
			}

			return connection.getInputStream();

		} else if (responseCode == 302) {

			if (Utils.DEBUG)
				System.out.println("Redirecting to " + connection.getHeaderField("Location"));

			return http_post(connection.getHeaderField("Location"), data, headers);

		} else {

			if (Utils.DEBUG) {
				System.out.println("HTTP error " + responseCode);
				System.out.println(connection.getContent());
			}

			throw new Exception("POST " + url + " failed with status " + responseCode);
		}

	}

	public static String hexString(byte[] bytes) {
		StringBuilder sb = new StringBuilder();

		for (byte b : bytes) {
			String x = Integer.toString((b >= 0 ? b : 256 + b), 16);
			if (x.length() == 1)
				sb.append("0");
			sb.append(x);
		}

		return sb.toString();
	}

	private static String base64code = 
		  "ABCDEFGHIJKLMNOPQRSTUVWXYZ" 
		+ "abcdefghijklmnopqrstuvwxyz" 
		+ "0123456789" + "+/";

	private static byte getPadded(byte b[], int i) {
		return i < b.length ? b[i] : 0;
	}

	private static int getBase64(byte c) {
		if (c >= 'A' && c <= 'Z')
			return (int)c - (int)'A';
		if (c >= 'a' && c <= 'z')
			return (int)c - (int)'a' + 26;
		if (c >= '0' && c <= '9')
			return (int)c - (int)'0' + 52;
		if (c == '+')
			return 62;
		if (c == '/')
			return 63;
		
		return 0;
	}

	public static String base64encode(String s) {
		return base64encode(s.getBytes());
	}

	public static String base64encode(byte b[]) {
		StringBuilder encoded = new StringBuilder();
		int padding = (3 - (b.length % 3)) % 3;
		for (int i = 0; i < b.length; i += 3) {
			int j = (getPadded(b, i) << 16) + (getPadded(b, i + 1) << 8) + getPadded(b, i + 2);
			encoded.append(base64code.charAt((j >> 18) & 0x3f));
			encoded.append(base64code.charAt((j >> 12) & 0x3f));
			encoded.append(base64code.charAt((j >> 6) & 0x3f));
			encoded.append(base64code.charAt((j >> 0) & 0x3f));
		}

		encoded.replace(encoded.length() - padding, encoded.length(),
				"==".substring(0, padding));

		return encoded.toString();
	}

	public static byte[] base64decode(String s) {
		return base64decode(s.getBytes());
	}
	
	public static byte[] base64decode(byte[] b) {
		if ((b.length % 4) != 0)
			throw new RuntimeException("invalid base64 array: length=" + b.length);

		int l = b.length / 4 * 3;

		if (b[b.length - 1] == '=')
			l--;
		if (b[b.length - 2] == '=')
			l--;

		byte[] result = new byte[l];
		int ri = 0;

		for (int i=0; i < b.length; i += 4) {
			int v = (getBase64(b[i+0]) << 18)
			      | (getBase64(b[i+1]) << 12) 
			      | (getBase64(b[i+2]) << 6) 
			      | (getBase64(b[i+3]) << 0);

			result[ri++] = (byte) ((v >> 16) & 0xFF);
			if (ri >= result.length)
				break;

			result[ri++] = (byte) ((v >> 8) & 0xFF);
			if (ri >= result.length)
				break;

			result[ri++] = (byte) ((v >> 0) & 0xFF);
			if (ri >= result.length)
				break;
		}

		return result;
	}

	@SuppressWarnings("deprecation")
	public static Element parseXML(String xmldata) throws Exception
	{
		return parseXML(new java.io.StringBufferInputStream(xmldata));
	}

	public static Element parseXML(InputStream input)
		throws Exception
	{
		try {
			DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
			factory.setNamespaceAware(false);
			
			if (DEBUG && input.markSupported())
				input.mark(10240);
			
			Document doc = factory.newDocumentBuilder().parse(input);
			return doc.getDocumentElement();
		} catch(Exception e) {
			if (DEBUG) {
				if (input.markSupported())
					input.reset();
				
				byte[] buffer = new byte[10240];
				int l = input.read(buffer);
				if (l > 0)
					System.out.println("input: " + new String(buffer, 0, l));
				
				e.printStackTrace(System.out);
			}
			return null;
		}
	}

	@SuppressWarnings("deprecation")
	public static void parseFile(String xmldata, DefaultHandler handler)
		throws Exception
	{
		parseXML(new java.io.StringBufferInputStream(xmldata), handler);
	}

	public static void parseXML(InputStream input, DefaultHandler handler)
		throws Exception
	{
		SAXParserFactory factory = SAXParserFactory.newInstance();
		factory.setValidating(false);
		factory.setNamespaceAware(false);

		SAXParser parser = factory.newSAXParser();
		
		try {
			if (DEBUG && input.markSupported())
				input.mark(10240);
			
			parser.parse(input, handler);
		} catch(SAXException e) {
			if (DEBUG) {
				if (input.markSupported())
					input.reset();
				
				byte[] buffer = new byte[10240];
				int l = input.read(buffer);
				if (l > 0)
					System.out.println("input: " + new String(buffer, 0, l));
				
				e.printStackTrace(System.out);
			}
			throw new RTCError(e.getMessage());
		}
	}

	public static String printXML(Element root) throws Exception
	{
		DocumentBuilder builder = 
			DocumentBuilderFactory.newInstance().newDocumentBuilder();
		DOMImplementation impl = builder.getDOMImplementation();
		DOMImplementationLS ls = (DOMImplementationLS) impl.getFeature("LS", "3.0");
		return ls.createLSSerializer().writeToString(root);
	}

	public static String getElementValue(Element root, String name) throws Exception {
		try {
			return root.getElementsByTagName(name).item(0).getTextContent();
		} catch(Exception e) {
			if (DEBUG) {
				System.out.println("element: " + name);
				System.out.println(printXML(root));
			}
			
			throw e;
		}
	}
	
	public static long getElementValueLong(Element root, String name) throws Exception {
		String value = getElementValue(root, name).trim();
		if (value.length()==0 || "null".equalsIgnoreCase(value))
			return 0;
		
		if ("unlimited".equalsIgnoreCase(value))
			return Long.MAX_VALUE;
		
		try {
			return Long.parseLong(value);
		} catch(Exception e) {
			if (DEBUG)
				System.out.println(value + ": cannot converto to long");
			
			return 0;
		}
	}
	
	public static Date getElementValueDate(Element root, String name) throws Exception {
		String value = getElementValue(root, name).trim();
		if (value.length()==0 || "null".equalsIgnoreCase(value))
			return null;
		
		try {
			//return DateFormat.getDateTimeInstance().parse(value);
			SimpleDateFormat df = new SimpleDateFormat("EEE MMM dd HH:mm:ss z yyyy");
			return df.parse(value);
		} catch(Exception e) {
			if (DEBUG)
				System.out.println(value + ": cannot converto to Date");

			return null;
		}
	}

		/* valid XML characters:
		 * #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]
		 */
	private static Pattern INVALID_XML_PATTERN =
		Pattern.compile("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F\\uD800-\\uDFFF\\uFFFE\\uFFFF]");
	
	public static String escapeXML(String value) throws Exception
	{
		if (value == null)
			return null;

		if (INVALID_XML_PATTERN.matcher(value).find())
			throw new Exception("invalid-xml-character");

		return value.replaceAll("&", "&amp;").replaceAll("<", "&lt;");
	}
}
