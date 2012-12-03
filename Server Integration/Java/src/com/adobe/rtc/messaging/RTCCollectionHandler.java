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
import org.xml.sax.*;
import org.xml.sax.helpers.*;

public class RTCCollectionHandler extends DefaultHandler
{
    private enum State { 
	START,
	PARTIAL_START,
	RESULT,
	REPOSITORY,
	ROOT_NODE,
	ROOT_COLLECTION,
        NODES,
	NODE, 
	COLLECTION, 
	CONFIGURATION, 
	FIELD, 
	ITEMS,
	ITEM,
	PROPERTY,
	VALUE_COMPOSITE,
	VALUE_ITEM,
	VALUE
    };

    class Context {

	public State state;
	public Object data;
	public String id;
	public String type;
	public boolean autoPop;

	Context(State state, Object data, String id, String type)
	{
	    this.state = state;
	    this.data = data;
	    this.id = id;
	    this.type = type;
	    this.autoPop = false;
	}

	public Map<String, Object> getMap()
	{
		@SuppressWarnings("unchecked")
		Map<String, Object> map = (Map<String, Object>) data;
		return map;
	}

	public ArrayList<Object> getArray()
	{
		@SuppressWarnings("unchecked")
		ArrayList<Object> arr = (ArrayList<Object>) data;
		return arr;
	}

	public void addValue(Object v)
	{
	        if (state == State.VALUE_ITEM) {
		    int i = Integer.parseInt(id);
		    ArrayList<Object> arr = getArray();
		    if (i < arr.size())
		    	arr.set(i, v);
		    else
		    	arr.add(i, v);
	        } else {
	    	    getMap().put(id, v);
		}
	}
    }
	

    private State m_initialState;
    private State m_partialState;
    private String m_root;
    private Stack<Context> m_context = new Stack<Context>();
    private Map<String, Object> m_result;
    private StringBuilder m_value = new StringBuilder();

	/**
	 * Constructor for full repository
	 */
    protected RTCCollectionHandler(Map<String, Object> result)
    {
	this(result, "PersistenceRepository");
    }

    protected RTCCollectionHandler(Map<String, Object> result, String root)
    {
	m_initialState = State.START;
	m_root = root;
	m_result = result;
    }

	/**
	 * Constructor for partial repository
	 */
    private RTCCollectionHandler(Map<String, Object> result, State state, String root)
    {
	m_initialState = State.PARTIAL_START;
	m_partialState = state;
	m_root = root;
	m_result = result;
    }

	/**
	 * Get a parser for <result>
	 */
    public static RTCCollectionHandler getResult(Map<String, Object> result, String root) {
	return new RTCCollectionHandler(result, State.RESULT, root);
    }

	/**
	 * Get a parser for <item>
	 */
    public static RTCCollectionHandler getItemHandler(Map<String, Object> result, String root) {
	return new RTCCollectionHandler(result, State.ITEMS, root);
    }

	/**
	 * Get a parser for <configuration>
	 */
    public static RTCCollectionHandler getConfigurationHandler(Map<String, Object> result, String root) {
	return new RTCCollectionHandler(result, State.COLLECTION, root);
    }

    private void checkElement(String ele, String expected)
	throws SAXException
    {
    	if (! ele.equals(expected)) 
	    throw new SAXException("expected " + expected + ", got " + ele);
    }

    private String getAttribute(Attributes attrs, String name)
	throws SAXException
    {
	String value = attrs.getValue(name);
	if (null == value)
	    throw new SAXException("expected attribute " + name);

	return value;
    }

    private String getAttribute(Attributes attrs, String name, String defaultValue)
	throws SAXException
    {
	String value = attrs.getValue(name);
	if (null == value)
	    return defaultValue;

	return value;
    }

    @SuppressWarnings("unused")
	private String getAttributes(Attributes attrs)
        throws SAXException
    {
        StringBuilder sb = new StringBuilder();
        int n = attrs.getLength();

	for (int i=0; i < n; i++) {
	  sb.append(' ').append(attrs.getQName(i))
	    .append('=').append(attrs.getValue(i));
	}

        return sb.toString();
    }

    // this state needs to be "popped" automatically
    // when found
    private Context pushStateAutoPop(State state, Object data)
    {
	pushState(state, data, null, null);
	Context curr = m_context.peek();
	curr.autoPop = true;
        return curr;
    }

    private void pushState(State state, Object data)
    {
	pushState(state, data, null, null);
    }

    private void pushState(State state)
    {
	Context curr = m_context.peek();
    	pushState(state, curr.data, curr.id, curr.type);
    }

    private void pushStateId(State state, String id)
    {
	Context curr = m_context.peek();
    	pushState(state, curr.data, id, null);
    }

    private void pushStateType(State state, String type)
    {
	Context curr = m_context.peek();
    	pushState(state, curr.data, curr.id, type);
    }

    private void pushState(State state, Object data, String id, String type)
    {
    	m_context.push(new Context(state, data, id, type));
    }

    public void startDocument()
    {
    	pushState(m_initialState, null, null, null);
    }

    public void endDocument()
    {
    	@SuppressWarnings("unused")
    	Context ctx = m_context.pop();
    }
  
    public void startElement(
    	String uri,
	String localName,
	String qName,
	Attributes attributes)
  	throws SAXException
    {
  	Context ctx = m_context.peek();
	Map<String, Object> map;
	String value;

	switch(ctx.state)
	{
	case START:
	    checkElement(qName, m_root);
	    pushState(State.REPOSITORY, m_result);
	    break;

	case PARTIAL_START:
	    checkElement(qName, m_root);
	    pushState(m_partialState, m_result);
	    break;

	case RESULT:
	    if ("status".equals(qName)) {
		String code = getAttribute(attributes, "code");
		if (!"ok".equals(code)) {
			String subcode = getAttribute(attributes, "subcode");
	    		throw new SAXException(subcode==null ? "status-" + code : code + "-" + subcode);
		}

	        pushState(State.RESULT);
		break; // wait for collection
	    }

	    checkElement(qName, "collections");
	    pushState(State.REPOSITORY);
	    break;


	case REPOSITORY:
	    checkElement(qName, "node");
	    value = getAttribute(attributes, "id");
	    map = new HashMap<String, Object>();
	    ctx.getMap().put(value, map);
	    pushState(State.ROOT_NODE, map);
	    break;

	case ROOT_NODE:
	    checkElement(qName, "collection");
	    pushState(State.ROOT_COLLECTION);
	    break;

	case ROOT_COLLECTION:
	    if ("configuration".equals(qName)) {
	        map = new HashMap<String, Object>();
	        ctx.getMap().put("configuration", map);
	    	pushState(State.CONFIGURATION, map);
                break;
	    }

	    else if ("nodes".equals(qName)) {
	        map = new HashMap<String, Object>();
	        ctx.getMap().put("nodes", map);
	    	pushState(State.NODES, map);
                break;
	    }

	    else { 
                // old repositores had node(s) directly under collection
	        checkElement(qName, "node");
	        map = new HashMap<String, Object>();
	        ctx.getMap().put("nodes", map);
	    	ctx = pushStateAutoPop(State.NODES, map);

                // continue to NODES
            }

	case NODES:
	    checkElement(qName, "node");
	    value = getAttribute(attributes, "id");
	    map = new HashMap<String, Object>();
	    ctx.getMap().put(value, map);
	    pushState(State.NODE, map);
	    break;

	case NODE:
	    checkElement(qName, "collection");
	    pushState(State.COLLECTION);
	    break;

	case COLLECTION:
	    if ("configuration".equals(qName)) {
	        map = new HashMap<String, Object>();
	        ctx.getMap().put("configuration", map);
	    	pushState(State.CONFIGURATION, map);
	    }

	    else if ("items".equals(qName)) {
	        map = new HashMap<String, Object>();
	        ctx.getMap().put("items", map);
	    	pushState(State.ITEMS, map);
	    }

	    else
	    	throw new SAXException("expected configuration/items, got " + qName);
	    break;

	case CONFIGURATION:
	    checkElement(qName, "field");
	    value = getAttribute(attributes, "var");
	    pushStateId(State.FIELD, value);
	    break;

	case FIELD:
	    checkElement(qName, "value");
	    value = getAttribute(attributes, "type", "string");
	    m_value.setLength(0);
	    pushStateType(State.VALUE, value);
	    break;

	case ITEMS:
	    checkElement(qName, "item");
	    value = getAttribute(attributes, "id");
	    map = new HashMap<String, Object>();
	    if (value.length() == 0) {
		// report error
	    }  else {
	        ctx.getMap().put(value, map);
            }
	    pushState(State.ITEM, map);
	    break;

	case ITEM:
	    checkElement(qName, "property");
	    value = getAttribute(attributes, "name");
	    pushStateId(State.PROPERTY, value);
	    break;

	case PROPERTY:
	case VALUE_ITEM:
	    checkElement(qName, "value");
	    value = getAttribute(attributes, "type", "string");
	    m_value.setLength(0);

	    if ("object".equals(value)) {
	        map = new HashMap<String, Object>();
		ctx.addValue(map);
	        pushState(State.VALUE_COMPOSITE, map, ctx.id, value);
	    }

	    else if ("array".equals(value)) {
	        ArrayList<?> arr = new ArrayList<Object>();
		ctx.addValue(arr);
	        pushState(State.VALUE_COMPOSITE, arr, ctx.id, value);
	    }

	    else
	        pushStateType(State.VALUE, value);
	    break;

	case VALUE_COMPOSITE:
	    if ("item".equals(qName)) {
		value = getAttribute(attributes, "index");
	    	pushStateId(State.VALUE_ITEM, value);
	    }

	    else if ("property".equals(qName)) {
		value = getAttribute(attributes, "name");
	    	pushStateId(State.PROPERTY, value);
	    }

	    else
	    	throw new SAXException("expected item/property, got " + qName);
	    break;
	}
    }

    public void endElement(
    	String uri,
	String localName,
	String qName)
  	throws SAXException
    {
	   //
	   // remove autoPop nodes
	   //
	while (m_context.peek() != null && m_context.peek().autoPop)
	   m_context.pop();

    	Context ctx = m_context.pop();

	if (State.VALUE == ctx.state) {
	    Object value = RTCValue.getValue(ctx.type, m_value.toString(), true);
	    m_context.peek().addValue(value);
	    m_value.setLength(0);
	}
	
	else if (State.VALUE_COMPOSITE == ctx.state
		&& "array".equals(ctx.type)) {

	    ArrayList<?> arr = ctx.getArray();
	    m_context.peek().addValue(arr.toArray());
	}
    }

    public void characters(char[] ch, int start, int length)
	throws SAXException
    {
    	Context ctx = m_context.peek();

	if (State.VALUE == ctx.state)
	    m_value.append(ch, start, length);
    }
}
