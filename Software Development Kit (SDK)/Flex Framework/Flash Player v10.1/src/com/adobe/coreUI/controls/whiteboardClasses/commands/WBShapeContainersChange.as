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
package com.adobe.coreUI.controls.whiteboardClasses.commands
{
	import com.adobe.coreUI.controls.whiteboardClasses.IWBCommand;
	import com.adobe.coreUI.controls.whiteboardClasses.WBCommandBase;
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapeDescriptor;
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapeTween;
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapeContainer;

	/**
	 * @private
	 */
   public class  WBShapeContainersChange extends WBCommandBase
	{
		protected var _changedDescriptors:Array;
		protected var _oldDescriptors:Array;
		
		public function WBShapeContainersChange(p_descriptors:Array)
		{
			_changedDescriptors = p_descriptors;
		}
		
		override public function unexecute():void
		{
			var l:int = _changedDescriptors.length;
			for (var i:int=0; i<l; i++) {
				var desc:WBShapeDescriptor = _oldDescriptors[i] as WBShapeDescriptor;
				_canvas.model.moveSizeRotateShape(desc.shapeID, desc.x, desc.y, desc.width, desc.height, desc.rotation);
				if (!areShapeContainersEqual(desc, _canvas.model.getShapeDescriptor(desc.shapeID))) {
					var sContainer:WBShapeContainer = _canvas.getShapeContainer(desc.shapeID);
					var shapeTween:WBShapeTween = new WBShapeTween(sContainer, desc, _canvas);
				}
			}
		}
		
		override public function execute():void
		{
			_oldDescriptors = new Array();
			var l:int = _changedDescriptors.length;
			for (var i:int=0; i<l; i++) {
				var desc:WBShapeDescriptor = _changedDescriptors[i] as WBShapeDescriptor;
				_oldDescriptors.push(_canvas.model.getShapeDescriptor(desc.shapeID).clone());
				_canvas.model.moveSizeRotateShape(desc.shapeID, desc.x, desc.y, desc.width, desc.height, desc.rotation);
				if (!areShapeContainersEqual(desc, _canvas.model.getShapeDescriptor(desc.shapeID))) {
					var sContainer:WBShapeContainer = _canvas.getShapeContainer(desc.shapeID);
					var shapeTween:WBShapeTween = new WBShapeTween(sContainer, desc, _canvas);
				}
			}
		}
		
		protected function areShapeContainersEqual(p_shape1:WBShapeDescriptor, p_shape2:WBShapeDescriptor):Boolean
		{
			return (p_shape1.x==p_shape2.x && p_shape1.y==p_shape2.y && p_shape1.width==p_shape2.width 
					&& p_shape1.height==p_shape2.height && p_shape1.rotation==p_shape2.rotation);
		}
	}
}