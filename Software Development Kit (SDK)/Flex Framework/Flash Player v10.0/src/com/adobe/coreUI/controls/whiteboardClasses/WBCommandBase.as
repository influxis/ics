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
	/**
	 * @private
	 */
   public class  WBCommandBase implements IWBCommand
	{
		protected var _canvas:WBCanvas;
		
		public function set canvas(p_canvas:WBCanvas):void
		{
			_canvas = p_canvas;
		}
		
		public function get canvas():WBCanvas
		{
			return _canvas;
		}
		
		public function unexecute():void
		{
		}
		
		public function execute():void
		{
		}
		
	}
}