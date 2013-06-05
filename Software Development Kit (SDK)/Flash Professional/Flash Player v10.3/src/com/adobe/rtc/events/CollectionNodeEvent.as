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
package com.adobe.rtc.events
{
	import com.adobe.rtc.messaging.MessageItem;
	
	import flash.events.Event;

	/**
	 * CollectionNodeEvent describes all the events dispatched by CollectionNodes. 
	 * See the constants below for a listing of possible types.
	 * 
	 * @see com.adobe.rtc.sharedModel.CollectionNode
	 */	
	
   public class  CollectionNodeEvent extends Event
	{

		/**
		* The type of event emitted when the CollectionNode gains or loses synchronization with its source.
		*/
		public static const SYNCHRONIZATION_CHANGE:String = "synchronizationChange"; 


		/**
		 * The type of event emitted when the CollectionNode is about to reconnect to the server. 
		 * This typically happens automatically if the CollectionNode is still subscribed. 
		 * The typical response to this event is to re-initialize any 
		 * shared parts of a model from scratch since they are about to be re-received from the server.
		 */
		public static const RECONNECT:String = "reconnect";

		/**
		* The type of event emitted when a new node is added to the CollectionNode.
		*/
		public static const NODE_CREATE:String = "nodeCreate"; 

		/**
		* The type of event emitted when the CollectionNode receives a change in configuration on one of its nodes.
		*/
		public static const CONFIGURATION_CHANGE:String = "configurationChange"; 

		/**
		* The type of event emitted when a node is deleted from the CollectionNode.
		*/
		public static const NODE_DELETE:String = "nodeDelete"; 

		/**
		* The type of event emitted when the CollectionNode receives an item on one of its nodes.
		*/
		public static const ITEM_RECEIVE:String = "itemReceive"; 

		/**
		* The type of event emitted when the CollectionNode retracts an item from one of its nodes.
		*/
		public static const ITEM_RETRACT:String = "itemRetract"; 

		/**
		* The type of event emitted when the CollectionNode receives a change in <code>userRole</code> 
		* (<b>for any user</b>) on itself <b>or one of its nodes</b>. In general, this event is only 
		* useful for situations in which users are assigned roles at the individual node level and where 
		* the developer cares about the user roles other than the current user on these nodes. 
		* Use <code>MY_ROLE_CHANGE</code> for its more useful and specific counterpart.
		*/
		public static const USER_ROLE_CHANGE:String = "userRoleChange"; 

		/**
		* The type of event emitted when the CollectionNode receives a change in <code>userRole</code> <b>
		* for the current user</b> on itself only (<b>not on its individual nodes</b>).
		* This event is the most commonly used of the two role events as it is rare for users to have roles
		* defined on specific nodes and rare that a user interface cares about the roles of users other 
		* than the current user. For a more general purpose event which handles all cases, 
		* use <b>USER_ROLE_CHANGE</b>.
		*/
		public static const MY_ROLE_CHANGE:String = "myRoleChange"; 


		/**
		* The node name to which this event pertains. In the case of <code>userRoleChanges</code> for an 
		* entire CollectionNode and <code>myRoleChange</code>, this is null.
		*/
		public var nodeName:String;

		/**
		* For <code>itemReceive</code> and <code>itemRetract</code> events, item contains the newly received 
		* or retracted MessageItem.
		*/
		public var item:MessageItem;
		
		/**
		* For <code>userRoleChange</code> events, the <code>userID</code> contains the ID of the affected user.
		*/
		public var userID:String;

		
		public function CollectionNodeEvent(p_type:String, p_nodeName:String="",p_item:MessageItem=null,p_userID:String="")
		{
			super(p_type);
			if (p_nodeName!="") {
				nodeName = p_nodeName;
			}
			
			if (p_item != null ) {
				item = p_item ;
			}
			
			if (p_userID != "" ) {
				userID = p_userID ;
			}
		}

		/**
		 * @private
		 */
		public override function clone():Event
		{
			return new CollectionNodeEvent(type, nodeName,item,userID);
		}		
	}
}