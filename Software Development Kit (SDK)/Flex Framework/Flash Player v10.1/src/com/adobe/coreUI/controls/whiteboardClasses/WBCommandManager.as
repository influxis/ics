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
	import flash.events.EventDispatcher;

	/**
	 * @private
	 */
   public class  WBCommandManager extends EventDispatcher
	{
		protected var _currentCommandIdx:int = -1;
		protected var _commandStack:Array;
		protected var _canvas:WBCanvas;
		
		public function WBCommandManager(p_canvas:WBCanvas)
		{
			_canvas = p_canvas;
			reset();
		}
		
		public function addCommand(p_command:IWBCommand):void
		{
			_currentCommandIdx++;
			if (_currentCommandIdx<_commandStack.length) {
				// clear these commands
				_commandStack.splice(_currentCommandIdx, _commandStack.length-_currentCommandIdx);
			}
			p_command.canvas = _canvas;
			_commandStack.push(p_command);
			p_command.execute();
		}
		
		public function removeRecentCommands(p_commandType:Class):void
		{
			var l:Number = _commandStack.length;
			for (var i:Number=l-1; i>=0; i--) {
				if (_commandStack[i] is p_commandType) {
					_commandStack.splice(i, 1);
					_currentCommandIdx--;
				} else {
					break;
				}
			} 
		}
		
		public function undo():void
		{
			if (_currentCommandIdx>=0) {
				IWBCommand(_commandStack[_currentCommandIdx]).unexecute();
				_currentCommandIdx--;
			}
		}
		
		public function redo():void
		{
			if (_currentCommandIdx<_commandStack.length-1) {
				_currentCommandIdx++;
				IWBCommand(_commandStack[_currentCommandIdx]).execute();
			}
		}
		
		public function reset():void
		{
			_commandStack = new Array();
			_currentCommandIdx = -1;
		}
		
	}
}