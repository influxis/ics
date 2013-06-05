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
package com.adobe.rtc.sharedModel.descriptors
{
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.messaging.IValueObjectEncodable;
	
	/**
	 * ChatMessageDescriptor is a simple value-object to describe chat message properties.
	 */
   public class  ChatMessageDescriptor extends Object implements IValueObjectEncodable
	{
		/**
		 * Display name of the chat message sender. 
		 */
		public var displayName:String;
		
		/**
		 * The chat message contents. The contents should not contain any HTML formatting
		 * Since formatting is done by using .color at the receiving end.
		 */
		public var msg:String;
		
		/**
		 * The chat message sender-specified color.
		 */
		public var color:uint;
		
		/**
		 * For private messages intended for a specific recipient, an optional 
		 * recipient <code>userID</code>. For messages sent to all recipients of a 
		 * particular role level, see <code>role</code>. 
		 */
		public var recipient:String;
		
		/**
		 * For private messages intended for a specific recipient, the recipient's 
		 * <code>displayName</code>. For messages sent to all recipients of a 
		 * particular role level, see <code>role</code>. 
        * <p>
        * By default, when a user is present, their display name appears next to 
        * their message. When they leave, <code>recipientDisplayName</code> enables 
        * the chat window to continue displaying their name along with the old messages.
		 */
		public var recipientDisplayName:String;	//For display after the recipient leaves.
		
		/**
		 * For public messages intended for a role group rather than a specific recipient, 
		 * <code>role</code> specifies the minimum role level required to receive the message. 
		 * For example, instead of using <code>userID</code> to limit recipients to a single   
		 * specified user, you can use <code>role</code> to send a message to everyone with 
		 * a minimum role level or above as follows: 
		 * <ul>
		 * <li><strong>UserRoles.VIEWER</strong>: Messages are sent to everyone.</li>
		 * <li><strong>UserRoles.PUBLISHER</strong>: Messages are sent to publishers and owners.</li>
		 * <li><strong>UserRoles.OWNER</strong>: Messages are sent only to owners.</li>
		 * </ul>
		 */
		public var role:int=UserRoles.VIEWER;
		
		/**
		 * [Read-only] The time the message was sent.
		 */
		public var timeStamp:Number;
		
		/**
		 * [Read-only] The sender's <code>userID</code>.
		 */
		public var publisherID:String;
		
		/**
		 * Constructor. 
		 * 
		 * @param p_msg The message to send.
		 */
		public function ChatMessageDescriptor(p_msg:String=""):void
		{
			msg = p_msg;
		}

		/**
		 * @private
		 */
		public function readValueObject(p_valueObject:Object):void
		{
			displayName = p_valueObject.displayName;
			msg = p_valueObject.msg;
			color = p_valueObject.color;
			recipient = p_valueObject.recipient;
			role = p_valueObject.role;
			recipientDisplayName = p_valueObject.recipientDisplayName;
		}
		
		/**
		 * @private
		 */
		public function createValueObject():Object
		{
			var res:Object = new Object();
			res.displayName = displayName;
			res.msg = msg;
			res.color = color;
			res.role = role;
			res.recipientDisplayName = recipientDisplayName;
			return res;
		}
	}
}