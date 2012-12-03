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
package com.adobe.rtc.util
{
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.RoomSettings;
	import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
	import com.adobe.rtc.sharedManagers.FileManager;
	import com.adobe.rtc.sharedManagers.RoomManager;
	import com.adobe.rtc.sharedManagers.StreamManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	// FLeX Begin
	import mx.controls.Alert;
	// FLeX End
	import mx.core.UIComponent;
	// FLeX Begin
	import mx.events.CloseEvent;
	// FLeX End
	
	/**
	 * Dispatched when the component either loses its connection to the session or regains it
	 * and has finished re-synchronizing itself to the rest of the room.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	

	/**
	 * RoomCleaner is a simple utility class primarily used during development 
	 * in order to restore a room to its pristine state. It resets all RoomManager 
	 * settings and deletes any CollectionNodes in the room other than the sharedManagers' 
	 * CollectionNodes (which are required). It thereby effectively wipes any data 
	 * stored in the room. RoomCleaner also pops up a dialog asking for confirmation 
	 * before proceeding. Note that only users with an owner role can clean up a room.
	 * 
	 * @see LCCS Developer Guide
	 * @see com.adobe.rtc.sharedModel.CollectionNode
	 */
   public class  RoomCleaner extends UIComponent implements ISessionSubscriber
	{
		/**
		 * @private
		 */
		protected var _rootNode:RootCollectionNode;
		/**
		 * @private
		 */
		protected var _collectionNames:Object = new Object();
		
		/**
		 * @private
		 */
		protected var _collectionsToKeep:Object = new Object();
		/**
		 * @private
		 */
		protected var _lastCollectionName:String;
		/**
		 * @private
		 */
		protected var _autoClean:Boolean = true;
		/**
		 * @private
		 */
		protected var _pendingClean:Boolean = false;
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
		  * @private 
		  */	
		 protected var _roomManager:RoomManager ;
		
		/**
		 * @private
		 */
		public function set autoClean(p_auto:Boolean):void
		{
			_autoClean = p_auto;
		}
		
		/**
		 * Determines whether the component should automatically begin cleaning the room 
		 * (true) or whether it should wait until <code>clean()</code> is explicitly 
		 * called (false).
		 * 
		 * @default true
		 */
		public function get autoClean():Boolean
		{
			return _autoClean;
		}
		/**
		 * The <code>sharedID</code> is the ID of the class.
		 * 
		  * @param p_id The shared class ID.
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
		 *
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
		 * Returns true if the model is synchronized.
		 */
		public function get isSynchronized():Boolean
		{
			if ( !_rootNode ) {
				return false ;
			}
			
			return _rootNode.isSynchronized ;
		}
		
		
		public function close():void
		{
			if ( _rootNode ) {
				_rootNode.removeEventListener(CollectionNodeEvent.NODE_CREATE, onCollectionCreate);
				_rootNode.removeEventListener(CollectionNodeEvent.NODE_DELETE, onCollectionDelete);
				_rootNode.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
				_rootNode.unsubscribe();
			}
		}
		
		/**
		 * Initiates a subscription. 
		 */
		public function subscribe():void
		{
			if ( !_roomManager ) {
				_roomManager = _connectSession.roomManager ;
			}
			
			_collectionsToKeep[UserManager.COLLECTION_NAME] = true;
			_collectionsToKeep[RoomManager.COLLECTION_NAME] = true;
			_collectionsToKeep[StreamManager.COLLECTION_NAME] = true;
			_collectionsToKeep[FileManager.COLLECTION_NAME] = true;
			
			_rootNode = new RootCollectionNode();
			_rootNode.connectSession = _connectSession;
			_rootNode.addEventListener(CollectionNodeEvent.NODE_CREATE, onCollectionCreate);
			_rootNode.addEventListener(CollectionNodeEvent.NODE_DELETE, onCollectionDelete);
			_rootNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
			_rootNode.subscribe();
		}
		
		/**
		 * Begins actually cleaning the room and opens a dialog box to asking the user to confirm the action.
		 */
		public function clean():void
		{
			_pendingClean = true;
			if (_rootNode.isSynchronized) {
				// emulate a synch
				onSyncChange();
			} else {
				// assume a synch is going to happen sooner or later.
			}
		}
		
		// FLeX Begin
		/**
		 * @private
		 */
		override protected function createChildren():void
		{
			if ( !_subscribed ) {
				subscribe();
				_subscribed = true ;
			}
		}
		// FLeX End
		
		/**
		 * @private
		 */
		protected function onCollectionCreate(p_evt:CollectionNodeEvent):void
		{
			if (_collectionsToKeep[p_evt.nodeName]!=true) {
				_collectionNames[p_evt.nodeName] = true;
			}
		}
		
		/**
		 * @private
		 */
		protected function onSyncChange(p_evt:CollectionNodeEvent=null):void
		{
			if (_rootNode.isSynchronized && (autoClean || _pendingClean)) {
				_pendingClean = false;
				// begin deleting the content!
				// FLeX Begin
				Alert.show("RoomCleaner will now reset your room to its original state. All stored data will be deleted. Proceed?",
							"Confirm House Keeping", 3, null, onAlertClick);
				// FLeX End
				
			}
		}
		
		// FLeX Begin
		/**
		 * @private
		 */
		protected function onAlertClick(p_evt:CloseEvent):void
		{
			if (p_evt.detail==Alert.YES) {
				var roomMgr:RoomManager = _roomManager;
				// first, reset the Room Management options to default
				roomMgr.autoPromote = false;
				roomMgr.endMeetingMessage = "";
				roomMgr.roomState = RoomSettings.ROOM_STATE_ACTIVE;
				roomMgr.selectedBandwidth = RoomSettings.AUTO;
				roomMgr.guestsHaveToKnock = false;
				// now, just delete all extra collectionNodes
				for (var collectionName:String in _collectionNames) {
					_rootNode.removeNode(collectionName);
				}
				_lastCollectionName = collectionName;
			} else {
				// no-op
			}
		}
		// FLeX End
		
		/**
		 * @private
		 */
		protected function onCollectionDelete(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName==_lastCollectionName) {
				// we're done
				// FLeX Begin
				Alert.show("Your Room has been reset to its default state successfully", "HouseKeeping Complete", Alert.OK);
				// FLeX End
			}
		}
		
	}
}