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
package com.adobe.rtc.sharedModel.userQueueClasses
{
	import com.adobe.rtc.messaging.IValueObjectEncodable;

	/**
	 * UserQueueItem is a "descriptor" for describing the properties of a user 
	 * request in a UserQueue. 
	 * 
	 * @see com.adobe.rtc.sharedModel.UserQueue
	 */
   public class  UserQueueItem implements IValueObjectEncodable
	{
		/**
		 * Requests are pending when a queue manager hasn't dealt with them yet. 
		 * Requests start in this status.
		 */
		public static const STATUS_PENDING:int = 0;

		/**
		 * Requests are accepted when a queue manager accepts them. Look at the 
		 * <code>dealtBy</code> <code>userID</code> to see who accepted the request.
		 */
		public static const STATUS_ACCEPTED:int = 1;

		/**
		 * Requests are denied when a queue manager denies them. Look at the 
		 * <code>dealtBy</code> <code>userID</code> to see who denied the request.
		 */
		public static const STATUS_DENIED:int = 2;

		/**
		 * Requests are canceled when a user cancels it or a queue manager cancels it for them. 
		 * Look at the <code>dealtBy</code> <code>userID</code> to see who canceled the request.
		 */
		public static const STATUS_CANCELED:int = 3;

		/**
		 * The position in the queue of this UserQueueItem.
		 */
		public var position:int = -1;
		
		/**
		 * The status of this UserQueueItem.
		 */
		public var status:int = 0;

		/**
		 * Who posted this request?
		 */
		public var userID:String;
		
		/**
		 * The optional message that came along with the request.
		 */
		public var message:String;
		
		/**
		 * The optional response that came along with the accept, deny, or cancel request.
		 */
		public var response:String;
	
		/**
		 * Who affected the status of this UserQueueItem?
		 */
		public var dealtBy:String;
		/**
		 * The object that describes information about the queueitem
		 */
		public var descriptor:Object ;
		
		/**
		 * Takes in a <code>valueObject</code> and structure the MessageItem according to the values therein.
		 * 
		 * @param p_valueObject An Object which represents the non-default values for this MessageItem.
		 */
		public function readValueObject(p_valueObject:Object):void
		{
			for (var i:* in p_valueObject) {
				this[i] = p_valueObject[i];
			}
		}
		
		/**
		 * Creates a ValueObject representation of this MessageItem.
		 * 
		 * @return An Object which represents the non-default values for this MessageItem 
		 * which is suitable for consumption by <code>readValueObject</code>.
		 */	
		public function createValueObject():Object
		{
			var writeObj:Object = new Object();

			if ( position != -1 ) {
				writeObj.position = position;
			}
			if ( status != -1 ) {
				writeObj.status = status;
			}
			if ( userID != null ) {
				writeObj.userID= userID;
			}
			if ( message != null ) {
				writeObj.message = message;
			}
			if ( dealtBy != null ) {
				writeObj.dealtBy = dealtBy;
			}
			if ( response != null ) {
				writeObj.response = response;
			}
			
			if ( descriptor != null ) {
				writeObj.descriptor = descriptor ;
			}

			return writeObj;
		}
		
		/**
		 * @private
		 */
		public function toString():String
		{
			return "status: "+status+", userID: "+userID+", message: "+message+", dealtBy: "+dealtBy+", response: "+response;
		}
	}
}