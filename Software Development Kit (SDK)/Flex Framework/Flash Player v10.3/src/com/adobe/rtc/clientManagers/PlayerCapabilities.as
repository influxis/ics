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
	import flash.system.Capabilities;
	import flash.events.EventDispatcher;
	import adobe.utils.ProductManager;
	
	/**
	 * 
	 * PlayerCapabilities is a utility component that provides properties like the cureent OS,
	 * if it's debug version of Flash Player etc.  There can be only one 
	 * instance of PlayerCapabilities class. It's APIs mostly use flash.system.Capabilities 
	 * class in the Flash player. </p>
	 */
	
   public class  PlayerCapabilities extends EventDispatcher
	{
		/**
		* @private
		* 
		* Implementing the singleton pattern and holding the singleton instance.
		*/
		protected static var _instance:PlayerCapabilities;
		/**
		* @private
		*
		* Implementing the singleton pattern; it is only true during its initial creation.
		*/
		protected static var _creating:Boolean = false;
		
		/**
		 * @private
		 */
		public var canDownloadAddIn:Boolean = true;
		/**
		 * @private
		 */
		protected var _platform:String;
		/**
		 * @private
		 */
		protected var _playerMajorVersion:Number;
		/**
		 * @private
		 */
		protected var _revision:Number;
		/**
		 * @private
		 */
		protected var _hasFullScreen:Boolean;
		
		public function PlayerCapabilities()
		{	
			if(!_creating) {
				throw new Error("Class cannot be instantiated.  Use getInstance() instead.");
				return;
			}
			
			_platform = Capabilities.os.toLowerCase();
			
			var vers:Array = Capabilities.version.split(",");
			_revision = parseInt(vers[2]); //user's current player rev "0"
			_playerMajorVersion = parseInt(vers[0].split(" ")[1]); // "6" user's current player version	
			
			if ( _playerMajorVersion < 9 ) {
				// If the flash player version is less than 9, always false
				_hasFullScreen = false ;
			}else if ( _playerMajorVersion == 9 ) {
				// if it is equal to 9, it should be at least secondary version greater than equal to 28
				_hasFullScreen = (vers[1]>=0 && vers[2]>= 28 )  ;
			}else {
				// If the player version is higher than 9, then it should be version 1 
				// and version 2 greater than 0.
				_hasFullScreen = ( vers[1]>=0 && vers[2]>= 0 ) ; 
			}
			
			
		}

		/**
		 * Static function to get the instance of it.
		 */
		public static function getInstance():PlayerCapabilities
		{
			// Checks if the singleton has been created; if not, it creates and 
			// returns the instance. Otherwise, it just returns.
			if(!_instance) {
				_creating = true;
				_instance = new PlayerCapabilities();
				_creating = false;
			}
			
			return _instance;
		}
	
		/**
		 * @private
		 */
		public function get hasFullScreen():Boolean
		{
			return _hasFullScreen;
		}
		
		/**
		 * Returns the platform string.
		 */
		public function get platform():String
		{
			return _platform;
		}	
		
		/**
		 * Returns true if using the Mac OS.
		 */
		public function get isOnMac():Boolean
		{
			return (_platform.toLowerCase().indexOf("mac os") != -1);
		}
		
		/**
		 * Returns true if using the debug version of the Flash player.
		 */
		public function get isDebuggingPlayer():Boolean
		{
			return Capabilities.isDebugger;
		}	
	}
}
