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
package com.adobe.rtc.sharedModel
{
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.SharedPropertyEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.util.DebugUtil;
	import com.adobe.rtc.util.Invalidator;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	

	/**
	 * Dispatched when the <code>SharedProperty</code> goes in and out of sync.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	

	/**
	 * Dispatched when the user's role with respect to this <code>SharedProperty</code> changes.
	 */
	[Event(name="myRoleChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	

	/**
	 * Dispatched when the value of the property is changed: it is subject to round
	 * tripping to the service. 
	 */
	[Event(name="change", type="com.adobe.rtc.events.SharedPropertyEvent")]
	

	/**
	 * <code>SharedProperty</code> is a model (and ui-less component) that manages a 
	 * variable of any type and which is shared amongst all users connected to the room.
	 * <p>
	 * Note that this component supports "piggybacking" on existing CollectionNodes 
	 * through its constructor. Developers can avoid CollectionNode proliferation in 
	 * their applications by pre-supplying a CollectionNode and a <code>nodeName</code> 
	 * for the <code>SharedProperty</code> to use. If none is supplied, the SharedProperty 
	 * will create its own <code>collectionNode</code> for sending and receiving messages.
	 * 
	 * @see com.adobe.rtc.sharedModel.CollectionNode
	 */
   public class  SharedProperty extends EventDispatcher implements ISessionSubscriber
	{

		/**
		 * @private
		 */
		protected var _collectionNode:CollectionNode;
		
		/**
		 * @private
		 */
		protected var userManager:UserManager;

		/**
		 * @private
		 */
		protected var _value:*;

		/**
		 * @private
		 */
		protected var _cachedValueForSync:*;
		
		/**
		 * @private
		 */
		protected var _sharedID:String = "_SharedProperty";
		
		/**
		 * @private
		 */
		protected var _nodeNameText:String = "value";
		
		/**
		 * @private
		 */
		protected var _sendDataTimer:Timer;
		
		/**
		 * @private
		 */
		protected var _cachedValueForSending:*;

		/**
		 * @private
		 */
		protected var _itemReceived:Boolean = false;
		
		/**
		 * @private
		 */
		protected var _isClearAfterSessionRemoved:Boolean = false;
		/**
		 * @private
		 */
		protected var _accessModel:int = -1 ;
		/**
		 * @private
		 */
		 protected var _tempAccessModel:int = -1 ;
		/**
		 * @private
		 */
		protected var _publishModel:int = -1 ;
		/**
		 * @private
		 */
		 protected var _tempPublishModel:int = -1 ;
		/**
		 * @private
		 */
		 protected const invalidator:Invalidator = new Invalidator();
		 
		/**
		 * @private 
		 */		
		protected var _connectSession:IConnectSession = ConnectSession.primarySession;
		/**
		 * @private
		 */
		 protected var _updateInterval:uint = 0 ;
		
		/**
		 * Constructor.
		 * 
		 * @param p_id A unique ID.
		 * @param p_collectionNode If you'd like to "bring your own" collection node, pass it here.
		 * @param p_nodeNameValue If you'd like to specify the node name to use for the value, pass it here.
		 * @param p_sessionDependent Whether the property should be cleared when the session ends. Defaults to false
		 * which means that it will not be cleared.
		 */
		public function SharedProperty():void
		{
		
			_sendDataTimer = new Timer(300, 1);
			_sendDataTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);
			
			invalidator.addEventListener(Invalidator.INVALIDATION_COMPLETE,commitProperties);
		}
		
		
		/**
		 * Sets the Collection Node to which the shared property subscribes/publishes
		 * @param p_collectionNode the CollectionNode
		 */
		public function set collectionNode(p_collectionNode:CollectionNode ):void
		{
			if ( p_collectionNode != null ) {
				_collectionNode = p_collectionNode ;
			}
		}
		
		
		/**
		 * @private
		 */
		public function get collectionNode():CollectionNode
		{
			return _collectionNode ;
		}
		
		/**
		 * Sets the Node Name to which the value is published
		 * @param p_nodeName The name of the node
		 */
		public function set nodeName(p_nodeNameValue:String):void
		{
			if ( p_nodeNameValue != null ) {
				_nodeNameText = p_nodeNameValue ;
			}
		}
		
		/**
		 * @private
		 */
		public function get nodeName():String
		{
			return _nodeNameText ;
		}
		
		/**
		 * Sets true or false whether the it should depend on the session, default is false
		 * @param p_sessionDependent 
		 */
		public function set isSessionDependent(p_sessionDependent:Boolean ):void
		{
			_isClearAfterSessionRemoved = p_sessionDependent ;
		}
		
		/**
		 * @private
		 */
		public function get isSessionDependent():Boolean
		{
			return _isClearAfterSessionRemoved ;
		}
		
		
		/**
		 * Sets the update Interval(in milliseconds) , defaults to 0. 
		 * The Messages will get transmitted after that interval everytime if it is set.
		 */
		public function get updateInterval():uint
		{
			return _updateInterval ;
		}
		
		/**
		 * @private
		 */
		public function set updateInterval(p_updateInterval:uint):void
		{
			if ( p_updateInterval == _updateInterval ) {
				return ;
			}	
			
			_updateInterval = p_updateInterval ;
		}
		
		
		/**
		 * Cleans up all networking and event handling; it is recommended for garbage collection.
		 */
		public function close():void
		{
			//we were removed from the display list, clean everything up
			
			//remove all listeners (do a search for addEventListener, copy and paste here, then replace all "add"s with "remove"s

			//call .unsubscribe() on all collectionNodes you have

			//call .destroy() on all children models

			//null-ify all references to other classes and Objects (no need to nullify ints, Bools, etc)
			//	I find it easy to copy and paste all the variable declarations from the top here to help me do this
			
			_collectionNode.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);	
			_collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.removeEventListener(CollectionNodeEvent.MY_ROLE_CHANGE, onMyRoleChange);			
			_collectionNode.unsubscribe();
			_collectionNode = null;

			_sendDataTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);
			_sendDataTimer.stop();

			userManager = null;
		}
		
		
		/**
		 * Tells the component to begin synchronizing with the service.  
		 * For "headless" components such as this one, this method must be called explicitly.
		 */
		public function subscribe():void
		{
			userManager = _connectSession.userManager;
			
			if (_collectionNode == null) {			
				_collectionNode = new CollectionNode();
				_collectionNode.connectSession = connectSession ;
				_collectionNode.sharedID =  sharedID  ;
				_collectionNode.subscribe();
			} else {
				if (_collectionNode.isSynchronized) {
					onSynchronizationChange(new CollectionNodeEvent(CollectionNodeEvent.SYNCHRONIZATION_CHANGE));
				}
			}
			_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);	
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.addEventListener(CollectionNodeEvent.MY_ROLE_CHANGE, onMyRoleChange);
		}
		
		
		/**
		 * Defines the logical location of the component on the service - typically this assigns the sharedID of the collectionNode
		 * used by the component. sharedIDs should be unique within a room (if they're expressing 2 unique locations). Note that
		 * this can only be assigned once (before <code>subscribe()</code> is called). For components with an <code class="property">id</code> property, 
		 * sharedID defaults to that value.
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
		 * The IConnectSession with which this component is associated. Note that this may only be set once before <code>subscribe</code>
		 * is called; re-sessioning of components is not supported. Defaults to the first IConnectSession created in the application.
		 */
		public function get connectSession():IConnectSession
		{
			return _connectSession;
		}
		
		public function set connectSession(p_session:IConnectSession):void
		{
			_connectSession = p_session;
		}
		
		
		/**
		 * @private
		 */
		//[Bindable(event="change")]
		public function get value():*
		{
			return _value;
		}
		
		/**
		 * The value of the SharedProperty which users can only set if <code>canUserEdit
		 * </code> is true. If the SharedProperty is not yet synchronized, the value will 
		 * be cached and sent when the SharedProperty is back in sync.
		 * 
		 * @param p_value 
		 */
		public function set value(p_value:*):void
		{
			if (p_value == value) {	//no need to set it again
				return;
			}
			
			if (_collectionNode.isSynchronized) {
				_cachedValueForSending = p_value;
				
				if ( updateInterval != 0 ) {
					_sendDataTimer.delay = updateInterval ;
					_sendDataTimer.reset();
					_sendDataTimer.start();
				}else {
					onTimerComplete();
				}
			} else {
				_cachedValueForSync = p_value;
			}
		}
		
		/**
		 * Returns value as a Boolean.
		 */
		public function getAsBoolean():Boolean
		{
			return (value==null) ? false : (value as Boolean);
		}
		
		/**
		 * Returns value as a Number.
		 */
		public function getAsNumber():Number
		{
			return (value==null) ? 0 : (value as Number);
		}
		
		/**
		 * Returns value as a String.
		 */
		public function getAsString():String
		{
			return (value==null) ? "" : (value as String);
		}
		

		
		//[Bindable(event="synchronizationChange")]
		/**
		 * Determines whether the SharedProperty is connected and fully synchronized with the service.
		 */
		public function get isSynchronized():Boolean
		{
			return _collectionNode.isSynchronized;
		}

		/**
		 * Determines whether the current user can edit the property.
		 */
		public function get canIEdit():Boolean
		{
			return canUserEdit(userManager.myUserID);
		}
		
		/**
		 * Determines whether the specified user can edit the property.
		 * 
		 * @param p_userID The user to query regarding whether they can edit. 
		 */
		public function canUserEdit(p_userID:String):Boolean
		{
			return (_collectionNode.canUserPublish(p_userID,_nodeNameText));
		}
		
		/**
		 * Allows the current user with an owner role to grant the specified user 
		 * the ability to edit the property. 
		 * 
		 * @param p_userID The userID of the user being granted editing privileges.
		 * 
		 */
		public function allowUserToEdit(p_userID:String):void
		{
			// If I can't configure, cancel.
			if(!_collectionNode.canUserConfigure(userManager.myUserID,_nodeNameText)){
				return;
			}
			
			_collectionNode.setUserRole(p_userID, UserRoles.PUBLISHER, _nodeNameText);
		}
		
		
		/**
		 * Gets the NodeConfiguration of the SharedProperty Node. 
		 */
		public function getNodeConfiguration():NodeConfiguration
		{	
			return _collectionNode.getNodeConfiguration(_nodeNameText).clone();
		}
		
		/**
		 * Sets the NodeConfiguration on the SharedProperty node.
		 * @param p_nodeConfiguration The node Configuration of the shared property node to be set.
		 * 
		 */
		public function setNodeConfiguration(p_nodeConfiguration:NodeConfiguration):void
		{	
			_collectionNode.setNodeConfiguration(_nodeNameText,p_nodeConfiguration);
			
		}
		
			/**
		 * @private
		 */
		public function set publishModel(p_publishModel:int):void
		{	
			if ( p_publishModel < 0 || p_publishModel > 100 ) 
				return ; 
				
			if ( _collectionNode.isSynchronized ) {
				_publishModel = p_publishModel ;
				invalidator.invalidate();
			} else {
				_tempPublishModel = p_publishModel ;
			}
			
		}
		
		/**
		 * Role Value required to publish on the property
		 */
		public function get publishModel():int
		{
			if ( _collectionNode.isNodeDefined(_nodeNameText) ) {
				return _collectionNode.getNodeConfiguration(_nodeNameText).publishModel;
			}
			
			return -1 ;
		}
		
		/**
		 * @private
		 */
		public function set accessModel(p_accessModel:int):void
		{	
			if ( p_accessModel < 0 || p_accessModel > 100 ) 
				return ; 
			
			if ( _collectionNode.isSynchronized ) {
				_accessModel = p_accessModel ;
				invalidator.invalidate();
			} else {
				_tempAccessModel = p_accessModel ;
			}
			
		}
		
		/**
		 * Role value which is required for access the property
		 */
		public function get accessModel():int
		{
			// the access model remains always same for HISTORY_NODE_PARTICIPANTS and HISTORY_NODE_HOSTS..
			// any change is only for everyone and typing node, so we return that value
			
			if ( _collectionNode.isNodeDefined(_nodeNameText) ) {
				return _collectionNode.getNodeConfiguration(_nodeNameText).accessModel;
			}
			
			return -1 ;
		}
		
		
			
		/**
		 *  Returns the role of a given user for the property.
		 * 
		 * @param p_userID UserID of the user in question
		 */
		public function getUserRole(p_userID:String):int
		{
			return _collectionNode.getUserRole(p_userID);
		}
		
		/**
		 *  Sets the role of a given user for the property.
		 * 
		 * @param p_userID UserID of the user whose role we are setting
		 * @param p_userRole Role value we are setting
		 */
		public function setUserRole(p_userID:String ,p_userRole:int):void
		{
			if ( p_userID == null ) 
				return ;
				
			
			if ( (p_userRole < 0 || p_userRole > 100) && p_userRole != CollectionNode.NO_EXPLICIT_ROLE ) 
				return ; 
 
			
			_collectionNode.setUserRole(p_userID,p_userRole);
		}
		
		

		//this gets called AFTER all the itemReceiveHandlers
		/**
		 * @private
		 */
		protected function onSynchronizationChange(p_evt:Event):void
		{

			if (_collectionNode.isSynchronized) {
				if (!_collectionNode.isNodeDefined(_nodeNameText)) {	//we're the first ones there
					var nodeConf:NodeConfiguration = new NodeConfiguration();
					nodeConf.accessModel = UserRoles.VIEWER;
					nodeConf.publishModel = UserRoles.PUBLISHER;
					nodeConf.sessionDependentItems = _isClearAfterSessionRemoved;
					nodeConf.modifyAnyItem = true;
					_collectionNode.createNode(_nodeNameText, nodeConf);

					if (_cachedValueForSync) {
						if (_value == null) {					
							value = _cachedValueForSync;
							_cachedValueForSync = null;
						}
					} else {
						if (_value != null && !_itemReceived) {	//this happens on disconnect
							//this is if you never got an item, you still want to say "I'm ready!"
							_value = null;
							dispatchEvent(new SharedPropertyEvent(SharedPropertyEvent.CHANGE));
						}
					}
					
				}
				
				if ( _tempAccessModel != -1 || _tempPublishModel != -1) {
					if ( _tempAccessModel != -1 ) {
						_accessModel = _tempAccessModel ;
						_tempAccessModel = -1 ;
					}
				
					if ( _tempPublishModel != -1 ) {
						_publishModel = _tempPublishModel ;
						_tempPublishModel = -1 ;
					}
					
					invalidator.invalidate() ;
				}
				
			} else {
				//clear model
				_sendDataTimer.stop();
				//_value = null; cannot do this, we want the getter to still work!
				_cachedValueForSync = null;
				_cachedValueForSending = null;
				_itemReceived = false;
			}
			
			dispatchEvent(p_evt);
		}

		/**
		 * @private
		 */
		protected function onItemReceive(p_evt:CollectionNodeEvent):void
		{
			var theItem:MessageItem = p_evt.item;	
			
			switch (theItem.nodeName) {
				case _nodeNameText:
					_value = theItem.body;
					_itemReceived = true;
					_cachedValueForSync = null;
					
					var evt:SharedPropertyEvent = new SharedPropertyEvent(SharedPropertyEvent.CHANGE,p_evt.item.publisherID);
					evt.value = _value ;
					
					dispatchEvent(evt);
					break;
			}
		}
		
		/**
		 * @private
		 */
		protected function onMyRoleChange(p_evt:CollectionNodeEvent):void
		{
			//TODO: Peldi clean up my model if I have to?
			dispatchEvent(p_evt);
		}
		
		/**
		 * @private
		 */
		protected function onTimerComplete(p_evt:TimerEvent=null):void
		{
			//this gets triggered after the update interval in ms after the last set value call
			_collectionNode.publishItem(new MessageItem(_nodeNameText, _cachedValueForSending));
			_cachedValueForSending = null;
		}

		/**
		 * @private
		 */
		protected function myTrace(p_msg:String):void
		{
			DebugUtil.debugTrace("#SharedProperty "+_sharedID+"# "+p_msg);
		}	
		
		/**
		 * @private
		 */
		protected function commitProperties(p_evt:Event=null):void
        {	
        	var nodeConf:NodeConfiguration ;
			
			if ( _publishModel != -1 && _collectionNode.getNodeConfiguration(_nodeNameText).publishModel != _publishModel ){
				nodeConf = _collectionNode.getNodeConfiguration(_nodeNameText) ;
				nodeConf.publishModel = _publishModel ;
				_collectionNode.setNodeConfiguration(_nodeNameText,nodeConf );
			}
			
			if ( _accessModel != -1 && _collectionNode.getNodeConfiguration(_nodeNameText).accessModel != _accessModel ){
				nodeConf = _collectionNode.getNodeConfiguration(_nodeNameText) ;
				nodeConf.accessModel = _accessModel ;
				_collectionNode.setNodeConfiguration(_nodeNameText, nodeConf ) ;
			}
			
        }
	}
}
