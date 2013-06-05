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
package com.adobe.rtc.messaging
{
	
	/**
	 * UserRoles is a class for holding the constant values for standard user roles. 
	 * Roles are all stored as integers. Note that it is possible to set roles not 
	 * listed here both in NodeConfigurations and the various roles functions on 
	 * CollectionNode and UserManager.
	 * 
	 * @see com.adobe.rtc.sharedModel.CollectionNode
	 * @see com.adobe.rtc.messaging.NodeConfiguration
	 * @see com.adobe.rtc.sharedManagers.UserManager
	 */
	
   public class  UserRoles
	{
		/**
		 * LOBBY can only subscribe to collections such as the ones used for knocking or for features in the lobby.
		 */
		public static const LOBBY:int = 5;
		
		/**
		 * VIEWER can subscribe to most nodes but cannot publish or configure. It corresponds to "NONE" in XEP-60.
	 	 */
		public static const VIEWER:int = 10;

		/**
		 * PUBLISHER can publish and subscribe to most nodes but cannot create, delete or configure nodes.
	 	 */
		public static const PUBLISHER:int = 50;

		/**
		 * OWNER can create, configure, and delete nodes, as well as publish and subscribe. 
		 * The OWNER is typically the person who created the room.
	 	 */
		public static const OWNER:int = 100;
	}
}