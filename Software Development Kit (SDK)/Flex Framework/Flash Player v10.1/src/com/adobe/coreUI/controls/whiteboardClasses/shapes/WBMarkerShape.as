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
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import mx.core.Application;
	import com.adobe.coreUI.events.WBShapeEvent;
	import flash.geom.Rectangle;
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapeBase;
	import flash.display.LineScaleMode;
	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.filters.DropShadowFilter;
	import mx.effects.Tween;
	
	/**
	 * @private
	 */
   public class  WBMarkerShape extends WBShapeBase
	{
		public static const MARKER_SIZE:int = 10;
		public static const MARKER_COLOR:int = 0x3a3a3a;
		public static const TRACKING_INTERVAL:int = 10;

		protected var _markerTimer:Timer;
		protected var _points:Array;
		protected var _lastPtIndexRendered:int = -1;
		protected var _animationIndex:int = 0;
		protected var _animating:Boolean = false;
		
		protected var _primaryColor:uint = 0x3a3a3a;
		protected var _lineThickness:uint = 10;
		protected var _lineAlpha:Number = 0.5;
		protected var _dropShadow:Boolean = true;
		
		protected var _drawingSprite:Sprite;
		protected var _drawingBitmap:Bitmap;
		
		public override function initialize():void
		{
			super.initialize();
			if (!_points) {
				_points = new Array();
			}
		}


		protected override function createChildren():void
		{
			_drawingSprite = new Sprite();
			addChild(_drawingSprite);
		}

		public override function get definitionData():*
		{
			return _points;
		}
		
		public override function set definitionData(p_data:*):void
		{
			_points = p_data as Array;
		}
		
		public override function get propertyData():*
		{
			var returnObj:Object = super.propertyData;
			returnObj.lineColor = _primaryColor;
			returnObj.lineThickness = _lineThickness;
			returnObj.alpha = _lineAlpha;
			return returnObj;
		}
		
		public override function set propertyData(p_data:*):void
		{
			super.propertyData = p_data;
			if (p_data) {
				_primaryColor = p_data.lineColor;
				_lineThickness = p_data.lineThickness;
				_lineAlpha = p_data.alpha;
				invalidateDisplayList();
			}
		}
		

		protected override function setupDrawing():void
		{
			_markerTimer = new Timer(TRACKING_INTERVAL);
			_markerTimer.addEventListener(TimerEvent.TIMER, trackMarker);
			_markerTimer.start();
		}
		
		protected override function cleanupDrawing():void
		{
			if (_markerTimer) {
				_markerTimer.stop();
				_markerTimer.removeEventListener(TimerEvent.TIMER, trackMarker);
				_markerTimer = null;
			}
			normalizePoints();
		}


		protected function trackMarker(p_evt:Event):void
		{
			var l:int = _points.length;
			if (l!=0) {
				var lastPt:Object = _points[l-1];
				if (lastPt.x==mouseX && lastPt.y==mouseY) {
					return;
				}
			}
			_points.push({x:mouseX, y:mouseY});
			renderPoints(0);
		}
		
		protected override function updateDisplayList(p_w:Number, p_h:Number):void
		{
			super.updateDisplayList(p_w, p_h);
			if (animateEntry) {
				animateEntry = false;
				_animationIndex = 0;
				_animating = true;
				animateSegment();
			}	else if (!_isDrawing && !_animating) {
				renderPoints();
			}
			if (_dropShadow) {
				filters = [new DropShadowFilter(4, 45, 0, 0.3)];
			} else {
				filters = null;
			}
		}
		
		protected function renderPoints(p_startIndex:uint=0):void
		{
			var lastPt:Object;
			var g:Graphics = _drawingSprite.graphics;
			var l:int = _points.length;
			if (p_startIndex<_lastPtIndexRendered) {
				// we're backtracking - start over
				_drawingSprite.visible = true;
				g.clear();
				p_startIndex = 0;
			}
			
			if (p_startIndex==0) {
				lastPt = _points[0];
			} else {
				lastPt = _points[_lastPtIndexRendered];
			}

			var pt:Object;
			g.lineStyle(_lineThickness, _primaryColor, _lineAlpha, true, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND, 8);
			var multiplierW:Number = (_isDrawing) ? 1 : width;
			var multiplierH:Number = (_isDrawing) ? 1 : height;
			for (var i:int=p_startIndex; i<l; i++) {
				if (i==0) {
					g.moveTo(lastPt.x*multiplierW, lastPt.y*multiplierH);
					continue;
				}
				pt = _points[i];
				g.lineTo(pt.x*multiplierW, pt.y*multiplierH);
				lastPt = pt;
			}
			_lastPtIndexRendered = i-1;
		}
		
		protected function normalizePoints():void
		{
			var bounds:Rectangle = getBounds(this);
			var l:int = _points.length;
			for (var i:int=0; i<l; i++) {
				var pt:Object = _points[i];
				pt.x = (pt.x-bounds.x)/bounds.width;
				pt.y = (pt.y-bounds.y)/bounds.height;
			}
		}

		protected function animateSegment():void
		{
			var segmentTween:Tween = new Tween(this, 0, 1, 20);

		}
		
		public function onTweenUpdate(p_val:Object):void
		{
			var g:Graphics = _drawingSprite.graphics;
			g.clear();
			g.lineStyle(_lineThickness, _primaryColor, _lineAlpha, true, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND, 8);

			var lastPt:Object = _points[0];
			var pt:Object;
			for (var i:int=0; i<=_animationIndex; i++) {
				if (i==0) {
					g.moveTo(lastPt.x*width, lastPt.y*height);
					continue;
				}
				pt = _points[i];
				g.lineTo(pt.x*width, pt.y*height);
				lastPt = pt;
			}

			lastPt = _points[_animationIndex];
			var nextPt:Object = _points[_animationIndex+1];
			var newY:Number = lastPt.y + (nextPt.y-lastPt.y)*Number(p_val);
			var newX:Number = lastPt.x + (nextPt.x-lastPt.x)*Number(p_val);
			g.lineTo(newX*width, newY*height);
		}
		
		public function onTweenEnd(p_val:Object):void
		{
			onTweenUpdate(p_val);
			if (_animationIndex<_points.length-2) {
				_animationIndex++;
				animateSegment();
			} else {
				_animationIndex = 0;
				_animating = false;
				_lastPtIndexRendered = _points.length-1;
				updateDisplayList(width, height);
			}
		}

	}
}