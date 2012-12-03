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
	/**
	 * Defines the set of parameters used for setting quality of ON2 video; 
	 * for example, the webcamera stream.
	 * 
	 * @see flash.media.Camera
	 */
   public class  On2ParametersDescriptor extends Object
	{
		/**
		 * Compression quality of the video. Defaults to 70 with 100 being the best.
		 * 
		 * @default 70
		 */
		public var quality:uint;
		
		/**
		 * @private
		 */
		public var performance:uint;
		
		/**
		* Specifies which video frames are transmitted in full (called keyframes) 
		* instead of being interpolated by the video compression algorithm. The default 
		* value is 15, which means that every 15th frame is a keyframe.
		* 
		* @default 15
		*/
		public var keyframeInterval:uint;
		
		/**
		 * The maximum rate for the camera to capture data in frames per second. The maximum 
		 * rate possible depends on the capabilities of the camera; that is, if the camera 
		 * doesn't support the value you set here, this frame rate will not be achieved.
		 */
		public var fps:uint;

		/**
		 * @private
		 */
		public var captureWidthHeightFactor:Number;
		
		/**
		 * Force screen share to use High Fedelity quality setting. 
		 */
		public var enableHFSS:Boolean = false;
		
		/**
		 * Bandwidth setting
		 */ 
		public var bandwidth:uint;
		
		
		/**
		 * Creates a ValueObject representation of this descriptor.
		 * 
		 * @return An Object which represents the non-default values for this descriptor, 
		 * suitable for consumption by <code>readValueObject</code>.
		 */	
		public function createValueObject():Object
		{
			var writeObj:Object = new Object();
			
			writeObj.quality = quality;
			writeObj.performance = performance;		
			writeObj.keyframeInterval = keyframeInterval;
			writeObj.fps = fps;			
			writeObj.enableHFSS = enableHFSS;			
			writeObj.bandwidth = bandwidth;					
			writeObj.captureWidthHeightFactor = captureWidthHeightFactor;
				
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
	}
}
