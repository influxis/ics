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
	import flash.events.MouseEvent;
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapeBase;
	import flash.geom.Point;
	import flash.display.Graphics;
	import mx.utils.ColorUtil;
	import flash.geom.Matrix;
	import flash.filters.DropShadowFilter;
	import flash.geom.Rectangle;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.GradientType;

	/**
	 * @private
	 */
   public class  WBArrowShape extends WBShapeBase
	{
		
		protected static const MIN_DIMENSIONS:Number = 50;
		protected static const HEAD_ANGLE:Number = Math.PI/8; // 45 degrees
		
		protected var _basePercentX:Number = 0;
		protected var _basePercentY:Number = 0;
		protected var _headPercentX:Number = 1;
		protected var _headPercentY:Number = 1;
		protected var _drawingX:int = 0;
		protected var _drawingY:int = 0;
		protected var _isStraight:Boolean = false; // handling degenerate case where the line is perfectly horizontal or vertical
		protected var _lineThickness:Number = 10;
		protected var _lineColor:uint = 0x3a3a3a;
		protected var _dropShadow:Boolean = true;
		protected var _gradientFill:Boolean = true;
		protected var _lineAlpha:Number = 1;
		protected var _arrowHeadSprite:Sprite;
		protected var _lineSprite:Sprite;
		protected var _arrowHead:Boolean = true;
		
		public override function get definitionData():*
		{
			var returnObj:Object = new Object();
			returnObj.basePercentX = _basePercentX;
			returnObj.basePercentY = _basePercentY;
			returnObj.headPercentX = _headPercentX;
			returnObj.headPercentY = _headPercentY;
			returnObj.arrowHead = _arrowHead;
			
			return returnObj;
		}
		
		public override function set definitionData(p_data:*):void
		{
			_basePercentX = p_data.basePercentX;
			_basePercentY = p_data.basePercentY;
			_headPercentX = p_data.headPercentX;
			_headPercentY = p_data.headPercentY;
			_arrowHead = p_data.arrowHead;
		}
		
		public override function set propertyData(p_data:*):void
		{
			super.propertyData = p_data;
			if (p_data.lineThickness!=null) {
				_lineThickness = p_data.lineThickness as Number;
			} 
			if (p_data.lineColor!=null) {
				_lineColor = p_data.lineColor as uint;
			}
			if (p_data.dropShadow!=null) {
				_dropShadow = p_data.dropShadow as Boolean;
			}
			if (p_data.gradientFill!=null) {
				_gradientFill = p_data.gradientFill as Boolean;
			}
			if (p_data.alpha!=null) {
				_lineAlpha = p_data.alpha as Number;
			}
			invalidateDisplayList();
		}
		
		public override function get propertyData():*
		{
			var returnObj:Object = super.propertyData;
			returnObj.lineThickness = _lineThickness;
			returnObj.lineColor = _lineColor;
			returnObj.dropShadow = _dropShadow;
			returnObj.gradientFill  = _gradientFill;
			returnObj.alpha = _lineAlpha;
			return returnObj;
		}
		
		protected override function createChildren():void
		{
			_arrowHeadSprite = new Sprite();
			addChild(_arrowHeadSprite);
			_lineSprite = new Sprite();
			addChild(_lineSprite);
		}
		
		protected override function setupDrawing():void
		{
			stage.addEventListener(MouseEvent.MOUSE_MOVE, trackMouse);
		}
		
		protected override function cleanupDrawing():void
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, trackMouse);
		}
		
		protected function trackMouse(p_evt:MouseEvent):void
		{
			var pt:Point = globalToLocal(stage.localToGlobal(new Point(p_evt.stageX, p_evt.stageY)));
			_drawingX = pt.x;
			_drawingY = pt.y;
			invalidateDisplayList();
			validateNow();
		}
		
		override public function getBounds(p_target:DisplayObject):Rectangle
		{
			
			var realBounds:Rectangle = _lineSprite.getBounds(p_target);
			var newBounds:Rectangle = realBounds.clone();
			var inflateAmount:Number;
			if (realBounds.width<MIN_DIMENSIONS) {
				inflateAmount = (MIN_DIMENSIONS-realBounds.width)/2;
				newBounds.inflate(inflateAmount, 0);
				_basePercentX = inflateAmount/newBounds.width;
				_headPercentX = (newBounds.width-inflateAmount)/newBounds.width;
			}
			if (realBounds.height<MIN_DIMENSIONS) {
				inflateAmount = (MIN_DIMENSIONS-realBounds.height)/2;
				newBounds.inflate(0, inflateAmount);
				_basePercentY = inflateAmount/newBounds.height;
				_headPercentY = (newBounds.height-inflateAmount)/newBounds.height;
			}
			if (_drawingX<0) { 
				var tmpBaseX:Number = _basePercentX;
				_basePercentX = _headPercentX;
				_headPercentX = tmpBaseX; 
			}
			if (_drawingY<0) {
				var tmpBaseY:Number = _basePercentY;
				_basePercentY = _headPercentY;
				_headPercentY = tmpBaseY;
			}
			return newBounds;
		}
		
		protected override function updateDisplayList(p_w:Number, p_h:Number):void
		{
			super.updateDisplayList(p_w, p_h);
			
			g = _lineSprite.graphics;
			g.clear();

			var secondColor:uint = ColorUtil.adjustBrightness(_lineColor, -55);
			var rotationMatrix:Matrix = new Matrix();
			rotationMatrix.createGradientBox(p_w, p_h, Math.PI/2);
			
			g.lineStyle(_lineThickness, _lineColor, _lineAlpha,true);
//			g.lineGradientStyle(GradientType.LINEAR, [_lineColor, secondColor], [_lineAlpha,_lineAlpha], [0,255], rotationMatrix);
			
			var headPointX:Number;
			var headPointY:Number;
			var basePointX:Number = 0;
			var basePointY:Number = 0;
			
			if (_isDrawing) {
				headPointX = _drawingX;
				headPointY = _drawingY;
				g.lineTo(_drawingX, _drawingY);

			} else {
				basePointX = p_w*_basePercentX;
				headPointX = p_w*_headPercentX;
				var halfLineThickness:Number = _lineThickness/2;
				var modifier:Number = (basePointX<headPointX) ? 1 : -1;
				basePointX += halfLineThickness*modifier;
				headPointX -= halfLineThickness*modifier;

				basePointY = p_h*_basePercentY;
				headPointY = p_h*_headPercentY;
				modifier = (basePointY<headPointY) ? 1 : -1;
				basePointY += halfLineThickness*modifier;
				headPointY -= halfLineThickness*modifier;
				
				g.moveTo(basePointX, basePointY);
				g.lineTo(headPointX, headPointY);
			}

			if (_dropShadow) {
				filters = [new DropShadowFilter(4, 45, 0, 0.3)];
			} else {
				filters = null;
			}

			if (!_arrowHead) {
				return;
			}
			var angle:Number = HEAD_ANGLE;
			var arrowHeadLength:Number = 20 + _lineThickness * 3;
			var rightHeadX: Number = Math.sin(angle)*arrowHeadLength;
			var rightHeadY: Number = Math.cos(angle)*arrowHeadLength;
			
			var g:Graphics = _arrowHeadSprite.graphics;
			g.clear();
			
			g.lineStyle(_lineThickness, _lineColor, _lineAlpha,true);
//			g.lineGradientStyle(GradientType.LINEAR, [_lineColor, secondColor], [_lineAlpha,_lineAlpha], [0,255], rotationMatrix);
			g.lineTo(rightHeadX, rightHeadY);
			g.moveTo(0,0);
			g.lineTo(-rightHeadX, rightHeadY);
			
			_arrowHeadSprite.x = headPointX;
			_arrowHeadSprite.y = headPointY;

			var arrowHeadAngle:Number = 90 + 180*Math.atan2(headPointY-basePointY, headPointX-basePointX)/Math.PI;
			_arrowHeadSprite.rotation = arrowHeadAngle;
			
		}
		

		
	}
}