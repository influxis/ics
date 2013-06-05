// ActionScript file
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
	 * StreamDescriptor defines the set of a streams audio and video properties. 
	 * It is responsible for managing and communicating the set of <code>streamDescriptors</code> 
	 * to users in the room. Collaboration components such as WebcamSubscriber or AudioSubscriber
	 * use <code>streamDescriptors</code> to directly access the raw streams and may be thought
	 * of as control metadata for indicating the presence and current state of streams in a room.
	 * <p>
	 * 
	 * StreamDescriptors can be accessed through the StreamManager's methods, and StreamManager's 
	 * events will notify of any changes to  the set of <code>streamDescriptors</code>.
	 * 
	 * @see com.adobe.rtc.sharedManagers.StreamManager
	 * @see com.adobe.rtc.collaboration.WebcamSubscriber
	 * @see com.adobe.rtc.collaboration.AudioSubscriber
	 */
   public class  StreamDescriptor implements IValueObjectEncodable
	{
		/**
		 * The unique stream ID. 
		 */
		public var id:String;
		
		/**
		 * The type of the stream: either StreamManager.AUDIO_STREAM or StreamManager.CAMERA_STREAM.
		 */	
		public var type:String;

		/**
		 *  The stream publisher's <code>userID</code>.
		 */
		public var streamPublisherID:String;
		
		/**
		 * The userID of the user publishing their screen. Note that for screensharing, the streamPublisherID will have to a "shadow" user ID which isn't available in the userManager - this
		 * represents the screen share addIn connection being used. To find the "real" userID of the publisher of a screen share, use this property.
		 */		
		public var originalScreenPublisher:String;
		
		/**
		 *  The group name which the stream descriptor belongs to
		 */
		public var groupName:String ;
		/**
		 * The <code>userID</code> of whomever requested this stream be initiated.
		 * It is usually identical to the <code>streamPublisherID</code>, but in 
		 * "push sharing" cases, it will be the requester.
		 * 
		 */
		public var initiatorID:String;
		
		/**
		 * Describes the video stream's original width.
		 */	
		public var nativeWidth:Number=0;
		
		/**
		 * Describes the video stream's original height.
		 */	
		public var nativeHeight:Number=0;
		
		/**
		 * Gets the stream's bandwidth setting.
		 */
		public var kBps:Number=0;
		
		/**
		 * The mute state for audio streams: true for muted, false for not
		 */
		public var mute:Boolean=false;
		
		/**
		 * The video stream pause state: true for paused, false for not
		 */
		public var pause:Boolean=false;
		
		/**
		 * The audio stream volume.   
		 */
		public var volume:Number=0;
		
		/**
		 *  Whether the stream has begun actually publishing (true) or whether the descriptor 
		 * is being sent for initial validation (false).
		 */
		public var finishPublishing:Boolean=false;
	
		/**
		 * @private
		 */
		public var peerID:String;
		/**
		 * Array of recipientIDs for this stream. Default is null i.e. broadcast stream to everyone.
		 */
		public var recipientIDs:Array;
		
		public var requestControl:Boolean;
		
		/**
		 * Creates a ValueObject representation of this descriptor.
		 */	
		public function createValueObject():Object
		{
			var writeObj:Object = new Object();
			//if the id is not null while creating this value object , put it in the object created
			if (id!=null) {
				writeObj.id = id;
			}
			// if the type is not null while creating this value object , put it in the object created
			if (type!=null) {
				writeObj.type = type;
			}
			
			if ( groupName != null ) {
				writeObj.groupName = groupName ;
			}
			// if the nativeWidth is not zero while creating this value object , put it in the object created
			if (nativeWidth!=0) {
				writeObj.nativeWidth = nativeWidth;
			}
			// if the nativeHeight is not zero while creating this value object , put it in the object created
			if (nativeHeight!=0) {
				writeObj.nativeHeight = nativeHeight;
			}
			if(volume!=0){
				writeObj.volume = volume;
			}
			// if the kbps is not zero while creating this value object , put it in the object created
			if (kBps != 0) {
				writeObj.kBps = kBps;
			}
			
			if (originalScreenPublisher!=null) {
				writeObj.originalScreenPublisher = originalScreenPublisher;
			}
			
			writeObj.requestControl = requestControl;
			
			
			// copy the mute and finishPublishing value in the object created
			writeObj.mute=mute;
			writeObj.pause=pause;
			writeObj.peerID=peerID;
			writeObj.finishPublishing = finishPublishing;
			writeObj.recipientIDs = recipientIDs ;
			return writeObj;
		}
		
		/**
		 * Takes in a <code>valueObject</code> and structure the MessageItem according to the 
		 * values therein.
		 * 
		 * @param p_valueObject An Object which represents the non-default values for this MessageItem.
		 */
		public function readValueObject(p_valueObject:Object):void
		{
			for (var i:* in p_valueObject) {
				this[i] = p_valueObject[i];
			}
		}		
	}			
}
