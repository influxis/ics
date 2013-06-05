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
	import flash.events.Event;
	import com.adobe.rtc.sharedManagers.descriptors.UserDescriptor;

	/**
	 * UserEvent is the generic class pertaining to users. It is thrown by UserManager and (potentially) 
	 * components for signalling changes to <code>userDescriptors</code> and roles.
	 *
 	 * @see com.adobe.rtc.sharedManagers.descriptors.UserDescriptor
 	 * @see com.adobe.rtc.sharedManagers.UserManager
	 */
	
   public class  UserEvent extends Event
	{
		

		/**
		* The <code>userDescriptor</code> of the affected user.
		*/
		public var userDescriptor:UserDescriptor;
		
		/**
		* @private 
		* For type CUSTOM_FIELD_CHANGE, the name of the custom field which changed.
		*/
		public var customFieldName:String;

		

		/**
		* Dispatched when the <code>userManager</code> loses connection or when it has finished 
		* reconnecting and synching to the room's state.
		*/
		public static const SYNCHRONIZATION_CHANGE:String = "synchronizationChange";
		/**
		 * Dispatched when the user role changes.
		 */
		public static const USER_ROLE_CHANGE:String = "userRoleChange";
		/**
		 * Dispatched when the user displayName changes.
		 */
		public static const USER_NAME_CHANGE:String = "userNameChange";
		/**
		 * Dispatched when the user's connection speed changes.
		 */
		public static const USER_CONNECTION_CHANGE:String = "userConnectionChange";
		/**
		 * Dispatched when the user avatar URL of a user changes.
		 */
		public static const USER_USERICONURL_CHANGE:String = "userUsericonURLChange";
		/**
		 * Dispatched when the status of a user changes.
		 */
		public static const USER_STATUS_CHANGE:String = "userStatusChange";
		/**
		 * Dispatched when the user is speaking or has stopped speaking.
		 */
		public static const USER_VOICE_STATUS_CHANGE:String = "userVoiceStatusChange";
		/**
		 * @private
		 */
		public static const USER_PING_DATA_CHANGE:String = "userPingDataChange";		// when either latency or drops changes;
																						//   they usually do so together
		/**
		 * Dispatched when a new user enters the room.
		 */
		public static const USER_CREATE:String = "userCreate";
		/**
		 * Dispatched when a user leaves the room.
		 */
		public static const USER_REMOVE:String = "userRemove";
		/**
		 * Dispatched when a user is forcibly ejected from the room.
		 */
		public static const USER_BOOTED:String ="userBooted";
		/**
		 * @private
		 */
		public static const CUSTOM_FIELD_CHANGE:String = "customFieldChange";
			/**
		 * @private
		 */
		public static const CUSTOM_FIELD_REGISTER:String = "customFieldRegister";
		/**
		 * @private
		 */
	public static const CUSTOM_FIELD_DELETE:String = "customFieldDelete";
		/**
		 * @private
		 */
		public static const STREAM_CHANGE:String ="streamChange" ;
		/**
		* @private
		*/
		public static const PEER_CONNECTION_CHANGE:String ="peerConnectionChange" ;
	    /**
		 * @private
		 */
		public static const ANONYMOUS_PRESENCE_CHANGE:String ="anonymousPresenceChange" ;

		
		
		public function UserEvent(p_type:String, p_descriptor:UserDescriptor=null, p_customFieldName:String=null)
		{
			userDescriptor = p_descriptor;
			customFieldName = p_customFieldName;
			super(p_type);
		}		

		/**
		 * @private
		 */
		public override function clone():Event
		{
			return new UserEvent(type, userDescriptor, customFieldName);
		}
		
	}
}
