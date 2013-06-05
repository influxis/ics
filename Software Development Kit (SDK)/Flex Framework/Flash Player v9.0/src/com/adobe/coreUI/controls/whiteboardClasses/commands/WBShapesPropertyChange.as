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
   public class  WBShapesPropertyChange extends WBCommandBase
	{

		protected var _changedDescriptors:Array;
		protected var _oldDescriptors:Array;

		public function WBShapesPropertyChange(p_changedDescriptors:Array)
		{
			_changedDescriptors = p_changedDescriptors;
		}
		
		override public function unexecute():void
		{
			var l:int = _oldDescriptors.length;
			for (var i:int=0; i<l; i++) {
				var desc:WBShapeDescriptor = _oldDescriptors[i] as WBShapeDescriptor;
				_canvas.model.changeShapeProperties(desc.shapeID, desc.propertyData);
			}
		}
		
		override public function execute():void
		{
			_oldDescriptors = new Array();
			var l:int = _changedDescriptors.length;
			for (var i:int=0; i<l; i++) {
				var desc:WBShapeDescriptor = _changedDescriptors[i] as WBShapeDescriptor;
				_oldDescriptors.push(_canvas.model.getShapeDescriptor(desc.shapeID).clone());
				_canvas.model.changeShapeProperties(desc.shapeID, desc.propertyData);
			}
		}
		
	}
}