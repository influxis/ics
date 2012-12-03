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
package com.adobe.rtc.sharedManagers.descriptors
{
	import com.adobe.rtc.messaging.IValueObjectEncodable;
	
	/**
	 * Describes the set of properties for a file present in the room for upload and download. 
	 * The FileManager is responsible for managing and communicating the set of FileDescriptors 
	 * to users in the room. Collaboration components such as FileSubscriber or FilePublisher 
	 * use FileDescriptors to access the raw files themselves. 
	 * <p>
	 * FileDescriptors can be thought of as control metadata for indicating the presence and 
	 * current state of files in the room. FileDescriptors can be accessed through FileManager's 
	 * methods, and FileManager's events will notify of any changes to the set of fileDescriptors.
	 * 
	 * @see com.adobe.rtc.sharedManagers.FileManager
	 * @see com.adobe.rtc.collaboration.FileSubscriber
	 */
   public class  FileDescriptor implements IValueObjectEncodable
	{
		/**
		 * Constant value descriptor state which is published in the descriptor for validation 
		 * to the service when the publisher is about to upload a file.
		 */
		public static var ANNOUNCING_INTENTION_TO_PUBLISH:String = "announcingIntentionToPublish";
		
		/**
		 * Constant value for the descriptor state: When the file upload is finished and the final
		 * URL has been determined, the descriptor is updated with the URL and this state.
		 */
		public static var PUBLISHING_DESCRIPTOR:String = "publishingDescriptor";
		
		/**
		 * Constant value for the descriptor stae: When the file upload is in progress, 
		 * the descriptor is periodically updated with the percent completion of the 
		 * upload and this state.
		 */
		public static var FILE_UPLOAD_PROGRESS:String = "fileUploadProgress";
		
		// If you change the (non-folded) descriptor fields, make sure you change createValueObject() too!
		// Or you will have SPOOKY BUGS OF THE NIGHT.

		/**
		 * The name of the file on the client.
		 */
		public var name:String;	
		
		/**
		 * The name of the file on the server (including possible encoding).
		 */
		public var filename:String;	
		
		/**
		 * If the file has been renamed, the last client name used before it was renamed.
		 */
		public var previousName:String;	
		
		/**
		 * If the file has been renamed, the last server fileName used before it was renamed.
		 */
		public var previousFilename:String;
		
		/**
		 * The final URL of the file on a server for download.
		 */
		public var url:String;
		
		/**
		 * The file type.
		 */
		public var type:String;
		
		/**
		 * The size of the file in bytes.
		 */
		public var size:int = 0;
		
		/**
		 * The progress of the file upload expressed numerically from 0 to 100.
		 */
		public var uploadProgress:Number = 0;
		
		/**
		 * A server token to allow for validated download of the file. 
		 */
		public var token:String; 
		
		// folded properties - these are set in manager onItemReceive handlers.
		// See FileManager.buildFileDescriptor() for an example of how to do this.
		/**
		 * A unique descriptor ID.
		 */
		public var id:String;
		/**
		 *  The group name which the stream descriptor belongs to
		 */
		public var groupName:String;
		
		/**
		 * The file publisher's <code>userID</code>.
		 */
		public var submitterID:String;	
		
		/**
		 * The timestamp of the last modified date.
		 */
		public var lastModified:int;
		/**
		 * It gives the complete url required for downloading the file 
		 */
		 public var downloadUrl:String ;
		
		
		/**
		 * The state of the publish operation which must be one of the constant values 
		 * described in this class. 
		 */
		public var state:String = ANNOUNCING_INTENTION_TO_PUBLISH;
		
		/**
		 * Creates a ValueObject representation of this descriptor.
		 * 
		 * @return An Object which represents the non-default values for this descriptor, 
		 * suitable for consumption by <code>readValueObject</code>.
		 */	
		public function createValueObject():Object
		{
			var writeObj:Object = new Object();
			
			if(id!=null)
				writeObj.id = id;
			if(name != null)
				writeObj.name = name;
			if(filename != null)
				writeObj.filename = filename;
			if(previousName != null)
				writeObj.previousName = previousName;
			if(previousFilename != null)
				writeObj.previousFilename = previousFilename;
			if(url != null)
				writeObj.url = url;
			if(type != null)
				writeObj.type = type;
			if(size != 0)
				writeObj.size = size;
			if(uploadProgress != 0)
				writeObj.uploadProgress = uploadProgress;
			if(state != ANNOUNCING_INTENTION_TO_PUBLISH)
				writeObj.state = state;
			if(token != null)
				writeObj.token = token;
			if(submitterID!=null)
				writeObj.submitterID = submitterID;
			if(groupName!=null)
				writeObj.groupName = groupName;
			
			writeObj.lastModified = lastModified;
			
			return writeObj;
		}		
		
		
		
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
		 * Returns a copy of itself.
		 */
		
		public function clone():FileDescriptor
		{
			var newFileDescriptor:FileDescriptor = new FileDescriptor();
			newFileDescriptor.id = id;
			newFileDescriptor.name = name;
			newFileDescriptor.filename = filename;
			newFileDescriptor.previousName = previousName;
			newFileDescriptor.previousFilename = previousFilename;
			newFileDescriptor.url = url;
			newFileDescriptor.type = type;
			newFileDescriptor.size = size;
			newFileDescriptor.submitterID = submitterID;
			newFileDescriptor.uploadProgress = uploadProgress;
			newFileDescriptor.lastModified = lastModified;
			newFileDescriptor.state = state;
			newFileDescriptor.token = token;
			newFileDescriptor.groupName = groupName ;
			newFileDescriptor.downloadUrl = downloadUrl ;
			return newFileDescriptor;
		}
	}
}
