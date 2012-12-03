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
	import com.adobe.rtc.events.SharedModelEvent;
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
	 * Dispatched when the component has fully connected and synchronized with 
	 * the service or when it loses the connection.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	
	
	/**
	 * Dispatched when the batonObject is given to someone or put down.
	 */
	[Event(name="batonHolderChange", type="com.adobe.rtc.events.SharedModelEvent")]
	
	/**
	 * BatonObject is a model class which provides a workflow between users for muliple resources. Essentially, it 
	 * tracks the "holder" of a given resource and provides APIs for grabbing, putting down, 
	 * and giving control to others. Users with an owner role always have the power to 
	 * grab the BatonObject, put it down, or give it to others regardless of who has the BatonObject. 
	 * Users with a publisher role must wait according to the <code class="property">grabbable</code> property:
	 * <ul>
	 * <li>If the BatonObject is set to <code>grabbable</code>, they may grab the resources in the BatonObject as soon 
	 * as it is available (since it will then have no controller).</li>
	 * <li>If the BatonObject is not <code>grabbable</code>, the owner must explicitly pass the resources in the BatonObject
	 * to someone else. 
	 * </ul>
	 * By default, a BatonObject will timeout in five seconds and be released. This timeout can be 
	 * adjusted in the constructor and extended during use of the resource in question using 
	 * <code>extendTimer</code>.
	 * <p>
	 * Note that users with an owner role may adjust the roles of other users relative to the 
	 * BatonObject using <code>allowUserToGrab</code> (which makes that user a publisher) and <code>
	 * allowUserToAdminister</code> (which makes that user an owner).
	 * </p>
	 * <p>
	 * This component also supports "piggybacking" on existing CollectionNodes through its constructor. 
	 * Developers can avoid CollectionNode proliferation in their applications by pre-supplying a 
	 * CollectionNode and a <code>nodeName</code> for the BatonObject to use. If none is supplied, the 
	 * BatonObject will create its own collection node for sending and receiving messages.
	 * 
	 * @see com.adobe.rtc.sharedModel.CollectionNode
	 * @see com.adobe.rtc.messaging.UserRoles
	 * @see com.adobe.rtc.sharedModel.Baton 
	 */	
	public class  BatonObject extends SharedObject implements ISessionSubscriber
	{
		/**
		 * @private
		 */
		protected var _batonNodeName:String = "holderIDs";
		/**
		 * @private
		 */
		protected var _holderID:Object;

		/**
		 * @private
		 */
		protected var _pubModelForControlling:int=UserRoles.PUBLISHER;
		/**
		 * @private
		 */
		protected var _pubModelForYanking:int=UserRoles.OWNER;
		/**
		 * @private
		 */
		protected var _autoReleaseTimers:Object;
		/**
		 * @private
		 */
		protected var _timeout:int = 0;	//in seconds
		/**
		 * @private
		 */
		protected var _cachedBatonHolderID:Object;
		/**
		 * @private
		 */
		protected var _userManager:UserManager;
		/**
		 * @private
		 */
		protected var _yankable:Boolean = true;
		/**
		 * @private
		 */
		protected var _grabbable:Boolean = true;
		/**
		 * @private
		 */
		protected var _accessModel:int = -1 ;
		/**
		 * @private
		 */
		protected var _publishModel:int = -1 ;
		/**
		 * @private
		 */
		protected const invalidator:Invalidator = new Invalidator();
		/**
		 * @private
		 */
		protected var _cachedValueForSetProp:Object;
		/**
		 * @private
		 */
		protected var _cachedValueForDeleteProp:Object;

		
		/**
		 * Constructor. 
		 * 
		 * @param p_id The unique identifier for this BatonObject. As a best practice, use the same ID 
		 * as the collaboration component that hosts it.
		 * @param p_timeOut Sets the auto-put-down timeout. Use 0 for no timeout.
		 * @param p_collectionNode If you'd like to "bring your own" collection node, pass it here.
		 * @param p_nodeName If you'd like to specify the node name to use for the BatonObject, pass it here.
		 */
		public function BatonObject()
		{
			super();
			_holderID = new Object();
			_cachedBatonHolderID = new Object();
			_autoReleaseTimers = new Object();
			_sharedID = sharedID = "_BatonObject";
			_cachedValueForSetProp = new Object();
			_cachedValueForDeleteProp = new Object();
			invalidator.addEventListener(Invalidator.INVALIDATION_COMPLETE,commitProperties);
		}
		
		
		
		/**
		 * Sets the Node Name to which the value is published
		 * @param p_nodeName The name of the node
		 */
		public function set batonNodeName(p_nodeNameValue:String):void
		{
			if ( p_nodeNameValue != null ) {
				_batonNodeName = p_nodeNameValue ;
			}
		}
		
		/**
		 * @private
		 */
		public function get batonNodeName():String
		{
			return _batonNodeName ;
		}
		
		/**
		 * Number of seconds after which the BatonObject times out
		 * If 0, no timeout is used. 
		 * @param p_timeOut Number of seconds until the resources in the BatonObject is released
		 * @param p_propertyName The id of the property 
		 */
		public function setTimeOut(p_timeOut:int,p_propertyName:String=null):void
		{
			if (p_propertyName) {
				createTimer(p_propertyName);
				_autoReleaseTimers[p_propertyName].delay = p_timeOut*1000 ;
			} else {
				if (_autoReleaseTimers) {
					for (var property:String in _autoReleaseTimers) {
						_autoReleaseTimers[property].delay = p_timeOut*1000 ;
					}
				}
				_timeout = p_timeOut;
			}
		}
		
		/**
		 * Number of seconds after which the BatonObject times out
		 * @param p_propertyName The id of the property
		 */
		public function getTimeOut(p_propertyName:String=null):int
		{
			if (p_propertyName) {
				return _autoReleaseTimers[p_propertyName].delay;
			} else {
				return _timeout;
			}
		}
		
		/**
		 * @private
		 */
		[Bindable]
		public function get grabbable():Boolean
		{
			return _grabbable;
		}
		
		/**
		 * Whether or not to allow users with a publisher role to grab an available resource in BatonObject.
		 * When false, the resources in BatonObject can only be handed off by users with an owner role.
		 */
		public function set grabbable(p_grabbable:Boolean):void
		{
			_grabbable = p_grabbable;
		}
		
		/**
		 * @private
		 */
		public function set publishModel(p_publishModel:int):void
		{	
			if ( p_publishModel < 0 || p_publishModel > 100 ) 
				return ; 
			
			_publishModel = p_publishModel ;
			invalidator.invalidate();
		}
		
		/**
		 * Role Value required to grab the BatonObject
		 */
		public function get publishModel():int
		{
			return _collectionNode.getNodeConfiguration(_batonNodeName).publishModel;
		}
		
		/**
		 * @private
		 */
		public function set accessModel(p_accessModel:int):void
		{	
			if ( p_accessModel < 0 || p_accessModel > 100 ) 
				return ; 
			
			_accessModel = p_accessModel ;
			invalidator.invalidate();
		}
		
		/**
		 * Role value which is required for seeing the BatonObject
		 */
		public function get accessModel():int
		{
			// the access model remains always same for HISTORY_NODE_PARTICIPANTS and HISTORY_NODE_HOSTS..
			// any change is only for everyone and typing node, so we return that value
			return _collectionNode.getNodeConfiguration(_batonNodeName).accessModel;
		}
		
		
		
		/**
		 *  Returns the role of a given user for the BatonObject.
		 * 
		 * @param p_userID UserID of the user in question
		 */
		override public function getUserRole(p_userID:String):int
		{
			return _collectionNode.getUserRole(p_userID,_batonNodeName);
		}
		
		/**
		 * Specifies the <code>userID</code> of the person controlling the the resource in the BatonObject. Returns null if 
		 * no one has the BatonObject. For example, this function might be used to create a "controlled 
		 * by XXX" tooltip for your component.
		 * @param p_propertyName The id of the property
		 */
		public function getHolderID(p_propertyName:String):String
		{
			//REVISIT
			return _holderID[p_propertyName];
		}
		
		
		/**
		 * Determines whether the current user has permission to administer the BatonObject 
		 * by taking it from someone or forcing them to put it down.
		 */
		public function get canIAdminister():Boolean
		{
			return canUserAdminister(_userManager.myUserID);
		}
		
		/**
		 * Determines whether a specified user can administer the BatonObject from others. 
		 * 
		 * @param p_userID The <code>userID</code> of the user to check if they have 
		 * adminstrator rights.
		 */		
		public function canUserAdminister(p_userID:String):Boolean
		{
			return(_yankable && _collectionNode.getUserRole(p_userID, _batonNodeName) >= _pubModelForYanking);
		}
		
		/**
		 * Determines whether the current user has permission to grab the BatonObject 
		 * when available.
		 */
		public function get canIGrab():Boolean
		{
			return canUserGrab(_userManager.myUserID);
		}
		
		/**
		 * Determines whether a specified user can grab the BatonObject if it's available.
		 * 
		 * @param p_userID  The <code>userID</code> of the user to check if they 
		 * can grab the BatonObject. 
		 */
		public function canUserGrab(p_userID:String):Boolean
		{
			return(_grabbable && _collectionNode.getUserRole(p_userID, _batonNodeName) >= _pubModelForControlling);
		}
		
		/**
		 * When called by an owner, <code>setUserRole()</code> sets the role of the specified 
		 * user with respect to this BatonObject. The following rules apply: 
		 * <ul>
		 * <li>Setting the role to <code>UserRoles.PUBLISHER</code> allows the user to grab the resources in the BatonObject. </li>
		 * <li>Setting the role to <code>UserRoles.OWNER</code> allows the user to administer the resources in the BatonObject.</li> 
		 * <li>Setting to <code>UserRoles.VIEWER</code> will allow neither.</li>
		 * </ul>
		 * 
		 * @param p_userID The <code>userID</code> of the user to set the role for. 
		 * @param p_role The new role for that user.  
		 */
		override public function setUserRole(p_userID:String ,p_userRole:int):void
		{
			if ( p_userID == null ) 
				return ;
			
			
			if ( (p_userRole < 0 || p_userRole > 100) && p_userRole != CollectionNode.NO_EXPLICIT_ROLE ) 
				return ; 
			
			_collectionNode.setUserRole(p_userID, p_userRole, _batonNodeName);
			super.setUserRole(p_userID, p_userRole);
		}
		
		
		/**
		 * Determines whether the current user is holding a resource in the BatonObject.
		 * @param p_propertyName The id of the property
		 */
		public function amIHolding(p_propertyName:String):Boolean
		{
			//REVISIT
			return (_holderID[p_propertyName] == _userManager.myUserID);
		}
		
		/**
		 * Determines whether the resource in the BatonObject is up for grabs because it has no current holder.
		 * @param p_propertyName The id of the property 
		 */
		public function isAvailable(p_propertyName:String):Boolean
		{
			//REVISIT
			return (_holderID[p_propertyName] == null) && _grabbable;
		}
		
		/**
		 * Cleans up all networking and event handling; recommended for garbage collection.
		 */
		override public function close():void
		{
			//we were removed from the display list, clean everything up
			_collectionNode.unsubscribe();
			_collectionNode = null;
			stopAllTimers();//REVISIT
			_userManager = null;
			super.close();
		}
		
		/**
		 * If grabbable, users with a publisher role can grab the control if it's available 
		 * by using this method. Users with an owner role may grab a resource in the BatonObject at any time.
		 * @param p_propertyName The id of the property 
		 */
		public function grab(p_propertyName:String):void
		{
			//REVISIT
			if (!canIAdminister) {
				// if I can Yank, don't worry about other
				if ( !isAvailable(p_propertyName) || !canIGrab) {
					return;
				}
			}
			
			if ( amIHolding(p_propertyName) ) {
				return;
			}
			
			createTimer(p_propertyName);
			if ( isSynchronized ) {
				//grab it
				_collectionNode.publishItem(new MessageItem(_batonNodeName, _userManager.myUserID, p_propertyName));
			} else {
				_cachedBatonHolderID[p_propertyName] = _userManager.myUserID;
			}
		}
		
		/**
		 * Users with an publisher role in control can use this method to 
		 * release their control. Users with an owner role  can use this method 
		 * to remove the BatonObject resource from a user who has it.
		 * @param p_propertyName The id of the property 
		 */
		public function putDown(p_propertyName:String):void
		{
			//REVISIT
			if ( isAvailable(p_propertyName) ) {
				return;
			}
			
			if (!canIAdminister && !amIHolding(p_propertyName)) {
				return;
			}			
			if ( isSynchronized ) {				
				//release it
				_collectionNode.retractItem(_batonNodeName,p_propertyName);
			} // else not in sync, doing nothing
		}
		
		/**
		 * If the BatonObject is grabbable, the holding user can hand the BatonObject's resource to a specified user. 
		 * A user with an owner role can give a BatonObject resource to anyone with the required permissions 
		 * at any time.
		 * 
		 * @param p_userID  The <code>userID</code> of the user to allow to grab the BatonObject.
		 * @param p_propertyName The id of the property   
		 */
		public function giveTo(p_userID:String,p_propertyName:String):void
		{
			//REVISIT
			if (!canIAdminister && (!_grabbable || !amIHolding(p_propertyName))) {
				return;
			}
			
			if ( isSynchronized ) {
				//give it to someone
				_collectionNode.publishItem(new MessageItem(_batonNodeName, p_userID, p_propertyName));
			} else {
				_cachedBatonHolderID[p_propertyName] = p_userID;
			}
		}
		
		/**
		 * Extends the timeout if the BatonObject has one.
		 * @param p_propertyName The id of the property  
		 */
		public function extendTimer(p_propertyName:String):void
		{
			//REVISIT
			if (_autoReleaseTimers[p_propertyName]) {
				if (_autoReleaseTimers[p_propertyName].running) {
					_autoReleaseTimers[p_propertyName].reset();
					_autoReleaseTimers[p_propertyName].start();
				}
			}
		}
		
		/**
		 * The value of the BatonObjects property which a user can only set it if the user is in 
		 * control of it.
		 * <p>
		 * If the BatonObject is not yet synchrnonized, the value will be cached and 
		 * sent when the BatonProperty is back in sync.
		 * <p>
		 * If the BatonObjects property is available, setting the value will also try to grab 
		 * control of the property before setting the value.
		 */
		override public function setProperty(p_propertyName:String, p_value:Object = null):void
		{
			if (isSynchronized) {
				if (isAvailable(p_propertyName)) {
					if (!_cachedValueForSetProp[p_propertyName]) {	//only toggle the first time
						grab(p_propertyName);
					}
					_cachedValueForSetProp[p_propertyName] = p_value; //overwrite the value that will eventually be published
				} else if (amIHolding(p_propertyName)){
					super.setProperty(p_propertyName,p_value);
					delete _cachedValueForSetProp[p_propertyName];
				}
			}
		}
		
		/**
		 * The value of the BatonObjects property which a user can only delete it if the user is in 
		 * control of it.
		 * <p>
		 * If the BatonObject is not yet synchrnonized, the value will be cached and 
		 * deleted when the BatonProperty is back in sync.
		 * <p>
		 * If the BatonObjects property is available, deleting the value will also try to grab 
		 * control of the property before deleting the value and then release the control as well.
		 */
		override public function removeProperty(p_propertyName:String):void
		{
			if (isAvailable(p_propertyName)) {
				if (!_cachedValueForDeleteProp[p_propertyName]) {	//only toggle the first time
					grab(p_propertyName);
				}
				_cachedValueForDeleteProp[p_propertyName] = "someRandomValue"; //overwrite the value that will eventually be published
			} else if (amIHolding(p_propertyName)){
				//putDown(p_propertyName);
				super.removeProperty(p_propertyName);
				//delete _cachedValueForDeleteProp [p_propertyName];
			}
		}
		
		/**
		 * Calls the <code>removeProperty</code> for all the properties in the BatonObject. It would delete all the properties that are
		 * avialable or properties that you are holding.
		 */
		override public function removeAll():void
		{
			for (var propertyName:String in _sharedObject) {
				removeProperty(propertyName);
			}
		}
		
		/**
		 * @private
		 */
		protected function onTimerComplete(p_evt:TimerEvent):void
		{
			//REVISIT
			for (var i:String  in _autoReleaseTimers) {
				if (_autoReleaseTimers[i] == p_evt.currentTarget) {
					_collectionNode.retractItem(_batonNodeName,i);
					break;
				}
			}
		}
		
		/**
		 * @private
		 */
		override protected function onSyncChange(p_evt:CollectionNodeEvent):void
		{
			if (!_userManager && _connectSession) {
				_userManager = _connectSession.userManager;
			}

			super.onSyncChange(p_evt);

			if (isSynchronized) {
				if (!_collectionNode.isNodeDefined(_batonNodeName)) {	//we're the first ones here
					var nodeConf:NodeConfiguration = new NodeConfiguration();
					nodeConf.accessModel = UserRoles.VIEWER;
					nodeConf.publishModel = _pubModelForControlling;
					nodeConf.modifyAnyItem = false;
					nodeConf.userDependentItems = true;
					_collectionNode.createNode(_batonNodeName, nodeConf);
				}
				
				if (_holderID && _cachedBatonHolderID) {	//this will work but I don't like it...we might want to use _holderIDSetFromNetwork:Boolean
					for (var i:String in _cachedBatonHolderID) {
						if ( getUserRole(_userManager.myUserID) >= _pubModelForYanking ) {
							//giveTo(_cachedBatonHolderID);
							giveTo(_cachedBatonHolderID[i],i);
						} else if ( canIGrab && _cachedBatonHolderID[i] == _userManager.myUserID ) {
							grab(_cachedBatonHolderID[i]);
						}
						delete _cachedBatonHolderID[i];
					}
				}
			} else {
				//clean up model!
				stopAllTimers();
				_cachedBatonHolderID = null;
				_holderID = null;
			}
			
		}
		
		
		/**
		 * @private
		 */
		override protected function onItemReceive(p_evt:CollectionNodeEvent):void
		{
			//REVISIT
			var theItem:MessageItem = p_evt.item;
			if (!_userManager && _connectSession) {
				_userManager = _connectSession.userManager;
			}
			
			if (theItem.nodeName == _batonNodeName) {
				_holderID[theItem.itemID] = theItem.body;	
				if (_cachedBatonHolderID[theItem.itemID]) {
					delete _cachedBatonHolderID[theItem.itemID];
				}
				if (amIHolding(theItem.itemID) && _autoReleaseTimers[theItem.itemID] && _autoReleaseTimers[theItem.itemID].delay>0) {
					createTimer(theItem.itemID);
					_autoReleaseTimers[theItem.itemID].start();
				}
				var evt:SharedModelEvent = new SharedModelEvent(SharedModelEvent.BATON_HOLDER_CHANGE, true);
				evt.PROPERTY_ID = theItem.itemID;
				if (_cachedValueForSetProp[theItem.itemID]) {
					if (isSynchronized && amIHolding(theItem.itemID)) {
						super.setProperty(theItem.itemID,_cachedValueForSetProp[theItem.itemID]);
						delete _cachedValueForSetProp[theItem.itemID];
					}
				} else if (_cachedValueForDeleteProp[theItem.itemID]) {
					if (isSynchronized && amIHolding(theItem.itemID)) {
						removeProperty(theItem.itemID);
						delete _cachedValueForDeleteProp[theItem.itemID];
					}
				}
				dispatchEvent(evt);
			} else {
				super.onItemReceive(p_evt);
			}
			
		}
		
		/**
		 * @private
		 */
		override protected function onItemRetract(p_evt:CollectionNodeEvent):void
		{
			//REVISIT
			var theItem:MessageItem = p_evt.item;
			if (p_evt.nodeName == _batonNodeName) {			//no need to check the itemID, I only have one
				delete _holderID[theItem.itemID];
				delete _cachedBatonHolderID[theItem.itemID];
				if (_autoReleaseTimers[theItem.itemID] && _autoReleaseTimers[theItem.itemID].running) {
					_autoReleaseTimers[theItem.itemID].stop();
				}
				//super.removeProperty(theItem.itemID);
				var evt:SharedModelEvent = new SharedModelEvent(SharedModelEvent.BATON_HOLDER_CHANGE, true);
				evt.PROPERTY_ID = theItem.itemID;
				dispatchEvent(evt);
			}else {
				super.onItemRetract(p_evt);
				delete _cachedValueForDeleteProp[theItem.itemID];
				if (amIHolding(theItem.itemID)) {
					putDown(theItem.itemID);
				}
			}
		}
		
		
		/**
		 * @private
		 */
		protected function myTrace(...args):void
		{
			DebugUtil.debugTrace("#Baton "+_sharedID+"# "+args);
		}
		
		/**
		 * @private
		 */
		protected function commitProperties(p_evt:Event):void
		{	
			var nodeConf:NodeConfiguration ;
			
			if ( _publishModel != -1 && _collectionNode.getNodeConfiguration(_batonNodeName).publishModel != _publishModel ){
				nodeConf = _collectionNode.getNodeConfiguration(_batonNodeName) ;
				nodeConf.publishModel = _publishModel ;
				_collectionNode.setNodeConfiguration(_batonNodeName,nodeConf );
			}
			
			if ( _accessModel != -1 && _collectionNode.getNodeConfiguration(_batonNodeName).accessModel != _accessModel ){
				nodeConf = _collectionNode.getNodeConfiguration(_batonNodeName) ;
				nodeConf.accessModel = _accessModel ;
				_collectionNode.setNodeConfiguration(_batonNodeName, nodeConf ) ;
			}
			
		}
		
		/**
		 * @private
		 */
		protected function createTimer(p_timerID:String):void
		{
			if (!_autoReleaseTimers[p_timerID]) {
				var timer:Timer = new Timer(_timeout*1000, 1);
				timer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);
				_autoReleaseTimers[p_timerID] =  timer;
			}
		}
		
		/**
		 * @private
		 */
		protected function stopAllTimers():void
		{
			for (var i:String in _autoReleaseTimers) {
				_autoReleaseTimers[i].stop();
			}
		}
	}
}