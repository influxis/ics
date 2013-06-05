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
package com.adobe.rtc.clientManagers
{
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.sharedManagers.StreamManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor;
	
	import flash.events.ActivityEvent;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.media.Microphone;
	
	[Event(name="activity", type="flash.events.ActivityEvent")]
	[Event(name="status", type="flash.events.StatusEvent")]

	/**
	 * MicrophoneManager is a utility component that provides features such as MicrophoneIndex, 
	 * silence timeout, echo suppression, gain, and so on. There is only one instance of it.
	 * 
	 * <p>
	 * AudioPublisher component uses it for getting and setting various microphone Properties. 
	 * Applications that use microphones use this component to alter the various settings 
	 * when AudioPublisher is not used. AudioPublisher also identifies which microphone is currently selected.
	 * </p>
	 * 
	 * @see com.adobe.rtc.collaboration.AudioPublisher
	 */
	
   public class  MicrophoneManager extends EventDispatcher
	{
		/**
		* @private
		* Implementing the singleton pattern; holds the singleton instance.
		*/
		protected static var _instance:MicrophoneManager;
		/**
		* @protected
		* Implementing the singleton pattern; only true during first creation.
		*/		
		protected static var _creating:Boolean = false;
		/**
		 * @private
		 */
		protected var _streamManager:StreamManager = ConnectSession.primarySession.streamManager;
		/**
		 * @private
		 */
		protected var _userManager:UserManager = ConnectSession.primarySession.userManager;
		/**
		 * @private
		 */
		protected var _micIndex:Number ;  //TODO what is this initially (default)?
		/**
		 * @private
		 */
		protected var _mic:Microphone;
		/**
		 * @private
		 */
		protected var _silenceLevel:Number;	
		/**
		 * @private
		 */	
		protected var _inUse:Boolean = false;	
		
		public function MicrophoneManager()
		{			
			if(!_creating) {
				throw new Error("Class cannot be instantiated.  Use getInstance() instead.");
				return;
			}
			micIndex = 0;				
		}
		
		/**
		 * Getting the MicrophoneManager Instance. It is created the first time the application
		 * calls it.
		 */
		public static function getInstance():MicrophoneManager
		{
			// Check if the singleton has been created; if not, create and return it. Otherwise, just return.
			if(!_instance) {
				_creating = true;
				_instance = new MicrophoneManager();
				_creating = false;
			}
			
			return _instance;
		}

		/**
		 * Returns the index and gain.
		 */
		public function get micState():Object
		{					
			return {micIndex:micIndex,					
					gain:gain};					
		}

		/**
		 * @private
		 */
		public function set micState(p_value:Object):void
		{
			micIndex = p_value.micIndex;		
			gain = p_value.gain;
		}

		/**
		 * @private
		 */
		[Bindable]
		public function set micIndex(p_value:Number):void
		{
			_micIndex = p_value;
			_mic = null;
			_mic = selectedMic;
		}

		/**
		 * Returns are microphone index.
		 */
		public function get micIndex():Number
		{
			return _micIndex;
		}

		/**
		 * Returns the currently selected microphone.
		 */
		public function get selectedMic():Microphone
		{
			// trace('get selected mic, player');
			if(!_mic)
			{		
				_mic = Microphone.getMicrophone(_micIndex);		
				
				if(_mic) {
					if ( _mic.hasOwnProperty("useEnhanced") ) {
						if ( (_mic as Object).useEnhanced ) {
							(_mic as Object).useEnhanced = false ; 
						}
					}
					_mic = Microphone.getMicrophone(_micIndex);	
					
					_mic.setSilenceLevel(10, 1000); // The default.			
					_mic.rate = 11; // The default is 11 which is the highest Flash player 9 supports.
					// Prevents the mutliple event listener case.
					_mic.removeEventListener(ActivityEvent.ACTIVITY, onActivity);				
					_mic.removeEventListener(StatusEvent.STATUS, onStatus);
					
					_mic.addEventListener(ActivityEvent.ACTIVITY, onActivity);				
					_mic.addEventListener(StatusEvent.STATUS, onStatus);
					
					
				}
			}
			return _mic;			
		}
		
		/**
		 * @private
		 */
		[Bindable]
		public function set echoSuppression(p_value:Boolean):void
		{		
			if(_mic){
				_mic.setUseEchoSuppression(p_value);
			}
		}
		
		/**
		 * Returns ture if there is echosuppression.
		 */
		public function get echoSuppression():Boolean
		{	
			if(_mic) {			
				return _mic.useEchoSuppression;
			} else {
				return false;
			}
		}
		
		/** 
		 * @private
		 */
		[Bindable]
		public function set silenceLevel(p_value:Number):void
		{		
			if(_mic) {
				_mic.setSilenceLevel( p_value);  // The default is 2 seconds.			
			}
		}
		
		/** 
		 * Returns the silence level.
		 */
		public function get silenceLevel():Number
		{
			if (_mic) {
				return _mic.silenceLevel;
			} else {
				return -1;
			}
		}
		
		/**
		 * @private
		 */
		[Bindable]
		public function set silenceTimeout(p_value:int):void
		{		
			if(_mic) {
				_mic.setSilenceLevel( _mic.silenceLevel, p_value );  //2 seconds is default			
			}
		}
		
		/**
		 *  Returns the silence timeout.
		 */
		public function get silenceTimeout():int
		{
			if (_mic) {
				return _mic.silenceTimeout;
			} else {
				return -1;
			}
		}
			
		
		/**
		 * @private
		 */
		[Bindable]
		public function set gain(p_value:Number):void
		{
			if (_mic) {
				_mic.gain = p_value;
			}
		}
		
		/** 
		 * Gain accepts values from 0% to 100% of the microphone's volume.
		 */ 	
		public function get gain():Number
		{
			if (_mic) {
				return _mic.gain;
			} else {
				return -1;
			}
		}	
		
		/**
		 * @private
		 */
		protected function onActivity(p_event:ActivityEvent):void
		{
			dispatchEvent(p_event);
		}
		
		/** 
		 * @private
		 * Tracks if the microphone has been muted locally through the security settings.
		 * 
		 * 
		**/
		protected function onStatus(p_evt:StatusEvent):void
		{
			//trace("Mic manager onStatus:" + p_evt.code);
			dispatchEvent(p_evt);
		}		
		
		/** 
		 * @private
		 * Tracks if the microphone is in use for remote broadcasting. 
		 **/
		public function get inUse():Boolean
		{
			var isUsed:Boolean = false;
			var streams:Object = _streamManager.getStreamsOfType(StreamManager.AUDIO_STREAM);			
			for each(var item:StreamDescriptor in streams)
			{
				if(item.streamPublisherID == _userManager.myUserID)
				{
					isUsed = true;
				}
			}			
			return isUsed;
		}
	
		
	}
}