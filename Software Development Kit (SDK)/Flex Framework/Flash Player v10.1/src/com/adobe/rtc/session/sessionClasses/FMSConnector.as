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
package com.adobe.rtc.session.sessionClasses
{
	import com.adobe.rtc.util.DebugUtil;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.NetConnection;
	import flash.net.ObjectEncoding;
	import flash.utils.Dictionary;
	import flash.utils.Timer;

	/**
	 * Dispatched when the connection or reconnection succeeds
	 *
	 * @eventType flash.events.Event
	 */
	[Event(name="connected", type="flash.events.Event")]

	/**
	 * Dispatched when the connection is severed
	 *
	 * @eventType flash.events.Event
	 */
	[Event(name="disconnect", type="flash.events.Event")]

	/**
	 * Dispatched when the connection fails, even after .maxConnectionAttempts attempts
	 *
	 * @eventType flash.events.Event
	 */
	[Event(name="failed", type="flash.events.Event")]
	
	/**
	 * @private
	 * This component connects a client to FMS. You pass it a set of protocols, ports, origins and edges (optional)
	 * and it does the right thing to connect you through firewalls and proxies if necessary.
	 * 
	 * This component also automatically deals with automatically reconnecting.
	 * 
	 * 
	 */
	
   public class  FMSConnector extends EventDispatcher
	{
		//include "../core/Version.as";
		
		protected var _appName:String;
		protected var _appInstanceName:String;
		protected var _edges:Array;
		protected var _origins:Array;
		protected var _originPort:Number = -1;
		protected var _protos:Array;	//of ProtocolPortPair
		protected var _maxAttempts:uint = 2;
		protected var _connectionParameters:Array;
		protected var _methodHandlerObject:*;
		
		protected var _currentAttempt:Number = 0;
		protected var _protoIndex:Number = 0;		
		protected var _edgesIndex:Number = 0;
		protected var _originsIndex:Number = 0;
		protected var _tempNCs:Array;
		protected var _mainNC:NetConnection;
		protected var _nextConnectTimer:Timer;
		protected var _timeOutTimer:Timer;
		protected var _giveUpReconnectingTimer:Timer;
		protected var _startFreshTimer:Timer;
		protected var _bProxyFallbackAttempted:Boolean = false;
		protected var _endDialogCounter:Number = 0;
		protected var _bTooManyEndDialogs:Boolean = false;
		
		protected var _ncDictionary:Dictionary;
		
		protected var _bIsTunneling:Boolean = false;
		protected var _bUsingRTMPS:Boolean = false;
		
		protected var _lastOriginTried:String;
		
		public var version:String;
		
		/*
		* Constructor - sets up defaults
		*/
		function FMSConnector():void
		{
			_ncDictionary = new Dictionary(true);

			//set up default _protos
			_protos = [new ProtocolPortPair("rtmp", 1935)];

			_nextConnectTimer = new Timer(5000);
			_nextConnectTimer.addEventListener(TimerEvent.TIMER, onNextConnectTimer); 

			_timeOutTimer = new Timer(8000, 1);
			_timeOutTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimeOutTimerComplete); 

			_giveUpReconnectingTimer = new Timer(90000, 1);
			_giveUpReconnectingTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onDoneRetryingTimerComplete); 
			
			_startFreshTimer = new Timer(5000, 1);
			_startFreshTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onStartFreshTimerTimerComplete);
		}
		
		/**
		 * 
		 * The application name to connect to. Required.
		 */
		[Inspectable(defaultValue=null)]
		public function get appName():String
		{
			return _appName;
		}
		/**
		 * @private
		 */		
		public function set appName(p_name:String):void
		{
			if ((p_name.length == 0) || (p_name == null)) {
				throw new Error("invalid input");
			}
			
			_appName = p_name;
		}
		
		/**
		 * The application instance name to connect to. Optional.
		 * @default = _defInst_
		 */
		[Inspectable(defaultValue=null)]
		public function get appInstanceName():String
		{
			return (_appInstanceName == null) ? "_defInst_" : _appInstanceName;
		}
		/**
		 * @private
		 */		
		public function set appInstanceName(p_name:String):void
		{
			_appInstanceName = p_name;
		}

		/**
		 * This will be assigned to the .client property of the NetConnection that goes through
		 * Pass an object to receive server-to-client method calls
		 */
		[Inspectable(defaultValue=null)]
		public function get methodHandlerObject():*
		{
			return _methodHandlerObject;
		}
		/**
		 * @private
		 */		
		public function set methodHandlerObject(p_obj:*):void
		{
			if (!(p_obj is Object)) {
				throw new Error("methodHandlerObject must be an object!");
				return;
			}
			_methodHandlerObject = p_obj;
		}
		
		/**
		 * An Array of edge server names to use. Optional.
		 */
		[Inspectable(defaultValue=null)]
		public function get edges():Array
		{
			return _edges;
		}
		/**
		 * @private
		 */		
		public function set edges(p_list:Array):void
		{
			if (p_list == null || p_list.length == 0) {
				throw new Error("must specify at least one edge");
				return;				
			}
			for each (var edge:* in p_list) {
				if (!(edge is String)) {
					throw new Error("edge is not a string");
					return;
				}
				if (edge.length == 0) {
					throw new Error("edge cannot be an empty string");
					return;
				}
				if (edge.indexOf(":") != -1) {
					throw new Error("don't pass a port as part of the edge name, pass it under protocols instead");
					return;
				}
			}
			
			_edges = p_list;
		}

		/**
		 * An array of origin servers to connect to. Required
		 */
		[Inspectable(defaultValue=null)]
		public function get origins():Array
		{
			return _origins;
		}
		/**
		 * @private
		 */		
		public function set origins(p_list:Array):void
		{			
			if (p_list == null || p_list.length == 0) {
				throw new Error("invalid input");
				return;				
			}
			for each (var origin:* in p_list) {
				if (!(origin is String) || (origin.length == 0) || (origin.indexOf(":") != -1)) {
					throw new Error("invalid input");
					return;
				}
			}
			
			_origins = p_list;
		}
		
		/**
		 * The port on the origin server to connect to. Optional.
		 * If this is not specified, the component will use the ports specified in protocols
		 */
		[Inspectable(defaultValue=-1)]
		public function get originPort():Number
		{
			if (_originPort == -1) {
				var protoPortTuple:ProtocolPortPair = _protos[_protoIndex];
				return protoPortTuple.port;
			} else {
				return _originPort;
			}
		}
		/**
		 * @private
		 */		
		public function set originPort(p_port:Number):void
		{
			_originPort = p_port;
		}

		/**
		 * An Array of ProtocolPortPair instances to use when connecting.
		 * If edges are used, the component will use these protocol/port pairs for connecting to the edge(s), and use rtmp://origin[x]:originPort/ as the origin connection string.
		 * If edges are NOT used, the component will use these protocol/port pairs for connecting to the origin, and ignore the originPort variable.
		 * @default [{"rtmp", 1935}, {"rtmps", 443}]
		 */
		[Inspectable(defaultValue="[{rtmp,1935}, {rtmps,443}]")]
		public function get protocols():Array
		{
			return _protos;
		}
		/**
		 * @private
		 */		
		public function set protocols(p_list:Array):void
		{
			if (p_list == null || p_list.length == 0) {
				throw new Error("must specify at least one protocol/port pair");
				return;				
			}
			for each (var protoPortTuple:* in p_list) {
				if (!(protoPortTuple is ProtocolPortPair)) {
					throw new Error("invalid protocol-port tuple");
					return;
				}
			}
			myTrace("protocols: "+p_list); 
			_protos = p_list;
		}
	
		/**
		 * How many time should this component try to connect or reconnect before giving up?
		 * @default 20
		 */
		[Inspectable(defaultValue=20)]
		public function get maxConnectionAttempts():uint
		{
			return _maxAttempts;
		}
		/**
		 * @private
		 */		
		public function set maxConnectionAttempts(p_attempts:uint):void
		{
			if (p_attempts<1) {
				throw new Error("invalid input");
				return;
			}
			
			_maxAttempts = p_attempts;
		}

		/**
		 * Used to pass an Array of connection parameters to FMS. They will be appended to the NetConnection.connect call.
		 */
		[Inspectable(defaultValue=null)]
		public function get connectionParameters():Array
		{
			return _connectionParameters;
		}
		/**
		 * @private
		 */		
		public function set connectionParameters(p_list:Array):void
		{
			_connectionParameters = p_list;
		}

		/**
		 * The NetConnection instance used to connect to FMS
		 */
		[Inspectable]
		public function get nc():NetConnection
		{
			//TODO: Peldi throw an error if this is not connected
			return _mainNC;
		}
	
	
		/**
		 * Is the current connection tunneling? This returns true if we're using rtmpt or rtmps (and not native TLS)
		 * @default false
		 */
		[Inspectable(defaultValue=false)]
		public function get tunneling():Boolean
		{
			return _bIsTunneling;
		}
	
		/**
		 * Is the current connection secure? This returns true if we're using rtmps (tunneled or native TLS)
		 * @default false
		 */
		[Inspectable(defaultValue=false)]
		public function get usingRTMPS():Boolean
		{
			return _bUsingRTMPS;
		}
		
		public function get lastOriginTried():String
		{
			return _lastOriginTried;
		}
		
		/**
		 * Call this method to start the connection process. You must have defined at least an appName and one origin
		 * @throws Error "appName not set" 
		 * @throws Error "origin undefined"
		 */
		public function connect():void
		{
			if (appName == null) {
				throw new Error("appName not set"); 
			}
			if (origins == null || origins.length == 0) {
				throw new Error("origin undefined");
			}
			
			startProtosConnect();
		}

		/**
		 * Call this method when you want to restart the internal connection attempt counter.
		 * Normally you would call this within your "connected" handler, but in some cases you might want to wait for a server-to-client 
		 * notification that everything is good on the server before considering the connection fully established. In that case, call resetAttemptNumber at that point.
		 */
		public function resetAttemptNumber():void
		{
			_currentAttempt = 0;
		}
		
		/**
		 * Call this when you want to disconnect from the FMS server.
		 */
		public function disconnect():void
		{
			stopAllTimers();
			if (_mainNC) {
				var wasConnected:Boolean = _mainNC.connected;
				//we might never have connected
				_mainNC.removeEventListener(NetStatusEvent.NET_STATUS, mainNetStatusHandler);
				_mainNC.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, mainSecurityErrorHandler);
				_mainNC.close();
				_mainNC = null;
				if (wasConnected) {
					dispatchEvent(new Event("disconnect"));
				}
			}
			deleteAllTempNCs();
		}

		/**
		 * If your origin tells you that you should try the next one, call this method
		 */
		public function tryNextOrigin():void
		{
			incOriginsIndex();
			tryAgain();
		}

		/**
		 * If your edge tells you that you should try the next one, call this method
		 */
		public function tryNextEdge():void
		{
			incEdgesIndex();
			tryAgain();
		}
		
		/**
		 * If you'd like to close the current connection and start the connection process again in 5 seconds, call this method
		 */
		public function tryAgain():void
		{
			_endDialogCounter = 0;
			_bTooManyEndDialogs = false;
	
			stopAllTimers();
	
			//Call startProtosConnect in 5 seconds
			_startFreshTimer.reset();
			_startFreshTimer.start();
		}

		/**
		 * @private
		 */
		protected function onStartFreshTimerTimerComplete(p_evt:TimerEvent):void
		{
			startProtosConnect();
		}
		
		/**
		 * @private
		 */
		protected function tempNetStatusHandler(p_event:NetStatusEvent):void
		{
			var nc:NetConnection = p_event.target as NetConnection;
			var index:Number = _ncDictionary[nc];
			var info:Object = p_event.info;

			myTrace("tempNetStatusHandler "+index+"/"+_protos.length, info.code);

			switch (info.code)
			{
				case "NetConnection.Connect.Success":
	
					stopAllTimers();
					deleteAllTempNCs(nc);	//don't close this one
					setUpMainNC(nc);
					break;
	
				case "NetConnection.Connect.Failed":
	
					if (index == (_protos.length-1)) {
						stopAllTimers();
						deleteAllTempNCs();
						myTrace("	Got a Failed and I'm the last protocol, trying again in 2");
						var handleFailedIn5Timer:Timer = new Timer(2000, 1);
						handleFailedIn5Timer.addEventListener(flash.events.TimerEvent.TIMER_COMPLETE, handleFailedIn5);
						handleFailedIn5Timer.start();
					}
	
					if (_bTooManyEndDialogs) {
						stopAllTimers();
						deleteAllTempNCs();
						dispatchEvent(new Event("failed"));
					}
	
					break;
	
				case "NetConnection.Connect.OriginNotFound":
					myTrace("	The origin ("+origins[_originsIndex]+") was not found, going to next origin");
	
					stopAllTimers();
					deleteAllTempNCs();
					incOriginsIndex();
	
					startProtosConnect();
					break;
	
				case "NetConnection.Connect.StartDialog":	// -- delivered when the certificate dialog is about to be opened
	
					//need to stop the connection process (don't try any other connection until we get EndDialog
					myTrace("	suspending connections");
					_nextConnectTimer.stop();
					_timeOutTimer.stop();
	
					break;
				case "NetConnection.Connect.EndDialog":		// -- delivered when the certificate dialog is closed
	
					//restart the connection process (don't try any other connection until we get EndDialog
					myTrace("	resuming connections");

					_nextConnectTimer.reset();
					_nextConnectTimer.start();

	
					_endDialogCounter++;
					if (_endDialogCounter > 3) {
						_bTooManyEndDialogs = true;
					}
	
					break;
			}
			
        }

		/**
		 * @private
		 */
        protected function tempSecurityErrorHandler(p_event:SecurityErrorEvent):void
        {
            myTrace("tempSecurityErrorHandler: " + p_event);
        }

		/**
		 * @private
		 */
		protected function mainNetStatusHandler(p_event:NetStatusEvent):void
		{
            myTrace("mainNetStatusHandler: " + p_event.info.code);
			dispatchEvent(p_event);
	
			if (p_event.info.code == "NetConnection.Connect.Closed") {
	
				dispatchEvent(new Event("disconnect"));
	
//				if (!_global.userWasEjected) {
					var reconnectInABitTimer:Timer = new Timer(Math.round(Math.random()*3000), 1);
					reconnectInABitTimer.addEventListener(flash.events.TimerEvent.TIMER_COMPLETE, reconnectInABit);
					reconnectInABitTimer.start();
//				}
			}

		}

		/**
		 * @private
		 */
		protected function reconnectInABit(p_event:TimerEvent):void
		{
			startProtosConnect();
			if (!_giveUpReconnectingTimer.running) {	//don't extend it if it's already set
				_giveUpReconnectingTimer.start();
			}			
		}
		
		/**
		 * @private
		 */
        protected function mainSecurityErrorHandler(p_event:SecurityErrorEvent):void
        {
            myTrace("mainSecurityErrorHandler: " + p_event);

        }
		
		/**
		 * @private
		 */
		protected function handleFailedIn5(p_event:TimerEvent):void
		{
			//go to the next edge
			if (edges!=null && edges.length > 0)
				incEdgesIndex();
			else
				incOriginsIndex();
	
			startProtosConnect();
		}

		/**
		 * @private
		 */
		protected function setUpMainNC(p_nc:NetConnection):void
		{
			_bTooManyEndDialogs = false;			

			var currentTempNc:NetConnection = p_nc;
			currentTempNc.removeEventListener(NetStatusEvent.NET_STATUS, tempNetStatusHandler);
			currentTempNc.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, tempSecurityErrorHandler);
			
			_mainNC = currentTempNc;
			_mainNC.addEventListener(NetStatusEvent.NET_STATUS, mainNetStatusHandler);
			_mainNC.addEventListener(SecurityErrorEvent.SECURITY_ERROR, mainSecurityErrorHandler);
			_mainNC.client = this;
			var u:String = _mainNC.uri.toLowerCase();

			_bIsTunneling = (((u.indexOf("rtmpt") != -1) || (u.indexOf("rtmps") != -1)) && !_mainNC.usingTLS);
			myTrace("isTunneling? "+tunneling);
	
			_bUsingRTMPS = (u.indexOf("rtmps") != -1);
			myTrace("is using RTMPS? "+usingRTMPS);

			dispatchEvent(new Event("connected"));
		}
		
		/**
		 * @private 
		 */
		public function getTicket():*
		{
			return _connectionParameters[0];
		}
		
		/**
		 * @private
		 */
		public function receiveLogin(p_userData:Object):void
		{
			_mainNC.client = _methodHandlerObject;
			_methodHandlerObject.receiveLogin(p_userData);
		}
		
		/**
		 * @private
		 */
		public function _onbwcheck(p_data:Object, p_ctx:Object):void
		{
			_methodHandlerObject._onbwcheck(p_data, p_ctx);
		}

		/**
		 * @private
		 */
		public function _onbwdone(p_latency:Number, p_bw:Number):void
		{
			_methodHandlerObject._onbwdone(p_latency, p_bw);
		}


		
		/**
		 * @private
		 */
		public function receiveError(p_error:Object):void
		{
			_methodHandlerObject.receiveError(p_error);
		}

		/**
		 * @private
		 */
		protected function startProtosConnect():void
		{
			stopAllTimers();
			deleteAllTempNCs();
			
			_currentAttempt++;
			
			if (_currentAttempt > _maxAttempts) {
				myTrace("startProtosConnect calling onDoneRetryingTimerComplete");
				onDoneRetryingTimerComplete();
				return;
			}
			
			_protoIndex = 0;
			_bProxyFallbackAttempted = false;
			
			//Create all the tempNCs
			_tempNCs = new Array();

			var connString:String = getConnectionString();

			myTrace("[attempt "+_currentAttempt+" of "+_maxAttempts+"] Connecting to "+_protoIndex+"/"+(_protos.length-1)+": "+connString+" #startProtosConnect#");

			var nc:NetConnection = setUpTempNC();
			_ncDictionary[nc] = _protoIndex;
			_tempNCs.push(nc);
			nc.connect(connString, _connectionParameters, version);
			
			if (_protoIndex < _protos.length-1) {
				_nextConnectTimer.delay = 5000;
				_nextConnectTimer.start();
			}
			
			_timeOutTimer.start();
		}

		/**
		 * @private
		 */
		protected function setUpTempNC():NetConnection
		{
			var nc:NetConnection = new NetConnection();
			nc.objectEncoding = flash.net.ObjectEncoding.AMF3;
			nc.addEventListener(NetStatusEvent.NET_STATUS, tempNetStatusHandler);
			nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, tempSecurityErrorHandler);
			nc.proxyType = "best";
			return nc;			
		}
		
		//uses the _protoIndex if nothing is passed, uses the index if it is
		/**
		 * @private
		 */
		protected function getConnectionString(...p_args):String
		{
			var index:Number = _protoIndex;
			if ((p_args.length == 1) && (p_args[0] is Number)) {
				index = p_args[0];
			}
			
			var currentProto:ProtocolPortPair = _protos[index];
			var connString:String;
			if (edges!=null && edges.length > 0) {
				connString = currentProto.protocol+"://"+edges[_edgesIndex]+":"+currentProto.port+"/?"+
							"rtmp://"+origins[_originsIndex]+":"+originPort+"/"+appName+"/"+appInstanceName;
				_lastOriginTried = origins[_originsIndex];
			} else {
//				connString = currentProto.protocol+"://"+origins[0]+":"+originPort+"/"+appName+"/"+appInstanceName;	
				connString = currentProto.protocol+"://"+origins[0]+"/"+appName+"/"+appInstanceName;	
				_lastOriginTried = origins[0];
			}
			
			return connString;
		}
		
		/**
		 * @private
		 */
		protected function onTimeOutTimerComplete(p_event:TimerEvent):void
		{
			myTrace("onTimeOutTimerComplete");

			var bWeAreTryingRtmps:Boolean = false;
			var rtmpsIndex:Number = -1;

			var l:Number = _protos.length;
			for (var i:uint=0; i<l; i++) {
				var protoPair:ProtocolPortPair = _protos[i];
				if (protoPair.protocol.toLowerCase()=="rtmps") {
					bWeAreTryingRtmps = true;
					rtmpsIndex = i;
					break;
				}
			}

			if (bWeAreTryingRtmps && !_bProxyFallbackAttempted) {
				_bProxyFallbackAttempted = true;
				
				deleteAllTempNCs();

				var nc:NetConnection = setUpTempNC();
				nc.proxyType = "http";	//this will try tunneling
				_ncDictionary[nc] = 0;
				_tempNCs = new Array();
				_tempNCs.push(nc);

				var connString:String = getConnectionString(rtmpsIndex);
	
				myTrace("[attempt "+_currentAttempt+" of "+_maxAttempts+"] Trying fallback tunneling connection "+connString+" #onTimeOutTimerComplete#");
	
				nc.connect(connString, _connectionParameters, version);
				
				_timeOutTimer.reset();	
				_timeOutTimer.start();
				return;
			}

			if (edges!=null && edges.length > 0)
				incEdgesIndex();
			else
				incOriginsIndex();

			startProtosConnect();
		}		
		
		/**
		 * @private
		 */
		protected function onNextConnectTimer(p_event:TimerEvent):void
		{
			_timeOutTimer.reset();	
			_timeOutTimer.start();
			_nextConnectTimer.stop();
			
			_protoIndex++;

			var connString:String = getConnectionString();

			myTrace("[attempt "+_currentAttempt+" of "+_maxAttempts+"] Connecting to "+_protoIndex+"/"+(_protos.length-1)+": "+connString+" #onNextConnectTimer#");

			var nc:NetConnection = setUpTempNC();
			_ncDictionary[nc] = _protoIndex;
			_tempNCs.push(nc);	
			nc.connect(connString, _connectionParameters, version);
			
			if (_protoIndex < _protos.length-1) {
				_nextConnectTimer.delay = 1500;
				_nextConnectTimer.start();
			}
		}

		/**
		 * @private
		 */
		protected function stopAllTimers():void
		{
			_nextConnectTimer.stop();
			_timeOutTimer.stop();
			_giveUpReconnectingTimer.stop();
		}
		
		/**
		 * @private
		 */
		protected function deleteAllTempNCs(...args):void
		{
			var ncToSkip:NetConnection;
			if (args.length == 1 && args[0] is NetConnection) {
				ncToSkip = args[0];
			}
			for each (var nc:NetConnection in _tempNCs) {
				if (nc == ncToSkip) {
					continue;
				}
				nc.removeEventListener(NetStatusEvent.NET_STATUS, tempNetStatusHandler);
				nc.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, tempSecurityErrorHandler);
				nc.close();
			}
			_tempNCs = new Array();
		}

		/**
		 * @private
		 */
		protected function incEdgesIndex():void
		{
			if (edges==null)
				return;
				
			_edgesIndex++;
			if (_edgesIndex == edges.length)
				_edgesIndex = 0;
			myTrace("	incEdgesIndex: _edgesIndex now:"+_edgesIndex+" (edge:"+edges[_edgesIndex]+")");
		}
	
		/**
		 * @private
		 */
		protected function incOriginsIndex():void
		{
			_originsIndex++;
			if (_originsIndex == _origins.length)
				_originsIndex = 0;
			myTrace("	incOriginsIndex: _originsIndex now:"+_originsIndex+" (origin:"+origins[_originsIndex]+")");
		}
		
		/**
		 * @private
		 */
		protected function onDoneRetryingTimerComplete(p_evt:TimerEvent=null):void
		{
			_currentAttempt = 0;
			stopAllTimers();
			disconnect();

			dispatchEvent(new Event("failed"));
		}

		/**
		 * @private
		 */
		protected function myTrace(...args):void
		{
			DebugUtil.debugTrace(""+args);
		}
	}

}
