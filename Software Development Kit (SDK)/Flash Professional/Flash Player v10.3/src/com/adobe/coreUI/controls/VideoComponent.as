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
package com.adobe.coreUI.controls
{
	import com.adobe.rtc.util.Invalidator;
	
	import flash.display.Sprite;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.net.NetStream;
	import flash.utils.Dictionary;
	import flash.display.Graphics;
	
import flash.display.Sprite //FlashOnlyReplacement 
 import flash.events.Event; //FlashOnlyReplacement;

	/**
	 * @private
	 *
	 *
	 *
	 */
public class VideoComponent extends Sprite //FlashOnlyReplacement
	{
		
		/**
	 	 *
	 	 */
		protected static var _registeredVideos:Dictionary = new Dictionary(true);
		
		/**
		 * @private
		 */
		protected var _deblocking:int = 0 ;
		
		protected const invalidator:Invalidator = new Invalidator();
		
		/**
	 	 *
	 	 */
		protected static function registerVideo(p_videoComponent:VideoComponent):void
		{
			_registeredVideos[p_videoComponent] = p_videoComponent;
		}
		
		/**
	 	 *
	 	 */
		protected static function unregisterVideo(p_videoComponent:VideoComponent):void
		{
			_registeredVideos[p_videoComponent] = null;
			delete _registeredVideos[p_videoComponent];
		}
		
		/**
	 	 *
	 	 */
		public static function prepareForBitmapCapture():void
		{
			for (var i:* in _registeredVideos) {
				var vid:VideoComponent = i as VideoComponent;
				if (!vid.isLocalCam) {
					vid.attachNetStream(null, true);
				}
			}
		}
		
		/**
	 	 *
	 	 */
		public static function endBitmapCapture():void
		{
			for (var i:* in _registeredVideos) {
				var vid:VideoComponent = i as VideoComponent;
				if (!vid.isLocalCam) {
					vid.attachNetStream(vid._savedNetStream);
				}
			}
		}
		
		/**
	 	 *
	 	 */
		protected var _video:Video;
		
		/**
	 	 *
	 	 */
		protected var _savedNetStream:NetStream;
		
		/**
	 	 *
	 	 */
		protected var _netStream:NetStream;
		
		/**
	 	 *
	 	 */
		protected var _camera:Camera;
		
		/**
	 	 *
	 	 */
		protected var _hitArea:Sprite;
		
		
		/**
	 	 *
	 	 */
public function VideoComponent():void 
 { 
 super(); 
 addEventListener(Event.ADDED_TO_STAGE, onAddTOStage); 
 } 
 public function onAddTOStage(p_evt:Event):void
		{
			registerVideo(this);

			_hitArea = new Sprite();
			if(!_video) {
_video = new Video();
 if (width > 0) { //Hack. To be looked into later 
_video.width = width; 
 }
 if (height > 0) {
_video.height = height; 
}
				addChild(_video);
				if (_netStream) {
					_video.attachNetStream(_netStream);
				}
				if (_camera) {
					_video.attachCamera(_camera);
				}
				_video.smoothing = true;				
			}
			addChild(_hitArea);
		}
		
		/**
	 	 *
	 	 */
		public function close():void
		{
			unregisterVideo(this);
			attachNetStream(null);
			_netStream = null;
			_savedNetStream = null;
		}

		 
		
	/**
	 *
	 *
	 *
	 *
	 */
		public function get isLocalCam():Boolean
		{
			return (_camera!=null);
		}
		
		
	/**
	 *
	 *
	 *
	 * @param p_netStream
	 * @param p_isForManHandling 
	 */
		public function attachNetStream(p_netStream:NetStream, p_isForManHandling:Boolean=false):void
		{
			if (p_isForManHandling) {
				_savedNetStream = _netStream;
			} else if (p_netStream==_savedNetStream) {
				// restoring the saved stream, release it for GC purposes
				_savedNetStream = null;
			}
			if (_video) {
				_video.attachNetStream(p_netStream);
			}
			_netStream = p_netStream;
		}

	/**
	 *
	 *
	 *
	 *
	 */
		public function clear():void
		{
			if (_video) {
				_video.clear();
			}
		}

	/**
	 *
	 *
	 *
	 *@param p_camera 
	 */
		public function attachCamera(p_camera:Camera):void
		{
			if (_video) {
				_video.attachCamera(p_camera);
			}
			_camera = p_camera;
		}
		
public function move(p_x:Number, p_y:Number):void
	    {
	        if (p_x != super.x)
	        {
	            super.x = p_x;
	        }
	
	        if (p_y != super.y)
	        {
	            super.y = p_y;
	        }
	        
	         
	    }
	    
	    public function get deblocking():int 
	    {
	    	return _deblocking ;
	    }
	    
	    
	    public function set deblocking(p_deblocking:int):void
	    {
	    	if ( _deblocking == p_deblocking ) {
	    		return ;
	    	}
	    	
			_deblocking = p_deblocking ;
			
			 
	    }
	    
	}
}
