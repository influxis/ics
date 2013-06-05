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
package com.adobe.rtc.pods.horizontalRosterClasses
{
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.constants.UserVoiceStatuses;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	
	import mx.controls.Image;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.core.UIComponent;
	import mx.core.UITextField;


	/**
	 * @private
	 */
   public class  UserItemRenderer extends UIComponent implements IListItemRenderer,ISessionSubscriber
	{
		protected var _data:Object = new Object();

		[Embed(source="../rosterAssets/hostRosterIcon.png")]
		protected var DefaultHostUsericon:Class;

		[Embed(source="../rosterAssets/audienceRosterIcon.png")]
		protected var DefaultAudienceUsericon:Class;
		
		[Embed(source="../rosterAssets/participantRosterIcon.png")]
		protected var DefaultParticipantUsericon:Class;
		
		[Embed(source="../rosterAssets/longAudioIndicator.swf#AudioStrip_glow")]
		protected var _audioAnimationClass:Class;
		[Embed(source="../rosterAssets/longAudioIndicator.swf#AudioStrip_off")]
		protected var _audioInactiveClass:Class;
		
		protected var _userManager:UserManager;
		protected var _label:UITextField;
		protected var _icon:DisplayObject;
		protected var _iconW:Number = 30;
		protected var _iconH:Number = 30;
		protected var _invVoiceStatus:Boolean = false;
		protected var _previousVoiceStatus:String;
		protected var _audioAnimation:DisplayObject;
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
		protected var _voiceStatus:String = null;
		/**
		 * @private 
		 */		
		protected var _connectSession:IConnectSession = new SessionContainerProxy(this as UIComponent);
		
		override protected function createChildren():void
		{
			if ( !_subscribed) {
				subscribe();
				_subscribed = true ;
			}
			
			createLabel();
			
			
		}
		
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
		 * Returns true if the model is synchronized
		 */
		public function get isSynchronized():Boolean
		{
			return _connectSession.isSynchronized ;
		}
		
		/**
		 * On Closing session..
		 */
		public function close():void
		{
			//NO OP
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
		
		public function subscribe():void
		{
			if (!_userManager ) {
				_userManager = _connectSession.userManager ;
			}
		}
		
		protected function createLabel():void
		{
			if (!_label) {
				_label = new UITextField();
				addChild(_label);
				_label.styleName = "userItemLabelStyle";
				if (_data) {
					_label.text = (_data.userID == _userManager.myUserID) ? "* "+_data.displayName : _data.displayName;
					invalidateDisplayList();
					buildIcon();
				}
			}
		}
		
		public function get data():Object
		{
			return _data;
		}
		
		protected function buildIcon():void
		{
			if (!_icon) {
				if (_data.usericonURL) {
					// cusom icon
					_icon = new Image();

					Image(_icon).source = _data.usericonURL+"&mst="+_userManager.myTicket;	//the URL always has a ?t=123456 timestamp to avoid caching
				} else {
					if (_data.role==UserRoles.OWNER) {
						_icon = new DefaultHostUsericon();
					} else if (_data.role==UserRoles.PUBLISHER) {
						_icon = new DefaultParticipantUsericon();
					} else {
						_icon = new DefaultAudienceUsericon();
					}
				}
				addChild(_icon);
				_icon.width = _iconW;
				_icon.height = _iconH;
				invalidateDisplayList();
			}
		}
		
		public function set data(p_value:Object):void
		{
			if (!_subscribed) {
				initialize();
			}
			if (_label && _label.text!=p_value.displayName) {
				_label.text = (p_value.userID == _userManager.myUserID) ? "* "+p_value.displayName : p_value.displayName;
				invalidateDisplayList();
			}
			if (p_value.usericonURL!=_data.usericonURL || (!_data.usericonURL && p_value.role!=_data.role)) {
				// we're changing icons
				if (_icon) {
					removeChild(_icon);
					_icon = null;
				}
				
			} 
			if (p_value.voiceStatus!=_voiceStatus) {
				_voiceStatus = p_value.voiceStatus;
				_invVoiceStatus = true;
				invalidateDisplayList();
			}
			_data = p_value;
			buildIcon();
		}
		
	
		
		protected override function updateDisplayList(p_w:Number, p_h:Number):void
		{
			super.updateDisplayList(p_w, p_h);
			
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0x000000, 0);
			g.drawRect(0,0,p_w,p_h);
			_label.setActualSize(p_w-18-_iconW-2, _label.textHeight+4);
			_label.truncateToFit("...");
			_icon.x = Math.round((p_w-_label.width-2-_iconW)/2);
			_icon.y = Math.round((p_h-_iconH)/2);
			_label.move(_icon.x+_iconW+2, Math.round((p_h-_label.height)/2));
			toolTip = _data.displayName;

			if (_invVoiceStatus) {
				_invVoiceStatus = false;
				
				if(_data.voiceStatus != UserVoiceStatuses.OFF) {
	
					if (!(_audioAnimation is _audioAnimationClass) && _data.voiceStatus==UserVoiceStatuses.ON_SPEAKING) {
						if (_audioAnimation) {
							removeChild(_audioAnimation);
						}
						_audioAnimation = new _audioAnimationClass();
						addChild(_audioAnimation);
					} else if (!(_audioAnimation is _audioInactiveClass) && _data.voiceStatus==UserVoiceStatuses.ON_SILENT) {
						if (_audioAnimation) {
							removeChild(_audioAnimation);
						}
						_audioAnimation = new _audioInactiveClass();
						addChild(_audioAnimation);
					}
					_audioAnimation.x = (p_w-_audioAnimation.width -4)/2;
					_audioAnimation.y = _label.y + _label.height;
					
					_previousVoiceStatus = data.voiceStatus;
	
		            setChildIndex(DisplayObject(_audioAnimation), numChildren - 1);
				}
				else if (_audioAnimation) {
					removeChild(_audioAnimation);
					_audioAnimation = null;
				}				
				
			}
		}
		
	}
}
