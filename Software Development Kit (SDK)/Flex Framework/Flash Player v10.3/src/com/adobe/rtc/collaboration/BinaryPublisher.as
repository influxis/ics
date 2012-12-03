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
package com.adobe.rtc.collaboration
{
	import com.adobe.rtc.sharedManagers.descriptors.FileDescriptor;
	import com.adobe.rtc.util.DebugUtil;
	
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	
	import mx.core.UIComponentGlobals;

	/**
	 * Dispatched on an upload completion.
	 */
	[Event(name="complete", type="flash.events.Event")]
	
	/**
	 * Dispatched on an HTTP status change.
	 */
	[Event(name="httpStatus", type="flash.events.HTTPStatusEvent")]


	/**
	 * BinaryPublisher is a specialized FilePublisher used in submitting ByteArray data via HTTP for file-sharing.
	 * It employs a very simple API: developers can specify a group to which to publish, then use <code>publish()</code>
	 * to submit a ByteArray of file data, and notify other users of the presence of the new file. Users on the receiving
	 * end can use the FileManager APIs to detect the presence of new files on the service, and use either the FileSubscriber
	 * or BinarySubscriber to download its contents either as a complete file or as file data.
	 * 
	 * @see com.adobe.rtc.sharedManagers.FileManager
	 * @see com.adobe.rtc.sharedManagers.descriptors.FileDescriptor
	 * @see com.adobe.rtc.collaboration.BinarySubscriber
	 * @see com.adobe.rtc.collaboration.FileSubscriber
	 * 
	 */
	
   public class  BinaryPublisher extends FilePublisher
	{
		/**
		 * @private 
		 */
		protected static const BOUNDARY:String = "---------------------------LIVESINNED";

		/**
		 * @private 
		 */
		protected var _fileName:String;
		
		/**
		 * @private 
		 */
		protected var _fileData:ByteArray;
		
		/**
		 * @private 
		 */
		protected var _contentType:String = "application/octet-stream";
		
		/**
		 * @private 
		 */
		protected var _url:String;
		
		/**
		 * @private 
		 */
		protected var _loader:URLLoader;

		
		/**
		 * <code>publish()</code> takes a file name, ByteArray-formatted file data, a <code class="property">uniqueID</code>, 
		 * and an optional content-type parameter, and publishes the given data via HTTP to the service. 
		 * Subscribed clients will receive a <code>updatedFileDescriptor</code>
		 * event from the FileManager to indicate progress of the upload. 
		 * 
		 * @param p_fileName The name for the new file, including the extension.
		 * @param p_fileData A ByteArray of data to publish as a file to the service.
		 * @param p_itemID A uniqueID to give the file.
		 * @param p_contentType Optionally, the MIME content-type of the data; it defaults to "application/octet-stream".
		 * 
		 */
		public function publish(p_fileName:String, p_fileData:ByteArray, p_itemID:String=null, p_contentType:String="application/octet-stream"):void
		{
			_fileName = p_fileName;
			_fileData = p_fileData;
			_contentType = p_contentType;
			_uploadFileDescriptor = new FileDescriptor();
			_uploadFileDescriptor.id = p_itemID;			
			_uploadFileDescriptor.submitterID = _userManager.myUserID;
			_uploadFileID = p_itemID;
			
			if(_fileName != null && _fileData.length > 0)
				announceIntentionPublish(_fileName, _fileData.length);
		}
		
		/**
		 * @private 
		 */
		override protected function uploading():void
		{																
			// Hack to make it easy for the security filter to find the ticket param without 
			// having to parse all of the multipart form data. We really shouldn't have to do
			// this, but it does make processing of the security filter faster/easier.
			var uploadUrl:String = _uploadFileDescriptor.url +  "?mst=" + _userManager.myTicket;
			
			var data:String = addParameter("type", "cr:file")
				+ addFile("file", _fileName, _contentType);
			
			var byteData:ByteArray = new ByteArray();
			byteData.writeUTF(data);
			// append our fileData
			byteData.writeBytes(_fileData);
			// append the footer
			byteData.writeUTF("\r\n--" + BOUNDARY + '--');

			_loader = new URLLoader();
			var request:URLRequest = new URLRequest(uploadUrl);
			request.data = byteData;
			request.method = URLRequestMethod.POST;
			request.requestHeaders.push( new URLRequestHeader("Content-type","multipart/form-data; charset=utf-8; boundary=" + BOUNDARY));
			_loader.addEventListener("complete", onPostComplete);
			_loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
			_loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onIOError);
			_loader.addEventListener(ProgressEvent.PROGRESS, onProgress);
			
			try {
				_loader.load(request);
			} catch (error:Error) {
				DebugUtil.debugTrace("Unable to load requested document.");
			}
			
			if(progressInterval) {				
				_progressTimer.start();
			}
		}

		
		/**
		 * @private 
		 */
		protected function addParameter(name:String, value:String):String
		{
			return "--" + BOUNDARY 
				+ '\r\nContent-Disposition: form-data;'
				+ ' name="' + name + '"\r\n\r\n' 
				+ value + '\r\n';
		}

		/**
		 * @private 
		 */
		protected function addFile(name:String, fileName:String, contentType:String):String
		{
			return "--" + BOUNDARY 
				+ '\r\nContent-Disposition: form-data;'
				+ ' name="' + name + '";'
				+ ' filename="' + fileName + '"'
				+ '\r\nContent-Type: ' + contentType 
				+ '\r\n\r\n';
		}

		/**
		 * @private 
		 */
		protected function onPostComplete(p_evt:Event):void
		{
			_model.amIUploadingFile = false;
			
			// In case the user cancels the upload.
			if(_uploadFileDescriptor == null || _model.getFileDescriptor(_uploadFileDescriptor.id) == null)
				return;
				
			if(progressInterval)
				_progressTimer.stop();			// Stop the progress timer.
				
			// stopAnimation();					// Remove graphics.
			_lastBytesLoaded = 0;				// Reset progress counters.
			
			// Send out one final message item with uploadProgress = 100.
			_uploadFileDescriptor.uploadProgress = 100;
			// _model.updateUploadProgress(_uploadFileDescriptor.id, 100);


			// Update the FileDescriptor with information about the selected information.
			_uploadFileDescriptor.name = _fileName;
			_uploadFileDescriptor.groupName = _groupName ;
			_uploadFileDescriptor.size = _fileData.length;
			_uploadFileDescriptor.type = _contentType;
			
			_uploadFileDescriptor.submitterID = _userManager.myUserID;
			
			_uploadFileDescriptor.state = FileDescriptor.PUBLISHING_DESCRIPTOR;
			
			// Now that the FileDescriptor is complete, share it with FileManager.
			_model.updateFileDescriptor(_uploadFileDescriptor.id, _uploadFileDescriptor.name, _uploadFileDescriptor.filename, _uploadFileDescriptor.url,
						_uploadFileDescriptor.type, _uploadFileDescriptor.size, _uploadFileDescriptor.uploadProgress, _uploadFileDescriptor.state);
			

			dispatchEvent(p_evt);
		}
		
		/**
		 * @inheritDoc 
		 */
		override public function cancelFileUpload():void
		{
			if(_model.amIUploadingFile == true) {
				// Indicates uploading is in progress.
				_loader.close();
				remove(_uploadFileDescriptor);			
				
			}			
			
			_model.amIUploadingFile = false;
		}
		
		/**
		 * @private
		 */
		override protected function measure():void
		{
			super.measure();
			
			if ( UIComponentGlobals.designMode ) {
        		minHeight = 40 ;
        		minWidth = 100 ;
        	}
		}
		
		
	}
}
