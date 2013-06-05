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
package com.adobe.coreUI.controls.whiteboardClasses
{
	import com.adobe.coreUI.events.WBModelEvent;
	
	import flash.events.EventDispatcher;

	/**
	 * Dispatched when the shape is first created
	 */
	[Event(name="shapeCreate", type="com.adobe.events.WBModelEvent")]
	/**
	 * Dispatched when the shape is added to the canvas of the whiteboard
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
	[Event(name="synchronizationChange", type="flash.events.Event")]
	
	/**
	 * This class represents the model for the standalone whiteboard.
	 * It stores all the shapes, properties and layouts.
	 * It has API's for adding, removing and accessing different shapes.
	 * 
	 * @see com.adobe.coreUI.controls.WhiteBoard
	 */
   public class  WBModel extends EventDispatcher
	{
		/**
		 * @private
		 */
		protected var _shapes:Object;
		/**
		 * @private
		 */
		protected var _shapeIDCount:Number = 0;
		/**
		 * @private
		 */
		protected var _addedShapes:Object;
		/**
		 * @private
		 */
		protected var _uniqueID:String;
		
		/**
		 * Constructor
		 */
		public function WBModel()
		{
			_shapes = new Object();
			_addedShapes = new Object();
		}
		
		/**
		 * Create a Shape
		 */
		public function createShape(p_shape:WBShapeDescriptor):void
		{
			if (p_shape.shapeID==null) {
				p_shape.shapeID = String(_shapeIDCount++);
			}
			_shapes[p_shape.shapeID] = p_shape;
			var evt:WBModelEvent = new WBModelEvent(WBModelEvent.SHAPE_CREATE);
			evt.shapeID = p_shape.shapeID;
			evt.isLocalChange = true;
			dispatchEvent(evt);
		}
		
		/**
		 * Add a shape to the canvas
		 */
		public function addShape(p_shape:WBShapeDescriptor):void
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
			evt.isLocalChange = true;

			dispatchEvent(evt);
		}
		
		/**
		 * Change layout of shape i.e. change x,y ,width,height or rotation of a shape defined by the shape ID
		 */
		public function moveSizeRotateShape(p_shapeID:String, p_x:Number, p_y:Number, p_w:Number, p_h:Number, p_rotation:int, p_isLocal:Boolean = false):void
		{
			var shapeDesc:WBShapeDescriptor = getShapeDescriptor(p_shapeID).clone();
			shapeDesc.x = p_x;
			shapeDesc.y = p_y;
			shapeDesc.width = p_w;
			shapeDesc.height = p_h;
			shapeDesc.rotation = p_rotation;
			_shapes[p_shapeID] = shapeDesc;
						
			var evt:WBModelEvent = new WBModelEvent(WBModelEvent.SHAPE_POSITION_SIZE_ROTATION_CHANGE);
			evt.shapeID = p_shapeID;
			evt.isLocalChange = true;

			dispatchEvent(evt);
		}
		
		/**
		 * Change the property data of a shape
		 */
		public function changeShapeProperties(p_shapeID:String, p_properties:*):void
		{
			var shapeDesc:WBShapeDescriptor = getShapeDescriptor(p_shapeID).clone();
			shapeDesc.propertyData = p_properties;
			_shapes[p_shapeID] = shapeDesc;
			
			var evt:WBModelEvent = new WBModelEvent(WBModelEvent.SHAPE_PROPERTIES_CHANGE);
			evt.shapeID = p_shapeID;
			evt.isLocalChange = true;

			dispatchEvent(evt);
		}
		
		public function modifyShapeDescriptor(p_shapeID:String, p_newShapeDescriptor:WBShapeDescriptor):void
		{
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
		 * remove an existing shape given by the shape id
		 */
		public function removeShape(p_shapeID:String):void
		{
			var shapeDesc:WBShapeDescriptor = getShapeDescriptor(p_shapeID);
			delete _shapes[p_shapeID];
			delete _addedShapes[p_shapeID];
			
			var evt:WBModelEvent = new WBModelEvent(WBModelEvent.SHAPE_REMOVE);
			evt.shapeID = p_shapeID;
			evt.deletedShape = shapeDesc;
			evt.isLocalChange = true;

			dispatchEvent(evt);
		}

		/**
		 * Returns the shape descriptor of a shape ID
		 */
		public function getShapeDescriptor(p_shapeID:String):WBShapeDescriptor
		{
			return _shapes[p_shapeID] as WBShapeDescriptor;
		}
		
		/**
		 * Returns if the shape is added already on the canvas
		 */
		public function getIsAdded(p_shapeID:String):Boolean
		{
			return (_addedShapes[p_shapeID]!=null);
		}
		
		/**
		 * Returns array of shape ids
		 */
		public function getShapeIDs():Array
		{
			var returnArray:Array = new Array();
			for (var shapeID:String in _shapes) {
				returnArray.push(shapeID);
			}
			return returnArray;
		}
		
		/**
		 * Remove all shapes
		 */
		public function removeAllShapes():void
		{
			for (var shapeID:String in _shapes) {
				removeShape(shapeID);
			}
		}
		
		/**
		 * @private 
		 * donno why it is here 
		 */
		public function get isSynchronized():Boolean
		{
			return true;
		}
		
		/**
		 * @private
		 * We don't need to expose this API
		 * An unique id for the model
		 */
		public function set uniqueID(p_id:String):void
		{
			_uniqueID = p_id;
		}
		
		/**
		 * @private
		 */
		public function get uniqueID():String
		{
			return _uniqueID;
		}
	}
}