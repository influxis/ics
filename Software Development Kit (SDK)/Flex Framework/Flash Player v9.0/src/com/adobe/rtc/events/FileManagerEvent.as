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
	import com.adobe.rtc.sharedManagers.descriptors.FileDescriptor;

	/**
	 * The event class sent by com.adobe.rtc.sharedManagers.FileManager. 
	 * 
	 * @see com.adobe.rtc.sharedManagers.FileManager
	 */
   public class  FileManagerEvent extends Event
	{
		// uploading

		/**
		 * Dispatched when a file has been cleared to begin uploading.
		 */
		public static const READY_FOR_UPLOAD:String = "readyForUpload";
		/**
		 * Dispatched when a file has been cleared for updating.
		 */
		public static const UPDATE_OK:String = "updateOK";

		// responding to external updates
		/**
		 * Dispatched when a file has begun uploading to the room.
		 */
		public static const NEW_FILE_DESCRIPTOR:String = "newFileDescriptor";
		/**
		 * Dispatched when a file within the room has been updated. 
		 */
		public static const UPDATED_FILE_DESCRIPTOR:String = "updatedFileDescriptor";
		/**
		 * Dispatched when a file within the room has been deleted.
		 */
		public static const CLEARED_FILE_DESCRIPTOR:String = "clearedFileDescriptor";
		/**
		 * Dispatched when there is a problem with a file operation.
		 */
		public static const FILE_ALERT:String = "fileAlert" ;
		

		/**
		 * The FileDescriptor for the related file, if appropriate.
		 */
		public var fileDescriptor:FileDescriptor;
		/**
		 * If applicable, the message corresponding to the problem with the file operation.
		 */
		public var alertMessage:String ;

		public function FileManagerEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = true):void {
			super(type, bubbles, cancelable);
		}

		/**
		 * @private
		 */
		public override function clone():Event
		{
			return new FileManagerEvent(type, bubbles, cancelable);
		}
	}
}