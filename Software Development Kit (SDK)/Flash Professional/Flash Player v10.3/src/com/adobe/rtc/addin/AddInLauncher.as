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
	import adobe.utils.ProductManager;
	
	import com.adobe.rtc.events.AddInLauncherEvent;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	import flash.external.ExternalInterface;
	


	/**
	 * Dispatched when the AddIn is launched.
	 *
	 * @eventType com.adobe.rtc.events.AddInLauncherEvent
	 */
	[Event(name="launch", type="com.adobe.rtc.events.AddInLauncherEvent", bubbles="true")]

	/**
	 * Dispatched when the AddIn launch fails.
	 *
	 * @eventType com.adobe.rtc.events.AddInLauncherEvent
	 */
	[Event(name="fail", type="com.adobe.rtc.events.AddInLauncherEvent")]
	
	/**
	 * This class is used to launch a specific URL in the addin. You pass it an addin name, 
	 * minimum version and location to download it from, and it downloads it and installs it if necessary.
	 * It then tells the addin to load the specified URL.
	 * <br/>
	 * AddInLauncher properly deals with the following situations:<br/>
	 * <ol>
	 * <li>addin not installed - it will try to install it before launching the url.</li>
	 * <li>addin installed but old (its version is < minVersion) - it will try to install a new addin before launching the url</li>
	 * <li>addin installed and has version >= minVersion - it will just launch the url in the addin</li>
	 * <li>If the version that gets installed in 1 or 2 is still < than the minVersion, a FAIL event will be dispatched.</li>
	 * </ol>
	 * 
	 * @see author Peldi Guilizzoni
	 */
	
     
   public class  AddInLauncher extends EventDispatcher
	{
		public static const DEFAULT:String = "default";
		
		protected var _addInLocalConnection:AddInLocalConnection;
		protected static var _minVersion:String;
		protected static var _addInName:String;
		protected static var _addInLocation:String = "default";
		protected var _addin:ProductManager;
	
		/**
		 *@private
		 * implementing the singleton pattern - holds the singleton instance
		 */
		protected static var _instance:AddInLauncher;
		
		/**
		 *@private
		 * implementing the singleton pattern - is only true during first creation
		 */
		protected static var _creating:Boolean = false;
		
		/**
		 * @public
		 * return an AddinLauncer instance
		 */ 
		public static function getInstance(p_minVersion:String, p_addInName:String, p_addInLocation:String="default"):AddInLauncher
		{
			// this functions checks if the singleton has been created , if not , it creates and returns otherwise it just returns
			_minVersion = p_minVersion;
			_addInName = p_addInName;
			_addInLocation = p_addInLocation;
			
			if(!_instance) {
				_creating = true;
				_instance = new AddInLauncher();
				_creating = false;
			}
			
			return _instance;
		}
		
		/**
		 * Constructor - pass the minimum version required and the name of the executable to launch (for instance "connectaddin6x0")
		 */
		function AddInLauncher()
		{
			if(!_creating) {
				throw new Error("Class cannot be instantiated.  Use getInstance() instead.");
				return;
			}
		}

		/**
		 * @private
		 */
		public function get minVersion():String
		{
			return _minVersion;
		}

		/**
		 * the minimum version of the AddIn required
		 */
		public function set minVersion(p:String):void
		{
			_minVersion = p;
		}
	
		/**
		 * @private
		 */
		public function get addInName():String
		{
			return _addInName;
		}

		/**
		 * the name of the executable to launch (for instance "connectaddin6x0")
		 */
		public function set addInName(p:String):void
		{
			_addInName = p;
		}

		/**
		 * @private
		 */
		public function get addInLocation():String
		{
			return _addInLocation;
		}

		/**
		 * pass "default" to use express install, or an URL if you're hosting your own installer
		 */
		public function set addInLocation(p:String):void
		{
			_addInLocation = p;
		}
	
		/**
		 * Main entry point. Launches the specified url in the addin after downloading and installing it if necessary.
		 */
		public function openInAddIn(p_urlToOpen:String):void
		{
			var e:AddInLauncherEvent;

			var os:String = Capabilities.os.toLowerCase();	//something like "mac os 10.4.9"
			if (os.indexOf("mac os") != -1) {
				var osVersion:Array = os.split(" ")[2].split(".");
				var osMajorVersion:uint = parseInt(osVersion[0]);
				var osMinorVersion:uint = parseInt(osVersion[1]);
				if (osMajorVersion < 10 || (osMajorVersion==10 && osMinorVersion<4)) {
					//fail, we only support 10.4 or higher
					e = new AddInLauncherEvent(AddInLauncherEvent.FAIL);
					dispatchEvent(e);			
					return;
				}
			}
			
			if (!_addInLocalConnection) {
				_addInLocalConnection = new AddInLocalConnection(_minVersion, p_urlToOpen);
				_addInLocalConnection.addEventListener(AddInLauncherEvent.LAUNCH, onLaunch);
				_addInLocalConnection.addEventListener(AddInLauncherEvent.FAIL, onFail);
			}
	
/*
			* @event complete Event Dispatched by the ProductManager object when the download is successful and complete.
			* @event cancel Event The user has canceled the file download.
			* @event error Event Dispatched when the stage is too small to display the download ui.
			* @event networkError Event Dispatched when the download is interrupted.
			* @event verifyError Event Dispatched when the downloaded file is invalid.
			* @event diskError Event Dispatched when the downloaded file cannot be saved to disk.
*/
			_addin = new ProductManager(_addInName);
			_addin.addEventListener(Event.COMPLETE, onComplete);
			_addin.addEventListener(Event.CANCEL, onError);
			_addin.addEventListener(ErrorEvent.ERROR, onError);
			_addin.addEventListener(IOErrorEvent.NETWORK_ERROR, onError);
			_addin.addEventListener(IOErrorEvent.VERIFY_ERROR, onError);
			_addin.addEventListener(IOErrorEvent.DISK_ERROR, onError);

			var bNeedUpdate:Boolean = compareVersions(_addin.installedVersion, _minVersion);
			
			if (!_addin.installed || bNeedUpdate) {
				//download it 
				if (addInLocation == AddInLauncher.DEFAULT) {
					var bDownloadStarted:Boolean = _addin.download();
					if (!bDownloadStarted) {
						e = new AddInLauncherEvent(AddInLauncherEvent.FAIL);
						e.version = _addin.installedVersion;
						dispatchEvent(e);	
					}
				} else {
				    openWindow(addInLocation);
					e = new AddInLauncherEvent(AddInLauncherEvent.LAUNCH);
					dispatchEvent(e);	
				}
			} else {
				launch();
			}
			
		}
		
		private function getBrowserName():String{
            var browser:String;
            
            // Reach out to browser and grab browser useragent info.
            // FIXME: Probably need to special-case AIR here...
            var browserAgent:String = ExternalInterface.call("function getBrowser() {return navigator.userAgent;}");
            
            if (browserAgent != null && browserAgent.indexOf("Firefox") >= 0) {
                browser = "Firefox";
            } else if (browserAgent != null && browserAgent.indexOf("Safari") >= 0) {
                browser = "Safari";
            } else if (browserAgent != null && browserAgent.indexOf("MSIE") >= 0) {
                browser = "IE";
            } else if (browserAgent != null && browserAgent.indexOf("Opera") >= 0) {
                browser = "Opera";
            } else {
                browser = "Undefined";
            }
            return (browser);
        }        
        
        private function openWindow(url:String):void {
             //Sets function name into a variable to be executed by ExternalInterface. 
             //Otherwise Flex will try to find a local function or value by that name.  
             var WINDOW_OPEN_FUNCTION:String = "window.open";
             var browserName:String = getBrowserName();
               
             if (browserName == "Firefox") {
                 //If browser is Firefox, use ExternalInterface to call out to browser 
                 //and launch window via browser's window.open method.
                ExternalInterface.call(WINDOW_OPEN_FUNCTION, url);
             } else {
                 // Otherwise, use Flex's native 'navigateToURL()' function to pop-window. 
                 // This is necessary because Safari 3 no longer works with the above ExternalInterface work-a-round.
                 navigateToURL(new URLRequest(url));
             }
        }
        		
		
		protected function compareVersions(p_installed:String, p_required:String):Boolean
		{
//			trace("p_installed:"+p_installed+", p_required:"+p_required);
			var installedVersion:Array = p_installed.split(".");
			var minVers:Array = p_required.split(",");

			var needUpdate:Boolean = false;

//			trace("addinname:"+_addInName);
//			trace("installedVersion:"+installedVersion);
//			trace("minVers:"+minVers);

			for (var i:uint=0; i<4; i++) {
				if (Number(installedVersion[i]) > Number(minVers[i])) {
					break;
				}
				if (Number(installedVersion[i]) < Number(minVers[i])) {
					needUpdate = true;
					break;
				}
			}
			
			return needUpdate;			
		}

		/**
		 * @private
		 */
		protected function onComplete(p_evt:Event):void
		{
			trace("#AddInLauncher onComplete: installedVersion:"+_addin.installedVersion+", "+_minVersion+", "+p_evt.toString());
			//we might have just downloaded a bad version
			var bDownloadIsOld:Boolean = compareVersions(_addin.installedVersion, _minVersion);
			if (bDownloadIsOld) {
				trace("		downloadIsOld!!!!");
				var e:AddInLauncherEvent = new AddInLauncherEvent(AddInLauncherEvent.FAIL);
				e.version = _addin.installedVersion;
				dispatchEvent(e);
			} else {
				trace("		all good, calling launch!!!!");
				launch();
			}
		}
		
		/**
		 * @private
		 */
		protected function launch():void
		{
			//launch it!
			var bLaunched:Boolean = _addin.launch();
			if (!bLaunched) {
				var e:AddInLauncherEvent = new AddInLauncherEvent(AddInLauncherEvent.FAIL);
				e.version = _addin.installedVersion;
				dispatchEvent(e);
			} else {				
				_addInLocalConnection.startTimer();
			}
		}
		
		/**
		 * @private
		 */
		protected function onError(p_evt:Event):void
		{
			trace("AddInLauncher: onError "+p_evt.toString());
			var e:AddInLauncherEvent = new AddInLauncherEvent(AddInLauncherEvent.FAIL);
			dispatchEvent(e);			
		}
		
		/**
		 * @private
		 */
		protected function onLaunch(p_evt:AddInLauncherEvent):void
		{
//			trace("AddInLauncher: onLaunch, adding installedVersion and bubbling event");
			var e:AddInLauncherEvent = new AddInLauncherEvent(AddInLauncherEvent.LAUNCH);
			e.version = _addin.installedVersion;
			dispatchEvent(e);
		}

		/**
		 * @private
		 */
		protected function onFail(p_evt:AddInLauncherEvent):void
		{
			trace("AddInLauncher: onFail");
			var e:AddInLauncherEvent = new AddInLauncherEvent(AddInLauncherEvent.FAIL);
			e.version = p_evt.version;
			dispatchEvent(e);
		}
	}
}