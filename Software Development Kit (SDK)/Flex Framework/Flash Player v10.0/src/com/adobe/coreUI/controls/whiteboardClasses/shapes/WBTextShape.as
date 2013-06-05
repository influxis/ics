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
package com.adobe.coreUI.controls.whiteboardClasses.shapes
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.events.Event;
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapeBase;
	import flash.events.MouseEvent;
	import mx.utils.StringUtil;
	import com.adobe.coreUI.events.WBShapeEvent;
	import mx.core.EdgeMetrics;
	
	/**
	 * @private
	 */
   public class  WBTextShape extends WBShapeBase
	{
		protected var _drawnPt:Point;
		
		public override function parentChanged(p:DisplayObjectContainer):void
		{
			super.parentChanged(p);
			if (shapeContainer) {
				shapeContainer.resizable = false;
				if (_textArea && _textArea.width!=shapeContainer.shapeWidth) {
					shapeContainer.width = _textArea.width;
				}
				if (_textArea && _textArea.height!=shapeContainer.shapeHeight) {
					shapeContainer.height = _textArea.height;
				}
			}
		}
		
		public override function getBounds(p_space:DisplayObject):Rectangle
		{
			if (_drawnPt) {
				var tmpPt:Point = p_space.globalToLocal(_drawnPt);
				_drawnPt = null;
				return new Rectangle(tmpPt.x, tmpPt.y, 10, 10);
			} else {
				return super.getBounds(p_space);
			}
		}
		
		protected override function setupDrawing():void
		{
			focusTextEditor();
		}

		protected override function onMouseUpHandler(p_evt:MouseEvent):void
		{
			// no-op;
		}
		
		protected override function updateDisplayList(p_w:Number, p_h:Number):void
		{
			super.updateDisplayList(p_w, p_h);
			if (shapeContainer) {
				if (_textArea && _textArea.width!=shapeContainer.shapeWidth) {
					shapeContainer.width = _textArea.width;
				}
				if (_textArea && _textArea.height!=shapeContainer.shapeHeight) {
					shapeContainer.height = _textArea.height;
				}
			}
		}
		
		protected override function disposeTextEditor(p_evt:Event=null):void
		{
			if (!_isRotated) {
				var pt:Point = new Point(_tempEditor.x+4, _tempEditor.y+4);
				var containerPt:Point = _tempEditor.parent.localToGlobal(pt);

				var eM:EdgeMetrics = _tempEditor.viewMetrics;
				var lastLine:Number = (htmlText=="") ? 0 : lastLineHeightHack(_tempEditor);

				_tempEditor.height = _tempEditor.textHeight + eM.top + eM.bottom + 8 - lastLine; // TODO : MAGIC NUMBER?
				positionTextEditor();
				
				if (_isDrawing) {
					_drawnPt = containerPt;
				} else {
					containerPt = shapeContainer.parent.globalToLocal(containerPt);
					shapeContainer.x = containerPt.x - 2;
					shapeContainer.y = containerPt.y + eM.top + 5;
				}
			}
			super.disposeTextEditor(p_evt);
			if (_isDrawing) {
				if (_htmlText==null || StringUtil.trim(_htmlText)=="") {
					dispatchEvent(new WBShapeEvent(WBShapeEvent.DRAWING_CANCEL));
				} else {
					endDrawing();
				}
			}
		}

	}
}