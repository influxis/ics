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
package com.adobe.rtc.pods.rosterClasses
{
	import com.adobe.coreUI.localization.ILocalizationManager;
	import com.adobe.coreUI.localization.Localization;
	import com.adobe.rtc.events.RTCEvent;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.pods.Roster;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.constants.UserVoiceStatuses;
	import com.adobe.rtc.sharedManagers.descriptors.UserDescriptor;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.controls.Button;
	import mx.controls.Image;
	import mx.controls.List;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.core.FlexVersion;
	import mx.core.UIComponent;
	import mx.core.UITextField;
	import mx.core.UITextFormat;
	import mx.effects.Fade;
	import mx.styles.StyleManager;
	
	/**
	 * @private
	 *
	 */
   public class  UserItemRenderer extends UIComponent implements IListItemRenderer,ISessionSubscriber
	{
		public function UserItemRenderer()
		{
			super();
		}
		
		public static const ROLE_STRINGS:Object = {10:"Audience", 50:"Participants", 100:"Hosts"};
		protected static const JEWEL_W:Number = 18;
		
		protected var _menuJewel:Button;
		protected var _data:Object;
		protected var _label:UITextField;
		protected var _userDesc:UserDescriptor;
		protected var _oldIconURL:String;
		protected var _oldRole:int=-1;
		
		[Embed(source="../rosterAssets/hostRosterIcon.png")]
		protected var DefaultHostUsericon:Class;

		[Embed(source="../rosterAssets/audienceRosterIcon.png")]
		protected var DefaultAudienceUsericon:Class;
		
		[Embed(source="../rosterAssets/participantRosterIcon.png")]
		protected var DefaultParticipantUsericon:Class;
		
		[Embed(source="../rosterAssets/microphoneIcon.png")]
		protected var MicIndicator:Class;

		[Embed(source="../rosterAssets/audioIndicator.swf#AudioStrip_glow")]
		protected var AudioIndicator:Class;

		protected var _icon:DisplayObject;
		protected var _micIndicator:DisplayObject;
		protected var _audioIndicator:DisplayObject;
		protected var _userManager:UserManager;
		protected var _lm:ILocalizationManager;
		protected var _menuClicked:Boolean = false ;

		public var isMenuShown:Boolean = false;
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
	 * 
	 *
	 * 
	 * 
	 */
		public function get data():Object
		{
			return _data;
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
	 * 
	 *
	 * 
	 * @param p_value 
	 */
		public function set data(p_value:Object):void
		{
			if (!_subscribed ) {
				// if it has not subscribed yet, we need to subscribe it so that it gets the value
				// of the connectsession looking up the displaylist
				initialize();
			}
			
			_userDesc = p_value as UserDescriptor;
				if (_icon) {
					if (_userDesc==null || _userDesc.usericonURL!=_oldIconURL || _userDesc.role!=_oldRole) {
						removeChild(_icon);
						_icon = null;
					}
				}
				if (_micIndicator && (_userDesc==null || _userDesc.voiceStatus==UserVoiceStatuses.OFF)) {
					removeChild(_micIndicator);
					_micIndicator = null;
					removeChild(_audioIndicator);
					_audioIndicator = null;
				}
			_oldIconURL = (p_value!=null) ? p_value.usericonURL : null;
			_oldRole = (p_value!=null) ? p_value.role : -1;
			_data = p_value;
			invalidateProperties();
//			invalidateSize();
			dispatchEvent(new RTCEvent(RTCEvent.DATA_CHANGE));
		}
		
		protected override function createChildren():void
		{
			if (!_subscribed ) {
				subscribe();
				_subscribed = true ;
			}
			
			if (!_label)
			{
				_label = UITextField(createInFontContext(UITextField));
				_label.styleName = this;
				addChild(DisplayObject(_label));
			}
			
			_lm = Localization.impl;
		}
		
		protected override function commitProperties():void
		{
			super.commitProperties();
			if (_data==null) {
				return;
			}
			var tf:UITextFormat = _label.getUITextFormat();
			if (! (_userDesc)) {
				tf.bold = false;
				tf.italic = true;
				_label.text = Localization.impl.getString(ROLE_STRINGS[_data.role]);
				
			} else {
				tf.bold = true;
				tf.italic = false;
				_label.text = _userDesc.displayName;

				if (!_icon) {
					buildIcon();
				}
				if (_userDesc.voiceStatus!=UserVoiceStatuses.OFF && !_micIndicator) {
					// build the mic indicator
					_micIndicator = new MicIndicator();
					_audioIndicator = new AudioIndicator();
					addChild(_micIndicator);
					addChild(_audioIndicator);
				}
				if (_audioIndicator) {
					_audioIndicator.visible = (_userDesc.voiceStatus==UserVoiceStatuses.ON_SPEAKING);
				}
			}
			_label.multiline = List(owner).variableRowHeight;
			_label.setTextFormat(tf);
		}
		
		protected override function updateDisplayList(p_unscaledWidth:Number, p_unscaledHeight:Number):void
		{
			var iconSize:Number ;
			if ( FlexVersion.compatibilityVersion > FlexVersion.VERSION_3_0) {
				iconSize = 20 ;
			}else {
				iconSize = getStyle("iconSize");
			}
			//_label.visible = (p_unscaledHeight >= measuredHeight);
			super.updateDisplayList(p_unscaledWidth, p_unscaledHeight);
			
			if (needsMenuJewel()) {
				if (!_menuJewel) {
					_menuJewel = new Button();
					_menuJewel.styleName = StyleManager.getStyleDeclaration(getStyle("menuButtonStyleName"));
					_menuJewel.width = _menuJewel.height = 20;
					_menuJewel.toolTip = Localization.impl.getString("Options for this User");
					_menuJewel.addEventListener(MouseEvent.CLICK, onMenuClick);
					addChild(_menuJewel);
					var f:Fade = new Fade(_menuJewel);
					f.alphaFrom = 0;
					f.alphaTo = 1;
					f.duration = 500;
					f.play(); 
				}
				_menuJewel.move(p_unscaledWidth-_menuJewel.width-5, Math.round((p_unscaledHeight-_menuJewel.height)/2));
			} else if (_menuJewel) {
				_menuJewel.removeEventListener(MouseEvent.MOUSE_DOWN, onMenuClick);
				removeChild(_menuJewel);
				_menuClicked = false ;
				_menuJewel = null;
			}
			var startX:Number = 0;
			if (_userDesc) {
				startX = iconSize;
				var rightPadding:Number = 0;
				if (_micIndicator) {
					_audioIndicator.x = p_unscaledWidth - 5 - JEWEL_W - 5 - _audioIndicator.width;
					_audioIndicator.y = Math.round((p_unscaledHeight-_audioIndicator.height)/2);
					_micIndicator.x = _audioIndicator.x - 2 - _micIndicator.width;
					_micIndicator.y = Math.round((p_unscaledHeight-_micIndicator.height)/2);
					rightPadding = p_unscaledWidth - 5 - _micIndicator.x;
				} else if (_menuJewel) {
					rightPadding = 5 + JEWEL_W + 5;
				}
				_label.setActualSize(p_unscaledWidth-iconSize-rightPadding, _label.getExplicitOrMeasuredHeight());
				_label.x = iconSize+5;
				_icon.width = iconSize;
				_icon.height = iconSize;
				_icon.y = (measuredHeight-_icon.height)/2;
			} else {
				_label.setActualSize(p_unscaledWidth, measuredHeight);
				_label.x = 0;
			}
			_label.y = (p_unscaledHeight-_label.height)/2;

		}
		
		override protected function measure():void
		{
			super.measure();
			var iconSize:Number = getStyle("iconSize");
	
			var w:Number = 0;
	
			if (_icon)
				w = _icon.width;
	
			// Guarantee that label width isn't zero
			// because it messes up ability to measure.
			if (_label.width < 4 || _label.height < 4)
			{
				_label.width = 4;
				_label.height = 16;
			}
	
			if (isNaN(explicitWidth))
			{
				w += _label.getExplicitOrMeasuredWidth();
				measuredWidth = w;
				measuredHeight = _label.getExplicitOrMeasuredHeight();
			}
			else
			{
				measuredWidth = explicitWidth;
				_label.setActualSize(Math.max(explicitWidth - w, 4), _label.height);
				measuredHeight = _label.getExplicitOrMeasuredHeight();
				if (_userDesc && iconSize > measuredHeight)
					measuredHeight = iconSize;
			}
			
		}
		
		protected function needsMenuJewel():Boolean
		{
			var bounds:Rectangle = getBounds(this);
			if ((List(owner).isItemHighlighted(_data) || bounds.contains(mouseX, mouseY)) && _userDesc) {
				// if the item is either highlighted or has the mouse in it, and we're diplaying a userDescriptor
				return (Roster(owner).needsMenuButton(_userDesc));
			} else {
				return isMenuShown;
			}
		}
	
		
		protected function buildIcon():void
		{
			if (_userDesc.usericonURL) {
				// cusom icon
				_icon = new Image();

				Image(_icon).source = _data.usericonURL+"&mst="+_userManager.myTicket;	//the URL always has a ?t=123456 timestamp to avoid caching
			} else {
				if (_userDesc.role==UserRoles.OWNER) {
					_icon = new DefaultHostUsericon();
				} else if (_userDesc.role==UserRoles.PUBLISHER) {
					_icon = new DefaultParticipantUsericon();
				} else {
					_icon = new DefaultAudienceUsericon();
				}
			}
			addChild(_icon);
			invalidateDisplayList();
		}
		
		protected function onMenuClick(p_evt:MouseEvent):void
		{
			if ( !_menuClicked) {
				dispatchEvent(new Event("menuShow", true));
				_menuClicked = true ;
			}else {
				dispatchEvent(new Event("menuHide", true));
				_menuClicked = false ;
			}
			
		}
		
	}
}
