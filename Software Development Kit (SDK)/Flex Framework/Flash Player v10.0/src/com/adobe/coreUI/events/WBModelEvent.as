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
package com.adobe.coreUI.events
{
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapeDescriptor;
	
	import flash.events.Event;


	/**
	 * @private
	 */
   public class  WBModelEvent extends Event
	{
		
		public var shapeID:String;
		public var deletedShape:WBShapeDescriptor;
		public var isLocalChange:Boolean = false;
		
		public static const SHAPE_CREATE:String = "shapeCreate";
		public static const SHAPE_ADD:String = "shapeAdd";
		public static const SHAPE_POSITION_SIZE_ROTATION_CHANGE:String = "shapePositionSizeRotationChange";
		public static const SHAPE_PROPERTIES_CHANGE:String = "shapePropertiesChange";
		public static const SHAPE_REMOVE:String = "shapeRemove";
		public static const SYNCHRONIZATION_CHANGE:String = "synchronizationChange";
		public static const MY_ROLE_CHANGE:String = "myRoleChange";
		
		public function WBModelEvent(p_type:String)
		{
			super(p_type);
		}
		
		public override function clone():Event
		{
			var evt:WBModelEvent = new WBModelEvent(type);
			if (shapeID != null) {
				evt.shapeID = shapeID;
			}
			
			if (deletedShape != null) {
				evt.deletedShape = deletedShape;
			}
			
			evt.isLocalChange = isLocalChange;
			
			return evt;
		}
	}
}