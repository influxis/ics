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
package com.adobe.rtc.util
{	
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.RoomSettings;
	import com.adobe.rtc.session.managers.SessionManagerFMS;
	import com.adobe.rtc.sharedManagers.RoomManager;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.SharedObject;	
	

	[Event(name="BandwidthMeterPrefsUpdate", type="flash.events.Event")]	
	
	/**
	 * @private
	 */
   public class  BandwidthMeter extends EventDispatcher
	{
		protected var _ldr:Loader;
		protected var _startTime:int;
		protected var _bytesTotal:Number;
		protected var _bytesPerSecond:Number = -1024;
		static protected var _myIP:String;
		protected var _tries:Number = 0;
		protected var _kbps:Number = -1;
		protected var _bwSpeedIPTable:Array = null;
		
		protected var _sessionManager:SessionManagerFMS;
		
		protected static var _instance:BandwidthMeter;
		
		public static const BANDWIDTH:String = "DownloadBandwidth";
		
		public static function getInstance():BandwidthMeter
		{
			if(!_instance)
				_instance = new BandwidthMeter();
			return _instance;
		}
		
		public function BandwidthMeter()
		{
			super();
			
			if(_instance)
			{
				throw new Error("BandwidthMeter instantiated outside of singleton");
			}			
		}
		
		public function set myIP(ip:String):void {
			_myIP = ip;
		}
		
		/**
		 * this is called after our fms connection is established, so we can use fms netconnection to measure bw
		 */
		public function calBandwidth():void
		{									
			getCookie(); //check for cookie first
			
			if(_kbps > 0) return;
			
			if(_sessionManager == null) {
				_sessionManager  = (ConnectSession.primarySession.sessionInternals.session_internal::sessionManager as SessionManagerFMS);
				_sessionManager.addEventListener("bwDetectionDone", onBwDetectionDone);
			}
			
			_sessionManager.detectBandwidth();
			
		}
		
		/**
		 * Once we detect the bw we set our values
		 */
		protected function onBwDetectionDone(p_evt:Event):void
		{
			_sessionManager.removeEventListener("bwDetectionDone", onBwDetectionDone);
			
			if (_sessionManager.detectedBw == 0 && _tries < 2) {
				_tries++;
				_sessionManager.addEventListener("bwDetectionDone", onBwDetectionDone);
				_sessionManager.detectBandwidth();
			} else {											
				_kbps = _sessionManager.detectedBw;
				setGlobalProperty();
				setCookie();				
			}
		}
		

		/**
		 * this is where we set the global attribute
		 */
		private function setGlobalProperty():void {
			
			var evt:Event = new Event("BandwidthMeterPrefsUpdate");
			dispatchEvent(evt);									
		}
		
		/**
		 * setting cookie of paired ip/speed, so that next time we don't measure again with same ip
		 */
		private function setCookie():void {
			var m:Object = new Object();
			m.ip = _myIP;
			m.bw = _kbps;
			
			//make sure we don't have more than 5 cached at a time
			if(_bwSpeedIPTable == null) _bwSpeedIPTable = new Array();
			else if(_bwSpeedIPTable.length >= 5) _bwSpeedIPTable.pop();
			
			_bwSpeedIPTable.push(m);
			
			var so:SharedObject = SharedObject.getLocal(BANDWIDTH, "/");
			so.data._bwSpeedTable = _bwSpeedIPTable;
			var currentDate:Date = new Date();		
			var lMillToDay:Number = 60000 * 60 * 24;
			
			so.data._expire = currentDate.getTime() + lMillToDay * 7; //seven day expiration
			
			so.flush();
		}
		
		/**
		 * getting the cookie value for checking caching speed data
		 */
		private function getCookie():void {
			var so:SharedObject = SharedObject.getLocal(BANDWIDTH, "/");
						
			if(so.data._expire != undefined) {
				var currentDate:Date = new Date();
				var expiredDate:Date = new Date(so.data._expire);
									
				if(expiredDate <= currentDate) {
					so.clear();
					return;
				}
			}			
			
			if(so.data._bwSpeedTable != undefined)
			{
				_bwSpeedIPTable = (so.data._bwSpeedTable as Array);
				for(var i:Number=0; i<_bwSpeedIPTable.length; i++) {					
					var table:Object = _bwSpeedIPTable[i];							
					if(table != null && table.hasOwnProperty("ip") && table.hasOwnProperty("bw") && table.ip == _myIP) {						
						_kbps = _bwSpeedIPTable[i].bw;
						setGlobalProperty();
					}					
				} 
			}
		}
		
		/** 
		 * returns bandwidth in kilobytes per second
		 * if negative, bandwidth test has not been administered
		 **/
		public function get kbps():Number
		{			
			return _kbps;
		}	
				
		
		
	}
}
