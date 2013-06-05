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
package com.adobe.rtc.session.managers
{
	import com.adobe.coreUI.localization.ILocalizationManager;
	import com.adobe.coreUI.localization.Localization;
	import com.adobe.rtc.core.messaging_internal;
	
	import com.adobe.rtc.events.SessionEvent;
	import com.adobe.rtc.session.sessionClasses.FMSConnector;
	import com.adobe.rtc.util.DebugUtil;
	
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.Responder;
	import flash.utils.Timer;
	import flash.utils.setTimeout ;
	
	import com.adobe.rtc.core.session_internal ;
	
	use namespace session_internal;
	
	/**
	 * Dispatched when the bandwidth detection triggered by detectBandwidth is done.
	 * Look at detectedBandwidth and detectedLatency for results.
	 *
	 * @eventType flash.events.Event
	 */
	[Event(name="bwDetectionDone", type="flash.events.Event")]
		
	/**
	 * @private
	 */
   public class  SessionManagerFMS extends SessionManagerBase
	{
		public static const CONNECTION_RECONNECTING:String = "connectionReconnecting";
		public static const CONNECTION_GOOD:String = "connectionGood";
		public static const CONNECTION_FAIR:String = "connectionFair";

		protected static const PING_TIMER_INTERVAL:int = 8000;

		//TODO: public getters/setters?
		protected static const CONNECTION_GOOD_THRESHHOLD:int = 500;
		protected static const CONNECTION_FAIR_THRESHHOLD:int = 4000;
		
		protected static const PING_HISTORY_LENGTH:int = 10;

		protected var _fmsConnector:FMSConnector;
		protected var _ticket:String;
		protected var _detectedLatency:Number;
		protected var _detectedBw:Number;

		protected var _autoPing:Boolean = true;
		protected var _autoPingTimer:Timer;
		protected var _pingHistory:Array;				// a queue, holding the last ten ping request data
		protected var _responder:Responder;
		protected var _connectionStatus:String = CONNECTION_GOOD;	//until proven guilty
		protected var _rejected:Boolean = true ;
		
		protected var _lm:ILocalizationManager;
		
		

		public function SessionManagerFMS(p_ticket:String="", p_roomName:String="A")
		{
			super();
			isLocalManager = false;
			
			_fmsConnector = new FMSConnector();
			_fmsConnector.appName = "cocomo";
			_fmsConnector.methodHandlerObject = this;
			_fmsConnector.addEventListener("connected", onFmsConnectorConnect);
			_fmsConnector.addEventListener("disconnect", onFmsConnectorDisconnect);
			_fmsConnector.addEventListener("failed", onFmsConnectorFailed);

			_pingHistory = new Array();
						
			// set up connection and responder
			_responder = new Responder(onPingResult);
			
			_autoPingTimer = new Timer(PING_TIMER_INTERVAL, 0);
			_autoPingTimer.addEventListener(TimerEvent.TIMER, onAutoPingTimer);
		}
		
		public function get ticket():String
		{
			return _ticket;
		}

		/**
		 * This will trigger automatic bandwidth detection. When the calculation is done, a "bwDetectionDone" event is dispatched.
		 */
		public function detectBandwidth():void
		{
			_fmsConnector.nc.call("_checkbw", null);
		}

		/**
		 * returns the latency detected from detectBandwidth
		 */
		public function get detectedLatency():Number
		{
			return _detectedLatency;
		}
		/**
		 * returns the latency detected from detectBandwidth
		 */
		public function get detectedBw():Number
		{
			return _detectedBw;
		}

		public function get automaticPing():Boolean
		{
			return _autoPing;
		}
		
		public function set automaticPing(p_automaticPing:Boolean):void
		{
			_autoPing = p_automaticPing;
			updateAutoPingTimer();
		}
		
		public function pingNow():void
		{
			if (_fmsConnector.nc.connected) {
				_fmsConnector.nc.call("getStats", _responder);
			}
		}

		public function get connectionStatus():String
		{
			return _connectionStatus;
		}
		
		protected function updateAutoPingTimer():void
		{
			//clear the interval for good measure
			_autoPingTimer.reset();
			_autoPingTimer.stop();
			
			if (_autoPing) {
				_autoPingTimer.start();
			}
		}
		
		protected function onAutoPingTimer(p_evt:TimerEvent):void
		{
			pingNow();	
		}

		protected function onPingResult(p_data:Object):void
		{
			var event:SessionEvent = new SessionEvent(SessionEvent.PING);
			event.rawPingData = p_data;
			// The Ping History stores the last PING_HISTORY_LENGTH number of pings.
			// So that we don't get wildly-fluctuating results, we average all of them and use those
			//   numbers instead of the fresh new ones each time.
			if (!_lm) {
				_lm = Localization.impl;
			}
			// If _pingHistory is full, get rid of the oldest one.
			if(_pingHistory.length == PING_HISTORY_LENGTH) {
				_pingHistory.shift();
			}
			p_data.time = (new Date()).getTime();
			_pingHistory.push(p_data);
			
			// Find highest edge_rtt
			var ping_rtt:int = 0;
			for(var i:String in _pingHistory) {
				if(_pingHistory[i].ping_rtt > ping_rtt) {
					ping_rtt = _pingHistory[i].ping_rtt;
				}
			}
			
			var previousConnectionStatus:String = _connectionStatus;

			if ( _fmsConnector.nc && _fmsConnector.nc.connected ) {
				if(ping_rtt < CONNECTION_GOOD_THRESHHOLD) {
					_connectionStatus = CONNECTION_GOOD;
				}else {
					_connectionStatus = CONNECTION_FAIR;
				}
			} else {
				_connectionStatus = CONNECTION_RECONNECTING ;
			}
			
			if (_connectionStatus != previousConnectionStatus) {
				var connStatusEvent:SessionEvent = new SessionEvent(SessionEvent.CONNECTION_STATUS_CHANGE);
				connStatusEvent.connectionStatus = _connectionStatus;
				dispatchEvent(connStatusEvent);
			}
			
			var originLat:String;
			if(p_data.ping_rtt < 1) {
				originLat = "< 1 "+_lm.getString("msec");
			}
			else {
				var originLatency:Object = formatTime(p_data.ping_rtt / 1000);
				originLat = originLatency.value + " " + originLatency.unit;
			}
			event.latency = p_data.ping_rtt/1000;
			event.latencyString = originLat;
		
			// Calculate upload rate.
			var uploadRate:Object = formatRate(p_data.bw_in * 8);
			event.bwUp = p_data.bw_in*8;
			event.bwUpString = uploadRate.value + " " + uploadRate.unit;
			
			// Calculate download rate.
			var downloadRate:Object = formatRate(p_data.bw_out * 8);
			event.bwDown = p_data.bw_out*8;
			event.bwDownString = downloadRate.value + " " + downloadRate.unit;

			dispatchEvent(event);
		}
		
		/**
		 * @private, required by FMS for bw detection
		 */
		public  function _onbwcheck(p_data:Object, p_ctx:Object):Object
		{
//			trace("_onbwcheck");
			return p_ctx;
		}
		
		/**
		 * @private
		 */
		public function _onbwdone(p_latency:Number, p_bw:Number):void
		{
			_detectedLatency = p_latency;
			_detectedBw = p_bw;
			dispatchEvent(new Event("bwDetectionDone"));
		}
				
		/**
		 * @private
		 */
		protected function onFmsConnectorConnect(p_evt:Event):void
		{
			//trace("connected!");
			//trace("rtmps? "+_fmsConnector.usingRTMPS+", tunneling? "+_fmsConnector.tunneling);
			_fmsConnector.resetAttemptNumber();
		}

		protected function onFmsConnectorFailed(p_evt:Event):void
		{
			//what should I do?
			
			_autoPingTimer.stop();	//just in case
		}
		
		/**
		 * @private
		 */
		protected function onFmsConnectorDisconnect(p_evt:Event):void
		{
			disconnect();
			
			_connectionStatus = CONNECTION_RECONNECTING;
			var connStatusEvent:SessionEvent = new SessionEvent(SessionEvent.CONNECTION_STATUS_CHANGE);
			connStatusEvent.connectionStatus = _connectionStatus;
			dispatchEvent(connStatusEvent);
			
			_autoPingTimer.stop();	//just in case
		}
				
		override public function receiveLogin(p_userData:Object):void
		{

			session_internal::connection = _fmsConnector.nc;
			_ticket = p_userData.ticket;
			_fmsConnector.connectionParameters = new Array(_ticket);	//use the new ticket for reconnects

			//start the ping timer now
			updateAutoPingTimer();

			super.receiveLogin(p_userData);	
			
		}
		
		/**
		 * The response to the "login" RPC if something went wrong on the server.
		 * Notifies the session that the connectiong has failed
		 * @param p_error  the error message
		 */
		override public function receiveError(p_error:Object /*contains .message and .name*/):void
		{
			// by default, errors during login cause a full disconnect
			_fmsConnector.disconnect();				
			if (p_error.name == "WRONG_HOST") {
				//need to disconnect and call /fms again
				_fmsConnector.tryNextOrigin();
			} else {
				super.receiveError(p_error);
			}
		}		
		
		override session_internal function login():void
		{
			_ticket = "0";

			_fmsConnector.appInstanceName = "defaultRoom";

			var origin:String = "10.133.192.176";	// GUMBY
//			var origin:String = "206.80.15.17";	// public
//			var origin:String = "localhost";

			_fmsConnector.origins = new Array(origin);
			_fmsConnector.originPort = 1935;
			_fmsConnector.connectionParameters = new Array(ticket);

			try {
				_fmsConnector.connect();	
			} catch (e:Error) {
				throw e;
			}
		}
		
		override session_internal function logout():void
		{
			try {
				_fmsConnector.disconnect();	
			} catch (e:Error) {
				throw e;
			}
		}
		
		override session_internal function subscribeCollection(p_collectionName:String=null, p_nodeNames:Array=null):void
		{
			if (_fmsConnector.nc==null) {
				return;
			}
			_fmsConnector.nc.call("subscribeCollection", null, p_collectionName, p_nodeNames);
		}

		override session_internal function unsubscribeCollection(p_collectionName:String=null):void
		{
			_fmsConnector.nc.call("unsubscribeCollection", null, p_collectionName);
		}
		
		override session_internal function createNode(p_collectionName:String, p_nodeName:String, p_nodeConfigurationVO:Object=null):void
		{
			_fmsConnector.nc.call("createNode", null, p_collectionName, p_nodeName, p_nodeConfigurationVO);
		}
		
		override session_internal function configureNode(p_collectionName:String, p_nodeName:String, p_nodeConfigurationVO:Object):void
		{
			_fmsConnector.nc.call("configureNode", null, p_collectionName, p_nodeName, p_nodeConfigurationVO);
		}
		
		override session_internal function removeNode(p_collectionName:String, p_nodeName:String=null):void
		{
			_fmsConnector.nc.call("removeNode", null, p_collectionName, p_nodeName);
		}
		
		
		override session_internal function publishItem(p_collectionName:String, p_nodeName:String, p_itemVO:Object, p_overWrite:Boolean=false,p_p2pDataMessaging:Boolean=false):void
		{
				
				_fmsConnector.nc.call("publishItem", null, p_collectionName, p_nodeName, p_itemVO, p_overWrite);
				
		}

		override session_internal function retractItem(p_collectionName:String, p_nodeName:String, p_itemID:String=null):void
		{
			_fmsConnector.nc.call("retractItem", null, p_collectionName, p_nodeName, p_itemID);
		}
		
		override session_internal function fetchItems(p_collectionName:String, p_nodeName:String, p_itemIDs:Array):void
		{
			_fmsConnector.nc.call("fetchItems", null, p_collectionName, p_nodeName, p_itemIDs);
		}
		
		override session_internal function setUserRole(p_userID:String, p_role:int, p_collectionName:String=null, p_nodeName:String=null):void
		{
			_fmsConnector.nc.call("setUserRole", null, p_userID, p_role, p_collectionName, p_nodeName);
		}
		
		override session_internal function getAndPlayAVStream(p_streamID:String, p_peerID:String=null):NetStream
		{
			if ( p_streamID == null ) {
				return null ;
			}
			
			var netStream:NetStream ;
			if ( p_peerID != null ) {
				netStream = new NetStream(connection as NetConnection,p_peerID);
			}else {
				netStream = new NetStream(connection as NetConnection,NetStream.CONNECT_TO_FMS);
			}
			
			
			netStream.play(p_streamID);
			netStream.addEventListener(NetStatusEvent.NET_STATUS,onStreamNetStatus);
			return netStream ;
		}
		
		protected function formatNumber(p_value:Number):Object
		{
			var result:Object;
	
			if ( p_value < 0.001 )
				result = {value:0,exponent:0};
			else if ( p_value < 1 )
				result = {value:p_value*1000, exponent:-3};
			else if ( p_value < 1000 )
				result = {value:p_value, exponent:0};
			else if ( p_value < 1000000 )
				result = {value:p_value/1000, exponent:3};
			else if ( p_value < 1000000000 )
				result = {value:p_value/1000000, exponent:6};
	
			if ( result.value < 10 )
				result.value = (Math.round(result.value*100))/100;
			else if ( result.value < 100 )
				result.value = (Math.round(result.value*10))/10;
			else
				result.value = Math.round(result.value);
	
			return result;
		}
	
		protected function formatTime(p_value:Number):Object
		{
			var fixp:Object = formatNumber(p_value);
			if ( fixp.exponent == -3 )
				fixp.unit = _lm.getString("msec");
			else if ( fixp.exponent == 0 )
				fixp.unit = _lm.getString("sec");
	
			return fixp;
		}
			
		protected function formatRate(p_value:Number):Object
		{
			var fixp:Object = formatNumber(p_value);
	
			if ( fixp.exponent == -3 ) {
				fixp.value = 0; fixp.exponent = 0;
			} else if ( fixp.exponent == 0 ) {
				fixp.value = fixp.value / 1000;
				fixp.unit = _lm.getString("bit/s");
			} else if ( fixp.exponent == 3 )
				fixp.unit = _lm.getString("kbit/s");
			else if ( fixp.exponent == 6 )
				fixp.unit = _lm.getString("mbit/s");
	
			return fixp;
		}
	
		
		
		protected function onStreamNetStatus(e:NetStatusEvent):void
		{
			dispatchEvent(e);
		}
		
	}
}
