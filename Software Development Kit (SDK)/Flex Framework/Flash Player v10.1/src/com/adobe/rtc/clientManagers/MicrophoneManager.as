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
	import com.adobe.rtc.sharedManagers.descriptors.UserDescriptor;
	import com.adobe.rtc.util.DebugUtil;
	
	import flash.events.ActivityEvent;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.media.Microphone;
	import flash.media.SoundCodec;
	 
	import flash.system.Capabilities;
	
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
		/**
		 * @private
		 */	
		protected var _encodeQuality:Number = 10 ;
		/**
		 * @private
		 */
		protected var _framesPerPacket:Number = 2 ;
		
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
				setAdvancedMicrophone();
				if(_mic) {
					
					if ( !isWasabi() ) { 
						if ( _mic.hasOwnProperty("useEnhanced") ) {
							if ( (_mic as Object).useEnhanced ) {
								(_mic as Object).useEnhanced = false ; 
							}
						}
						_mic = Microphone.getMicrophone(_micIndex);
						_mic.setSilenceLevel(10, 1000); //default
					}
					
					//first initialization
					var isPlayer9:Boolean = false ;
					for ( var i:int = 0 ; i < _userManager.userCollection.length ; i++ ) {
						if (parseInt((_userManager.userCollection.getItemAt(i) as UserDescriptor).playerVersion.split(",")[0].split(" ")[1]) <= 9 ){
							_mic.codec  =  SoundCodec.NELLYMOSER;
							isPlayer9 = true 
							break ;
						}
					}
					
					
					if ( !isPlayer9 ) {
						_mic.codec = SoundCodec.SPEEX;
						_mic.encodeQuality = _encodeQuality ;
						_mic.framesPerPacket = _framesPerPacket ;
					} 
					//_mic.codec  =  SoundCodec.NELLYMOSER;			
					//_mic.rate = 11; //default, highest player 9 will support
					//Prevents the mutliple event listener case
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
		protected function setAdvancedMicrophone():void
		{
			  
			_mic = Microphone.getMicrophone(_micIndex);
		}
		
		/**
		 * @private
		 */
		protected function isWasabi():Boolean
		{
			var currentVersion:Array = Capabilities.version.split(" ")[1].split(",") ;
			if (currentVersion[0] > 10) {
				return true;
			} else {
				return (currentVersion[0] >= 10 && currentVersion[1] >= 3) ;
			}
		}
		
		
		/**
		 * @private
		 */
		public function set selectedMic(p_mic:Microphone):void
		{
			_mic = p_mic ;
		}
		
		/**
		 * @private
		 */
		[Bindable]
		public function set codec(p_value:String):void
		{		
			if(_mic ){
				_mic.codec = p_value;
				if ( _mic.codec.toLowerCase() == SoundCodec.SPEEX.toLowerCase() ) {
					_mic.encodeQuality = _encodeQuality ;
					_mic.framesPerPacket = _framesPerPacket ;
				}
			}
		}
		
		/**
		 * Returns the code i.e. SPEEX or NELLYMOSER
		 */
		public function get codec():String
		{	
			if(_mic) {			
				return _mic.codec;
			} else {
				return null;
			}
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
		 * Returns the silence level[read-only].
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
		 * gain accepts values from 0% to 100% of the mic's volume
		 */ 
		
		[Bindable]
		public function set encodeQuality(p_value:Number):void
		{
			if (_mic && _mic.codec.toLowerCase() == SoundCodec.SPEEX.toLowerCase()) {
				_mic.encodeQuality = p_value;
				_encodeQuality = p_value ;
			}else {
				_encodeQuality = p_value ;
			}
		}	
		public function get encodeQuality():Number
		{
			return _encodeQuality ;
		}
		
		/** 
		 * Frames per packet .. default value is 2.
		 */ 
		
		[Bindable]
		public function set framesPerPacket(p_value:int):void
		{
			if (_mic && _mic.codec.toLowerCase() == SoundCodec.SPEEX.toLowerCase()) {
				_mic.framesPerPacket = p_value;
				_framesPerPacket = p_value ;
			}else {
				_framesPerPacket = p_value ;
			}
		}	
		public function get framesPerPacket():int
		{
			return _framesPerPacket ;
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