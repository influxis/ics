// Light Weight RemoteAuthentication Class
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
	
	import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	/**
	 * @private
	 */
   public class  SingleUseTicketService extends EventDispatcher
	{	
		protected var _ticket:String = "";
		public var roomName:String = "";
        public var userImageURL:String = "";
		public var tempUser:Boolean = true;
			
		public function SingleUseTicketService() 
		{					
		}
					
		protected function addListeners(loader:URLLoader):void {
            loader.addEventListener(Event.COMPLETE, onComplete);
            loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
  		}
  		
  		protected function removeListeners(loader:URLLoader):void {
            loader.removeEventListener(Event.COMPLETE, onComplete);
            loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
            loader.removeEventListener(IOErrorEvent.IO_ERROR, onError);
  		}
  				
		public function get ticket():String
		{
			return _ticket;
		}
		
		public function sendRequest(p_room:String, p_ticket:String=null, p_baseURL:String="", p_authenticationKey:String=undefined):void
  		{  			
            var url:String = p_baseURL + "/app/ticket";
            var params:String = "instance=" + p_room;
            
            if (p_authenticationKey == null) { 
                // called from launcher, nothing to do
            } else if (p_authenticationKey != null && p_authenticationKey != "") {
                // called from LCCS, it should be valid
                params = p_authenticationKey + "&" + params; // gak goes first!
            } else {
                // called from LCCS, if not authenticated it's an error
				//DebugUtil.debugTrace("#THROWING ERROR# no authenticationKey");
    	        dispatchEvent(new Event("error"));	
    	        return;
			}
			
            if (p_ticket != null)
                params = params + "&current=" + p_ticket;
            
			params = params + "&x=" + Math.random(); // make sure it doesn't get cached
			//DebugUtil.debugTrace("#TicketService# request " + url + "?" + params);

			var request:URLRequest = new URLRequest(url);
	        var variables:URLVariables = new URLVariables(params);
            
            request.data = variables;
            request.method = URLRequestMethod.GET;                       
	        
	        try {
	        	var loader:URLLoader = new URLLoader();
	        	addListeners(loader);
	            loader.load(request);
	        } catch (error:Error) {
	        	trace("#THROWING ERROR# sendRequest catch statement");
				dispatchEvent(new Event("error"));				
	        }
  		}

        private function onComplete(event:Event):void 
        {
        	removeListeners(URLLoader(event.target));
        	
        	try {
	            var result:XML = XML(event.target.data);
				var status:XML = result.status[0];
				
				if (status.@code != "ok") {
					DebugUtil.debugTrace("#THROWING ERROR# onComplete status code not ok. Status: <"+status.@code+">");
					dispatchEvent(new Event("error"));				
				} else {
					_ticket = result.ticket[0].toString();	
					
					if(result["instance"] != undefined && result["instance"] != "null") {
						roomName = result.instance[0].toString();
					}
					
					if( result["userInfo"] != undefined && result["userInfo"] != "null") {
						var userInfo:XML = result["userInfo"][0];
						tempUser = (userInfo.@tempUser == "true");
                        if (userInfo.userImageURL != undefined)
                            userImageURL = userInfo.userImageURL;
					}

					DebugUtil.debugTrace("#TicketService# ticket received: " + _ticket);					
					dispatchEvent(new Event("login"));	
				}
        	} catch (e:TypeError) {
        		//this means it's the login page
	        	trace("#THROWING ERROR# onComplete catch statement: " + e);
				dispatchEvent(new Event("error"));				
        	}
        }

        private function onError(event:Event):void 
        {
        	removeListeners(URLLoader(event.target));
        	
			DebugUtil.debugTrace("#THROWING ERROR# onError from URLLoader. Error.: <"+event.toString()+">");
            dispatchEvent(new Event("error"));	
        }
	}
}
