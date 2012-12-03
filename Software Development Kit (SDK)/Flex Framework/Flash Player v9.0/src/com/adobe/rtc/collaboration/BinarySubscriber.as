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
	
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	
	import mx.core.UIComponentGlobals;
	
	/**
	 * BinarySubscriber is a simple variant of FileSubscriber that allows the developer to download a given 
	 * FileDescriptor as a ByteArray in memory rather than as a file to be saved on the user's file system.
	 * To access lists of files in the room, see the FileManager APIs.
	 *  
	 * @see com.adobe.rtc.sharedManagers.FileManager
	 * @see com.adobe.rtc.sharedManagers.descriptors.FileDescriptor
	 * @see com.adobe.rtc.collaboration.FilePublisher
	 * @see com.adobe.rtc.collaboration.BinaryPublisher
	 * @see com.adobe.rtc.collaboration.FileSubscriber
	 */
	
   public class  BinarySubscriber extends FileSubscriber
	{
		/**
		 * @private 
		 */
		protected var _loader:URLLoader;
		
		/**
		 * @private 
		 */
		protected var _fileData:ByteArray;
		
		public function BinarySubscriber()
		{
			super();
		}
		
		[Bindable(event="complete")]
		/**
		 * The file data of the downloaded file: it is null until a <code>complete</code> event fires.
		 */
		public function get fileData():ByteArray
		{
			return _fileData;			
		}
		/**
		 * Downloads the file specified by the supplied FileDescriptor. The file in question will populate the 
		 * <code class="property">fileData</code> upon completion.
		 * 
		 * @param p_fileDescriptor A FileDescriptor representing the file to download. For details about
		 * accessing a list of files available in the room, see the FileManager's APIs.
		 */
		override public function download(p_fileDescriptor:FileDescriptor):void
		{
			var ticket_token:String = "?mst="+ _userManager.myTicket+"&token="+p_fileDescriptor.token;
			
			try {
				_loader = new URLLoader();
				var request:URLRequest = new URLRequest(p_fileDescriptor.url + p_fileDescriptor.filename + ticket_token);
				request.method = URLRequestMethod.GET;	
				_loader.dataFormat = URLLoaderDataFormat.BINARY;
				_loader.addEventListener("complete", onComplete);
				_loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
				_loader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
				_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onIoError);
				
				_loader.load(request);
										
			}catch(e:Error) {
				throw e;
			}
		}
		
		/**
		 * @private
		 */
		override protected function onComplete(p_event:Event):void
		{
			_fileData = p_event.target.data;
			dispatchEvent(p_event);
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
