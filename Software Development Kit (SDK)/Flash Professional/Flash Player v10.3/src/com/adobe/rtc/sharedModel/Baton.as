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
	 * Dispatched when the baton is given to someone or put down.
	 */
	[Event(name="batonHolderChange", type="com.adobe.rtc.events.SharedModelEvent")]

	/**
	 * Baton is a model class which provides a workflow between users. Essentially, it 
	 * tracks the "holder" of a given resource and provides APIs for grabbing, putting down, 
	 * and giving control to others. Users with an owner role always have the power to 
	 * grab the baton, put it down, or give it to others regardless of who has the baton. 
	 * Users with a publisher role must wait according to the <code class="property">grabbable</code> property:
	 * <ul>
	 * <li>If the baton is set to <code>grabbable</code>, they may grab the baton as soon 
	 * as it is available (since it will then have no controller).</li>
	 * <li>If the baton is not <code>grabbable</code>, the owner must explicitly pass the baton
	 * to someone else. 
	 * </ul>
	 * By default, a baton will timeout in five seconds and be released. This timeout can be 
	 * adjusted in the constructor and extended during use of the resource in question using 
	 * <code>extendTimer</code>.
	 * <p>
	 * Note that users with an owner role may adjust the roles of other users relative to the 
	 * baton using <code>allowUserToGrab</code> (which makes that user a publisher) and <code>
	 * allowUserToAdminister</code> (which makes that user an owner).
	 * </p>
	 * <p>
	 * This component also supports "piggybacking" on existing CollectionNodes through its constructor. 
	 * Developers can avoid CollectionNode proliferation in their applications by pre-supplying a 
	 * CollectionNode and a <code>nodeName</code> for the baton to use. If none is supplied, the 
	 * baton will create its own collection node for sending and receiving messages.
	 * 
	 * @see com.adobe.rtc.sharedModel.CollectionNode
	 * @see com.adobe.rtc.messaging.UserRoles
	 */	
   public class  Baton extends EventDispatcher implements ISessionSubscriber
	{
		/**
		 * @private
		 */
		protected var _nodeName:String = "holderID";
		/**
		 * @private
		 */
		protected var _collectionNode:CollectionNode;
		/**
		 * @private
		 */
		protected var _holderID:String;
		/**
		 * @private
		 */
		protected var _sharedID:String = "_Baton";
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
		protected var _autoPutDownTimer:Timer;
		/**
		 * @private
		 */
		protected var _timeout:int = 0;	//in seconds
		/**
		 * @private
		 */
		protected var _cachedBatonHolderID:String;
		/**
		 * @private
		 */
		protected var userManager:UserManager;
		/**
		 * @private
		 */
		protected var _inSync:Boolean = false;		
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
		protected var _connectSession:IConnectSession = ConnectSession.primarySession;
		
		/**
		 * Constructor. 
		 * 
		 * @param p_id The unique identifier for this baton. As a best practice, use the same ID 
		 * as the collaboration component that hosts it.
		 * @param p_timeOut Sets the auto-put-down timeout. Use 0 for no timeout.
		 * @param p_collectionNode If you'd like to "bring your own" collection node, pass it here.
		 * @param p_nodeName If you'd like to specify the node name to use for the baton, pass it here.
		 */
		public function Baton()
		{
			super();
			
			_autoPutDownTimer = new Timer(_timeout*1000, 1);
			_autoPutDownTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);
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
				_nodeName = p_nodeNameValue ;
			}
		}
		
		/**
		 * @private
		 */
		public function get nodeName():String
		{
			return _nodeName ;
		}
		
		/**
		 * Number of seconds after which the baton times out
		 * If 0, no timeout is used. 
		 * @param p_timeOut Number of seconds until the baton is released 
		 */
		public function set timeOut(p_timeOut:int ):void
		{
			_timeout = p_timeOut ;
			_autoPutDownTimer.delay = p_timeOut*1000 ;
		}
		
		/**
		 * @private
		 */
		public function get timeOut():int
		{
			return _timeout ;
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
				_collectionNode.sharedID = sharedID  ;
				_collectionNode.connectSession = _connectSession ;
				_collectionNode.subscribe();
			} else {
				if (_collectionNode.isSynchronized) {
					onSynchronizationChange(new CollectionNodeEvent(CollectionNodeEvent.SYNCHRONIZATION_CHANGE));
				}
			}
			_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);				
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
		}
		
		
		/**
		 * Defines the logical location of the component on the service - typically this assigns the sharedID of the collectionNode
		 * used by the component. sharedIDs should be unique within a room (if they're expressing 2 unique locations). Note that
		 * this can only be assigned once (before <code>subscribe()</code> is called). For components with an <code class="property">id</code> property, 
		 * sharedID defaults to that value.
		 */
		public function set sharedID(p_id:String):void
		{
			if ( p_id != null ) 
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
		//[Bindable]
		public function get grabbable():Boolean
		{
			return _grabbable;
		}
		
		/**
		 * Whether or not to allow users with a publisher role to grab an available baton.
		 * When false, the baton can only be handed off by users with an owner role.
		 */
		public function set grabbable(p_grabbable:Boolean):void
		{
			_grabbable = p_grabbable;
		}

		/**
		 * Gets the NodeConfiguration of the Baton Node. 
		 */
		public function getNodeConfiguration():NodeConfiguration
		{	
			return _collectionNode.getNodeConfiguration(_nodeName).clone();
		}
		
		/**
		 * Sets the NodeConfiguration on the baton node.
		 * @param p_nodeConfiguration The node Configuration of the baton node to be set.
		 * 
		 */
		public function setNodeConfiguration(p_nodeConfiguration:NodeConfiguration):void
		{	
			_collectionNode.setNodeConfiguration(_nodeName,p_nodeConfiguration);
			
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
		 * Role Value required to grab the baton
		 */
		public function get publishModel():int
		{
			return _collectionNode.getNodeConfiguration(_nodeName).publishModel;
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
		 * Role value which is required for seeing the baton
		 */
		public function get accessModel():int
		{
			// the access model remains always same for HISTORY_NODE_PARTICIPANTS and HISTORY_NODE_HOSTS..
			// any change is only for everyone and typing node, so we return that value
			return _collectionNode.getNodeConfiguration(_nodeName).accessModel;
		}
		
		
			
		/**
		 *  Returns the role of a given user for the baton.
		 * 
		 * @param p_userID UserID of the user in question
		 */
		public function getUserRole(p_userID:String):int
		{
			return _collectionNode.getUserRole(p_userID,_nodeName);
		}
		
		/**
		 * Specifies the <code>userID</code> of the person controlling the baton. Returns null if 
		 * noone has the baton. For example, this function might be used to create a "controlled 
		 * by XXX" tooltip for your component.
		 */
		public function get holderID():String
		{
			return _holderID;
		}
		
		
		//[Bindable(event="synchronizationChange")]
		/**
		* Determines whether the component has connected to the server and has fully synchronized.
		* 
		* @see com.adobe.rtc.messaging.CollectionNode
		*/
		public function get isSynchronized():Boolean
		{
			return _inSync;
		}

		/**
		 * Determines whether the current user has permission to administer the baton 
		 * by taking it from someone or forcing them to put it down.
		 */
		public function get canIAdminister():Boolean
		{
			return canUserAdminister(userManager.myUserID);
		}

		/**
		 * Determines whether a specified user can administer the baton from others. 
		 * 
		 * @param p_userID The <code>userID</code> of the user to check if they have 
		 * adminstrator rights.
		 */		
		public function canUserAdminister(p_userID:String):Boolean
		{
			return(_yankable && _collectionNode.getUserRole(p_userID, _nodeName) >= _pubModelForYanking);
		}

		/**
		 * Determines whether the current user has permission to grab the baton 
		 * when available.
		 */
		public function get canIGrab():Boolean
		{
			return canUserGrab(userManager.myUserID);
		}

		/**
		 * Determines whether a specified user can grab the baton if it's available.
		 * 
		 * @param p_userID  The <code>userID</code> of the user to check if they 
		 * can grab the baton. 
		 */
		public function canUserGrab(p_userID:String):Boolean
		{
			return(_grabbable && _collectionNode.getUserRole(p_userID, _nodeName) >= _pubModelForControlling);
		}
		
		/**
		 * When called by an owner, <code>setUserRole()</code> sets the role of the specified 
		 * user with respect to this baton. The following rules apply: 
		 * <ul>
		 * <li>Setting the role to <code>UserRoles.PUBLISHER</code> allows the user to grab the baton. </li>
		 * <li>Setting the role to <code>UserRoles.OWNER</code> allows the user to administer the baton.</li> 
		 * <li>Setting to <code>UserRoles.VIEWER</code> will allow neither.</li>
		 * </ul>
		 * 
		 * @param p_userID The <code>userID</code> of the user to set the role for. 
		 * @param p_role The new role for that user.  
		 */
		public function setUserRole(p_userID:String, p_role:Number):void
		{
			if ( p_userID == null ) 
				return ;
				
			
			if ( (p_role < 0 || p_role > 100) && p_role != CollectionNode.NO_EXPLICIT_ROLE ) 
				return ; 
				
			_collectionNode.setUserRole(p_userID, p_role, _nodeName);
		}
		

		/**
		 * Determines whether the current user is holding the baton.
		 */
		public function get amIHolding():Boolean
		{
			return (_holderID == userManager.myUserID);
		}
		
		/**
		 * Determines whether the baton is up for grabs because it has no current holder.
		 */
		public function get available():Boolean
		{
			return (_holderID == null) && _grabbable;
		}

		/**
		 * Cleans up all networking and event handling; recommended for garbage collection.
		 */
		public function close():void
		{
			//we were removed from the display list, clean everything up
			_collectionNode.unsubscribe();
			_collectionNode = null;
			_autoPutDownTimer.stop();
			userManager = null;
		}
		
		/**
		 * If grabbable, users with a publisher role can grab the control if it's available 
		 * by using this method. Users with an owner role may grab the baton at any time.
		 */
		public function grab():void
		{
			if (!canIAdminister) {
				// if I can Yank, don't worry about other
				if ( !available || !canIGrab) {
					return;
				}
			}

			if ( amIHolding ) {
				return;
			}

			if ( _inSync ) {
				//grab it
				_collectionNode.publishItem(new MessageItem(_nodeName, userManager.myUserID));
			} else {
				_cachedBatonHolderID = userManager.myUserID;
			}
		}
	
		/**
		 * Users with an publisher role in control can use this method to 
		 * release their control. Users with an owner role  can use this method 
		 * to remove the baton from a user who has it.
		 */
		public function putDown():void
		{
			if ( available ) {
				return;
			}

			if (!canIAdminister && !amIHolding) {
				return;
			}			
			if ( _inSync ) {				
				//release it
				_collectionNode.retractItem(_nodeName);
			} // else not in sync, doing nothing
		}

		/**
		 * If the baton is grabbable, the holding user can hand the baton to a specified user. 
		 * A user with an owner role can give a baton to anyone with the required permissions 
		 * at any time.
		 * 
		 * @param p_userID  The <code>userID</code> of the user to allow to grab the baton.  
		 */
		public function giveTo(p_userID:String):void
		{
			if (!canIAdminister && (!_grabbable || !amIHolding)) {
				return;
			}
			
			if ( _inSync ) {
				//give it to someone
				_collectionNode.publishItem(new MessageItem(_nodeName, p_userID));
			} else {
				_cachedBatonHolderID = p_userID;
			}
		}
		
		/**
		 * Extends the timeout if the baton has one. 
		 */
		public function extendTimer():void
		{
			if (_autoPutDownTimer.running) {
				_autoPutDownTimer.reset();
				_autoPutDownTimer.start();
			}
		}

		/**
		 * @private
		 */
		protected function onTimerComplete(p_evt:TimerEvent):void
		{
			_collectionNode.retractItem(_nodeName);
		}

		/**
		 * @private
		 */
		protected function onSynchronizationChange(p_evt:CollectionNodeEvent):void
		{						
			_inSync = _collectionNode.isSynchronized;
			
			if (_inSync) {
				if (!_collectionNode.isNodeDefined(_nodeName)) {	//we're the first ones here
					var nodeConf:NodeConfiguration = new NodeConfiguration();
					nodeConf.accessModel = UserRoles.VIEWER;
					nodeConf.publishModel = _pubModelForControlling;
					nodeConf.modifyAnyItem = false;
					nodeConf.userDependentItems = true;
					_collectionNode.createNode(_nodeName, nodeConf);
				}

				if (_holderID == null && _cachedBatonHolderID != null) {	//this will work but I don't like it...we might want to use _holderIDSetFromNetwork:Boolean
					if ( getUserRole(userManager.myUserID) >= _pubModelForYanking ) {
						giveTo(_cachedBatonHolderID);
					} else if ( canIGrab && _cachedBatonHolderID == userManager.myUserID ) {
						grab();
					}
					_cachedBatonHolderID = null;
				}
			} else {
				//clean up model!
				_autoPutDownTimer.stop();
				_cachedBatonHolderID = null;
				_holderID = null;
			}
			
			dispatchEvent(p_evt);	//bubble it
		}

		/**
		 * @private
		 */
		protected function onItemReceive(p_evt:CollectionNodeEvent):void
		{
			var theItem:MessageItem = p_evt.item;

			if (theItem.nodeName == _nodeName) {
				_holderID = theItem.body;	
				_cachedBatonHolderID = null;
				if (amIHolding && _timeout>0) {
					_autoPutDownTimer.start();
				}
				dispatchEvent(new SharedModelEvent(SharedModelEvent.BATON_HOLDER_CHANGE, true));
			}			
		}

		/**
		 * @private
		 */
		protected function onItemRetract(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName == _nodeName) {			//no need to check the itemID, I only have one
				_holderID = null;
				_cachedBatonHolderID = null;
				if (_autoPutDownTimer.running) {
					_autoPutDownTimer.stop();
				}
				dispatchEvent(new SharedModelEvent(SharedModelEvent.BATON_HOLDER_CHANGE, true));
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
			
			if ( _publishModel != -1 && _collectionNode.getNodeConfiguration(_nodeName).publishModel != _publishModel ){
				nodeConf = _collectionNode.getNodeConfiguration(_nodeName) ;
				nodeConf.publishModel = _publishModel ;
				_collectionNode.setNodeConfiguration(_nodeName,nodeConf );
			}
			
			if ( _accessModel != -1 && _collectionNode.getNodeConfiguration(_nodeName).accessModel != _accessModel ){
				nodeConf = _collectionNode.getNodeConfiguration(_nodeName) ;
				nodeConf.accessModel = _accessModel ;
				_collectionNode.setNodeConfiguration(_nodeName, nodeConf ) ;
			}
			
        }		
	}
}