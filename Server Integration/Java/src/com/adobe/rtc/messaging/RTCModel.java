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

/**
 * A basic implementation of the RTC data model
 * that can be exchanged with the RTC service 
 */
public class RTCModel
{
  private Map<String, Collection> collections = new HashMap<String, Collection>();

  public RTCModel()
  {
  }
  
  /**
   * Create RTCModel from a VO
   */
  public RTCModel(Map<String, Object> vo)
  {
    addCollections(vo);
  }

  /**
   * Add a named Collection to the model
   *
   * @param name collection name
   * @return Collection
   */
  public Collection addCollection(String name)
  {
    Collection c = new Collection(name);
    collections.put(name, c);
    return c;
  }

  public void addCollections(Map<String, Object> data)
  {
    for (Map.Entry<String, Object>  e : data.entrySet()) {
      Collection c = addCollection(e.getKey());

      @SuppressWarnings("unchecked")
      Map<String, Object> collection = (Map<String, Object>)e.getValue();

      @SuppressWarnings("unchecked")
      Map<String, Object> nodes = (Map<String, Object>)
        (collection != null ? collection.get("nodes") : null);
      
      c.addNodes(nodes);
     }
  }
  
  /**
   * Return the Collection with the specified name
   *
   * @param name collection name
   */
  public Collection getCollection(String name) {
    return collections.get(name);
  }
  
  /**
   * Return the model as a Map, compatible with the ASC definition
   */
  public Map<String, Object> toMap() {
    return toMap(false);
  }
  
  public Map<String, Object> toMap(boolean removable)
  {
    Map<String, Object> map = new HashMap<String, Object>();
    for (Collection c : collections.values())
      map.put(c.getName(), c.toMap(removable));

    return map;
  }

  /**
   * Return the model as XML string
   *
   * @param root XML root element name
   */
  public String toXML(String root)
  {
    StringBuilder sb = new StringBuilder();
    toXML(sb, root);
    return sb.toString();
  }

  public void toXML(StringBuilder sb, String root)
  {
    sb.append("<").append(root).append(">");
    for (Collection c : collections.values())
      c.toXML(sb);
    sb.append("</").append(root).append(">");
  }

  /**
   * RTC Collection
   */ 
  public static class Collection
  {
    private String name;
    private Map<String, Node> nodes = new HashMap<String, Node>();

    /**
     * Create a collection with the specified name
     *
     * @param name collection name
     */
    public Collection(String name)
    {
      this.name = name;
    }

    /**
     * Add a named Node to the Collection
     *
     * @param name node name
     */
    public Node addNode(String name)
    {
      Node n = new Node(name);
      nodes.put(name, n);
      return n;
    }
    
    /**
     * Return the node with the given name
     *
     * @param name node name
     */
    public Node getNode(String name)
    {
        return nodes.get(name);
    }

    public void addNodes(Map<String, Object> data)
    {
      if (data == null)
        return;
        
      for (Map.Entry<String, Object>  e : data.entrySet()) {
        Node n = addNode(e.getKey());
    
        @SuppressWarnings("unchecked")
        Map<String, Object> nodeData = (Map<String, Object>)e.getValue();
        n.addNodeData(nodeData);
      }
    }

    /**
     * Return the Collection name
     */
    public String getName() {
      return name;
    }

    /**
     * Return the Collection as a Map, compatible with the ASC definition
     */
    public Map<String, Object> toMap()
    {
        return toMap(false);
    }
    
    public Map<String, Object> toMap(boolean removable)
    {
      Map<String, Object> coll = new HashMap<String, Object>();
      
      if (!removable || !nodes.isEmpty()) {
          Map<String, Object> cNodes = new HashMap<String, Object>();
          for (Node n : nodes.values())
            cNodes.put(n.getName(), n.toMap(removable));
    
          coll.put("nodes", cNodes);
      }
      
      return coll;
    }

    /**
     * Return the Collection as XML string
     */
    public void toXML(StringBuilder sb)
    {
      sb.append("<node id=\"").append(name).append("\">");
      sb.append("<collection>");
      sb.append("<nodes>");
      for (Node n : nodes.values())
        n.toXML(sb);
      sb.append("</nodes>");
      sb.append("</collection>");
      sb.append("</node>");
    }
  }

  /**
   * RTC Node
   */ 
  public static class Node
  {
    private String name;
    private Map<String, Item> items = new HashMap<String, Item>();
    private Map<String, Object> configuration = null;

    public Node(String name)
    {
      this.name = name;
    }

    public void addItem(String name, Object body)
    {
	items.put(name, new Item(name, body));
    }

    public void addItem(Map<String, Object> data)
    {
        String itemID = String.valueOf(data.get("itemID"));
        if (itemID == null)
            itemID = "item";
            
        items.put(itemID, new Item(data));
    }

    public void addNodeData(Map<String, Object> data)
    {
      @SuppressWarnings("unchecked")
      Map<String, Object> configuration = (Map<String, Object>) data.get("configuration");
      addConfiguration(configuration);
      
      @SuppressWarnings("unchecked")
      Map<String, Object> items = (Map<String, Object>) data.get("items");
      addItems(items);
    }
    
    public void addItems(Map<String, Object> items)
    {
      if (items == null)
        return;

      for (Map.Entry<String, Object>  e : items.entrySet()) {
        @SuppressWarnings("unchecked")
        Map<String, Object> item = (Map<String, Object>) e.getValue();
        addItem(item);
      }
    }
    
    public Item getItem(String name) {
        return items.get(name);
    }
    
    public java.util.Collection<Item> getItems() {
        return items.values();
    }
    
    public java.util.Collection<MessageItem> getMessageItems() {
        List<MessageItem> mItems = new ArrayList<MessageItem>();
        
        for (Item i : items.values()) {
            mItems.add(new MessageItem(i.toMap(name)));
        }
        
        return mItems;
    }
    
    public void addConfiguration(Map<String, Object> conf)
    {
        configuration = conf;
    }
    
    public Map<String, Object> getConfiguration() {
        return configuration;
    }
    
    public NodeConfiguration getNodeConfiguration() {
        return new NodeConfiguration(configuration);
    }

    /**
     * Return the Node name
     */
    public String getName() {
      return name;
    }

    /**
     * Return the Node as a Map, compatible with the ASC definition
     */
    public Map<String, Object> toMap()
    {
        return toMap(false);
    }
    
    public Map<String, Object> toMap(boolean removable)
    {
      Map<String, Object> node = new HashMap<String, Object>();
      
      if (!removable || !items.isEmpty()) {
          Map<String, Object> map = new HashMap<String, Object>();
          for (Item i : items.values())
            map.put(i.getName(), i.toMap(name));
    
          node.put("items", map);
      }
      
      if (configuration != null)
          node.put("configuration", configuration);
      return node;
    }

    /**
     * Return the Node as XML string
     */
    public void toXML(StringBuilder sb)
    {
      sb.append("<node id=\"").append(name).append("\"><collection>");
      
      getConfigurationXML(sb);

      sb.append("<items>");
      for (Item i : items.values())
        i.toXML(sb, name);
      sb.append("</items>");
      
      sb.append("</collection></node>");
    }

    /**
     * Return the configuration as XML String
     */
    protected boolean getConfigurationXML(StringBuilder sb)
    {
      if (configuration != null) {
        sb.append("<configuration>");
        for (Map.Entry<String, Object> entry : configuration.entrySet())
            fieldXML(sb, entry.getKey(), entry.getValue());
        sb.append("</configuration>");
	return true;
      } else
	return false;
    }
    
    /**
     * Return a configuration property (field) as XML string
     */
    protected void fieldXML(StringBuilder sb, String name, Object value)
    {
        sb.append("<field var=\"").append(name).append("\">");
        
        if (null != value) {
            RTCValue cv = RTCValue.getValue(value, false, true);
            if (null != cv) {
                sb.append("<value type=\"").append(cv.type).append("\">");
                sb.append(cv.value);
                sb.append("</value>");
            } else {
                sb.append("<value type=\"invalid\">");
                sb.append(value.toString());
                sb.append("</value>");
            }
        }
        sb.append("</field>");
    }
  }

  /**
   * RTC Item
   */ 
  public static class Item
  {
    private String name;
    private Object data;
    private boolean fullItem;

    public Item(String name, Object body)
    {
      this.name = name;
      this.data = body;
      this.fullItem = false;
    }

    public Item(Map<String, Object> data)
    {
        this.name = data.containsKey("itemID") ? data.get("itemID").toString() : "item";
        this.data = data;
        this.fullItem = true;
    }

    /**
     * Return the Item name
     */
    public String getName() {
      return name;
    }

    /**
     * Return the Item as a Map, compatible with the ASC definition
     */

          @SuppressWarnings("unchecked") 
    public Map<String, Object> toMap(String node)
    {
      if (null == data)
          return null;

      Map<String, Object> item;
      
      if (fullItem) {
          item = (Map<String, Object>) data;
      }

      else {
          item = new HashMap<String, Object>();
          item.put("nodeName", node);
          item.put("itemID",   name);
          item.put("body",     data);
      }

      return item;
    }

    /**
     * Return the Item as XML string
     */
    public void toXML(StringBuilder sb, String nodeName)
    {
      sb.append("<item id=\"").append(name).append("\">");

      if (fullItem) {
        @SuppressWarnings("unchecked")
        Map<String, Object> props = (Map<String, Object>) data;
        for (Map.Entry<String, Object>  p : props.entrySet()) {
          propertyXML(sb, p.getKey(), p.getValue());
        }
      } else {
        propertyXML(sb, "nodeName", nodeName);
        propertyXML(sb, "itemID", name);
        propertyXML(sb, "body", data);
      }

      sb.append("</item>");
    }

    public void propertyXML(StringBuilder sb, String name, Object value)
    {
      sb.append("<property name=\"").append(name).append("\">");
      valueXML(sb, value);
      sb.append("</property>");
    }

    public void valueXML(StringBuilder sb, Object value)
    {
      if (null == value)
	return;

      RTCValue cv = RTCValue.getValue(value, false, true);

	//
	// basic property
	//
      if (null != cv) {
        sb.append("<value type=\"").append(cv.type).append("\">");
        sb.append(cv.value);
        sb.append("</value>");
        return;
      }

	//
	// nested object
	//
      if (value instanceof Map) {
        sb.append("<value type=\"object\">");

	@SuppressWarnings("unchecked")
	Map<String, Object> properties = (Map<String, Object>) value;
        for (Map.Entry<String, Object>  p : properties.entrySet())
          propertyXML(sb, p.getKey(), p.getValue());

        sb.append("</value>");
        return;
      }

	//
	// ArrayList
	//
      if (value instanceof ArrayList) {
        sb.append("<value type=\"array\">");

	@SuppressWarnings("unchecked")
	ArrayList<Object> al = (ArrayList<Object>) value;
	int len = al.size();
	for (int i=0; i < len; i++) {
	    Object obj = al.get(i);

	    if (null != obj) {
                sb.append("<item index=\"" + i + "\">");
		valueXML(sb, obj);
                sb.append("</item>");
	    }
	}

        sb.append("</value>");
        return;
      }

	//
	// array
	//
      if (value.getClass().isArray()) {
        sb.append("<value type=\"array\">");

	int len = Array.getLength(value);
	for (int i=0; i < len; i++) {
	    Object obj = Array.get(value, i);

	    if (null != obj) {
                sb.append("<item index=\"" + i + "\">");
		valueXML(sb, obj);
                sb.append("</item>");
	    }
	}

        sb.append("</value>");
        return;
      }

	//
	// unknown type, but we return it anyway
	//
      cv = RTCValue.getValue(value, true, true);
      sb.append("<value type=\"").append(cv.type).append("\">");
      sb.append(cv.value);
      sb.append("</value>");
    }
  }
}
