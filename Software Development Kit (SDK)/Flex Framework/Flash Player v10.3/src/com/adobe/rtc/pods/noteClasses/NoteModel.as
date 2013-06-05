// ActionScript file
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
package com.adobe.rtc.pods.noteClasses
{
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.NoteEvent;
	import com.adobe.rtc.events.SharedModelEvent;
	import com.adobe.rtc.events.SharedPropertyEvent;
	import com.adobe.rtc.events.UserEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.UserDescriptor;
	import com.adobe.rtc.sharedModel.CollectionNode;
	import com.adobe.rtc.sharedModel.SharedProperty;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;

	/**
	 * Dispatched when the NoteModel has fully connected and synchronized with the 
	 * service or when it loses that connection.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	
	
	/**
	 * Dispatched when the selection on the note has changed.
	 */
	[Event(name="selectionChange", type="com.adobe.rtc.events.NoteEvent")]
	
	/**
	 * Dispatched when the set of users typing changes.
	 */
	[Event(name="typingListUpdate", type="flash.events.Event")]
	
	/**
	 * Dispatched when the current user's role changes with respect to this model.
	 */
	[Event(name="onMyRoleChange", type="com.adobe.rtc.events.CollectionNodeEvent")]
	
	/**
	 * Dispatched when the text of the note changes
	 */
	[Event(name="change", type="com.adobe.rtc.events.SharedPropertyEvent")]
	
	/**
	 * Dispatched when the note text changes.
	 */
	[Event(name="scrollUpdate", type="com.adobe.rtc.events.SharedModelEvent")]
	
	
	 
	/**
	 * NoteModel is a model component which drives the Note pod. Its job is to keep 
	 * the shared properties of the note pod synchronized across multiple users. 
	 * It exposes methods for manipulating that shared model and events indicating 
	 * when that model changes. In general, users with a publisher role and higher 
	 * can edit the note while users with a viewer role can only see the note. 
	 * The note model features synchronized text, selection and scroll position, 
	 * as well as a list of users currently engaged in editing or creating notes.
	 * 
	 * This component supports "piggybacking" on existing CollectionNodes through 
	 * its constructor. Developers can avoid CollectionNode proliferation in their 
	 * applications by pre-supplying a CollectionNode and a <code>nodeName</code> 
	 * for the NoteModel to use. If none is supplied, the NoteModel will create 
	 * its own collectionNode for sending and receiving messages.
	 * 
	 * @see com.adobe.rtc.pods.Note
	 * @see com.adobe.rtc.sharedModel.SharedProperty
	 * @see com.adobe.rtc.sharedModel.CollectionNode
	 */
   public class  NoteModel extends EventDispatcher implements ISessionSubscriber
	 {	
		/**
		 * @private
		 */
	 	protected const TEXT_NODE_NAME:String = "text";
		/**
		 * @private
		 */
		protected const EDITING_NODE_NAME:String = "editing";
		/**
		 * @private
		 */
		protected const SCROLL_POSITION_NODE_NAME:String = "scrollPosition";
		/**
		 * @private
		 */
		protected const SELECTION_NODE_NAME:String = "selection";
		/**
		 * @private
		 */
		protected var _collectionNode:CollectionNode;
	
		/**
		 * @private
		 */
		protected var _sessionDependentItems:Boolean =false;
		/**
		 * @private
		 */
		protected var _userManager:UserManager;
		/**
		 * @private
		 */
		protected var _usersEditing:ArrayCollection;
		/**
		 * @private
		 */
		protected var _userWithoutUserDescriptorEditing:ArrayCollection;
		/**
		 * @private
		 */
		protected var _editingTimer:Timer;
		
		/**
		 * @private
		 */
		protected var _textModel:SharedProperty;	
		/**
		 * @private
		 */
		protected var _verticalScrollModel:SharedProperty;
		
		/**
		 * @private
		 */
		protected var _selectionObj:Object ;
		/**
		 * @private
		 */
		protected var _cachedSelectionObj:Object ;

		/**
		 * @private
		 */
		protected const TOO_MANY_EDITING_THRESHOLD:uint = 5;
		/**
		 * @private 
		 */		
		protected var _connectSession:IConnectSession = ConnectSession.primarySession;
		/**
		 * @private
		 */
		protected var _sharedID:String = "default_Note";
			
		/**
		 * Constructor. 
		 */
		public function NoteModel(p_sessionDependentItems:Boolean=false ):void
		{
			_sessionDependentItems = p_sessionDependentItems;
		}
		
		/**
		 * Tells the component to begin synchronizing with the service.  
		 * For "headless" components such as this one, this method must be called explicitly.
		 */
		public function subscribe():void
		{
			_collectionNode = new CollectionNode();
			_collectionNode.sharedID = sharedID ;
			_collectionNode.connectSession = _connectSession ;
			_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			_collectionNode.subscribe();
			
			if(!_textModel) {
				_textModel = new SharedProperty();
				_textModel.updateInterval = 300 ;
				_textModel.collectionNode = _collectionNode ;
				_textModel.nodeName = TEXT_NODE_NAME ;
				_textModel.isSessionDependent = _sessionDependentItems;
				_textModel.sharedID = sharedID;
				_textModel.connectSession = _connectSession ;
				_textModel.subscribe();
//				_textModel.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
				_textModel.addEventListener(SharedPropertyEvent.CHANGE, onValueCommit);
				_textModel.addEventListener(CollectionNodeEvent.MY_ROLE_CHANGE, onMyRoleChange);
			}
			
			if(!_verticalScrollModel) {
				_verticalScrollModel = new SharedProperty();
				_verticalScrollModel.updateInterval = 300 ;
				_verticalScrollModel.collectionNode = _collectionNode ;
				_verticalScrollModel.nodeName = SCROLL_POSITION_NODE_NAME ;
				_verticalScrollModel.isSessionDependent = _sessionDependentItems;
				_verticalScrollModel.sharedID = sharedID ;
				_verticalScrollModel.connectSession = _connectSession ;
				_verticalScrollModel.subscribe();
//				_verticalScrollModel.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
				_verticalScrollModel.addEventListener(SharedPropertyEvent.CHANGE, onScrollValueCommit);
				_verticalScrollModel.addEventListener(CollectionNodeEvent.MY_ROLE_CHANGE, onMyRoleChange);
			}
						
			//_collectionNode.collectionName = _id+"_NoteModel";
			_userManager = _connectSession.userManager;
			_userManager.addEventListener(UserEvent.USER_CREATE,onUserDescriptorFetch);
			_usersEditing = new ArrayCollection();
			_userWithoutUserDescriptorEditing = new ArrayCollection();
			
			_cachedSelectionObj = new Object();
			_cachedSelectionObj.beginIndex = -1 ;
			_cachedSelectionObj.endIndex = -1 ;

			_editingTimer = new Timer(10000, 1);			
			_editingTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);
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
		
		[Bindable(event="synchronizationChange")]
		/**
		 * Determines whether the NoteModel is connected and fully synchronized with 
		 * the service.
		 */
		public function get isSynchronized():Boolean
		{
			return _collectionNode.isSynchronized;	//no need to check baton since it uses my collection
		}
		
		/**
		 * Gets the NodeConfiguration on a specific node in the Notemodel. If the node is not defined, it will return null
		 * @param p_nodeName The name of the node.
		 */
		public function getNodeConfiguration(p_nodeName:String):NodeConfiguration
		{	
			if ( _collectionNode.isNodeDefined(p_nodeName)) {
				return _collectionNode.getNodeConfiguration(p_nodeName).clone();
			}
			
			return null ;
		}
		
		/**
		 * Sets the NodeConfiguration on a already defined node in Notemodel. If the node is not defined, it will not do anything.
		 * @param p_nodeConfiguration The node Configuration on a node in the NodeConfiguration.
		 * @param p_nodeName The name of the node.
		 */
		public function setNodeConfiguration(p_nodeName:String,p_nodeConfiguration:NodeConfiguration):void
		{	
			if ( _collectionNode.isNodeDefined(p_nodeName)) {
				_collectionNode.setNodeConfiguration(p_nodeName,p_nodeConfiguration) ;
			}
			
		}
		
		/**
		 * Disposes all listeners to the network and framework classes. 
		 * Recommended for proper garbage collection of the component.
		 */
		public function close():void
		{
			if ( _textModel ) {
				_textModel.removeEventListener(SharedPropertyEvent.CHANGE, onValueCommit);
				_textModel.removeEventListener(CollectionNodeEvent.MY_ROLE_CHANGE, onMyRoleChange);
				_textModel.close();
			}
			
			if ( _verticalScrollModel ) {
				_verticalScrollModel.removeEventListener(SharedPropertyEvent.CHANGE, onScrollValueCommit);
				_verticalScrollModel.removeEventListener(CollectionNodeEvent.MY_ROLE_CHANGE, onMyRoleChange);
				_verticalScrollModel.close();
			}
			
			if ( _collectionNode ) {
				_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
				_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
				_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
				_collectionNode.unsubscribe();
				_collectionNode.close();
				_collectionNode = null ;
			}
			
			if (_userManager) {
				_userManager.removeEventListener(UserEvent.USER_CREATE,onUserDescriptorFetch);
			}
		}
		
		/**
		* Specifies the text for the note model. Only users with a publisher role may set this value.
		*/		
		public function get htmlText():String 
		{
			return _textModel.value;
		}
		/**
		 * @private
		 */
		public function set htmlText(p_htmlText:String):void
		{
			_textModel.value = p_htmlText;
		}
		
	
		/**
		 * Specifies the shared scroll position for the note model. Only users with a publisher role  
		 * may set this value.
 		 */
		public function get verticalScrollPos():Number
		{
			return _verticalScrollModel.value ;
		}
		
		/**
		 * @private
 		 */ 
		public function set verticalScrollPos(value:Number):void
		{
			// detect if this request is happening on initialization
			_verticalScrollModel.value = value ;
		}

		/**
		 * Specifies the selection object for the note model based on two properties:
		 * <ul>
		 * <li>beginIndex</li>
		 * <li>endIndex</li>
		 * </ul>
		 * The notes pod and model offers the option of shared selection; that is, a 
		 * highlighted item can be highlighted for everyone. For example, this property 
		 * can be used to determine the 0-based index within the text for where the 
		 * selection begins and ends when someone selects some text. This is used with 
		 * the <code>selectionChange</code> event.
		 */
		public function get selection():Object
		{
			return _selectionObj ;
		}

		/**
		 * @private
		 */		
		public function set selection(p_selectionObj:Object):void
		{
			if ( ! p_selectionObj ) {
				return ;
			}
			
			if(!_collectionNode.isSynchronized)
				_cachedSelectionObj = p_selectionObj ;
			else {
				
				if ( p_selectionObj.beginIndex == _selectionObj.beginIndex && p_selectionObj.endIndex == _selectionObj.endIndex ) {
					return ;
				}
				_collectionNode.publishItem(new MessageItem(SELECTION_NODE_NAME, p_selectionObj));
			}
		}
	
		
		/**
		 * @private
		 * Sets the specified user's role on this model such that the user can edit the text. 
		 * Note that only users with an ownwer role can change user roles.
		 * 
		 * @param p_userID The id of the desired user.
		 * 
		 */
		public function allowUserToEdit(p_userID:String):void
		{
			// If I can't configure, cancel.
			if(!_collectionNode.canUserConfigure(_userManager.myUserID)){
				return;
			}
			
			_collectionNode.setUserRole(p_userID, UserRoles.PUBLISHER);
		}

		/**
		 * Specifies an ArrayCollection of user <code>userIDs</code> who are currently editing the text.
		 */		
		public function get usersEditing():ArrayCollection
		{
			return _usersEditing;
		}
		
		/**
		 * Specifies a string of user <code>displayNames</code>  who are currently editing the text.
		 */		
		public function get usersEditingString():String
		{
			var res:String = "";
			if ( _usersEditing ) {
				for (var i:uint=0; i<_usersEditing.length; i++) {
					var userID:String = String(_usersEditing.getItemAt(i));
					var desc:UserDescriptor = _userManager.getUserDescriptor(userID);
					if (userID != _userManager.myUserID) {
						if ( desc != null ) 
							res += ((res=="") ? "" : ", ")+desc.displayName;
						else
							res += ((res=="") ? "" : ", ");
					}
				}
			}
			return res;
		}
		
		/**
		 * Determines whether the current user is editing.
		 */
		public function iAmEditing():void
		{			
			if (!_collectionNode.isSynchronized) {
				//too early, ignore
				return;
			}
			
			if (	!_usersEditing.contains(_userManager.myUserID)
					&& _usersEditing.toArray().length < TOO_MANY_EDITING_THRESHOLD
			) {
				//I'm not typing yet and we're below the threshold, publish my item
				_collectionNode.publishItem(new MessageItem(EDITING_NODE_NAME, _userManager.myUserID, _userManager.myUserID));
				
				//the receiveItem will start the timer
			}				

			//Extend the timer if it's running (and it's only running if we received our own typing item)
			if (_editingTimer.running) {
				_editingTimer.reset();
				_editingTimer.start();
			}	
		}
		
		/**
		 * @private
		 */
		public function set publishModel(p_publishModel:int):void
		{	
			if ( p_publishModel < 0 || p_publishModel > 100 ) 
				return ; 
			
			var nodeConf:NodeConfiguration ;
			
			if ( _collectionNode.getNodeConfiguration(EDITING_NODE_NAME).publishModel != p_publishModel ){
				nodeConf = _collectionNode.getNodeConfiguration(EDITING_NODE_NAME) ;
				nodeConf.publishModel = p_publishModel ;
				_collectionNode.setNodeConfiguration(EDITING_NODE_NAME, nodeConf ) ;
			}
			
			if ( _collectionNode.getNodeConfiguration(SELECTION_NODE_NAME).publishModel != p_publishModel ){
				nodeConf = _collectionNode.getNodeConfiguration(SELECTION_NODE_NAME) ;
				nodeConf.publishModel = p_publishModel ;
				_collectionNode.setNodeConfiguration(SELECTION_NODE_NAME, nodeConf ) ;
			}
			
			_textModel.publishModel = p_publishModel ;
			
		}
		
		/**
		 * The role value required for modifying the note text
		 */
		public function get publishModel():int
		{
			return _collectionNode.getNodeConfiguration(EDITING_NODE_NAME).publishModel;
		}
		
		/**
		 * @private
		 */
		public function set accessModel(p_accessModel:int):void
		{	
			if ( p_accessModel < 0 || p_accessModel > 100 ) 
				return ; 
			
			var nodeConf:NodeConfiguration ;
			
			if ( _collectionNode.getNodeConfiguration(EDITING_NODE_NAME).accessModel != p_accessModel ){
				nodeConf = _collectionNode.getNodeConfiguration(EDITING_NODE_NAME) ;
				nodeConf.accessModel = p_accessModel ;
				_collectionNode.setNodeConfiguration(EDITING_NODE_NAME, nodeConf ) ;
			}
			
			if ( _collectionNode.getNodeConfiguration(SELECTION_NODE_NAME).accessModel != p_accessModel ){
				nodeConf = _collectionNode.getNodeConfiguration(SELECTION_NODE_NAME) ;
				nodeConf.accessModel = p_accessModel ;
				_collectionNode.setNodeConfiguration(SELECTION_NODE_NAME, nodeConf ) ;
			}	
			
			_textModel.accessModel = p_accessModel ;
		}
		
		/**
		 * The role value required for accessing the note text
		 */
		public function get accessModel():int
		{
			// the access model remains always same for HISTORY_NODE_PARTICIPANTS and HISTORY_NODE_HOSTS..
			// any change is only for everyone and typing node, so we return that value
			return _collectionNode.getNodeConfiguration(EDITING_NODE_NAME).accessModel;
		}
		
		
			
		/**
		 *  Returns the role of a given user for the note.
		 * 
		 * @param p_userID UserID of the user in question
		 */
		public function getUserRole(p_userID:String):int
		{
			return _collectionNode.getUserRole(p_userID);
		}
		
		/**
		 *  Sets the role of a given user for the note.
		 * 
		 * @param p_userID UserID of the user whose role we are setting
		 * @param p_userRole Role value we are setting
		 */
		public function setUserRole(p_userID:String ,p_userRole:int,p_nodeName:String=null):void
		{
			if ( p_userID == null ) 
				return ;
				
			
			if ( (p_userRole < 0 || p_userRole > 100) && p_userRole != CollectionNode.NO_EXPLICIT_ROLE ) 
				return ; 
			
			if (p_nodeName) {
				if ( _collectionNode.isNodeDefined(p_nodeName)) {
					 _collectionNode.setUserRole(p_userID,p_userRole,p_nodeName);
				}else {
					throw new Error("NoteModel: The node on which role is being set doesn't exist");
				}
			}else {
				_collectionNode.setUserRole(p_userID,p_userRole);
			}
		}
		
		/**
		 * The synchronization change handler. 
		 * 
		 * @private
		 */
		protected function onSynchronizationChange(event:CollectionNodeEvent):void
		{			
			if (_collectionNode.isSynchronized) {
				//If collection node is synchronized then create the nodeconfiguration and the nodes
				var nodeConf:NodeConfiguration = new NodeConfiguration();
				nodeConf.modifyAnyItem = true;
				nodeConf.accessModel = UserRoles.VIEWER;
				
				if (!_collectionNode.isNodeDefined(EDITING_NODE_NAME)){
					_collectionNode.createNode(EDITING_NODE_NAME, new NodeConfiguration(UserRoles.VIEWER, UserRoles.VIEWER, true, false, true, _sessionDependentItems, NodeConfiguration.STORAGE_SCHEME_MANUAL));
				}
				
				if (!_collectionNode.isNodeDefined(SELECTION_NODE_NAME)){
					nodeConf.sessionDependentItems = true ;
					_collectionNode.createNode(SELECTION_NODE_NAME,nodeConf); 
				} 
				
					
				// if the cached scroll position is  not null, then update the model with it and set the cached value to null
				if( !_selectionObj ) {
					_selectionObj = _cachedSelectionObj;
				} 
				
			} else {
				//clean up local model, it will "come back" when I reconnect
				_cachedSelectionObj.beginIndex = -1 ;
				_cachedSelectionObj.endIndex = -1 ;
			}
			
			dispatchEvent(event);	//bubble it
		}		
		
		
		/**
		 * @private
		 */
		protected function onTimerComplete(p_evt:TimerEvent=null):void
		{
			//I am no longer typing
			if (_usersEditing.contains(_userManager.myUserID) && _collectionNode.isSynchronized) {
				_collectionNode.retractItem(EDITING_NODE_NAME, _userManager.myUserID);
			}
		}
		
		/**
		 * @private
		 */
		protected function onItemReceive(event:CollectionNodeEvent):void
		{
			var theItem:MessageItem = event.item;
			var scrollPos:Array;
			switch(theItem.nodeName) {
				case SELECTION_NODE_NAME:
					_selectionObj = theItem.body ;
					//if ( theItem.publisherID != _userManager.myUserID ) {
						dispatchEvent(new NoteEvent(NoteEvent.SELECTION_CHANGE));
					//} 
					break ;
				case EDITING_NODE_NAME:
					if (!_usersEditing.contains(theItem.itemID)) {
					
						if (theItem.itemID == _userManager.myUserID) {
							_usersEditing.addItem(theItem.itemID);
							//we got our own item back, start the timer
							_editingTimer.reset();
							_editingTimer.start();
							dispatchEvent(new Event("typingListUpdate"));
						} else if (_userManager.getUserDescriptor(theItem.itemID)) {
							_usersEditing.addItem(theItem.itemID);
							dispatchEvent(new Event("typingListUpdate"));
						} else {
							_userWithoutUserDescriptorEditing.addItem(theItem.itemID);
						}
					
					}
					break;
			}
		}
		
		/**
		 * @private
		 */
		protected function onUserDescriptorFetch(p_evt:UserEvent):void
		{
			if (_userWithoutUserDescriptorEditing.contains(p_evt.userDescriptor.userID)) {
				_usersEditing.addItem(p_evt.userDescriptor.userID);
				dispatchEvent(new Event("typingListUpdate"));
				_userWithoutUserDescriptorEditing.removeItemAt(_userWithoutUserDescriptorEditing.getItemIndex(p_evt.userDescriptor.userID));
			}
		}

		
		/**
		 * @private
		 */
		protected function onItemRetract(p_evt:CollectionNodeEvent):void
		{
			var item:MessageItem = p_evt.item;
			if (item.nodeName == EDITING_NODE_NAME)
			{
				if (_usersEditing.contains(item.itemID)) {
					_usersEditing.removeItemAt(_usersEditing.getItemIndex(item.itemID));
					dispatchEvent(new Event("typingListUpdate"));
				}
				
				if (_userWithoutUserDescriptorEditing.contains(item.itemID)) {
					_userWithoutUserDescriptorEditing.removeItemAt(_userWithoutUserDescriptorEditing.getItemIndex(item.itemID));	
				}

			}
		}
		
		/**
		 * Handler for the <code>myRoleChange</code>.
		 * 
		 * @private
		 */
		protected function onMyRoleChange(p_evt:CollectionNodeEvent):void
		{
			dispatchEvent(p_evt);
		}
		
		
		/**
		 * @private
		 */
		protected function onValueCommit(p_evt:SharedPropertyEvent):void
		{
			dispatchEvent(new SharedPropertyEvent(p_evt.type,p_evt.publisherID));
		}
		
		/**
		 * @private
		 */
		protected function onScrollValueCommit(p_evt:SharedPropertyEvent):void
		{
			if ( _verticalScrollModel.value <= -1 && _verticalScrollModel.value >= -2 ) {
				dispatchEvent(new SharedModelEvent(SharedModelEvent.SCROLL_UPDATE));
			}  else if ( _verticalScrollModel.value >= 0 ) {
				dispatchEvent(new NoteEvent(NoteEvent.CLICK_INDEX_CHANGE));
			}

		}
	}

}
			

		
