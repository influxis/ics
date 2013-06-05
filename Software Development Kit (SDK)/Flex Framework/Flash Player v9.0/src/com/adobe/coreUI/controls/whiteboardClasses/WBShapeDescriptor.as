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
	import flash.utils.ByteArray;
	
	/**
	 * Descriptor class for a shape
	 * 
	 * @see com.adobe.coreUI.controls.WhiteBoard
	 */
   public class  WBShapeDescriptor
	{
		/**
		 * Factory class defining which type or class of shape
		 */
		public var factoryID:String;
		/**
		 * Definition date for this shape
		 */
		public var definitionData:*;
		/**
		 * Unique Shape Id
		 */
		public var shapeID:String;
		/**
		 * X-coordinate
		 */
		public var x:Number;
		/**
		 * Y-coordinate
		 */
		public var y:Number;
		/**
		 *  Width of this shape
		 */
		public var width:Number;
		/**
		 * Height of this shape
		 */
		public var height:Number;
		/**
		 * Rotation of shape , default is 0
		 */
		public var rotation:int=0;
		/**
		 * Property data for this shape
		 */
		public var propertyData:*;
		
		/**
		 * @private
		 */
		public function clone():WBShapeDescriptor
		{
			var retObj:WBShapeDescriptor = new WBShapeDescriptor();
			retObj.factoryID = factoryID;
			retObj.definitionData = copyObject(definitionData);
			retObj.shapeID = shapeID;
			retObj.x = x;
			retObj.y = y;
			retObj.width = width;
			retObj.height = height;
			retObj.rotation = rotation;
			retObj.propertyData = copyObject(propertyData);
			
			return retObj;
		}
		
		/**
		 * @private
		 */
		public function createValueObject():Object
		{
			var retObj:Object = new Object();
			retObj.factoryID = factoryID;
			retObj.definitionData = definitionData;
			retObj.shapeID = shapeID;
			retObj.x = x;
			retObj.y = y;
			retObj.width = width;
			retObj.height = height;
			retObj.rotation = rotation;
			retObj.propertyData = propertyData;
			
			return retObj;
		}
		
		/**
		 * @private
		 */
		public function readValueObject(p_vo:Object):void
		{
			if (p_vo["factoryID"]) {
				factoryID = p_vo["factoryID"];
			}
			if (p_vo["definitionData"]) {
				definitionData= p_vo["definitionData"];
			}
			if (p_vo["shapeID"]) {
				shapeID= p_vo["shapeID"];
			}
			if (p_vo["x"]) {
				x= p_vo["x"];
			}
			if (p_vo["y"]) {
				y= p_vo["y"];
			}
			if (p_vo["width"]) {
				width= p_vo["width"];
			}
			if (p_vo["height"]) {
				height= p_vo["height"];
			}
			if (p_vo["rotation"]) {
				rotation= p_vo["rotation"];
			}
			if (p_vo["propertyData"]) {
				propertyData= p_vo["propertyData"];
			}
		}
		
		public function compareShapeAttributes(p_shapeDescriptor:WBShapeDescriptor):Boolean
		{
			if (p_shapeDescriptor.shapeID && p_shapeDescriptor.shapeID != shapeID) {
				return true;
			}
			if (p_shapeDescriptor.x && p_shapeDescriptor.x != x) {
				return true;
			}
			if (p_shapeDescriptor.y && p_shapeDescriptor.y != y) {
				return true;
			}
			if (p_shapeDescriptor.width && p_shapeDescriptor.width != width) {
				return true;
			}
			if (p_shapeDescriptor.height && p_shapeDescriptor.height != height) {
				return true;
			}
			if (p_shapeDescriptor.rotation && p_shapeDescriptor.rotation != rotation) {
				return true;
			}
			return false;
		}
		
		protected function copyObject(value:Object):Object
    	{
        	var buffer:ByteArray = new ByteArray();
        	buffer.writeObject(value);
        	buffer.position = 0;
        	var result:Object = buffer.readObject();
        	return result;
    	}
	}
}