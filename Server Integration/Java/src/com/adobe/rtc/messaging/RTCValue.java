package com.adobe.rtc.messaging;

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

import java.util.*;
import java.lang.reflect.*;

import com.adobe.rtc.util.Utils;

public class RTCValue
{
	/** Class to Type */
	private static final Map<Class<?>, String> m_class2type = 
		new HashMap<Class<?>, String>();
	/** Type to Class(String) constructor */
	private static final Map<String, Constructor<String>> m_type2const = 
		new HashMap<String, Constructor<String>>();

	private static final String TYPE_BYTEARRAY = "bytearray";
	private static final String TYPE_ENCODEDSTRING = "b64string";

	static {
		/*
		 * Class to Type
		 */
		m_class2type.put(String.class,  "string");
		m_class2type.put(Boolean.class, "boolean");
		m_class2type.put(Integer.class, "int");
		m_class2type.put(Long.class,    "long");
		m_class2type.put(Double.class,  "double");
		//m_class2type.put(XMLString.class,  "xml");

		/*
		 * Type to Constructor (for Class(String))
		 */
		for (Map.Entry<Class<?>, String> e : m_class2type.entrySet()) {
			Class<?> c = e.getKey();

			try {
				@SuppressWarnings("unchecked")
				Constructor<String> ct = (Constructor<String>) c.getConstructor(String.class);
				m_type2const.put(e.getValue(), ct);
			} catch(NoSuchMethodException ex) {
				// this should not happen
			}
		}
	}

	public String type;
	public String value;

	private RTCValue(String type, String value) {
		this.type = type;
		this.value = value;
	}

	public static RTCValue getValue(Object v, boolean unknownValue)
	{
		return getValue(v, unknownValue, false);
	}

	/**
	 * Convert an object to a type/value pair
	 */
	public static RTCValue getValue(Object v, boolean unknownValue, boolean validXML)
	{
		if (v instanceof String && validXML) {
			try {
				String s = Utils.escapeXML((String) v);
				return new RTCValue("string", s);
			} catch(Exception e) {
				String data = new String(Utils.base64encode(((String) v).getBytes()));
				return new RTCValue(TYPE_ENCODEDSTRING, data);
			}
		}

		String type = m_class2type.get(v.getClass());
		if (null != type)
			return new RTCValue(type, v.toString());

		Class<?> cType = v.getClass().getComponentType();
		if (cType == Byte.TYPE) { // byte array
			String data = new String(Utils.base64encode((byte[]) v));
			return new RTCValue(TYPE_BYTEARRAY, data);
		} 

		else if (unknownValue)
			return new RTCValue(v.getClass().getName(), v.toString());

		else
			return null;
	}

	public static RTCValue encodedStringValue(Object value)
	{
		if (value instanceof String) {
			String data = new String(Utils.base64encode(((String)value).getBytes()));
			return new RTCValue(TYPE_ENCODEDSTRING, data);
		} 
		
		else
			return null;
	}

	/**
	 * Convert a type/value pair to an object of the specified value
	 */
	public static Object getValue(String type, String value, boolean unknownValue)
	{
		if (TYPE_BYTEARRAY.equals(type)) {
			return Utils.base64decode(value);
		} else if (TYPE_ENCODEDSTRING.equals(type)) {
			return new String(Utils.base64decode(value));
		} else {
			try {
				Constructor<String> c = m_type2const.get(type);
				if (null == c)
					if (unknownValue)
						return value;
					else
						return null;

				return c.newInstance(value);
			} catch(Exception e) {
				return null;
			}
		}
	}
}
