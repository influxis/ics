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


import java.io.*;
import java.util.*;
import java.lang.reflect.Method;
import javax.servlet.ServletException;
import javax.servlet.http.*;

import flex.messaging.io.*;
import flex.messaging.io.amf.*;

/**
 * A simple servlet that decodes AMF requests for "RTCHOOKS" notifications.
 *
 * <h3>Usage:</h3>
 * <ol>
 *   <li>
 *     Subclass this servlet
 *   </li>
 *   <li>
 *     Override RTCHOOKS receive* methods
 *   </li>
 *   <li>
 *     Deploy LCCS.jar, lib/flex-messaging*.jar and your servlet in a web application
 *   </li>
 *   <li>
 *     Register your servlet endpoint using AccountManager.registerHook
 *   </li>
 * </ol>
 */
public class RTCServlet extends HttpServlet
{
	/**
	 * Enable debug messages. Default true
	 */
    protected boolean DEBUG = false;

	/**
	 * Default serialization context
	 */
    protected SerializationContext context = new SerializationContext();

	/**
	 * Process HTTP requests and invoke AMF remoting parser
	 */
    @Override
    final protected void service(
	HttpServletRequest request, 
	HttpServletResponse response) throws ServletException, IOException
    {
	String method = request.getMethod();
	String type = request.getContentType();
	int length = request.getContentLength();

	try {
	    if (!"POST".equals(method))
		throw new Exception("invalid-method:" + method);

            if (length <= 0)
		throw new Exception("no-data");

	    if (type == null || !type.endsWith("-amf"))
		throw new Exception("invalid-content-type:" + type);

	    byte buf[] = new byte[length];

	    int lRead = request.getInputStream().read(buf);
	    if (lRead != length)
		throw new Exception("not-enough-data");
	    
	    processBuffer(buf);
	    response.setStatus(HttpServletResponse.SC_OK);
	} catch(Exception e) {
	    debug("ERROR: " + e);
	    response.sendError(HttpServletResponse.SC_BAD_REQUEST);
	}
    }

    public RTCServlet() {
	//
	// prepare primitive to wrapper map
	//
	primitiveToWrapper.put(boolean.class, Boolean.class);
	primitiveToWrapper.put(char.class, Character.class);
	primitiveToWrapper.put(byte.class, Byte.class);
	primitiveToWrapper.put(short.class, Short.class);
	primitiveToWrapper.put(int.class, Integer.class);
	primitiveToWrapper.put(long.class, Long.class);
	primitiveToWrapper.put(float.class, Float.class);
	primitiveToWrapper.put(double.class, Double.class);

	//
	// prepare methods map (assume we don't have overloaded methods
	//
	for (Method m : this.getClass().getMethods())
	    methods.put(m.getName(), m);
    }

    private static Map<Class, Class> primitiveToWrapper = new HashMap<Class, Class>();
    private static Map<String, Method> methods = new HashMap<String, Method>();

    private boolean isAssignable(Class<?> lhs, Object rhs)
    {
	// null is assignable to any non-primitive type
	if (rhs==null)
	    return ! lhs.isPrimitive();

	// privitive types are not assignable to wrapper types (why?)
	// fix it!
	if (lhs.isPrimitive())
	    lhs = primitiveToWrapper.get(lhs);

	Class<?> c = rhs.getClass();
	return (lhs.isAssignableFrom(c) || c.isAssignableFrom(lhs));
    }

	/**
         * Process AMF request and execute commands
         */
    public void processBuffer(byte buf[]) throws Exception
    {
	AbstractAmfInput parser = new Amf0Input(context);
	parser.setInputStream(new ByteArrayInputStream(buf));

	int version = parser.readUnsignedByte();
	int client = parser.readUnsignedByte();
	int nHeaders = parser.readUnsignedShort();
	int nMessages = parser.readUnsignedShort();

	if (version != 0)
	    throw new Exception("invalid-version:" + version);

	if (nHeaders != 0)
	    throw new Exception("unexpected-header");

	for (int i=0; i < nMessages; i++) {
	    String target = parser.readUTF();
	    String resp = parser.readUTF();
	    int messageLength = parser.readInt();
	    Object message = parser.readObject();

	    if (message == null)
	      throw new Exception("null-message");

            if (! message.getClass().isArray())
	      throw new Exception("invalid-message-type");

            if (!target.startsWith("RTCHOOKS."))
	      throw new Exception("invalid-method:" + target);

	    Method m = methods.get(target.substring(9));
	    if (m == null)
	      throw new Exception("invalid-method:" + target);

	    Class<?> argsTypes[] = m.getParameterTypes();
	    Object args[] = (Object[]) message;
	    
	    if (argsTypes.length != args.length)
	      throw new Exception("invalid-parameters-count:" + target);

	    for (int j=0; j < args.length; j++) {
	      if (!isAssignable(argsTypes[j], args[j])) {
		if (argsTypes[j] == String.class) // everything is assignable to String
		  args[j] = args[j].toString();

		else if (argsTypes[j] == int.class && args[j] instanceof Number)
		  args[j] = (Object) ((Number)args[j]).intValue();

		else {
		  if (DEBUG) debug("not assignable: " + argsTypes[j] + "=" + args[j]);
	          throw new Exception("invalid-parameters:" + target);
		}
	      }
	    }

	    if (DEBUG)
	    	debug("invoking " + m.getName() + " " + Arrays.toString(args));

	    m.invoke(this, args);
	}
    }

    /**
     * Print debug message.
     *
     * By default this method uses the standard HttpServlet.log method.
     * Override to print on a different destination.
     */
    public void debug(String message)
    {
	log(message);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////

	/**
	 * Override to process RTCHOOKS.receiveNode
	 */
    public void receiveNode(String token, String roomName, String collectionName, String nodeName, Map config) {
	debug("receiveNode: " + token + " " + roomName + " " + collectionName + " " + nodeName);
    }

	/**
	 * Override to process RTCHOOKS.receiveNodeConfiguration
	 */
    public void receiveNodeConfiguration(String token, String roomName, String collectionName, String nodeName, Map config) {
	debug("receiveNodeConfiguration: " + token + " " + roomName + " " + collectionName + " " + nodeName);
    }
	
	/**
	 * Override to process RTCHOOKS.receiveNodeDeletion
	 */
    public void receiveNodeDeletion(String token, String roomName, String collectionName, String nodeName) {
	debug("receiveNodeDeletion: " + token + " " + roomName + " " + collectionName + " " + nodeName);
    }

	/**
	 * Override to process RTCHOOKS.receiveUserRole
	 */
    public void receiveUserRole(String token, String roomName, String collectionName, String nodeName, String userID, int role) {
	debug("receiveUserRole: " + token + " " + roomName + " " + collectionName + " " + nodeName + " " + userID + " " + role);
    }
	
	/**
	 * Override to process RTCHOOKS.receiveItem
	 */
    public void receiveItem(String token, String roomName, String collectionName, Map itemObj) {
	debug("receiveItem: " + token + " " + roomName + " " + collectionName);
    }

	/**
	 * Override to process RTCHOOKS.receiveItemRetraction
	 */
    public void receiveItemRetraction(String token, String roomName, String collectionName, String nodeName, Map itemObj) {
	debug("receiveItemRetraction: " + token + " " + roomName + " " + collectionName + " " + nodeName);
    }
}
