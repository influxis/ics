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
package com.adobe.rtc.collaboration.screenShareSubscriberClasses
{
	/* FLash Begin
	import com.adobe.rtc.collaboration.screenShareSubscriberClasses.screenShareSubscriberCursorAssets.ScreenShareSubscriberCursorNormal;
	import com.adobe.rtc.collaboration.screenShareSubscriberClasses.screenShareSubscriberCursorAssets.ScreenShareSubscriberCursorClick;
	FLash End*/
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.SessionEvent;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
	
	import flash.display.DisplayObject;
	import flash.utils.getDefinitionByName;
	
	import mx.core.UIComponent;
	
	/**
	 * Dispatched when the component either loses its connection to the session or regains it
	 * and has finished re-synchronizing itself to the rest of the room.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	
	
	/**
	 * @private
	 * While sharing screens, it's more bandwidth-efficient to stream the cursor coordinates separately from the
	 *   screen scrape and to redraw the cursor in the subscriber.  This class represents that cursor, along with
	 *   some added functionality.
	 * 
	 * <p>The ScreenShareSubscriberCursor can be made aware of the user currently in control, and will display that
	 *   user's avatar if available.</p>
	 * 
	 */
	
	public class  ScreenShareSubscriberCursor extends UIComponent implements ISessionSubscriber
	{
		
		// FLeX Begin
		[Embed (source = 'screenShareSubscriberCursorAssets/screenShareCursor.swf#com.adobe.rtc.collaboration.screenShareSubscriberClasses.screenShareSubscriberCursorAssets.ScreenShareSubscriberCursorClick')]
		protected static var ScreenShareSubscriberCursorClick:Class;
		
		[Embed (source = 'screenShareSubscriberCursorAssets/screenShareCursor.swf#com.adobe.rtc.collaboration.screenShareSubscriberClasses.screenShareSubscriberCursorAssets.ScreenShareSubscriberCursorNormal')]
		protected static var ScreenShareSubscriberCursorNormal:Class;
		// FLeX End
		
		protected var _cursor:DisplayObject;
		protected var _clicking:Boolean;
		protected var _clickingChanged:Boolean;
		/**
		 * @private
		 */
		protected var _sharedID:String;
		/**
		 * @private
		 */
		protected var _subscribed:Boolean = false ;
		/**
		 * @private 
		 */		
		protected var _connectSession:IConnectSession = new SessionContainerProxy(this as UIComponent);
		
		/**
		 * The <code>sharedID</code> is the ID of the class 
		 */
		public function set sharedID(p_id:String):void
		{
			_sharedID = p_id;
		}
		
		/**
		 * @private
		 */
		public function get sharedID():String
		{
			return _sharedID;
		}
		
		/**
		 * TODOTODO 
		 * @return 
		 * 
		 */
		public function get connectSession():IConnectSession
		{
			return _connectSession;
		}
		
		public function set connectSession(p_session:IConnectSession):void
		{
			_connectSession = p_session;
		}
		
		[Bindable(event="synchronizationChange")]
		/**
		 * Returns true/ false if not synchronized...
		 */
		public function get isSynchronized():Boolean
		{
			if ( !_connectSession ) {
				return false ;
			}
			
			return _connectSession.isSynchronized ;
		}
		
		
		public function close():void
		{
			//NO -OP
		}
		
		/**
		 * Function to subscribe 
		 */
		public function subscribe():void
		{
			_connectSession.addEventListener(SessionEvent.SYNCHRONIZATION_CHANGE,onSynchronizationChange);
		}
		
		// FLeX Begin
		override protected function commitProperties():void
		{
			
			if(_clickingChanged) {
				_clickingChanged = false;
				
				if(_clicking) {
					// The cursor doesn't seem to change unless we remove and add the child again...
					removeChild(_cursor);
					_cursor = DisplayObject(new ScreenShareSubscriberCursorNormal());
					addChild(_cursor);
				}
				else {
					removeChild(_cursor);
					_cursor = DisplayObject(new ScreenShareSubscriberCursorClick());
					addChild(_cursor);
				}
			}
			
			/*			if(_controllingUserIDChanged) {
			_controllingUserIDChanged = false;
			var descriptor:UserDescriptor = _userManager.getUserDescriptor(_controllingUserID);
			
			// Ensure that this user exists.
			if(!descriptor) {
			throw new Error("ScreenShareSubscriberCursor.controllingUserID: That user does not exist.");
			return;
			}
			
			/*				if(_controllingUserID == null) {/* || descriptor.usericonURL == null) {*
			removeChild(_decoration);
			_decoration = new _iconPresenterClass as Sprite;
			addChild(_decoration);
			}
			*				else {
			removeChild(_decoration);
			descriptor = _userManager.getUserDescriptor(_controllingUserID);
			_decoration = new Image();
			addChild(_decoration);
			Image(_decoration).source = descriptor.usericonURL;
			}
			*				
			}
			*/			
			super.commitProperties();
		}
		// FLeX End
		
		
		
		override protected function createChildren():void
		{
			if ( !_subscribed ) {
				subscribe();
				_subscribed = true ;
			}
			
			
			if(!_cursor) {
				_cursor = new ScreenShareSubscriberCursorNormal();
				//_cursor = new Loader();
				//_cursor.load(new URLRequest("screenShareSubscriberCursorAssets/cursor.png"));
				addChild(_cursor);
			}
			/*
			if(!_decoration) {
			_decoration = new Sprite();
			_decoration = new _iconPresenterClass as Sprite;
			addChild(_decoration);
			}*/
		}
		
		// FLeX Begin
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			_cursor.x = 0;
			_cursor.y = 0;
			/*
			if(_decoration is _iconPresenterClass) {
			_decoration.width = 24;
			_decoration.height = 18;
			}
			else if (_decoration is Image) {
			_decoration.width = 25;
			_decoration.height = 25;
			}
			_decoration.x = 10;
			_decoration.y = 10;
			*/
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		// FLeX End
		
		
		/* Public functions
		---------------------------------------------------------------------------------------*/
		
		
		public function set clicking(p_value:Boolean):void
		{
			if(p_value != _clicking) {
				_clicking = p_value;
				_clickingChanged = true;
				invalidateProperties();
				invalidateDisplayList();
			}
		}
		
		public function get clicking():Boolean
		{
			return _clicking;
		}
		
		/*
		public function set controllingUserID(p_value:String):void
		{
		_controllingUserID = p_value;
		_controllingUserIDChanged = true;
		invalidateProperties();
		invalidateDisplayList();
		}
		
		public function get controllingUserID():String
		{
		return _controllingUserID;
		}
		*/
		
		protected function onSynchronizationChange(p_evt:SessionEvent):void
		{
			dispatchEvent(p_evt);
		}
	}
}