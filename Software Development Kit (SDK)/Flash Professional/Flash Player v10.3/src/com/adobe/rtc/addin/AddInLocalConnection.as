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
package com.adobe.rtc.addin
{
	import flash.net.LocalConnection;
	import flash.events.StatusEvent;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import com.adobe.rtc.events.AddInLauncherEvent;
	import com.adobe.rtc.util.DebugUtil;

	/**
	 * Dispatched when the AddIn is launched.
	 *
	 * @eventType com.adobe.rtc.events.AddInLauncherEvent
	 */
	[Event(name="launch", type="com.adobe.rtc.events.AddInLauncherEvent")]

	/**
	 * Dispatched when the AddIn launch fails.
	 *
	 * @eventType com.adobe.rtc.events.AddInLauncherEvent
	 */
	[Event(name="fail", type="com.adobe.rtc.events.AddInLauncherEvent")]

	/**
	 * @private
	 * @see author Peldi Guilizzoni
	 */
	
   public class  AddInLocalConnection extends LocalConnection
	{		
		private var _bWaiting:Boolean;
		private var _lcName:String;
		private var _counter:Number;
		private var _minVersion:String;
		private var _retryTimer:Timer;
		private var _urlToOpen:String;

		private var IP_PATTERN:RegExp = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
		
		public function AddInLocalConnection(p_minVersion:String, p_urlToOpen:String):void
		{
			super();
			
			allowDomain("*");
			allowInsecureDomain("*");

			addEventListener(flash.events.StatusEvent.STATUS, onStatus);

			_minVersion = p_minVersion;	
			_urlToOpen = p_urlToOpen;
			_bWaiting = false;
				
			_retryTimer = new Timer(100, 0);
			_retryTimer.addEventListener(flash.events.TimerEvent.TIMER, trySend);
	
			// Find a connect id for response messages
			for (var i:uint=0; i<200; i++) {
				_lcName = "Cocomo" + i;
				try {
//					trace("trying to connect to "+_lcName);
					connect(_lcName);

					DebugUtil.debugTrace("#AddInLocalConnection# connected to " + _lcName);
					return;
				} catch (e:ArgumentError) {
//					trace("WARNING: connection "+_lcName+" taken, trying another ("+e.message+")");
				}
			}

			DebugUtil.debugTrace("#AddInLocalConnection# ERROR: couldn't connect!");
		}
	
		//self-listening to this one (yuck!)
		/**
		 * @private
		 */
		protected function onStatus(p_info:StatusEvent):void
		{
//			trace("#AddInLocalConnection# onStatus:"+p_info.code+", "+p_info.level);
			DebugUtil.debugTrace("#AddInLocalConnection# onStatus:"+p_info.code+", "+p_info.level);
			if (p_info.level == "status"){
				// The message was dispatched, we should get an InstallStatus response
				_retryTimer.stop();
			} else {
				// The message was dropped.
				if (_bWaiting) {
					// send was on the timer
					if (_counter++ > 60) {
						_retryTimer.stop();	// give up
						var e:AddInLauncherEvent = new AddInLauncherEvent(AddInLauncherEvent.FAIL);
						dispatchEvent(e);
					}
				}
			}
			_bWaiting = false;
		}
	
	
		public function startTimer():void
		{
			if (!_retryTimer.running) {
				// Start a .1 second interval, and retry
				_retryTimer.start();
				_counter = 0;
			}
		}
	
		private function trySend(p_evt:TimerEvent):void
		{
			// send the open request to the listener
			if (!_bWaiting) {	// don't send again if we are still waiting for a status
				_bWaiting = true;
				var a:Array = domain.split(".");
				if (a.length>2 && !IP_PATTERN.test(domain)) {
					// xxx.domain.com -> domain.com
					a.shift();
				}
				var fuzzedDomain:String = a.join(".");
//				trace("#AddinLocalConnection# calling installService: domain:"+domain+", _lcName:"+_lcName+", fuzzedDomain:"+fuzzedDomain+", url:"+_urlToOpen);
				DebugUtil.debugTrace("#AddinLocalConnection# calling installService: domain:"+domain+", _lcName:"+_lcName+", fuzzedDomain:"+fuzzedDomain+", url:"+_urlToOpen+", version:"+_minVersion);
				send("localhost:breeze", "installService", _urlToOpen, fuzzedDomain + ":" + _lcName, _minVersion);				
			}
		}
			
		//called by the Listener.as
		public function InstallStatus(p_info:Object):void
		{
			// the listener called us back with status...
//			trace("#AddInLocalConnection# InstallStatus: "+p_info.code+", v:"+p_info.version);
			DebugUtil.debugTrace("#AddInLocalConnection# InstallStatus: "+p_info.code+", version:"+p_info.version);
	
			_retryTimer.stop();

			var bNeedUpdate:Boolean = (p_info.code == "Open.NeedUpdate");
			if (bNeedUpdate) {
				send("localhost:breeze", "quit");
			}
			
			var e:AddInLauncherEvent;
			if (bNeedUpdate) {
				e= new AddInLauncherEvent(AddInLauncherEvent.FAIL);
				e.version = p_info.version;
			} else {
				e = new AddInLauncherEvent(AddInLauncherEvent.LAUNCH);
			}
			dispatchEvent(e);
		}
	}
}
