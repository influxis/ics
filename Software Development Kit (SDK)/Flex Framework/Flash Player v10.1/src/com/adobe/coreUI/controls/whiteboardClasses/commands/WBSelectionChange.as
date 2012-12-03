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

	/**
	 * @private
	 */
   public class  WBSelectionChange extends WBCommandBase
	{
		protected var _oldSelection:Array;
		protected var _newSelection:Array;
		
		public function WBSelectionChange(p_newSelection:Array)
		{
			_newSelection = p_newSelection;
		}
		
		override public function unexecute():void
		{
			_canvas.selectedShapeIDs = _oldSelection;
		}
		
		override public function execute():void
		{
			_oldSelection = _canvas.selectedShapeIDs.slice();
			_canvas.selectedShapeIDs = _newSelection;
		}
		
	}
}