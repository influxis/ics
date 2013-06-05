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
package com.adobe.rtc.pods
{
	import com.adobe.coreUI.controls.CustomMenu;
	import com.adobe.coreUI.localization.ILocalizationManager;
	import com.adobe.coreUI.localization.Localization;
	import com.adobe.coreUI.skins.NoBackgroundButtonSkin;
	import com.adobe.rtc.events.UserEvent;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.pods.rosterClasses.UserItemRenderer;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.UserDescriptor;
	
	import flash.events.Event;
	import flash.geom.Point;
	import flash.system.Capabilities;
	
	import mx.collections.ArrayCollection;
	import mx.controls.List;
	import mx.controls.Menu;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.controls.listClasses.ListItemRenderer;
	import mx.core.ClassFactory;
	import mx.core.IFactory;
	import mx.core.UIComponent;
	import mx.effects.IEffect;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.MenuEvent;
	import mx.managers.PopUpManager;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;
	import mx.core.FlexVersion;


	/**
 	*  Size of the user icon.
 	* 
 	*  @default 20
 	*/
	[Style(name="iconSize", type="uint", format="Length", inherit="no")]

	/**
 	*  StyleName for the MenuButton which appears in highlighted rows.
 	*/
	[Style(name="menuButtonStyleName", type="string", inherit="no")]

	/**
	* Dispatched when a user's options menu has an item clicked. Use <code>currentMenuItem</code> 
	* to determine with which ListItemRenderer the menu is associated. 
	*/
	[Event(name="userMenuItemClick", type="mx.events.MenuEvent")]
	/**
	* Dispatched when a user's items are synchronized.
	*/
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.UserEvent")]

	/**
	 * The Roster is a simple vertically-oriented list of users in the room which can be 
	 * optionally delimited by their roles. Each user's entry displays an icon based on 
	 * role, the user's name, and whether or not that user is speaking using VoIP. Each user 
	 * also has a menu of options which are exposed on rollover by a <code>menuButton</code> 
	 * defined by the <code class="property">menuDataProviderFunction</code> property.
	 * <p>
	 * The Roster uses UserManager's <code>userCollections</code> to populate this list 
	 * with UserDescriptors.
	 * 
	 * 
	 * @see com.adobe.rtc.sharedManagers.UserManager
	 * @see com.adobe.rtc.sharedManagers.descriptors.UserDescriptor
	 */
   public class  Roster extends List implements ISessionSubscriber
	{
		[Embed(source="rosterAssets/menuButtonIcon.png")]
		private static var menuButtonIconClass:Class;	
		[Embed(source="rosterAssets/menuButtonIcon_Over.png")]
		private static var menuButtonIconOverClass:Class;	
		private static var classConstructed:Boolean = classConstruct();
	
		private static function classConstruct():Boolean
		{
			var styleDeclaration:CSSStyleDeclaration = StyleManager.getStyleDeclaration("Roster");
	
			// If there's no style declaration already, create one.
			if (!styleDeclaration){
				styleDeclaration = new CSSStyleDeclaration();
				
				if ( FlexVersion.compatibilityVersion > FlexVersion.VERSION_3_0) {
					styleDeclaration["setStyle"]("backgroundColor","0xFFFFFF");
					styleDeclaration["setStyle"]("rollOverColor", "0xECEEED");
					styleDeclaration["setStyle"]("iconSize", "20");
					styleDeclaration["setStyle"]("backgroundAlpha", 1);
					styleDeclaration["setStyle"]("menuButtonStyleName", "rosterMenuButtonStyle");
					
					styleDeclaration["setStyle"]("upSkin",NoBackgroundButtonSkin);
					styleDeclaration["setStyle"]("downSkin", NoBackgroundButtonSkin);
					styleDeclaration["setStyle"]("overSkin", NoBackgroundButtonSkin);
					styleDeclaration["setStyle"]("icon", menuButtonIconClass);
					styleDeclaration["setStyle"]("overIcon", menuButtonIconOverClass);
				}
			}
			
			styleDeclaration.defaultFactory = function ():void {
				this.iconSize = 20;
				this.rollOverColor = 0xECEEED;
				this.backgroundColor = 0xFFFFFF;
				this.backgroundAlpha = 1;
				this.menuButtonStyleName = "rosterMenuButtonStyle";
			};

			StyleManager.setStyleDeclaration("Roster", styleDeclaration, false);
			
			styleDeclaration = StyleManager.getStyleDeclaration("rosterMenuButtonStyle");
			if (!styleDeclaration)
				styleDeclaration = new CSSStyleDeclaration();
			
			styleDeclaration.defaultFactory = function ():void {
				this.upSkin = NoBackgroundButtonSkin;
				this.downSkin = NoBackgroundButtonSkin;
				this.overSkin = NoBackgroundButtonSkin;
				this.icon = menuButtonIconClass;
				this.overIcon = menuButtonIconOverClass;
			};

			StyleManager.setStyleDeclaration("rosterMenuButtonStyle", styleDeclaration, false);			
			
			return true;
		}

		public function Roster()
		{
			super();
		}
		
		/**
		 * @private 
		 */
		protected static const ROW_HEADER:String = "RowHeader";

		/**
		 * Constant used in the default <code>menuDataProviderFunction</code> to 
		 * indicate that the user's role should be changed. 
		 */
		public static const ROLE_CHANGE:String = "RoleChange";
		
		/**
		 * Constant used in the default <code>menuDataProviderFunction</code> to 
		 * indicate that the user should be removed.  
		 */
		public static const REMOVE_USER:String = "RemoveUser";


		[Embed(source="rosterAssets/hostMenuIcon.png")]
		/**
		 * The host user icon used in the default menu that corresponds to UserRoles.OWNER.
		 */
		public static var MENU_HOST_USER_ICON:Class;
		
		[Embed(source="rosterAssets/audienceMenuIcon.png")]
		/**
		 * The audience user icon used in the default menu that corresponds to UserRoles.VIEWER.
		 */
		public static var MENU_AUDIENCE_USER_ICON:Class;
		[Embed(source="rosterAssets/participantMenuIcon.png")]
		/**
		 * The participant user icon used in the default menu that corresponds to UserRoles.PUBLISHER. 
		 */
		public static var MENU_PARTICIPANT_USER_ICON:Class;
		
		/**
		* @private
		*/
		protected var _userManager:UserManager;
		/**
		* @private
		*/
		protected var _hostCollection:ArrayCollection;
		/**
		* @private
		*/
		protected var _participantCollection:ArrayCollection;
		/**
		* @private
		*/
		protected var _audienceCollection:ArrayCollection;
		/**
		* @private
		*/
		protected var _showMenu:Boolean = true;
		/**
		 * @private
		 */		
		protected var _itemRendererSet:Boolean = false;
		
		/**
		* @private
		*/
		protected var _internalDP:ArrayCollection;	
		/**
		* @private
		*/
		protected var _lm:ILocalizationManager;	
		/**
		* @private
		*/
		protected var _userMenu:Menu;
		/**
		* @private
		*/
		protected var _currentMenuItem:IListItemRenderer;
		/**
		* @private
		*/
		protected var _currentMenuDP:Object;
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
		
		[Inspectable(enumeration="false,true", defaultValue="true")]
		/**
		 * Whether or not to show <code>menuButtons</code> when there is a rollover
		 * event on user entries. 
		 * 
		 * @default true
		 */
		public var showMenuButtons:Boolean = true;
		
		/**
		 * Specifies a user-supplied function to use in determining the <code>dataProvider</code> 
		 * of the user options menu for each <code>userDescriptor</code>. The function takes a 
		 * <code>userDescriptor</code> and returns a <code>dataProvider</code> suitable for a menu, 
		 * for example, <code>myDPFunction(p_user:UserDescriptor):Object</code>.
		 * In order to prevent any menu from being shown for this user, it returns null. 
		 */
		public var menuDataProviderFunction:Function;
		
		[Inspectable(enumeration="false,true", defaultValue="false")]
		/**
		 * whether or not to display selection
		 * @default false
		 */
		public var displaySelection:Boolean = false;
		
		[Inspectable(enumeration="false,true", defaultValue="true")]
		/**
		 * whether or not to show header rows for each role
		 * @default true
		 */
		public var showRoleHeaders:Boolean = true;
		
		
		/**
		 * @inheritdoc
		 */
		override public function set itemRenderer(p_value:IFactory):void
		{
			if (! (p_value.newInstance() is ListItemRenderer)) {
				_itemRendererSet = true;
			}
			super.itemRenderer = p_value;
		}

		/**
		 * Specifies the <code>itemRenderer</code> for the currently displayed user options menu. 
		 */
		public function get currentMenuItem():IListItemRenderer
		{
			return _currentMenuItem;
		}
		
		/**
		 * @private
		 * The <code>sharedID</code> is the ID of the class.
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

		[Bindable(event="synchronizationChange")]
		/**
		 * Returns true if the model is synchronized; otherwise, false.
		 */
		public function get isSynchronized():Boolean
		{
			return _userManager.isSynchronized ;
		}
		
		/**
		 * The IConnectSession with which this component is associated. 
		 * Note that this may only be set once before <code>subscribe()</code>
		 * is called; re-sessioning of components is not supported. 
		 * Defaults to the first IConnectSession created in the application.
		 */
		 
		public function get connectSession():IConnectSession
		{
			return _connectSession;
		}
		
		/**
		 * Sets the IConnectSession with which this component is associated.  
		 */
		public function set connectSession(p_session:IConnectSession):void
		{
			_connectSession = p_session;
		}

		/**
		 * @private
		 */
		public function needsMenuButton(p_userDesc:UserDescriptor):Boolean
		{
			if (menuDataProviderFunction!=null) {
				_currentMenuDP = menuDataProviderFunction(p_userDesc);
				return (_currentMenuDP!=null && _currentMenuDP.length!=0);
			}
			return false;
		}
		
		/**
		 * Disposes all listeners to the network and framework classes. Recommended for 
		 * proper garbage collection of the component.
		 */
		public function close():void
		{
			if (showRoleHeaders) {
				_hostCollection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onUserCollectionChange);
				_participantCollection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onUserCollectionChange);
				_audienceCollection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onUserCollectionChange);
			}
			dataProvider = new Array();
			if (_userMenu) {
				_userMenu.hide();
				PopUpManager.removePopUp(_userMenu);
			}
			
		}
		
		/**
		 * Tells the component to begin synchronizing with the service. 
		 * For UIComponent-based components such as this one,
		 * <code>subscribe()</code> is called automatically upon being added to the <code>displayList</code>. 
		 * For "headless" components, this method must be called explicitly.
		 */
		public function subscribe():void
		{
			if (!_userManager) {
				_userManager = _connectSession.userManager;
				_userManager.addEventListener(UserEvent.SYNCHRONIZATION_CHANGE,onSynchronizationChange);
			}
		}

		/**
		* @private
		*/
		override protected function updateDisplayList(p_w:Number,p_h:Number):void
		{
			if (p_w< 0 || p_h< 0) {
				return;
			}
			super.updateDisplayList(p_w, p_h);
		}

		/**
		 * @private
		 */
		override protected function createChildren():void
		{
			super.createChildren();
			
			if ( !_subscribed ) {
				subscribe();
				_subscribed = true  ;
			}
			
			
		}

		/**
		* @private
		*/
		override protected function commitProperties():void
		{
			super.commitProperties();
			

			if (!_itemRendererSet) {
				itemRenderer = new ClassFactory(UserItemRenderer);
			}

			if (!_userManager) {
				_userManager = _connectSession.userManager;
			}
			
			_lm = Localization.impl;
			if (showRoleHeaders) {
				_hostCollection = _userManager.hostCollection;
				_hostCollection.addEventListener(CollectionEvent.COLLECTION_CHANGE, onUserCollectionChange);
				_participantCollection = _userManager.participantCollection;
				_participantCollection.addEventListener(CollectionEvent.COLLECTION_CHANGE, onUserCollectionChange);
				_audienceCollection = _userManager.audienceCollection;
				_audienceCollection.addEventListener(CollectionEvent.COLLECTION_CHANGE, onUserCollectionChange);
				refreshDataProvider();
			} else {
				dataProvider = _userManager.userCollection;
			}
			
			if ( showMenuButtons ) {
				addEventListener("menuShow", onShowMenu);
				addEventListener("menuHide",onHideMenu)
			
				if (menuDataProviderFunction==null) {
					menuDataProviderFunction = defaultMenuDPFunction;
				}
			}
		}
		
		/**
		* @private
		*/
		protected function refreshDataProvider():void
		{
			var newArray:Array = new Array();
			if (_hostCollection.length>0) {
				newArray.push({type:ROW_HEADER, role:UserRoles.OWNER});
				newArray = newArray.concat(_hostCollection.source);
			}
			if (_participantCollection.length) {
				newArray.push({type:ROW_HEADER, role:UserRoles.PUBLISHER});
				newArray = newArray.concat(_participantCollection.source);
			}
			if (_audienceCollection.length) {
				newArray.push({type:ROW_HEADER, role:UserRoles.VIEWER});
				newArray = newArray.concat(_audienceCollection.source);
			}
			dataProvider = _internalDP = new ArrayCollection(newArray);
			
		}
		
		/**
		* @private
		*/
		protected function onUserCollectionChange(p_evt:CollectionEvent):void
		{
			var targetCollection:ArrayCollection = p_evt.target as ArrayCollection;
			var role:Number = UserRoles.OWNER;
			var currentHeaderOffset:int = 0;
			if (targetCollection==_participantCollection) {
				currentHeaderOffset = _hostCollection.length + int(Boolean(_hostCollection.length));
				role = UserRoles.PUBLISHER;
			} else if (targetCollection==_audienceCollection) {
				currentHeaderOffset = _hostCollection.length + int(Boolean(_hostCollection.length)) + 
											_participantCollection.length + int(Boolean(_participantCollection.length));
				role = UserRoles.VIEWER;
			}
			if (p_evt.kind==CollectionEventKind.ADD) {
				if (targetCollection.length==1) {
					// first time we've ever added to this group - needs a header.
					_internalDP.addItemAt({type:ROW_HEADER, role:role}, currentHeaderOffset);
				}
				_internalDP.addItemAt(p_evt.items[0], currentHeaderOffset+1+p_evt.location);
			} else if (p_evt.kind==CollectionEventKind.REMOVE) {
				if (targetCollection.length==0) {
					// we just removed the last item from this group - remove the header
					var e:IEffect;
					if (cachedItemsChangeEffect) {
						e = cachedItemsChangeEffect;
						cachedItemsChangeEffect = null;
					}
					
					if ( _internalDP.length > 0 ) {
						_internalDP.removeItemAt(currentHeaderOffset);
					}
					validateNow();
					if (e) {
						cachedItemsChangeEffect = e;
					}
				}
				
				if ( _internalDP.length > 0 ) {
					_internalDP.removeItemAt(currentHeaderOffset+1-int(!Boolean(targetCollection.length))+p_evt.location);
				}
				
			}
		}
		
		/**
		* @private
		*/
		protected function defaultMenuDPFunction(p_user:UserDescriptor):Object
		{
			if (_userManager.getUserRole(_userManager.myUserID)==UserRoles.OWNER || (p_user.userID==_userManager.myUserID && _userManager.myUserAffiliation==UserRoles.OWNER)) {
				var menuDP:Object = new ArrayCollection();
				menuDP.addItem({label: _lm.getString("Role"), children: [
						{label: _lm.getString("Host"), kind:ROLE_CHANGE, icon: MENU_HOST_USER_ICON, value:UserRoles.OWNER},
						{label: _lm.getString("Participant"), kind:ROLE_CHANGE, icon: MENU_PARTICIPANT_USER_ICON, value:UserRoles.PUBLISHER},
						{label: _lm.getString("Audience"), kind:ROLE_CHANGE, icon: MENU_AUDIENCE_USER_ICON, value:UserRoles.VIEWER}
					]});
				if (_userManager.getUserRole(_userManager.myUserID) ==UserRoles.OWNER && p_user.userID!=_userManager.myUserID) {
					menuDP.addItem({label:_lm.getString("Remove User"), kind:REMOVE_USER});
				}
				
				return menuDP;
			}
			return null;
		}
		
		
		/**
		* @private
		*/
		protected function onShowMenu(p_evt:Event):void
		{
			_currentMenuItem = p_evt.target as IListItemRenderer;
			if (_currentMenuItem is UserItemRenderer) {
				UserItemRenderer(_currentMenuItem).isMenuShown = true;
			}
			
			
			if (!_userMenu) {
				_userMenu = CustomMenu.createCustomMenu(null, _currentMenuDP);
//				_userMenu.styleName = this;
				_userMenu.addEventListener(MenuEvent.MENU_HIDE, onMenuHide);
				_userMenu.addEventListener(MenuEvent.ITEM_CLICK, onMenuItemClick);
			} else {
				_userMenu.dataProvider = _currentMenuDP;
			}
			_userMenu.owner = stage;
			addChild(_userMenu);
			_userMenu.validateNow();
			var menuW:Number = _userMenu.measuredWidth;
			var menuH:Number = _userMenu.measuredHeight;
			removeChild(_userMenu);

			var menuPt:Point = stage.globalToLocal(_currentMenuItem.localToGlobal(new Point(_currentMenuItem.width-menuW, _currentMenuItem.height-3)));
			
			if (Capabilities.hasScreenBroadcast) { 
				menuPt.x = Math.min(Object(Object(stage).window).width-menuW, menuPt.x);
				menuPt.y = Math.min(Object(Object(stage).window).height-menuH, menuPt.y);
			} else {
				menuPt.x = Math.min(stage.width-menuW, menuPt.x);
				menuPt.y = Math.min(stage.height-menuH, menuPt.y);
			}
			_userMenu.show(menuPt.x, menuPt.y); // this too
			
			
		}
		
		/**
		 * @private
		 */
		protected function onHideMenu(p_evt:Event):void
		{
			if ( _userMenu ) {
				_userMenu.hide();
			}
		}
			
		
		/**
		* @private
		*/
		protected function onMenuHide(p_evt:MenuEvent):void
		{
			if (p_evt.menu!=_userMenu) {
				return;
			}
			if (_currentMenuItem is UserItemRenderer) {
				UserItemRenderer(_currentMenuItem).isMenuShown = false;
			}
			var tmpItem:IListItemRenderer = _currentMenuItem;
			_currentMenuItem = null;
			drawItem(tmpItem);
		}
		
		/**
		* @private
		*/
		protected function onMenuItemClick(p_evt:MenuEvent):void
		{
			var data:Object = p_evt.item;
			var userDesc:UserDescriptor = _currentMenuItem.data as UserDescriptor;
			if (data.kind==ROLE_CHANGE) {
				_userManager.setUserRole(userDesc.userID, data.value);
			} else if (data.kind==REMOVE_USER) {
				_userManager.removeUser(userDesc.userID);
			}
			var evt:Event = new MenuEvent("userMenuItemClick", p_evt.bubbles, p_evt.cancelable, p_evt.menuBar, p_evt.menu, p_evt.item,
											p_evt.itemRenderer, p_evt.label, p_evt.index);
			dispatchEvent(evt);
		}
		
		/**
		* @private
		*/
		override protected function drawItem(p_item:IListItemRenderer, p_selected:Boolean=false, p_highlighted:Boolean=false, p_caret:Boolean=false, p_transition:Boolean=false):void
		{
			if (p_item==null) {
				super.drawItem(p_item, p_selected, p_highlighted, p_caret, p_transition);
				return;
			}
			if (!(p_item.data is UserDescriptor)) {
				p_selected = false;
				p_highlighted = false;
			}
			if (!displaySelection) {
				p_selected = false;
			}
			if (p_item==_currentMenuItem) {
				p_highlighted = true;
			}
			super.drawItem(p_item, p_selected, p_highlighted, p_caret, p_transition);
		}
		
		/**
		 * @private
		 */
		protected function onSynchronizationChange(p_evt:UserEvent):void
		{
			if ( !_userManager.isSynchronized && _internalDP ) {
				//clean the data provider
				_internalDP.removeAll();
			}
			
			if ( _connectSession && _connectSession.archiveManager && _connectSession.archiveManager.isPlayingBack ) {
				enabled = false ;
			}
			
			dispatchEvent(p_evt);
		}
		
		/**
		 *  Sets the role of a given user for the room as a whole; it is equivalent to <code>UserManager.setUserRole()</code>.
		 * 
		 * @param p_userID The user's user ID whose role should be set.
		 * @param p_userRole The role value to set.
		 */
		public function setUserRole(p_userID:String,p_userRole:int):void
		{
			if ( p_userID == null ) 
				return ;
				
			_userManager.setUserRole(p_userID,p_userRole);
		}
		
		/**
		 *  Returns the role of a given user for the room as a whole; it is equivalent to <code>UserManager.getUserRole()</code>.
		 * 
		 * @param p_userID The user ID for the user being queried.
		 */
		public function getUserRole(p_userID:String):int
		{
			if ( p_userID == null ) {
				throw new Error("Roster Pod: USerId can't be null");
			}
			
			return _userManager.getUserRole(p_userID);
		}
		
	}
}
