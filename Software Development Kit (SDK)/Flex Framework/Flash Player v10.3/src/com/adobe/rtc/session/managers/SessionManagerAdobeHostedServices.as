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
	import com.adobe.rtc.authentication.AbstractAuthenticator;
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.events.AuthenticationEvent;
	import com.adobe.rtc.events.MeetingInfoEvent;
	import com.adobe.rtc.events.SessionEvent;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.sessionClasses.MeetingInfoService;
	import com.adobe.rtc.session.sessionClasses.ProtocolPortPair;
	import com.adobe.rtc.session.sessionClasses.SingleUseTicketService;
	import com.adobe.rtc.util.DebugUtil;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.utils.Timer;
	
	import mx.utils.URLUtil;

	use namespace session_internal;

	/**
	 * @private
	 */
   public class  SessionManagerAdobeHostedServices extends SessionManagerFMS
	{
		protected var _authenticator:AbstractAuthenticator;
		protected var _meetingInfo:MeetingInfoService;
		protected var _sUTicket:SingleUseTicketService;
		
		protected var _fmsURL:String;
		protected var _loader:URLLoader;
		
		protected var _currentOrigin:String;
		protected var _currentProtos:Array;
		protected var _currentRetryAttempts:Number;

		protected var _token:String;
		
		protected var _tryFMSAgainTimer:Timer;
		
		protected var _acornRequestCounter:uint = 0;
		protected var _maxAcornRequests:uint = 3;
        
        protected var _userImageURL:String;
        protected var _tempUser:Boolean;
        
		public function SessionManagerAdobeHostedServices():void
		{
			super();
			_fmsConnector.version = ConnectSession.BUILD_NUMBER;
			_tryFMSAgainTimer = new Timer(5*1000, 1);
			_tryFMSAgainTimer.addEventListener(TimerEvent.TIMER_COMPLETE, tryFMSAgain);	
		}
		
		protected function setupMeetingInfo():void
		{
			if (null == _meetingInfo)
				_meetingInfo = new MeetingInfoService(roomURL, _authenticator);
			else
				_meetingInfo.setURL(roomURL);
		}
		
		protected function getMeetingInfo():void
		{
			setupMeetingInfo();
			
            _meetingInfo.addEventListener(MeetingInfoEvent.INFO_RECEIVE, onMeetingInfo);
            _meetingInfo.addEventListener("error", onMeetingError);
			_meetingInfo.requestRoomInfo();
		}
		
		protected function onMeetingInfo(p_evt:MeetingInfoEvent):void
		{
			_meetingInfo.removeEventListener(MeetingInfoEvent.INFO_RECEIVE, onMeetingInfo);
			_meetingInfo.removeEventListener("error", onMeetingError);
			_fmsURL = URLUtil.getFullURL(_meetingInfo.baseURL, _meetingInfo.fmsURL);

			// now it's time to get a short-term ticket
			_sUTicket = new SingleUseTicketService();
			_sUTicket.addEventListener("login", onTicket);
			_sUTicket.addEventListener("error", onTicketError);
			_sUTicket.sendRequest(_meetingInfo.roomName, null, _meetingInfo.baseURL, _authenticator.authenticationKey); //it will be null the first time
		}
		
		protected function onMeetingError(p_evt:Event):void
		{
			_meetingInfo.removeEventListener(MeetingInfoEvent.INFO_RECEIVE, onMeetingInfo);
			_meetingInfo.removeEventListener("error", onMeetingError);

			var error:Object = new Object();
			error.name = "INVALID_INSTANCE";
			error.message = "Invalid Instance";
			receiveError(error);
		}
		
		protected function onTicket(p_evt:Event):void
		{
			_ticket = _sUTicket.ticket;
            _userImageURL = _sUTicket.userImageURL;
            _tempUser = _sUTicket.tempUser;
			getFMSXML();
		}
		
		protected function onTicketError(p_evt:Event):void
		{
			receiveError({name:'TICKET_ERROR', message:'error getting ticket'});
		}
		
		protected function onAuthenticationSuccess(p_evt:AuthenticationEvent):void
		{
			// the authenticator should now have an authenticationKey for us, on to meeting-info
			getMeetingInfo();
		}
		

		override session_internal function login():void
		{
			_acornRequestCounter = 0;
			if (authenticator) {
				if (authenticator is AbstractAuthenticator) {
					_authenticator = authenticator as AbstractAuthenticator;
					
					if (_authenticator.authenticationKey == null) {
						_authenticator.addEventListener(AuthenticationEvent.AUTHENTICATION_SUCCESS, onAuthenticationSuccess);
						// we are doing error handling in Abstarcat Authenticator 
						// otherwise the developer can add the event listener himself
					}
					
					getMeetingInfo();
				} else {
					throw new Error("SessionManagerAdobeHostedServices requires an AbstractAuthenticator");
				}
			}
		}

		override session_internal function logout():void
		{
            super.logout();
            if (_authenticator != null)
                _authenticator.logout();
        }
        
        public function saveToTemplate(p_name:String):void
        {
        	_fmsConnector.nc.call("saveToTemplate", null, p_name);
        }
        
        public function receiveTemplateSave(p_name:String):void
        {
        	var e:SessionEvent = new SessionEvent(SessionEvent.TEMPLATE_SAVE);
        	e.templateName = p_name;
        	dispatchEvent(e);
        }
        
        public var protocol:String = "rtmfp";
        public var requireRTMFP:Boolean = false;

		protected function getFMSXML(p_suffix:String=""):void
		{
			_acornRequestCounter++;
			if (protocol && protocol.toLowerCase()=="rtmfp") {
				p_suffix += "&proto=rtmfp";
			}
			if (_acornRequestCounter > _maxAcornRequests) {
				var error:Object = new Object();
				error.name = "TOOMANYATTEMPTS";			
				receiveError(error);
				return;
			}
			
			if (!_loader) {
				_loader = new URLLoader();
	            _loader.addEventListener(Event.COMPLETE, onLoaderComplete);
	            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);
	            _loader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);			
	  		}

			var url:String = _fmsURL.replace(/#ticket#/, _ticket) + p_suffix;
			DebugUtil.debugTrace("Getting FMS at "+url+", attempt #"+_acornRequestCounter+"/"+_maxAcornRequests);
            _loader.load(new URLRequest(url));
		}
		
		public function get fmsURL():String
		{
			return _fmsConnector.nc.uri;
		}
		

        private function onLoaderComplete(event:Event):void 
        {     
            var result:XML = XML(event.target.data);
            
			DebugUtil.debugTrace("result: "+result);
            
			/* result looks like this:
			<fms>
				<origin>localhost</origin>
				<proto_ports>rtmp:1935,rtmp:443</proto_ports>
				<retry_attempts>3</retry_attempts>
			</fms>
			*/

			if(result..error != undefined) {					
				var error:Object = new Object();
				error.message = result..error[0].toString();
				error.name = "Error";			
				receiveError(error);
				return;
			}
			
			var vers:Array = Capabilities.version.split(",");
			var majorVersion:int = parseInt(vers[0].split(" ")[1]); // "6" user's current player version	
			
			
            _currentOrigin = result..origin[0].toString();
            _currentProtos = new Array();
            var a:Array = result..proto_ports[0].toString().split(",");
            for (var i:uint=0; i<a.length; i++) {
            	var protoPort:Array = a[i].split(":");
            	if (String(protoPort[0]).toLowerCase()=="rtmfp" && majorVersion < 10) {
            		continue;
            	} else if (requireRTMFP && String(protoPort[0]).toLowerCase()!="rtmfp") {
            		continue;
            	}
            	_currentProtos.push(new ProtocolPortPair(protoPort[0], protoPort[1]));
            }
            _currentRetryAttempts = Number(result..retry_attempts[0]);
            
            connectToFMS();
        }
        
        protected function connectToFMS():void
        {
			_fmsConnector.connectionParameters = new Array(_ticket);		
			if (_meetingInfo != null) {
				_fmsConnector.appInstanceName = _meetingInfo.roomName;
			}
			
			_fmsConnector.origins = new Array(_currentOrigin);
			_fmsConnector.protocols = _currentProtos;
			_fmsConnector.maxConnectionAttempts = _currentRetryAttempts;
			_fmsConnector.connect();
        }

		/**
		 * The response to the "login" RPC if something went wrong on the server.
		 * Notifies the session that the connectiong has failed
		 * @param p_error  the error message
		 */
		override public function receiveError(p_error:Object /*contains .message and .name*/):void
		{
			if (p_error.name == "WRONG_HOST" || p_error.name == "ACORN_TIME_OUT") {
				//need to disconnect and call /fms again
				_fmsConnector.disconnect();
				tryFMSAgain();
			} else {
				super.receiveError(p_error);
			}
		}

		public function get token():String
		{
			return _token;
		}
        
		public function receiveToken(p_token:String):void
		{
			_token = p_token;
			dispatchEvent(new Event("tokenChange"));
		}
		
        public function get userImageURL():String {
            return _userImageURL;
        }
        
        public function get isTempUser():Boolean {
            return _tempUser;
        }
		
		override protected function onFmsConnectorFailed(p_evt:Event):void
		{
			tryFMSAgain();
		}
		
		protected function tryFMSAgain(p_evt:TimerEvent=null):void
		{
			getFMSXML("&connect-error=true&origin="+_fmsConnector.lastOriginTried);
		}

        private function onLoaderError(event:Event):void 
        {
			DebugUtil.debugTrace("Acorn is down or our network is not back yet, try again in 5");
        	_tryFMSAgainTimer.reset();
        	_tryFMSAgainTimer.start();
        }
	}
}
