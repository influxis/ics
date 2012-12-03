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
package com.adobe.rtc.pods.sharedWhiteBoardClasses
{
	import com.adobe.coreUI.controls.whiteboardClasses.WBModel;
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapeDescriptor;
	import com.adobe.coreUI.controls.whiteboardClasses.shapeDescriptors.WBArrowShapeDescriptor;
	import com.adobe.coreUI.controls.whiteboardClasses.shapeDescriptors.WBEllipseShapeDescriptor;
	import com.adobe.coreUI.controls.whiteboardClasses.shapeDescriptors.WBHighlightAreaShapeDescriptor;
	import com.adobe.coreUI.controls.whiteboardClasses.shapeDescriptors.WBLineShapeDescriptor;
	import com.adobe.coreUI.controls.whiteboardClasses.shapeDescriptors.WBMarkerShapeDescriptor;
	import com.adobe.coreUI.controls.whiteboardClasses.shapeDescriptors.WBRectangleShapeDescriptor;
	import com.adobe.coreUI.controls.whiteboardClasses.shapeDescriptors.WBRoundedRectangleShapeDescriptor;
	import com.adobe.coreUI.controls.whiteboardClasses.shapeDescriptors.WBTextShapeDescriptor;
	import com.adobe.coreUI.controls.whiteboardClasses.shapes.WBSimpleShape;
	import com.adobe.coreUI.events.WBModelEvent;
	import com.adobe.rtc.collaboration.SharedCursorPane;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedModel.CollectionNode;
	
	
	[Event(name="myRoleChange", type="com.adobe.events.WBModelEvent")]
	/**
	 * Dispatched when the shape is first created
	 */
	[Event(name="shapeCreate", type="com.adobe.events.WBModelEvent")]
	/**
	 * Dispatched when the shape is added
	 */
	[Event(name="shapeAdd", type="com.adobe.events.WBModelEvent")]
	/**
	 * Dispatched when the layout of shape i.e. height, width, rotation angle changes
	 */
	[Event(name="shapePositionSizeRotationChange", type="com.adobe.events.WBModelEvent")]
	/**
	 * Dispatched when the propertyData of a shape changes
	 */
	[Event(name="shapePropertiesChange", type="com.adobe.events.WBModelEvent")]
	/**
	 * Dispatched when a shape for e.g. an ellipse, rectangle is removed.
	 */
	[Event(name="shapeRemove", type="com.adobe.events.WBModelEvent")]
	/**
	 * Dispatched when the SharedWhiteBoardModel has fully connected and synchronized with the service
	 * or when it loses that connection.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]
	
	
	/**
	 * SharedWhiteBoardModel is a model component which drives the SharedWhiteBoard pod. 
	 * Its job is to keep the shared state of the whiteboard synchronized across
	 * multiple users using an internal CollectionNode. It exposes methods for 
	 * manipulating that shared model as well as events indicating when that 
	 * model changes. In general, user with the publisher role and higher can both 
	 * add new messages and with viewer role or higher can view all messages.
	 * 
	 * @see com.adobe.rtc.pods.SharedWhiteBoard
	 * @see com.adobe.rtc.sharedModel.CollectionNode
	 */
   public class  SharedWBModel extends WBModel implements ISessionSubscriber
	{
		/**
		 * @private
		 */
		protected var _collectionNode:CollectionNode;
		/**
		 * @private
		 */
		protected static const SHAPE_DEFINITION_NODE:String = "shapeDefinitionNode";
		/**
		 * @private
		 */
		protected static const SHAPE_PROPERTIES_NODE:String = "shapePropertiesNode";
		/**
		 * @private
		 */
		protected static const SHAPE_CONTAINER_NODE:String = "shapeContainerNode";
		/**
		 * @private
		 */
		protected var _userManager:UserManager;
		/**
		 * @private
		 */
		protected var _myUserID:String;
		/**
		 * @private
		 */
		protected var _cursorPane:SharedCursorPane;
		/**
		 * @private
		 */
		protected var _seenIDs:Object = new Object();
		/**
		 * @private
		 */
		protected var _sharedID:String = "default_WB";
		/**
		 * @private 
		 */		
		protected var _connectSession:IConnectSession = ConnectSession.primarySession;
		
		/**
		 * Determines if the model is session dependant
		 */
		public var sessionDependent:Boolean = false;
		
		/**
		 * Constructor
		 */
		public function SharedWBModel()
		{
		}
		
		/**
		 * @private
		 */
		public function set sharedCursorPane(p_pane:SharedCursorPane):void
		{
			_cursorPane = p_pane;
			if (uniqueID) {
				_cursorPane.collectionNode = _collectionNode;
			}
		}
		
		/**
		 * SharedCursorPane for the whiteboard
		 * @see com.adobe.rtc.collaboration.SharedCursorPane
		 */
		public function get sharedCursorPane():SharedCursorPane
		{
			return _cursorPane;
		}
		
		/**
		 * Disposes all listeners to the network and framework classes. 
		 * Recommended for proper garbage collection of the component.
		 */
		public function close():void
		{
			_collectionNode.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
			_collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			_collectionNode.removeEventListener(CollectionNodeEvent.MY_ROLE_CHANGE, onMyRoleChange);
			_collectionNode.unsubscribe();
			_addedShapes = new Object();
			_shapes = new Object();
			_seenIDs = new Object();
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
			_collectionNode.subscribe();
			_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
			_collectionNode.addEventListener(CollectionNodeEvent.RECONNECT, onReconnect);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			_collectionNode.addEventListener(CollectionNodeEvent.MY_ROLE_CHANGE, onMyRoleChange);
			if (_cursorPane) {
				_cursorPane.collectionNode = _collectionNode;
			}
			_userManager = _connectSession.userManager;
		}
		
		
		/**
		 * When called by an owner, <code>setUserRole()</code> sets the role of the specified 
		 * user on a specific node or the collection Node itself. The following rules apply: 
		 * @param p_userID The <code>userID</code> of the user to set the role for. 
		 * @param p_role The new role for that user.  
		 * @param p_nodeName The nodename, if nothing is specified , it sets on the complete collectionNode
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
		 *  User Role of an user who can access/publish on the shared white board model
		 * 
		 * @param p_userID UserID of the user whose role we get to have
		 */
		public function getUserRole(p_userID:String):int
		{
			if ( p_userID == null ) {
				throw new Error("CameraModel: USerId can't be null");
			}
			
			return _collectionNode.getUserRole(p_userID);
		}
		
		/**
		 * The <code>sharedID</code> is the ID of the class 
		 */
		public function set sharedID(p_id:String):void
		{
			super.uniqueID = p_id ;
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
		
		/**
		 * @private
		 */
		public function set connectSession(p_session:IConnectSession):void
		{
			_connectSession = p_session;
		}
		
		/**
		 * Gets the NodeConfiguration on a specific node in the WhiteBoardmodel. If the node is not defined, it will return null
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
		 * Sets the NodeConfiguration on a already defined node in WhiteBoardmodel. If the node is not defined, it will not do anything.
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
		 * API for creating a new shape. Input is a shapedescriptor object. 
		 * The shape ID is assigned from the server
		 */
		override public function createShape(p_shape:WBShapeDescriptor):void
		{
			if (!canUserDraw(_myUserID)) {
				throw new Error("SharedWhiteBoard - insufficient permissions to draw");
			}
			var item:MessageItem = new MessageItem(SHAPE_DEFINITION_NODE, p_shape.createValueObject(), p_shape.shapeID);
			_collectionNode.publishItem(item);
		}
		
		/**
		 * API for adding an existing shape with a shape ID to the canvas. Input is the shapeDescriptor
		 * 
		 */
		override public function addShape(p_shape:WBShapeDescriptor):void
		{
			if (!canUserDraw(_myUserID)) {
				throw new Error("SharedWhiteBoard - insufficient permissions to draw");
			}
			
			var item:MessageItem = new MessageItem(SHAPE_DEFINITION_NODE, p_shape.createValueObject(), p_shape.shapeID);
			_collectionNode.publishItem(item);
			
		}
		
		/**
		 * API for changing shape layout like x,y position width, height, rotation.
		 */
		override public function moveSizeRotateShape(p_shapeID:String, p_x:Number, p_y:Number, p_w:Number, p_h:Number, p_rotation:int, p_allowLocalChange:Boolean = false):void
		{
			if (!canUserDraw(_myUserID)) {
				throw new Error("SharedWhiteBoard - insufficient permissions to draw");
			}
			var shapeDesc:WBShapeDescriptor = new WBShapeDescriptor();
			if (!shapeDesc) {
				return;
			}
			shapeDesc.shapeID = p_shapeID;
			shapeDesc.x = p_x;
			shapeDesc.y = p_y;
			shapeDesc.width = p_w;
			shapeDesc.height = p_h;
			shapeDesc.rotation = p_rotation;
			
			var shapeDescObject:Object = shapeDesc.createValueObject();
			if (p_allowLocalChange) {
				shapeDescObject.allowLocalChange = p_allowLocalChange;
			}
			
			var item:MessageItem = new MessageItem(SHAPE_CONTAINER_NODE, shapeDescObject, p_shapeID);
			_collectionNode.publishItem(item);
			
		}
		
		/**
		 * API for changing shapeID and property Data
		 */
		override public function changeShapeProperties(p_shapeID:String, p_properties:*):void
		{
			if (!canUserDraw(_myUserID)) {
				throw new Error("SharedWhiteBoard - insufficient permissions to draw");
			}
			var shapeDesc:WBShapeDescriptor = new WBShapeDescriptor();
			shapeDesc.shapeID = p_shapeID;
			shapeDesc.propertyData = p_properties;
			
			var item:MessageItem = new MessageItem(SHAPE_PROPERTIES_NODE, shapeDesc.createValueObject(), p_shapeID);
			_collectionNode.publishItem(item);
		}
		
		/**
		 * API for changing properties and attributes of the Shape. Ensure that all the properties of the shape are set for expected behaviour
		 */
		override public function modifyShapeDescriptor(p_shapeID:String, p_newShapeDescriptor:WBShapeDescriptor):void
		{
			if (!canUserDraw(_myUserID)) {
				throw new Error("SharedWhiteBoard - insufficient permissions to draw");
			}
			var shapeDesc:WBShapeDescriptor = getShapeDescriptor(p_shapeID);
			var mutatedShapeDescriptor:WBShapeDescriptor = shapeDesc.clone();
			mutatedShapeDescriptor.readValueObject(p_newShapeDescriptor);
			if(shapeDesc.compareShapeAttributes(mutatedShapeDescriptor)) {
				moveSizeRotateShape(shapeDesc.shapeID, mutatedShapeDescriptor.x, mutatedShapeDescriptor.y, mutatedShapeDescriptor.width, mutatedShapeDescriptor.height, mutatedShapeDescriptor.rotation, true);
			}
			
			for (var i:String in mutatedShapeDescriptor.propertyData) {
				if (shapeDesc.propertyData.hasOwnProperty(i)) {
					if (shapeDesc.propertyData[i] != mutatedShapeDescriptor.propertyData[i]) {
						changeShapeProperties(shapeDesc.shapeID, mutatedShapeDescriptor.propertyData);
						break;
					}
				}
			}
		}
		
		/**
		 * API for removing a shape with a given shape ID
		 */
		override public function removeShape(p_shapeID:String):void
		{
			if (!canUserDraw(_myUserID)) {
				throw new Error("SharedWhiteBoard - insufficient permissions to draw");
			}
			_collectionNode.retractItem(SHAPE_DEFINITION_NODE, p_shapeID);
			_collectionNode.retractItem(SHAPE_PROPERTIES_NODE, p_shapeID);
			_collectionNode.retractItem(SHAPE_CONTAINER_NODE, p_shapeID);
		}
		
		/**
		 * Returns the shape with the given shape ID if it exists
		 */
		override public function getShapeDescriptor(p_shapeID:String):WBShapeDescriptor
		{
			return _shapes[p_shapeID] as WBShapeDescriptor;
		}
		
		
		/**
		 * Returns array of all shape IDs of shapes currently in the whiteboard
		 */
		override public function getShapeIDs():Array
		{
			var returnArray:Array = new Array();
			for (var shapeID:String in _shapes) {
				returnArray.push(shapeID);
			}
			return returnArray;
		}
		
		
		/**
		 * returns if the shape is already added to the canvas... 
		 */
		override public function getIsAdded(p_shapeID:String):Boolean
		{
			return (_addedShapes[p_shapeID]!=null);
		}	
		
		/**
		 * returns if an user can create/add a shape
		 */
		public function canUserDraw(p_userID:String):Boolean
		{
			return _collectionNode.canUserPublish(p_userID, SHAPE_DEFINITION_NODE);
		}
		
		[Bindable(event="synchronizationChange")]
		/**
		 * Dispatches when the collectionNode is synchronized.
		 */
		override public function get isSynchronized():Boolean
		{
			if (_collectionNode) {
				return _collectionNode.isSynchronized;
			}
			return false;
		}
		
		/**
		 * @private
		 */
		protected function onShapeCreate(p_shape:WBShapeDescriptor, p_local:Boolean):void
		{
			_shapes[p_shape.shapeID] = p_shape;
			if (_collectionNode.isSynchronized) {
				var evt:WBModelEvent = new WBModelEvent(WBModelEvent.SHAPE_CREATE);
				evt.shapeID = p_shape.shapeID;
				evt.isLocalChange = p_local;
				dispatchEvent(evt);
			} else {
				_addedShapes[p_shape.shapeID] = true;
			}
		}
		
		/**
		 * @private
		 */
		protected function onShapeAdd(p_shape:WBShapeDescriptor, p_local:Boolean):void
		{
			var shapeDesc:WBShapeDescriptor = getShapeDescriptor(p_shape.shapeID);
			if (shapeDesc) {
				shapeDesc.x = p_shape.x;
				shapeDesc.y = p_shape.y;
				shapeDesc.width = p_shape.width;
				shapeDesc.height = p_shape.height;
				shapeDesc.rotation = p_shape.rotation;
				_shapes[p_shape.shapeID] = shapeDesc;
			} else {
				_shapes[p_shape.shapeID] = p_shape;
			}
			_addedShapes[p_shape.shapeID] = true;
			
			var evt:WBModelEvent = new WBModelEvent(WBModelEvent.SHAPE_ADD);
			evt.shapeID = p_shape.shapeID;
			evt.isLocalChange = p_local;
			
			dispatchEvent(evt);
		}		
		
		/**
		 * @private
		 */
		protected function onShapeLayoutChange(p_shape:WBShapeDescriptor, p_local:Boolean):void
		{
			var currShape:WBShapeDescriptor = getShapeDescriptor(p_shape.shapeID);
			currShape.x = p_shape.x;
			currShape.y = p_shape.y;
			currShape.width = p_shape.width;
			currShape.height = p_shape.height;
			currShape.rotation = p_shape.rotation;
			
			var evt:WBModelEvent = new WBModelEvent(WBModelEvent.SHAPE_POSITION_SIZE_ROTATION_CHANGE);
			evt.shapeID = p_shape.shapeID;
			evt.isLocalChange = p_local;
			
			dispatchEvent(evt);			
		}
		
		/**
		 * @private
		 */
		protected function onShapePropertiesChange(p_shape:WBShapeDescriptor, p_local:Boolean):void
		{
			getShapeDescriptor(p_shape.shapeID).propertyData = p_shape.propertyData;
			
			var evt:WBModelEvent = new WBModelEvent(WBModelEvent.SHAPE_PROPERTIES_CHANGE);
			evt.shapeID = p_shape.shapeID;
			evt.isLocalChange = p_local;
			
			dispatchEvent(evt);			
		}
		
		/**
		 * @private
		 */
		protected function onSyncChange(p_evt:CollectionNodeEvent):void
		{
			if (_collectionNode.isSynchronized) {
				_myUserID = _userManager.myUserID;
				// has the model been setup?
				if (!_collectionNode.isNodeDefined(SHAPE_CONTAINER_NODE)  || !_collectionNode.isNodeDefined(SHAPE_PROPERTIES_NODE)
					|| !_collectionNode.isNodeDefined(SHAPE_DEFINITION_NODE) ) {
					// it hasn't		
					if (_collectionNode.canUserConfigure(_connectSession.userManager.myUserID)) {
						// it hasn't and I have rights to. Rock on!
						var nodeConfig:NodeConfiguration = new NodeConfiguration();
						nodeConfig.itemStorageScheme = NodeConfiguration.STORAGE_SCHEME_MANUAL;
						nodeConfig.sessionDependentItems = sessionDependent;
						if (!_collectionNode.isNodeDefined(SHAPE_DEFINITION_NODE)) {
							_collectionNode.createNode(SHAPE_DEFINITION_NODE, nodeConfig);
						}
						if (!_collectionNode.isNodeDefined(SHAPE_CONTAINER_NODE)) {
							_collectionNode.createNode(SHAPE_CONTAINER_NODE, nodeConfig);
						}
						if (!_collectionNode.isNodeDefined(SHAPE_PROPERTIES_NODE)) {
							_collectionNode.createNode(SHAPE_PROPERTIES_NODE, nodeConfig);
						}
					}
					_collectionNode.addEventListener(CollectionNodeEvent.NODE_CREATE, onNodeCreate);
				} else {
					dispatchEvent(new WBModelEvent(WBModelEvent.SYNCHRONIZATION_CHANGE));
				}
			} else {
				dispatchEvent(new WBModelEvent(WBModelEvent.SYNCHRONIZATION_CHANGE));
			}
			
		}	
		
		/**
		 * @private
		 */
		protected function onReconnect(p_evt:CollectionNodeEvent):void
		{
			_seenIDs = new Object();
			_addedShapes = new Object();
			_shapes = new Object();
			dispatchEvent(p_evt);
		}
		
		/**
		 * @private
		 */
		protected function onMyRoleChange(p_evt:CollectionNodeEvent):void
		{
			var evt:WBModelEvent = new WBModelEvent(WBModelEvent.MY_ROLE_CHANGE);
			dispatchEvent(evt);			
		}
		
		/**
		 * @private
		 */
		protected function onItemReceive(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName!=SHAPE_DEFINITION_NODE && p_evt.nodeName!=SHAPE_CONTAINER_NODE && p_evt.nodeName!=SHAPE_PROPERTIES_NODE) {
				return;
			}
			
			var didIChangeIt:Boolean = (p_evt.item.publisherID==_myUserID);
			var shapeDesc:WBShapeDescriptor = new WBShapeDescriptor();
			//			shapeDesc.readValueObject(p_evt.item.body);
			
			var shapePropertyData:Object = p_evt.item.body.propertyData;
			var shapeDefinitionData:Object = p_evt.item.body.definitionData;
			var factoryID:String = p_evt.item.body.factoryID;
			
			if (factoryID == "com.adobe.coreUI.controls.whiteboardClasses.shapes::WBArrowShapeFactory") {
				if (shapeDefinitionData.arrowHead == true) {
					var arrowShapeDesc:WBArrowShapeDescriptor = new WBArrowShapeDescriptor();
					arrowShapeDesc.readValueObject(p_evt.item.body);
					shapeDesc = arrowShapeDesc;
				} else {
					var lineShapeDesc:WBLineShapeDescriptor = new WBLineShapeDescriptor();
					lineShapeDesc.readValueObject(p_evt.item.body);
					shapeDesc = lineShapeDesc;
				}
			} else if (factoryID == "com.adobe.coreUI.controls.whiteboardClasses.shapes::WBSimpleShapeFactory") {
				if (shapeDefinitionData == WBSimpleShape.ELLIPSE) {
					var ellipseShapeDesc:WBEllipseShapeDescriptor = new WBEllipseShapeDescriptor();
					ellipseShapeDesc.readValueObject(p_evt.item.body);
					shapeDesc = ellipseShapeDesc;
				} else if (shapeDefinitionData == WBSimpleShape.ROUNDED_RECTANGLE) {
					if (shapePropertyData.primaryColor == 0xffff00 || shapePropertyData.alpha == 0.5 ) {
						var highLightAreaShapeDesc:WBHighlightAreaShapeDescriptor = new WBHighlightAreaShapeDescriptor();
						highLightAreaShapeDesc.readValueObject(p_evt.item.body);
						shapeDesc = highLightAreaShapeDesc;
					} else {
						var rRectangleAreaShapeDesc:WBRoundedRectangleShapeDescriptor = new WBRoundedRectangleShapeDescriptor();
						rRectangleAreaShapeDesc.readValueObject(p_evt.item.body);
						shapeDesc = rRectangleAreaShapeDesc;
					}
				} else if (shapeDefinitionData == WBSimpleShape.RECTANGLE) {
					var rectangleShapeDesc:WBRectangleShapeDescriptor = new WBRectangleShapeDescriptor();
					rectangleShapeDesc.readValueObject(p_evt.item.body);
					shapeDesc = rectangleShapeDesc;
				} else {
					shapeDesc.readValueObject(p_evt.item.body);
				}
			} else if (factoryID == "com.adobe.coreUI.controls.whiteboardClasses.shapes::WBTextShapeFactory") {
				var textShapeDesc:WBTextShapeDescriptor = new WBTextShapeDescriptor();
				textShapeDesc.readValueObject(p_evt.item.body);
				shapeDesc = textShapeDesc;
			} else if (factoryID == "com.adobe.coreUI.controls.whiteboardClasses.shapes::WBMarkerShapeFactory") {
				var markerShapeDesc:WBMarkerShapeDescriptor = new WBMarkerShapeDescriptor();
				markerShapeDesc.readValueObject(p_evt.item.body);
				shapeDesc = markerShapeDesc;
			} else {
				shapeDesc.readValueObject(p_evt.item.body);
			}
			if (shapeDesc.shapeID==null) {
				shapeDesc.shapeID = p_evt.item.itemID
			}
			if (p_evt.nodeName==SHAPE_DEFINITION_NODE && _seenIDs[shapeDesc.shapeID] == null) {
				// it's a totally new shape
				onShapeCreate(shapeDesc, didIChangeIt);
				
			} else if (p_evt.nodeName==SHAPE_DEFINITION_NODE && _addedShapes[shapeDesc.shapeID]==null) {
				// we'd seen the shape, but not added it
				onShapeAdd(shapeDesc, didIChangeIt);
				
			} else {
				// we'd already added the shape, it's now had either its properties or layout changed
				var oldDesc:WBShapeDescriptor = getShapeDescriptor(shapeDesc.shapeID);
				if (!oldDesc) {
					// possible to get a vestigal update belonging to nothing
					return;
				}
				//				if (shapeDesc.x!=oldDesc.x || shapeDesc.y!=oldDesc.y || shapeDesc.width!=oldDesc.width || 
				//					shapeDesc.height!=oldDesc.height || shapeDesc.rotation!=oldDesc.rotation) {
				if (p_evt.nodeName==SHAPE_CONTAINER_NODE) {
					// the layout changed	
					if (Object(p_evt.item.body).hasOwnProperty("allowLocalChange") && p_evt.item.body.allowLocalChange) {
						onShapeLayoutChange(shapeDesc, !p_evt.item.body.allowLocalChange);
					} else {
						onShapeLayoutChange(shapeDesc, didIChangeIt);
					}
					
				} else if (p_evt.nodeName==SHAPE_PROPERTIES_NODE) {
					// the properties changed
					onShapePropertiesChange(shapeDesc, didIChangeIt);
				}
			}
			_seenIDs[shapeDesc.shapeID] = true;
		}
		
		/**
		 * @private
		 */
		protected function onItemRetract(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName!=SHAPE_DEFINITION_NODE) {
				return;
			}
			var shapeID:String = p_evt.item.itemID;
			var shapeDesc:WBShapeDescriptor = getShapeDescriptor(shapeID);
			delete _shapes[shapeID];
			delete _addedShapes[shapeID];
			
			var evt:WBModelEvent = new WBModelEvent(WBModelEvent.SHAPE_REMOVE);
			evt.shapeID = shapeID;
			evt.deletedShape = shapeDesc;
			evt.isLocalChange = (p_evt.item.publisherID==_myUserID);
			
			dispatchEvent(evt);
			
		}
		
		/**
		 * @private
		 */
		protected function onNodeCreate(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName==SHAPE_PROPERTIES_NODE) {
				_collectionNode.removeEventListener(CollectionNodeEvent.NODE_CREATE, onNodeCreate);
				dispatchEvent(new WBModelEvent(WBModelEvent.SYNCHRONIZATION_CHANGE));
			}
		}
		
	}
}