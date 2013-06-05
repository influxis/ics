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
package com.adobe.rtc.collaboration
{
/**
* AdobePatentID="B585"
*/
	import com.adobe.rtc.collaboration.sharedCursorClasses.RemoteUserCursor;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.UserEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.UserDescriptor;
	import com.adobe.rtc.sharedModel.CollectionNode;
	
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.Application;
	import mx.core.UIComponent;
	
	
	/**
	 * Dispatched when the component either loses its connection to the session or regains it
	 * and has finished re-synchronizing itself to the rest of the room.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]

	/**
	 * SharedCursorPane is a UIComponent that, when stretched over a region, tracks the cursor positions 
	 * of any user with role of <code>UserRoles.PUBLISHER</code> or higher within it and reports that position to 
	 * other users. The pane is also responsible for rendering the remote cursors corresponding to 
	 * these positions.
	 */
	
   public class  SharedCursorPane extends UIComponent implements ISessionSubscriber
	{
		/**
		 * @private
		 */
		protected static const ADOBE_PATENT_B585:String = 'AdobePatentID="B585"';
		
		/**
		 * @private
		 */
		protected static const INACTIVITY_TIME:int = 2000;
		
		/**
		 * @private
		 */
		protected static const COLLECTION_NAME:String = "SharedCursorsCollection_";	
		/**
		 * Constant for supplying sizingMode settings. In ABSOLUTE_MODE, the position of the cursors is determined 
		 * in absolute pixel values.
		 */ 
		 public static const ABSOLUTE_MODE:String = "absolute" ;
		 /**
		 * Constant for supplying sizingMode settings. In RELATIVE_MODE, the position of the cursors is determined 
		 * relative to the size of the sharedCursorPane.
		 */
		 public static const RELATIVE_MODE:String = "relative" ;
		 /**
		 * @private 
		 */
		 protected var _sizingMode:String = RELATIVE_MODE ;
		/**
		 * @private
		 */
		protected var _pointTimer:Timer;
		
		/**
		 * @private
		 */
		protected var _inactivityTimer:Timer;
		
		/**
		 * @private
		 */
		protected var _areaRect:Rectangle;
		
		/**
		 * @private
		 */
		protected var _cursorsByID:Object = new Object();
		
		/**
		 * @private
		 */
		protected var _collectionNode:CollectionNode;
		
		/**
		 * @private
		 */
		protected var _userMgr:UserManager;
		
		/**
		 * @private
		 */
		protected var _myID:String;
		
		/**
		 * @private
		 */
		protected var _myCursorClass:Class;
		
		/**
		 * @private
		 */
		protected var _lastMouseX:Number = -1;
		
		/**
		 * @private
		 */
		protected var _lastMouseY:Number = -1;
		
		/**
		 * @private
		 */
		protected var _wasPublisher:Boolean = false;
		 
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
		  protected var _hasRetracted:Boolean = false;
		  /**
		  * @private 
		  * 
		  */
		  protected var _labelField:String = "displayName" ; 
		  /**
		  * @private
		  */
		  protected var _labelFunction:Function ;
		   
		 /**
		  * @private 
		  */		
		 protected var _connectSession:IConnectSession = new SessionContainerProxy(this as UIComponent);
		 /**
		  * @private
		  */
		 protected var _waitingUserDescriptorList:Object = new Object();


		/**
		* The default class used for rendering remote pointers.
		*/
		[Embed (source = 'sharedCursorAssets/sharedCursors.swf#MoveCursor')]
		public static var defaultCursorClass:Class;


		/**
		 * @private
		 */
		protected var _nodeName:String = "Shared_Cursors";
		
		/**
		 * The time in milliseconds of the polling interval for cursor positions. 
		 * Note that setting this to a higher number reduces 
		 * network message traffic but also reduces responsiveness. Setting it to a lower 
		 * number uses more bandwidth.
		 */
		public var pollInterval:int = 500;
		
		/**
		 * @private
		 */
		public function set myCursorClass(p_cursorClass:Class):void
		{
			_myCursorClass = p_cursorClass;
		}
		
		/**
		 * Class to use for the current user's cursor. This will be sent to other users  
		 * who will use it in rendering that user's remote cursor.
		 */
		public function get myCursorClass():Class
		{
			return _myCursorClass;
		}

		/**
		 * @private
		 */
		public function set collectionNode(p_collectionNode:CollectionNode):void
		{
			_collectionNode = p_collectionNode;
		}
		
		/**
		 * SharedCursorPane allows developers to "piggyback" the message traffic of the pane on an existing CollectionNode.
		 * The name of the node to use may also be specified using the <code class="property">nodeName</code> property.
		 * This avoids CollectionNode proliferation for a component that requires only one node. If not set, SharedCursorPane
		 * creates its own CollectionNode.
		 * 
		 * @see nodeName
		 */
		public function get collectionNode():CollectionNode
		{
			return _collectionNode;
		}
		
		/**
		 * @private
		 */
		public function set nodeName(p_nodeName:String):void
		{
			_nodeName = p_nodeName;
		}
		
		
		/**
		 * The field of UserDescriptor you want to show as label with your cursor. You can also show custom fields
		 * @default displayname
		 */
		 public function get labelField():String
		 {
		 	return _labelField ;
		 }
		 
		 /**
		 * @private
		 */
		 public function set labelField(p_field:String):void
		 {
		 	if ( p_field == _labelField ) {
		 		return ;
		 	}
		 	
		 	_labelField = p_field ;
		 	
		 	refreshLabelFieldAndFunction();
		 }
		 
		 
		 /**
		 * The function you want to set as labelFunction
		 *
		 */
		 public function get labelFunction():Function
		 {
		 	return _labelFunction ;
		 }
		 
		 /**
		 * @private
		 */
		 public function set labelFunction(p_function:Function):void
		 {
		 	if ( p_function == _labelFunction ) {
		 		return ;
		 	}
		 	
		 	_labelFunction = p_function ;
		 	
		 	refreshLabelFieldAndFunction();
		 }
		 
		 
		 
		
		/**
		 * When specifying an existing CollectionNode, <code class="property">nodeName</code> specifies a 
		 * <code class="property">nodeName</code>  to use within that collectionNode for
		 * all message traffic. Defaults to "Shared_Cursors".
		 */
		public function get nodeName():String
		{
			return _nodeName;
		}
		
		/**
		 * Closes any event listeners and network operations. Using this function 
		 * is recommended for garbage collection.
		 */
		public function close():void
		{
			removeMyEventListeners();
		}
		
		/**
		 * Defines the logical location of the component on the service; typically this assigns the <code class="property">sharedID</code> of the collectionNode
		 * used by the component. <code class="property">sharedIDs</code> should be unique within a room if they're expressing two 
		 * unique locations. Note that this can only be assigned once before <code>subscribe()</code> is called. For components 
		 * with an <code class="property">id</code> property, <code class="property">sharedID</code> defaults to that value.
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
		 * The IConnectSession with which this component is associated; it defaults to the first 
		 * IConnectSession created in the application.  Note that this may only be set once before 
		 * <code>subscribe()</code> is called, and re-sessioning of components is not supported.
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
		 * Returns true is synchronized; false if not synchronized.
		 */
		public function get isSynchronized():Boolean
		{
			if ( !_collectionNode ) {
				return false ;
			}
			
			return _collectionNode.isSynchronized ;
		}
		/**
		 * Property for sharing mode. There are two modes of sharing, ABSOLUTE_MODE and  RELATIVE_MODE.
		 * In ABSOLUTE_MODE you get the exact position of the cursor of the sharing user.
		 * In RELATIVE_MODE you get the relative position with respect to the size of your own cursor pane.
		 * Default mode is RELATIVE_MODE.
		 */
		public function get sizingMode():String 
		{
			return _sizingMode ;
		}
		/**
		 * @private
		 */
		public function set sizingMode(p_sizingMode:String):void
		{
			if (p_sizingMode != _sizingMode ) {
				_sizingMode = p_sizingMode ;
			}
		}
		/**
		 * Gets the NodeConfiguration of the shared cursor node. 
		 */
		public function getNodeConfiguration():NodeConfiguration
		{	
			return _collectionNode.getNodeConfiguration(_nodeName).clone();
		}
		
		/**
		 * Sets the NodeConfiguration.
		 * @param p_nodeConfiguration The node Configuration of the SharedCursor node.
		 * 
		 */
		public function setNodeConfiguration(p_nodeConfiguration:NodeConfiguration):void
		{	
			_collectionNode.setNodeConfiguration(_nodeName,p_nodeConfiguration);
			
		}
		
		/**
		 * Tells the component to begin synchronizing with the service. For UIComponent-based components such as this one,
		 * this is called automatically upon being added to the <code class="property">displayList</code>. 
		 * For "headless" components, this method must be called explicitly.
		 */
		public function subscribe():void
		{
			if ( id == null ){
				if ( sharedID == null ) {
					sharedID = COLLECTION_NAME ;
				}
			}else {
				if ( sharedID == null ) {
					sharedID = id ;
				}
			}
			
			if (!_collectionNode) {
				_collectionNode = new CollectionNode();
				_collectionNode.sharedID = sharedID ;
				_collectionNode.connectSession = _connectSession ;
				_collectionNode.subscribe();
			}
			_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			
			if ( !_userMgr ) {
				_userMgr = _connectSession.userManager;
			}
		}
		
		/**
		 * Sets the role of a given user for sharing cursors in the component's group
		 * specified by <code class="property">groupName</code>.
		 * 
		 * @param p_userID The user ID of the user whose role should be set.
		 * @param p_userRole The role value to assign to the user with this user ID.
		 * @param p_nodeName The nodename to set the role on, if nothing is specified, it applies to the entire collectionNode.
		 */
		public function setUserRole(p_userID:String, p_role:Number, p_nodeName:String=null):void
		{
			if ( p_userID == null ) 
				return ;
				
			
			if ( (p_role < 0 || p_role > 100) && p_role != CollectionNode.NO_EXPLICIT_ROLE ) 
				return ; 
				
			if (p_nodeName) {
				if ( _collectionNode.isNodeDefined(p_nodeName)) {
					 _collectionNode.setUserRole(p_userID,p_role,p_nodeName);
				}else {
					throw new Error("SharedWhiteBoardModel: The node on which role is being set doesn't exist");
				}
			}else {
				_collectionNode.setUserRole(p_userID,p_role);
			}	
		}
		
		
		/**
		 *  Returns the role of a given user for sharing cursors.
		 * 
		 * @param p_userID The user ID of the user whose role we should get.
		 */
		public function getUserRole(p_userID:String):int
		{
			if ( p_userID == null ) {
				throw new Error("SharedCursorPane: USerId can't be null");
			}
			
			return _collectionNode.getUserRole(p_userID);
		}
		
		
		
		/**
		 * @private 
		 */
		override public function initialize():void
		{
			super.initialize();
			
			if ( !_subscribed ) {
				subscribe();
				_subscribed = true ;
			}
		}
		/**
		 * @private
		 */
		protected function removeMyEventListeners():void
		{
			if (_pointTimer) {
				_pointTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, sendMyCursor);
				_pointTimer.stop();
			}			
			
			if ( !_connectSession.archiveManager.isPlayingBack ) {
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			}
			
			if (_inactivityTimer) {
				_inactivityTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onInactivity);
				_inactivityTimer.stop();
				_inactivityTimer = null;
			}
			_userMgr.removeEventListener(UserEvent.USER_CREATE,onUserDescriptorFetch);
		}
		
		/**
		 * @private
		 */
		override protected function updateDisplayList(p_w:Number, p_h:Number):void
		{
			_areaRect = new Rectangle(0, 0, p_w, p_h);
		}
		
		/**
		 * @private
		 */
		override protected function commitProperties():void
		{
			
			if (!_pointTimer) {
				_pointTimer = new Timer(pollInterval, 1);
				_pointTimer.addEventListener(TimerEvent.TIMER_COMPLETE, sendMyCursor);
			}
		}
		
		/**
		 * @private
		 */
		protected function onSynchronizationChange(p_evt:CollectionNodeEvent):void
		{
			if (_collectionNode.isSynchronized) {
				_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
				_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
				_collectionNode.addEventListener(CollectionNodeEvent.MY_ROLE_CHANGE, onMyRoleChange);
				_myID = _userMgr.myUserID;
				if (!_collectionNode.isNodeDefined(_nodeName) && _collectionNode.canUserConfigure(_myID)) {
					// this is blank and I can configure it. 
					var nodeConfig:NodeConfiguration = new NodeConfiguration();
					nodeConfig.userDependentItems = true;
					nodeConfig.modifyAnyItem = false;
					nodeConfig.itemStorageScheme = NodeConfiguration.STORAGE_SCHEME_MANUAL;
					_collectionNode.createNode(_nodeName, nodeConfig);
					_collectionNode.addEventListener(CollectionNodeEvent.NODE_CREATE, onNodeCreate);
				} else {
					if (!_collectionNode.isNodeDefined(_nodeName)) {
						_collectionNode.addEventListener(CollectionNodeEvent.NODE_CREATE, onNodeCreate);
					} else if (_collectionNode.canUserPublish(_myID, _nodeName)) {
						_wasPublisher = true;
						if ( stage ) {
							stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
						}
					}
				}
				if (_userMgr) {
					_userMgr.addEventListener(UserEvent.USER_CREATE,onUserDescriptorFetch);
				}
			} else {
				removeMyEventListeners();
			}
			
			dispatchEvent(p_evt);
			
		}
		
		/**
		 * @private
		 */
		protected function onNodeCreate(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName && _collectionNode.canUserPublish(_myID, _nodeName)) {
				_wasPublisher = true;
				stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			}
		}
		
		/**
		 * @private
		 */
		protected function onItemReceive(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName==_nodeName) {
				if (p_evt.item.publisherID!=_myID) {
					// we ignore our own cursor
					var body:Object = p_evt.item.body;
					var screenX:Number ;
					var screenY:Number ;
					var cursorClass:Class = getDefinitionByName(body.cursor) as Class;
					if ( _sizingMode == SharedCursorPane.RELATIVE_MODE ) {
						 screenX = body.x*width;
						 screenY = body.y*height;
					}else if ( _sizingMode == SharedCursorPane.ABSOLUTE_MODE ) {
						screenX = body.x ;
						screenY = body.y
					}
					
					
					
					if (_cursorsByID[p_evt.item.publisherID]!=null) {
						// it's a cursor we've already seen - move it
						moveCursorTo(p_evt.item.publisherID, cursorClass, screenX, screenY);
					} else {
						// it's a brand new cursor - fade it in
						addNewCursor(p_evt.item.publisherID, cursorClass, screenX, screenY);
					}
				} else {
					//book-keep my own, just in case
					_cursorsByID[p_evt.item.publisherID] = true;
				}
			}
		}
		
		/**
		 * @private
		 */
		protected function onItemRetract(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName==_nodeName) {
				removeCursor(p_evt.item.publisherID);
			}
		}
		
		/**
		 * @private
		 */
		protected function onMyRoleChange(p_evt:CollectionNodeEvent):void
		{
			// disable / enable 
			if (_wasPublisher && !_collectionNode.canUserPublish(_myID, _nodeName)) {
				removeMyEventListeners();
				_wasPublisher = false;
			} else if (!_wasPublisher && _collectionNode.canUserPublish(_myID, _nodeName)) {
				stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				_pointTimer.addEventListener(TimerEvent.TIMER_COMPLETE, sendMyCursor);
				_wasPublisher = true;
			}
		}
		
		/**
		 * @private
		 */
		protected function sendMyCursor(p_evt:TimerEvent=null):void
		{
			// Start a timer to time out if we haven't moved.
			if (mouseX==_lastMouseX && mouseY==_lastMouseY) {
				if (!_inactivityTimer) {
					_inactivityTimer = new Timer(INACTIVITY_TIME, 1);
				}
				if (!_inactivityTimer.running) {
					_inactivityTimer.reset();
					_inactivityTimer.start();
					_inactivityTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onInactivity);
				}
				// Don't renew the point timer; we're at a standstill. Instead, wait for a mouseMove.
				if (stage) {
					stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				}
								
			} else {
				if (!_myCursorClass) {
					_myCursorClass = defaultCursorClass;
				}
				
				var item:MessageItem ;
				if ( _sizingMode == SharedCursorPane.RELATIVE_MODE ) {
					var relativeX:Number = mouseX/width;
					var relativeY:Number = mouseY/height;
					item = new MessageItem(_nodeName, {x:relativeX, y:relativeY, cursor:getQualifiedClassName(_myCursorClass)}, _myID);
				} else if ( _sizingMode == SharedCursorPane.ABSOLUTE_MODE ) {
					item = new MessageItem(_nodeName, {x:mouseX, y:mouseY, cursor:getQualifiedClassName(_myCursorClass)}, _myID);
				}
				
				if (_collectionNode.isSynchronized) {
					// safety check.
					_hasRetracted = false;
					_collectionNode.publishItem(item);
				}
				_lastMouseX = mouseX;
				_lastMouseY = mouseY;

				// Start the timers for the next poll; switch from polling mouseMove to timers to reduce message intensity.
				removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				_pointTimer.reset();
				_pointTimer.start();
			}
		}
		
		/**
		 * @private
		 */
		protected function moveCursorTo(p_userID:String, p_cursorClass:Class, p_x:Number, p_y:Number):void
		{
			var cursor:RemoteUserCursor = _cursorsByID[p_userID] as RemoteUserCursor;
			cursor.cursorClass = p_cursorClass;
			cursor.moveTo(p_x, p_y);
		}
		
		/**
		 * @private
		 */
		protected function addNewCursor(p_userID:String, p_cursorClass:Class, p_x:Number, p_y:Number):void
		{
			var newCursor:RemoteUserCursor = new RemoteUserCursor();
			addChild(newCursor);
			newCursor.cursorClass = p_cursorClass;
			newCursor.x = p_x;
			newCursor.y = p_y;
			_cursorsByID[p_userID] = newCursor;
			refreshLabelFieldAndFunction();
			newCursor.reveal();
		}
		
		/**
		 * @private
		 */
		protected function refreshLabelFieldAndFunction():void
		{
			for ( var userID:String in _cursorsByID ) {
				if ( _cursorsByID[userID] is RemoteUserCursor ) {
					var tempCursor:RemoteUserCursor = RemoteUserCursor(_cursorsByID[userID])  ;
					var desc:UserDescriptor = _userMgr.getUserDescriptor(userID) ;
					if (desc) {
						if ( labelFunction == null ) {
							if (desc.hasOwnProperty(labelField)){
								tempCursor.displayName = desc[labelField];
							}else {
								var customFields:Object = desc.customFields ;
								for ( var id:String in customFields ) {
									if ( id == labelField ) {
										tempCursor.displayName = desc.customFields[id] ;
									}
								}
							}
						}else {
							tempCursor.displayName = labelFunction(desc) ;
						}
					}else {
						//Lazysubscription might have been set. So call the function again after 
						//the UserManager fetches the UserDescriptor
						_waitingUserDescriptorList[userID] = "waiting";
					}
				}
			}
		}
		
		protected function onUserDescriptorFetch(p_evt:UserEvent):void
		{
			if (_waitingUserDescriptorList[p_evt.userDescriptor.userID]) {
				refreshLabelFieldAndFunction();
				delete _waitingUserDescriptorList[p_evt.userDescriptor.userID];
			}
		}
		
		/**
		 * @private
		 */
		protected function removeCursor(p_userID:String):void
		{
			if (_cursorsByID[p_userID]) {
				if (_cursorsByID[p_userID] is RemoteUserCursor) {
					RemoteUserCursor(_cursorsByID[p_userID]).hide();
				}
				delete _cursorsByID[p_userID];
			}
		}
		
		/**
		 * @private
		 */
		protected function removeMyCursor():void
		{
			if (_collectionNode.isSynchronized && _cursorsByID[_myID] && !_hasRetracted) {
				_hasRetracted = true;
				_collectionNode.retractItem(_nodeName, _myID);
			}
			// Time to start listening for mouseMove; stop listening to timers.
			if (stage) {
				stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			}
		}
		
		/**
		 * @private
		 */
		protected function onInactivity(p_evt:TimerEvent):void
		{
			_lastMouseX = _lastMouseY = -1;
			removeMyCursor();
		}
		
		/**
		 * @private
		 */
		protected function onMouseMove(p_evt:MouseEvent):void
		{
			if (_inactivityTimer) {
				_inactivityTimer.stop();
				_inactivityTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onInactivity);
				_inactivityTimer = null;
			}
			if (_areaRect) {
				var mousePt:Point = new Point(mouseX, mouseY);
				if (_areaRect.containsPoint(mousePt)) {
					// We're still in the pane area.
					if (!_pointTimer.running) {
						sendMyCursor();
					}
				} else if (_pointTimer.running) {
					// We're outside.
					removeMyCursor();
				}
			}			
		}
		
	}
}
