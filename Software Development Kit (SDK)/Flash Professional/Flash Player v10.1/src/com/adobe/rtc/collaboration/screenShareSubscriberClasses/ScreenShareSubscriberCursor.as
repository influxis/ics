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
	
	import com.adobe.rtc.collaboration.screenShareSubscriberClasses.screenShareSubscriberCursorAssets.ScreenShareSubscriberCursorNormal;
	import com.adobe.rtc.collaboration.screenShareSubscriberClasses.screenShareSubscriberCursorAssets.ScreenShareSubscriberCursorClick;
	
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.SessionEvent;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
 
	
	import flash.display.DisplayObject;
	import flash.utils.getDefinitionByName;
	
import flash.display.Sprite; //FlashOnlyReplacement 
 import flash.events.Event; //FlashOnlyReplacement
	
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
	
public class ScreenShareSubscriberCursor extends Sprite implements ISessionSubscriber //FlashOnlyReplacement
	{
		
		 
		
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
		protected var _connectSession:IConnectSession= null;
		
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
		
		 
		
		
		
public function ScreenShareSubscriberCursor():void 
 { 
 super(); 
 addEventListener(Event.ADDED_TO_STAGE, onAddTOStage); 
 } 
 public function onAddTOStage(p_evt:Event):void
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
		
		 
		
		
		/* Public functions
		---------------------------------------------------------------------------------------*/
		
		
		public function set clicking(p_value:Boolean):void
		{
			if(p_value != _clicking) {
				_clicking = p_value;
				_clickingChanged = true;
 
 
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