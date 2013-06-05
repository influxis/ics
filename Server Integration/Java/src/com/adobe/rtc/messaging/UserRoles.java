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
	
/**
 * UserRoles is a class for holding the constant values for standard user roles. 
 * Roles are all stored as integers. 
 * 
 * @see com.adobe.rtc.messaging.NodeConfiguration
 */
public class UserRoles
{
	public static final int NONE = 0;

	/**
	 * LOBBY can only subscribe to collections such as the ones used for knocking or for features in the lobby.
	 */
	public static final int LOBBY = 5;
	
	/**
	 * VIEWER can subscribe to most nodes but cannot publish or configure. It corresponds to "NONE" in XEP-60.
	 */
	public static final int VIEWER = 10;

	/**
	 * PUBLISHER can publish and subscribe to most nodes but cannot create, delete or configure nodes.
	 */
	public static final int PUBLISHER = 50;

	/**
	 * OWNER can create, configure, and delete nodes, as well as publish and subscribe. 
	 * The OWNER is typically the person who created the room.
	 */
	public static final int OWNER = 100;
}
