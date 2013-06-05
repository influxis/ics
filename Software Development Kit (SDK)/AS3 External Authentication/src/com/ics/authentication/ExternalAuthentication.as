package com.ics.authentication
{
	import com.adobe.rtc.authentication.AdobeHSAuthenticator;
	import com.adobe.rtc.events.AuthenticationEvent;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.session.sessionClasses.MeetingInfoService;
	import com.hurlant.crypto.Crypto;
	import com.hurlant.crypto.hash.HMAC;
	import com.hurlant.util.Base64;
	import com.hurlant.util.Hex;
	import com.ics.events.ExternalAuthTokenEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	
	[Event(name="ioError", type="flash.events.IOErrorEvent")]
	[Event(name="securityError", type="flash.events.SecurityErrorEvent")]
	[Event(name="externalTokenCreated", type="com.ics.events.ExternalAuthTokenEvent")]
	
	/**
	 * Used to generate external authentication tokens on the fly  
	 * 
	 * Usage: IN PROCESS
	 * 
	 * @author jccrosby
	 * @version 1.0
	 * @date 2012/10/20
	 */
	public class ExternalAuthentication extends EventDispatcher
	{
		// ============================================
		// Declarations
		// ============================================
		
		public var instance:String;
		public var account:String;
		public var userName:String;

		public var room:String;
		public var gak:String;
		
		public var baseURL:String;
		public var meetingURL:String;
		
		private var _password:String;
		private var _tokenRole:int = UserRoles.OWNER;
		private var _accountSecret:String;
		private var _sessionSecret:String;
		private var _auth:AdobeHSAuthenticator;
		private var _meetingInfo:MeetingInfoService;
		
		
		// ============================================
		// Init
		// ============================================
		
		public function ExternalAuthentication(baseURL:String, account:String, room:String, accountSecret:String, userName:String, password:String)
		{
			super(this);
			
			this.baseURL = baseURL;
			if(baseURL.charAt(baseURL.length-1) != "/")
				this.baseURL += "/";
			this.account = account;
			this.room = room;
			this.userName = userName;
			this._password = password;
			this._accountSecret = accountSecret;
			
			this.meetingURL = this.baseURL + this.account + "/" + this.room;
			
			_init();
		}
		
		private function _init():void
		{
			_auth = new AdobeHSAuthenticator();
			_auth.authenticationURL = this.baseURL + "app/login";
			_auth.userName = this.userName;
			_auth.password = this._password;
			_auth.addEventListener(AuthenticationEvent.AUTHENTICATION_SUCCESS, onAuthSuccess);
			_auth.addEventListener(AuthenticationEvent.AUTHENTICATION_FAILURE, onAuthFailure);
		}
		
		
		// ============================================
		// Control
		// ============================================
		
		public function getAuthenticationToken(role:int=100):void 
		{
			if(role < 0 || role > UserRoles.OWNER)
				throw new Error("invalid-role");
			
			_tokenRole = role;
			_auth.login();
		}
		
		private function _requestInfo():void 
		{
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			var request:URLRequest = new URLRequest();
			request.url = baseURL + account + "?mode=xml&accountonly=true&" + gak;
			loader.addEventListener(Event.COMPLETE, onInfoReceived);
			
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			
			loader.load(request);
		}
		
		private function _getSecret():void 
		{
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			var request:URLRequest = new URLRequest();
			request.url = baseURL + "app/session?instance=" + instance + "&" + gak;
			
			loader.addEventListener(Event.COMPLETE, onSecretComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			
			loader.load(request);
		}
		
		public function invalidate(baseURL:String, authToken:String, authHeaders:Array=null):void 
		{
			var data:String = "action=delete&instance=" + this.instance + "&" + authToken;
			
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest();
			request.method = URLRequestMethod.POST;
			request.url = baseURL + "app/session";
			request.data = data;
			
			loader.addEventListener(Event.COMPLETE, function(event:Event):void {
				trace("invalidate(): ", loader.data);  
			});
			
			loader.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):void {
				trace("Oops, IOErrorEvent", event.errorID, event.text);
				dispatchEvent(event);
			});
			
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(event:SecurityErrorEvent):void {
				trace("Oops, SecurityErrorEvent", event.errorID, event.text);
				dispatchEvent(event);
			});
			
			loader.load(request);
			
			this.instance = null;
			this.account = null;
			this.room = null;
			this._accountSecret = null;
			this._sessionSecret = null;
		}
		
		private function createExternalToken():void
		{	
			var token:String = "x:" + room + "::" + account + ":" + room + ":" + room + ":" + _tokenRole.toString();
			var signed:String = token + ":" + _sign(_accountSecret, token);
			
			var ext:String = "exx=" + Base64.encode(signed); 
			
			dispatchEvent(new ExternalAuthTokenEvent(ExternalAuthTokenEvent.EXTERNAL_TOKEN_CREATED, ext));
		}
		
		private function _sign(acctSecret:String, data:String):String {
			var bigSecret:String = acctSecret + ":" + _sessionSecret;
			
			var hmac:HMAC = Crypto.getHMAC("sha1");
			var k:ByteArray = Hex.toArray(Hex.fromString(bigSecret, true));
			var d:ByteArray = Hex.toArray(Hex.fromString(data, true))
			
			var value:ByteArray = hmac.compute(k, d);
			var signed:String = Hex.fromArray(value); 
			return signed;
		}
		
		
		// ============================================
		// Handlers
		// ============================================
		
		protected function onAuthSuccess(event:AuthenticationEvent):void
		{
			gak = _auth.authenticationKey;
			_requestInfo();
			//_meetingInfo.requestAccountInfo();
		}
		
		protected function onAuthFailure(event:AuthenticationEvent):void
		{
			dispatchEvent(event.clone());
		}
		
		protected function onInfoReceived(event:Event):void
		{
			var loader:URLLoader = URLLoader(event.target);
			trace("_getMeetingInfo(): ", loader.data); // Should be XML
			
			instance = new XML(loader.data).room.@instance;
			
			instance = instance.replace("#room#", room);
			
			// Need to get the "sesion secret"
			_getSecret();
		}
		
		protected function onSecretComplete(event:Event):void
		{
			var loader:URLLoader = URLLoader(event.target);
			trace("getSecret(): ", loader.data);
			
			var result:XML = new XML(loader.data);
			
			if(result.status.@code == "ok")
				_sessionSecret = result["session-secret"];
			else
				throw new Error("session-secret-error");
			
			// Now we can create the token
			createExternalToken();
		}
		
		protected function onIOError(event:IOErrorEvent):void
		{
			trace("Oops, IOErrorEvent", event.errorID, event.text);
		}
		
		protected function onSecurityError(event:SecurityErrorEvent):void
		{
			trace("Oops, IOErrorEvent", event.errorID, event.text);
		}		
		
		// ============================================
		// Getter/Setters
		// ============================================
		
		
	}
}