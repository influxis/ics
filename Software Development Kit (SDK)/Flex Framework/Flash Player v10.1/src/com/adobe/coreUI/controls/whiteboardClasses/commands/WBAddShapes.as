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

	/**
	 * @private
	 */
   public class  WBAddShapes extends WBCommandBase
	{
		
		protected var _descriptorsToAdd:Array;
		
		public function WBAddShapes(p_descriptorsToAdd:Array)
		{
			_descriptorsToAdd = p_descriptorsToAdd;
		}
		
		override public function unexecute():void
		{
			var l:int = _descriptorsToAdd.length;
			for (var i:int=0; i<l; i++) {
				_canvas.model.removeShape(WBShapeDescriptor(_descriptorsToAdd[i]).shapeID);
			}
		}
		
		override public function execute():void
		{
			var l:int = _descriptorsToAdd.length;
			for (var i:int=0; i<l; i++) {
				var desc:WBShapeDescriptor = _descriptorsToAdd[i] as WBShapeDescriptor;
				_canvas.model.addShape(desc);
			}
		}
		
		
		
	}
}