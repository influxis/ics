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
	import com.adobe.rtc.events.UserEvent;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.pods.horizontalRosterClasses.RosterTileList;
	import com.adobe.rtc.pods.horizontalRosterClasses.UserItemRenderer;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.UserDescriptor;
	
	import flash.display.GradientType;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.controls.listClasses.TileBaseDirection;
	import mx.core.ClassFactory;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.CollectionEvent;
	import mx.events.ListEvent;
	import mx.events.MenuEvent;
	
	/**
	 * Dispatched when a user is clicked if <code>useExternalMenuData</code> is set to true.
	 */
	[Event(name="userItemClick", type="flash.events.Event")]	

	/**
	 * Dispatched when a user's menu item is clicked if <code>useExternalMenuData</code> is set to true.
	 */
	[Event(name="itemClick", type="mx.events.MenuEvent")]	
	
	/**
	 * Dispatched when a user's items are synchronized.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.UserEvent")]
	

	/**
	 * The HorizontalRoster is a component for displaying the set of users horizontally. 
	 * It consists of three separate horizontal List controls. It groups users by their role 
	 * and places each group in a corresponding List. HorizontalRoster uses the UserManager 
	 * as its model and displays sets of UserDescriptors. The roster allows a menu to be shown 
	 * when a user item is clicked, thereby presenting choices that correspond to the 
	 * selected user. The set of choices is either a default set or a custom set created by 
	 * using <code>useExternalMenuData</code><code>menuData</code> and <code>showMenu()</code>.
	 * 
	 * @see com.adobe.rtc.sharedManagers.UserManager
	 * @see com.adobe.rtc.sharedManagers.descriptors.UserDescriptor
	 */
   public class  HorizontalRoster extends UIComponent implements ISessionSubscriber
	{
		/**
		 * @private
		 */
		protected static const MENU_ROLE_OWNER:String = "roleOwner";
		
		/**
		 * @private
		 */
		protected static const MENU_ROLE_PUBLISHER:String = "rolePublisher";
		
		/**
		 * @private
		 */
		protected static const MENU_ROLE_VIEWER:String = "roleViewer";
		
		/**
		 * @private
		 */
		protected static const MENU_REMOVE_USER:String = "removeUSer";

		/**
		 * @private
		 */
		protected static const MIN_LIST_WIDTH:Number = 130;
		
		/**
		* @private
		*/
		protected static const COLUMN_WIDTH:Number = 130;

		/**
		 * @private
		 * Width of the space between TileLists.  Unaffected by CSS or the actual appearance of the divider.
		 */
		protected static const DIVIDER_WIDTH:int = 4;

		[Embed(source="rosterAssets/hostMenuIcon.png")]
		 
		 /**
		 * Specifies the default user icon to use for users with an owner role.
		 */
		public var HostIconClass:Class;
		
		[Embed(source="rosterAssets/participantMenuIcon.png")]
		
		/**
		 * Specifies the default user icon to use for users with a publisher role.
		 */
		public var ParticipantIconClass:Class;
		
		[Embed(source="rosterAssets/audienceMenuIcon.png")]
		
		/**
		 * 		[Embed(source="horizontalRosterAssets/iconParticipant.png")]
		 * 
		 * Specifies the default user icon to use for users with a viewer role.
		 */
		public var AudienceIconClass:Class;
		
		/**
		 * @private
		 */
		protected var _hostList:RosterTileList;
		/**
		 * @private
		 */
		protected var _participantList:RosterTileList;
		/**
		 * @private
		 */
		protected var _audienceList:RosterTileList;
		
		/**
		 * @private
		 */
		protected var _currentMenu:CustomMenu;
		
		/**
		 * @private
		 */
		protected var _userManager:UserManager;
		
		/**
		 * @private
		 */
		protected var _menuData:ArrayCollection;
		/**
		 * @private
		 */
		protected var _useExternalMenuData:Boolean = false;
		/**
		 * @private
		 */
		protected var _menuDataChanged:Boolean = true;
		
		/**
		 * @private
		 */
		protected var _itemLastClicked:IListItemRenderer;
		/**
		 * @private
		 */
		protected var _itemLastTarget:RosterTileList;
				
		/**
		 * @private
		 */
		protected var _lm:ILocalizationManager = Localization.impl;
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
		
		[Inspectable(enumeration="false,true", defaultValue="false")]
		/**
		 * Determines whether to use the default menu when a user is clicked (false)
		 * or allow a custom menu (true). If set to true, the <code>userItemClick</code>
		 * event is fired on click. If a custom menu is used, the developer should supply 
		 * a custom set of menu data with <code>menuData</code> and call <code>showMenu</code>. 
		 * 
		 * @default false
		 */
		public function get useExternalMenuData():Boolean
		{
			return _useExternalMenuData;
		}
		
		/**
		 * @private
		 */
		public function set useExternalMenuData(p_useIt:Boolean):void
		{
			_useExternalMenuData = p_useIt;
		}
		
		/**
		 * Specifies a custom <code>dataProvider</code> to supply to a menu when a user item is clicked. 
		 * This can be set on <code>userItemClick</code> and then followed by a <code>showMenu</code> 
		 * command. To detect items on the menu being clicked, listen to the <code>itemClick</code> event.
		 */
		public function get menuData():ArrayCollection
		{
			return _menuData;
		}
		/**
		 * @private
		 */
		public function set menuData(p_data:ArrayCollection):void
		{
			_menuData = p_data;
			_menuDataChanged = true;
			invalidateProperties();
		}

		/**
		 * Returns the last user item clicked on the roster.
		 */
		public function get itemLastClicked():IListItemRenderer
		{
			return _itemLastClicked;
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
		
		[Bindable(event="synchronizationChange")]
		/**
		 * Returns true if the model is synchronized; otherwise, false.
		 */
		public function get isSynchronized():Boolean
		{
			return _userManager.isSynchronized ;
		}
		
		/**
		 * Disposes all listeners to the network and framework classes. 
		 * Recommended for proper garbage collection of the component.
		 */
		public function close():void
		{
			if ( _userManager ) {
				_userManager.hostCollection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange);
				_userManager.participantCollection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange);
				_userManager.audienceCollection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange);			
				_userManager.removeEventListener(UserEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
			}
			
			if ( _hostList ) {
				_hostList.removeEventListener(ListEvent.ITEM_CLICK, onRosterItemClick);
			}
			
			if ( _participantList ) {
				_participantList.removeEventListener(ListEvent.ITEM_CLICK, onRosterItemClick);
			}
			
			
			if ( _audienceList ) {
				_audienceList.removeEventListener(ListEvent.ITEM_CLICK, onRosterItemClick);
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
			if ( !_userManager ) {
				_userManager = _connectSession.userManager;
				// Update your local view when someone else changes someone's status in the roster.
				_userManager.hostCollection.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange);
				_userManager.participantCollection.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange);
				_userManager.audienceCollection.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange);			
				_userManager.addEventListener(UserEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
			}
			
			
		}
		
		/**
		 * @private
		 */
		override protected function createChildren():void
		{
			super.createChildren();
			
			if ( !_subscribed ) {
				
				subscribe();
				_subscribed = true ;
			}
			
			
			if(!_hostList) {
				_hostList = new RosterTileList();
				_hostList.itemRenderer = new ClassFactory(UserItemRenderer);
				_hostList.roleText = _lm.getString("HOSTS");
				_hostList.dataProvider = _userManager.hostCollection;
				_hostList.rowHeight = 41;
				_hostList.columnWidth = COLUMN_WIDTH;
				addChild(_hostList);
			}
			
			_hostList.addEventListener(ListEvent.ITEM_CLICK, onRosterItemClick);
			
			
			if(!_participantList) {
				_participantList = new RosterTileList();
				_participantList.itemRenderer = new ClassFactory(UserItemRenderer);
				_participantList.dataProvider = _userManager.participantCollection ;
				_participantList.roleText = _lm.getString("PARTICIPANTS");
				_participantList.rowHeight = 41;
				_participantList.columnWidth = COLUMN_WIDTH;
				addChild(_participantList);
			}
			
			_participantList.addEventListener(ListEvent.ITEM_CLICK, onRosterItemClick);
			
			if(!_audienceList) {
				_audienceList = new RosterTileList();
				_audienceList.itemRenderer = new ClassFactory(UserItemRenderer);
				_audienceList.roleText = _lm.getString("AUDIENCE");
				_audienceList.dataProvider = _userManager.audienceCollection ;
				_audienceList.rowHeight = 41;
				_audienceList.columnWidth = COLUMN_WIDTH;
				addChild(_audienceList);
			}
			
			_audienceList.addEventListener(ListEvent.ITEM_CLICK, onRosterItemClick);
			
			updateListVisibility();
		}

		
		
		/**
		 * @private
		 */		
		protected function onSyncChange(p_evt:UserEvent):void
		{
			_hostList.selectable = _participantList.selectable = _audienceList.selectable = _userManager.isSynchronized;
			hideMenu() ;
			
			dispatchEvent(p_evt);
		}
		
		/**
		 * @private
		 */
		public function hideMenu():void
		{
			if (_currentMenu) {
				_currentMenu.hide();
			}
		}
		
		/**
		 * @private
		 */
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			if ( !_subscribed ) {
				return ;
			}
			
			var runningWidth:Number = 0;
			var listArray:Array = new Array();
			if (_hostList.visible) {
				_hostList.invalidateSize();
				_hostList.validateNow();
				_hostList.setActualSize(_hostList.measuredWidth, h);
				runningWidth += _hostList.measuredWidth + DIVIDER_WIDTH;
				listArray.push(_hostList);
			}
			if (_participantList.visible) {
				_participantList.invalidateSize();
				_participantList.validateNow();
				_participantList.setActualSize(_participantList.measuredWidth, h);
				runningWidth += _participantList.measuredWidth + DIVIDER_WIDTH;
				listArray.push(_participantList);
			}
			if (_audienceList.visible) {
				_audienceList.invalidateSize();
				_audienceList.validateNow();
				_audienceList.setActualSize(_audienceList.measuredWidth, h);
				runningWidth += _audienceList.measuredWidth;
				listArray.push(_audienceList);
			}


			// overflowing?
			if (runningWidth>w && w > 0) {
				// since we're overflowing, let's take the biggest lists and squeeze some space out of them
				var overflow:Number = runningWidth-w;
				listArray.sortOn(["measuredWidth"], [Array.NUMERIC]);
				
				/*while (overflow>0) {
					var nextBiggestList:RosterTileList = listArray.pop() as RosterTileList;
					if (nextBiggestList) {
						var oldWidth:Number = nextBiggestList.width;
						nextBiggestList.setActualSize(Math.max(MIN_LIST_WIDTH, nextBiggestList.width-overflow), h);
						overflow -= (oldWidth - nextBiggestList.width);
					} else {
						break;
					}
				}*/
				
				var nextBiggestList:RosterTileList
				if ( listArray.length >= 1 ) {
					if ( listArray.length == 1 ) {
						nextBiggestList = listArray.pop() as RosterTileList;
						if (nextBiggestList) {
							nextBiggestList.setActualSize(w, h);
							nextBiggestList.validateNow();
						}
					}else if ( listArray.length == 2 ) {
						nextBiggestList = listArray.pop() as RosterTileList;
						var nextBiggestListWidthFactor:Number = (nextBiggestList.measuredWidth/runningWidth);
						var newWidth:Number = Math.max(MIN_LIST_WIDTH, (w*nextBiggestListWidthFactor)) - DIVIDER_WIDTH; 
						if (nextBiggestList) {
							nextBiggestList.setActualSize(newWidth, h);
							nextBiggestList.validateNow();
						}
						nextBiggestList = listArray.pop() as RosterTileList;
						if (nextBiggestList) {
							nextBiggestList.setActualSize(Math.max(MIN_LIST_WIDTH, w-newWidth ), h);
							nextBiggestList.validateNow();
						}
					}else if ( listArray.length == 3 ) {
						nextBiggestList = listArray.pop() as RosterTileList;
						var newBiggestListWidthFactor:Number = (nextBiggestList.measuredWidth/runningWidth);
						var newBiggestWidth:Number = Math.max(MIN_LIST_WIDTH, w*newBiggestListWidthFactor) - DIVIDER_WIDTH;
						if (nextBiggestList) {
							nextBiggestList.setActualSize(newBiggestWidth, h);
							nextBiggestList.validateNow();
						}
						nextBiggestList = listArray.pop() as RosterTileList;
						newBiggestListWidthFactor = (nextBiggestList.measuredWidth/runningWidth);
						newBiggestWidth += Math.max(MIN_LIST_WIDTH, w*newBiggestListWidthFactor);
						if (nextBiggestList) {
							nextBiggestList.setActualSize(Math.max(MIN_LIST_WIDTH, Math.max(MIN_LIST_WIDTH, w*newBiggestListWidthFactor)) -DIVIDER_WIDTH, h);
							nextBiggestList.validateNow();
						}
						nextBiggestList = listArray.pop() as RosterTileList;
						newBiggestListWidthFactor = (nextBiggestList.measuredWidth/runningWidth);
						newBiggestWidth += Math.max(MIN_LIST_WIDTH, w*newBiggestListWidthFactor);
						if (nextBiggestList) {
							nextBiggestList.setActualSize(Math.max(MIN_LIST_WIDTH, Math.max(MIN_LIST_WIDTH, w*newBiggestListWidthFactor)), h);
							nextBiggestList.validateNow();
						}
					}
				}
				
			}
			
			var runningX:Number = 0;
			
			if (_hostList.visible) {
				_hostList.move(runningX, 0);
				runningX += _hostList.width + DIVIDER_WIDTH;
			}
			if (_participantList.visible) {
				_participantList.move(runningX, 0);
				runningX += _participantList.width + DIVIDER_WIDTH;
			}
			if (_audienceList.visible) {
				_audienceList.move(runningX, 0);
				runningX += _audienceList.width + DIVIDER_WIDTH;
			}
			
			// Draw dividers between lists
			graphics.clear();
			if(_hostList.visible && (_participantList.visible || _audienceList.visible)) {
				drawDivider(_hostList.x + _hostList.width, h);
			}
			if(_participantList.visible && _audienceList.visible) {
				drawDivider(_participantList.x + _participantList.width, h);
			}
		}
		
		/**
		 * @private
		 * 
		 * @param p_x The x-coordinate of the upper-left corner (gutter) of the divider.
		 */
		protected function drawDivider(p_x:Number, p_height:Number):void
		{
			var rotationMatrix:Matrix = new Matrix();
			rotationMatrix.createGradientBox(unscaledWidth, unscaledHeight, Math.PI/2);
			var gutterColorsArray:Array;
			var gutterAlphasArray:Array;
			var borderColorsArray:Array;
			var borderAlphasArray:Array;
			
			if (!getStyle("gutterColors") && !getStyle("gutterAlphas")) {
				 gutterColorsArray = [0x686868, 0x242424];
				 gutterAlphasArray = [1, 1];
			} else {
				gutterColorsArray = getStyle("gutterColors");
				gutterAlphasArray = getStyle("gutterAlphas");
			}
			
			if (getStyle("borderColors") && getStyle("borderAlphas")) {
				borderColorsArray = getStyle("borderColors");
				borderAlphasArray = getStyle("borderAlphas");
			} else {
				borderColorsArray = [0x9d9d9d, 0x686868];
				borderAlphasArray = [1, 1];
			}

			graphics.beginGradientFill(GradientType.LINEAR, gutterColorsArray, gutterAlphasArray, [0,255], rotationMatrix);
			graphics.drawRect(p_x, 0, 1, p_height);
			graphics.endFill();
			
			
			graphics.beginGradientFill(GradientType.LINEAR, borderColorsArray, borderAlphasArray, [0,255], rotationMatrix);
			graphics.drawRect(p_x + 1, 0, 1, p_height);
			graphics.endFill();
		}
		
		/**
		 * @private
		 */
		protected function updateListVisibility():void
		{			
			_hostList.visible = (_userManager.hostCollection.length!=0);
			_participantList.visible = (_userManager.participantCollection.length!=0);
			_audienceList.visible = (_userManager.audienceCollection.length!=0);			
			invalidateSize();
			invalidateDisplayList();
		}
		
		/**
		 * @private
		 */
		protected function onCollectionChange(p_event:CollectionEvent):void
		{
			updateListVisibility();
		}
		
		/**
		 * @private
		 */
		override protected function measure():void
		{
			super.measure();
			var m:uint = 0;
			var min:uint = 0;
			if (_hostList.visible) {
				m+=Math.max(MIN_LIST_WIDTH, _hostList.measuredWidth);
				min+=MIN_LIST_WIDTH;
			}
			if (_participantList.visible) {
				m+=Math.max(MIN_LIST_WIDTH, _participantList.measuredWidth);
				min+=MIN_LIST_WIDTH;
			}
			if (_audienceList.visible) {
				m+=Math.max(MIN_LIST_WIDTH, _audienceList.measuredWidth);
				min+=MIN_LIST_WIDTH;
			}
			measuredWidth = m;			
			measuredMinWidth = min;
		}
		
		/**
		 * @private
		 */
		protected function onRosterItemClick(p_event:ListEvent):void
		{
			
			if (p_event.itemRenderer.data==null || !_userManager.isSynchronized) {
				return;
			}

			_itemLastClicked = p_event.itemRenderer;
			_itemLastTarget = (p_event.target as RosterTileList);
			
			if (_useExternalMenuData) {
				dispatchEvent(new Event("userItemClick"));
				return;
			} else {
				var menuData:ArrayCollection = new ArrayCollection();				
				// Build the menu content depending on who you are and who you're clicking.				
				var userDescriptor:UserDescriptor = _itemLastClicked.data as UserDescriptor;

				if (_userManager.myUserAffiliation == UserRoles.OWNER && userDescriptor.userID == _userManager.myUserID) {
					addRoleChange(menuData);
				}
				
				if (_userManager.getUserRole(_userManager.myUserID) == UserRoles.OWNER && userDescriptor.userID != _userManager.myUserID) {
					addRoleChange(menuData);
					menuData.addItem({label:_lm.getString("Remove user"), kind:MENU_REMOVE_USER});
				}
				
				showMenu();
			}
		}
		
		/**
		 * Causes a menu to appear using the custom <code>menuData</code>. It should be used
		 * with <code>useExternalMenuData=true</code>.
		 */
		public function showMenu():void
		{
			// Draw a CustomMenu above the clicked renderer.
			if (_currentMenu) {
				_currentMenu.removeEventListener(MenuEvent.ITEM_CLICK, onMenuItemClick);
				_currentMenu.removeEventListener(MenuEvent.MENU_HIDE, onMenuHide);
			}
			_currentMenu = CustomMenu.createCustomMenu(null, _menuData);
			_currentMenu.dataTipField = "notHere!";
			_currentMenu.rowHeight = 22;	// TODO: find some way to un-hard-code this
			_currentMenu.iconField = "icon";
			_currentMenu.addEventListener(MenuEvent.ITEM_CLICK, onMenuItemClick);
			_currentMenu.addEventListener(MenuEvent.MENU_HIDE, onMenuHide);
			var localPoint:Point = new Point(_itemLastClicked.x, _itemLastClicked.y);
			var globalPoint:Point = _itemLastTarget.localToGlobal(localPoint);
						
			if( (globalPoint.y - _currentMenu.rowHeight * _menuData.length - 15) < 0 )
			{
				_currentMenu.slideDirection = CustomMenu.SLIDE_DOWN;	
				globalPoint.y +=  _itemLastClicked.height;			
			}
			else
			{
				_currentMenu.slideDirection = CustomMenu.SLIDE_UP;
				globalPoint.y -=  (_currentMenu.rowHeight * _menuData.length + 15);
			}		
			//Add to the displaylist so we camn measure, and place accordingly on the stage
			this.addChild(_currentMenu);
			_currentMenu.validateNow();
			_currentMenu.validateSize(true);
			var menuWidth:Number = _currentMenu.measuredWidth;
			removeChild(_currentMenu);
			
			if((menuWidth + globalPoint.x) > stage.stageWidth)
			{				
				globalPoint.x = stage.stageWidth - menuWidth;								 
			}
				
			_currentMenu.show(globalPoint.x, globalPoint.y ); // this too						
		}
		
		// Helper functions

		/**
		 * @private
		 */		
		protected function addRoleChange(p_menuData:Object):void {
			p_menuData.addItem({label: _lm.getString("Role"), children: [
					{label: _lm.getString("Host"), icon: HostIconClass, kind:MENU_ROLE_OWNER},
					{label: _lm.getString("Participant"), icon: ParticipantIconClass, kind:MENU_ROLE_PUBLISHER},
					{label: _lm.getString("Audience"), icon: AudienceIconClass, kind:MENU_ROLE_VIEWER}
				]});
		}	
								
		/**
		 * @private
		 */		
		protected function onMenuHide(p_evt:MenuEvent):void
		{
			if (p_evt.menu==_currentMenu) {
				clearAllSelection();
			}
		}
		
		/**
		 * @private
		 */		
		protected function onMenuItemClick(p_evt:MenuEvent):void
		{
			if (_useExternalMenuData) {
				dispatchEvent(p_evt);
			} else {
				switch(p_evt.item["kind"]) {
					case MENU_ROLE_OWNER:
						changeSelectedUserRole(UserRoles.OWNER);
						break;
					case MENU_ROLE_PUBLISHER:
						changeSelectedUserRole(UserRoles.PUBLISHER);
						break;
					case MENU_ROLE_VIEWER:
						changeSelectedUserRole(UserRoles.VIEWER);
						break;
					case MENU_REMOVE_USER:
						var userDesc:UserDescriptor = _itemLastClicked.data as UserDescriptor;
						_userManager.removeUser(userDesc.userID);
						break;
				}
			}
		}
		
		
		/**
		 * @private
		 */		
		protected function clearAllSelection():void
		{
			if (_hostList) {
				_hostList.selectedIndex = -1;
			}
			if (_participantList) {
				_participantList.selectedIndex = -1;
			}
			if (_audienceList) {
				_audienceList.selectedIndex = -1;
			}
		}		
		
		/**
		 * @private
		 */		
		protected function changeSelectedUserRole(p_role:int):void
		{
			var userDesc:UserDescriptor = _itemLastClicked.data as UserDescriptor;
			_userManager.setUserRole(userDesc.userID, p_role);
			
			invalidateDisplayList();
		}
		
		
		/**
		 *  Sets the role of a given user for the room as a whole; it is equivalent to <code>UserManager.setUserRole()</code>.
		 * 
		 * @param p_userRole The role value to set on the specified user.
		 * @param p_userID The ID of the user whose role should be set.
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
				throw new Error("HorizontalRoster: USerId can't be null");
			}
			
			return _userManager.getUserRole(p_userID);
		}
		
	}
}
