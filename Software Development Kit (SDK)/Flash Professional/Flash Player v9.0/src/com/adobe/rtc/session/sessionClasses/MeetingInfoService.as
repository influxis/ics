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
	import com.adobe.rtc.authentication.AbstractAuthenticator;
	import com.adobe.rtc.events.AuthenticationEvent;
	import com.adobe.rtc.events.MeetingInfoEvent;
	import com.adobe.rtc.util.DebugUtil;
	import com.adobe.rtc.util.URLParser;
	
	import flash.events.*;
	import flash.net.*;
	
	[Event(name="infoReceive", type="com.adobe.rtc.events.MeetingInfoEvent")]
	[Event(name="itemsReceive", type="com.adobe.rtc.events.MeetingInfoEvent")]

	/**
	 * @private
	 */
   public class  MeetingInfoService extends EventDispatcher
	{
		public static const ROOM_ITEMS:String = "meetings";
		public static const TEMPLATE_ITEMS:String = "templates";
		public static const ARCHIVE_ITEMS:String = "archives";
		private static const CONTENT_PATH:String = "/app/content";
		private static const ACCOUNT_PATH:String = "/app/account";
		
		protected var _meetingURL:String;
		protected var _authenticator:AbstractAuthenticator;
		
		// populated from the results
		public var _roomName:String;
		public var _baseURL:String;
		public var _repositoryURL:String;
		public var _fmsURL:String;
		public var _ticketURL:String;

		public function get roomName():String {
			return _roomName;
		}

		public function get baseURL():String {
			return _baseURL;
		}

		public function get repositoryURL():String {
			return _repositoryURL;
		}
		
		public function get fmsURL():String {
			return _fmsURL;
		}

		public function get ticketURL():String {
			return _ticketURL;
		}

		public function MeetingInfoService(p_meetingURL:String, p_authenticator:AbstractAuthenticator)
		{
			_meetingURL = p_meetingURL;
			_authenticator = p_authenticator;
		}
		
		public function setURL(p_meetingURL:String):void
		{
			// XXX: here there is the possibility that we are jumping
			// from one environment to another, in which case we should also
			// invalidate the _authenticatorURL, but for now this is good enough
			_meetingURL = p_meetingURL;
		}

		private function fixAuthParams(params:String):String
		{
			if (! _authenticator.canLogin()) {
				// need to fetch the authentication URL
				params += "&" + _authenticator.getAuthenticationRequestParameters();
			} else {
				if (_authenticator.authenticationKey == null) {
		    			_authenticator.login();
		    			return null;
				}
				
				// gak likes to be first :(
				if (_authenticator.authenticationKey != "")
				    params = _authenticator.authenticationKey + "&" + params;
			}

			return params + "&x=" + Math.random();
		}
	
 		public function requestRoomInfo():void
		{
			requestInfo("mode=xml");
		}

 		public function requestAccountInfo():void
		{
			requestInfo("mode=xml&accountonly=true");
		}

 		public function requestInfo(params:String):void
		{
			params = fixAuthParams(params);
			if (params == null)
				return; // wait for login response
			
			// fetch the info, parse roomName, fmsURL, and ticketURL into their vars, 
			// call onInfoReceive when done
			DebugUtil.debugTrace("requestInfo " + _meetingURL + "?" + params);
			var req:URLRequest = new URLRequest(_meetingURL);
			req.method = URLRequestMethod.GET;
			req.data = new URLVariables(params);

			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onComplete);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onStatus);			
			loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
	    
			// mapping SECURITY_ERROR to onError:
			// assuming the system is configured correctly, we may get a security error
			// when trying to access an account that doesn't exist
			// (that redirects us to na1.connect.acrobat.com that is currently protected)
			// no problem: this will be treated as an invalid room error
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
    
			try {
				loader.load(req);
			} catch (error:Error) {
				trace("#THROWING ERROR# requestInfo catch statement");
				dispatchEvent(new Event("error"));
			}
		}

 		public function requestItems(type:String = ROOM_ITEMS):void
		{
			var params:String = fixAuthParams("action=info");
			if (params == null)
				return; // wait for login response

			// we only show /meetings or /templates
			if (type == null || type == "")
				type = ROOM_ITEMS;
			else if (type != ROOM_ITEMS && type != ARCHIVE_ITEMS)
				type = TEMPLATE_ITEMS;
			
			// fetch the requested node
			// call onItemsReceive when done
			var url:String = _repositoryURL + "/" + type;
			DebugUtil.debugTrace("requestItems " + url + "?" + params);
			var req:URLRequest = new URLRequest(url);
			req.method = URLRequestMethod.GET;
			req.data = new URLVariables(params);

			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onItemsComplete);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onStatus);			
			loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
	    
			// mapping SECURITY_ERROR to onError:
			// assuming the system is configured correctly, we may get a security error
			// when trying to access an account that doesn't exist
			// (that redirects us to na1.connect.acrobat.com that is currently protected)
			// no problem: this will be treated as an invalid room error
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
    
			try {
				loader.load(req);
			} catch (error:Error) {
				trace("#THROWING ERROR# requestItems catch statement");
				dispatchEvent(new Event("error"));
			}
		}

 		public function createRoom(room:String, template:String=null):void
		{
			var params:String = "mode=xml&room=" + room;
			if (template != null)
				params += "&template=" + template;

			params = fixAuthParams(params);
			if (params == null)
				return; // wait for login response
			
			// create room
			trace("createRoom " + _meetingURL + "?" + params);
			var req:URLRequest = new URLRequest(_meetingURL);
			req.method = URLRequestMethod.POST;
			req.data = new URLVariables(params);

			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onComplete);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onStatus);			
			loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
	    
			// mapping SECURITY_ERROR to onError:
			// assuming the system is configured correctly, we may get a security error
			// when trying to access an account that doesn't exist
			// (that redirects us to na1.connect.acrobat.com that is currently protected)
			// no problem: this will be treated as an invalid room error
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
    
			try {
				loader.load(req);
			} catch (error:Error) {
				trace("#THROWING ERROR# createRoom catch statement");
				dispatchEvent(new Event("error"));
			}
		}

		/**
		 * Create template from room
		 */
 		public function cloneDefaultTemplate(template:String):void
		{
			
			if ( template.length > 15 ) {
				throw new Error("The Template Name can't be more than 15 characters");
				return ;
			}
			
			var url:String = _baseURL + ACCOUNT_PATH;
			var params:String = "account=" + _roomName.split("/")[0] + "&template=" + template;
			
			params = fixAuthParams(params);
			if (params == null)
				return; // wait for login response
			
			// create template
			DebugUtil.debugTrace("cloneDefaultTemplate " + url + "?" + params);
			var req:URLRequest = new URLRequest(url);
			req.method = URLRequestMethod.POST;
			req.data = new URLVariables(params);

			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onCloneTemplateComplete);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onStatus);			
			loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
	    
			// mapping SECURITY_ERROR to onError:
			// assuming the system is configured correctly, we may get a security error
			// when trying to access an account that doesn't exist
			// (that redirects us to na1.connect.acrobat.com that is currently protected)
			// no problem: this will be treated as an invalid room error
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
    
			try {
				loader.load(req);
			} catch (error:Error) {
				trace("#THROWING ERROR# createRoom catch statement");
				dispatchEvent(new Event("error"));
			}
		}

 		public function deleteItem(item:String, type:String = ROOM_ITEMS):void
		{
			if (item == null)
				return;
            
			// we can only access /meetings or /templates
			if (type == null || type == "")
				type = ROOM_ITEMS;
			else if (type != ROOM_ITEMS && type != ARCHIVE_ITEMS)
				type = TEMPLATE_ITEMS;
            
			var params:String = "action=delete&response=inline";

			params = fixAuthParams(params);
			if (params == null)
				return; // wait for login response
			
			var url:String = _repositoryURL + "/" + type + "/" + item;

			// delete room
			DebugUtil.debugTrace("deleteItem " + url + "?" + params);
			var req:URLRequest = new URLRequest(url);
			req.method = URLRequestMethod.POST;
			req.data = new URLVariables(params);

			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onItemsComplete);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onStatus);			
			loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
	    
			// mapping SECURITY_ERROR to onError:
			// assuming the system is configured correctly, we may get a security error
			// when trying to access an account that doesn't exist
			// (that redirects us to na1.connect.acrobat.com that is currently protected)
			// no problem: this will be treated as an invalid room error
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
    
			try {
				loader.load(req);
			} catch (error:Error) {
				trace("#THROWING ERROR# deleteItem catch statement");
				dispatchEvent(new Event("error"));
			}
		}

		public function modifyItemTemplate(item:String, template:String=null, type:String = ARCHIVE_ITEMS):void
		{
			if (item == null) {
				return;
			}
			
			// we can only modify /archives templates (for now)
			if (type == null || type == "") {
				type = ARCHIVE_ITEMS;
			} else if (type != ARCHIVE_ITEMS) {
				type = ARCHIVE_ITEMS;
			}
			
			var params:String = "action=set-property&response=inline&name=cr:description";
			if (template != null) {
				params += "&value=" + template;
			}
			
			params = fixAuthParams(params);
			if (params == null) {
				// wait for login response
				return; 
			}
			
			var url:String = _repositoryURL + "/" + type + "/" + item;
			
			// modify item template
			DebugUtil.debugTrace("modifyItemTemplate " + url + "?" + params);
			var req:URLRequest = new URLRequest(url);
			req.method = URLRequestMethod.POST;
			req.data = new URLVariables(params);
			
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onItemsComplete);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onStatus);			
			loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			
			// mapping SECURITY_ERROR to onError:
			// assuming the system is configured correctly, we may get a security error
			// when trying to access an account that doesn't exist
			// (that redirects us to na1.connect.acrobat.com that is currently protected)
			// no problem: this will be treated as an invalid room error
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			
			try {
				loader.load(req);
			} catch (error:Error) {
				trace("#THROWING ERROR# modifyItemTemplate catch statement");
				dispatchEvent(new Event("error"));
			}
		}
		
		private function onComplete(event:Event):void {

			var result:XML;
			
			try {
				result = XML(event.target.data);
			} catch (error:Error) {
				trace("#THROWING ERROR# bad info result");
				dispatchEvent(new Event("error"));
				return;
			}
			
			if (result.child("authentication").length() != 0) {
				if (result.child("baseURL").length()>0) {
					setBase(result.baseURL.@href);
				}
				if (_authenticator.authenticationKey != null) {
					DebugUtil.debugTrace("#THROWING ERROR# bad authentication key");
					_authenticator.onAuthorizationFailure();
				} else {
					var url:String = result.authentication.@href;
					if (url.charAt(0) == "/")
						url = baseURL + url;
					_authenticator.authenticationURL = url;
					_authenticator.login();
				}
			} else {
				if (_authenticator.authenticationURL == null && _authenticator.authenticationKey != null && _authenticator.authenticationKey.indexOf("exx=") >= 0) {
					// we've made it this far because an authenticationKey was set, so we never needed to go to the authURL. Call it a success!
					_authenticator.dispatchEvent(new AuthenticationEvent(AuthenticationEvent.AUTHENTICATION_SUCCESS));
				}
				setBase(result.baseURL.@href);

				_roomName = result.room.@instance;
				setBase(result.baseURL.@href);
				_repositoryURL = baseURL
					+ CONTENT_PATH
					+ URLParser.cleanupURL(result.accountPath.@href);
				_fmsURL = URLParser.cleanupURL(result.fmsURL.@href);
				_ticketURL = URLParser.cleanupURL(result.ticketURL.@href);

				onInfoReceive();
			}
		}
        
		private function onCloneTemplateComplete(event:Event):void {

			var result:XML;
			
			try {
				result = XML(event.target.data);
			} catch (error:Error) {
				trace("#THROWING ERROR# bad info result");
				dispatchEvent(new Event("error"));
				return;
			}
			
			if (result.child("authentication").length() != 0) {
				if (result.child("baseURL").length()>0) {
					setBase(result.baseURL.@href);
				}
				if (_authenticator.authenticationKey != null) {
					trace("#THROWING ERROR# bad authentication key");
					_authenticator.onAuthorizationFailure();
				} else {
					var url:String = result.authentication.@href;
					if (url.charAt(0) == "/")
						url = baseURL + url;
					_authenticator.authenticationURL = url;
					_authenticator.login();
				}
			} else {
				if (result.status.@code != "ok") {
					DebugUtil.debugTrace("#THROWING ERROR# bad status: " + result.status.@code);
					dispatchEvent(new Event("error"));
					return;
				}
				
				var item:Object = new Object();
				var template:XMLList = result.template;

				//
				// return an array with only the new item
				//
				var items:Array = new Array();
				items.push({ 
					name: template.name,
					description: "",
					created: template.created
				});
				onItemsReceive(TEMPLATE_ITEMS, items);
			}
		}
        
        /**
         * @private
         *
         * update _baseURL with the real Acorn cluster URL
         * and also update _meetingURL so we can skip a redirect (whitcomb -> acorn)
         */
        private function setBase(baseURL:String):void {
            _baseURL = URLParser.cleanupURL(baseURL);
            var parts:Object = URLParser.parseURL(_meetingURL);
            _meetingURL = _baseURL + parts.path;
        }

		private function onItemsComplete(event:Event):void {

			var result:XML;
			
			try {
				result = XML(event.target.data);
			} catch (error:Error) {
				trace("#THROWING ERROR# bad items result");
				dispatchEvent(new Event("error"));
				return;
			}

			var type:String = result.node.name.toString();
			var nodes:XMLList = result.children.node;
			var items:Array = new Array();

			for each (var node:XML in nodes) {
				var props:XMLList = node..property;
				var nDesc:XMLList = props.(@name == 'cr:description');
				var nDate:XMLList = props.(@name == 'jcr:created');

				items.push({ 
					name: node.name.toString(),
					description: nDesc ? nDesc.value.toString() : "",
					created: nDate ? nDate.value.toString() : ""
				});
			}

			onItemsReceive(type, items);
		}

		private function onStatus(event:HTTPStatusEvent):void {
			if (event.status == 0) {
				DebugUtil.debugTrace("getMeetingInfo: status=0");
			}

			else if (event.status < 200 || event.status >= 300) { // real error
				DebugUtil.debugTrace("#THROWING ERROR# onStatus from URLLoader. Error.: <"+event.status+">");
	    			dispatchEvent(new Event("error"));
			}
		}

		private function onError(event:Event):void {
			DebugUtil.debugTrace("#THROWING ERROR# onError from URLLoader. Error.: <"+event.toString()+">");
	    		dispatchEvent(new Event("error"));
		}
		
		protected function onInfoReceive():void
		{
			// assuming we've gotten roomName, fmsURL, and ticketURL, tell the outside world
			dispatchEvent(new MeetingInfoEvent(MeetingInfoEvent.INFO_RECEIVE));
		}

		protected function onItemsReceive(type:String, items:Array):void
		{
			dispatchEvent(new MeetingInfoEvent(MeetingInfoEvent.ITEMS_RECEIVE, type, items));
		}
	}
}
