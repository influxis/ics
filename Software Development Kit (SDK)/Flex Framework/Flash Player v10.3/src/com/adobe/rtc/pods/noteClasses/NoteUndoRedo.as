// ActionScript file
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
package com.adobe.rtc.pods.noteClasses
{
	
	import flash.events.Event;
	
	/**
	 * UndoRedo Component used in Note, Whiteboard to undo and redo commands
	 * Developers can use this component to perform their undo's and redo's in their application on various string inputs
	 * 
	 * @see com.adobe.rtc.pods.SharedWhiteBoard
	 * @see com.adobe.rtc.pods.Note
	 */
   public class  NoteUndoRedo
	{
		/**
		 * @private
		 */
		protected var _stack:Array;	//the undo/redo stack, each element is a ICommand
		/**
		 * @private
		 */
		protected var _head:int;	//the position of the head in the stack
		/**
		 * @private
		 */
		protected var _currentText:String = "";
		/**
		 * @private
		 */
		protected var _startingText:String = "";
		
		public function NoteUndoRedo()
		{
			_stack = new Array();
			_head = -1;
		}
		
		/**
		 * Gets the head index of the undo redo stack
		 */
		public function get head():Number
		{
			return _head;
		}
		
		/**
		 * Gets the length of the stack
		 */
		public function get length():Number
		{
			return _stack.length;
		}
		
		/**
		 * Gets the currentText
		 */
		public function get text():String
		{
			return (_currentText == null) ? "" : _currentText;
		}
		
		/**
		 * Last Index from where the next text will start
		 */
		public function get endIndex():Number
		{
			if (_head >= 0) {
				if (_stack[_head].endIndex != null) {
					return _stack[_head].endIndex;	
				}
			}
			return -1;
		}
		
		/**
		 * @private
		 */
		public function set endIndex(p_index:Number):void
		{
			if(_head >=0 ){
				_stack[_head].endIndex=p_index;
			}
		}
		
		/**
		 * Sets the Starting Text
		 */
		public function set startingText(p_text:String):void
		{
			_currentText = p_text;
			_startingText = p_text;
		}
		
		
		/**
		 * Adds a text to the stack
		 */
		public function addKeyCommand(p_currentText:String, p_index:Number):void
		{
			_head++;
			_stack.splice(_head);	//clean the rest of the redo stack, it's a new branch
			var obj:Object = new Object();
			if (_head != 0) {
				obj.oldText = _stack[_head-1].newText;
			} else {
				obj.oldText = _startingText;
			}
			obj.newText = p_currentText;
			obj.endIndex = p_index;
			_stack[_head] = obj;
			_currentText = _stack[_head].newText;
		}
			
		/**
		 * Undo's an operation
		 */	
		public function undo():void
		{
			if (_head >= 0) {
				_head--;
				if (_head == -1) {
					_currentText = _startingText;
				} else {
					_currentText = _stack[_head].newText;
				}
			}
		}
		
		/**
		 * Redo an Operation
		 */
		public function redo():void
		{
			if (((_head+1) < _stack.length) 
					&& (_stack[_head+1] != undefined)
				) {
				_head++;
				_currentText = _stack[_head].newText;
			}
		}		
	}
}