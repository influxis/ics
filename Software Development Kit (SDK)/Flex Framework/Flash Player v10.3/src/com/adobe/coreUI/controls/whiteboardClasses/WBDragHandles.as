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
	import flash.events.MouseEvent;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	import flash.display.Graphics;
	import flash.geom.Point;
	import com.adobe.coreUI.events.WBShapeEvent;
	import mx.managers.CursorManager;
	import flash.display.GradientType;
	import flash.utils.Timer;
	import flash.display.DisplayObjectContainer;
	import mx.core.Application;
	import mx.core.UIComponent;
	import com.adobe.coreUI.localization.Localization;


	[Event(name="positionSizeRotateEnd", type="com.adobe.events.WBShapeEvent")]
	
	/**
	 * @private
	 */
   public class  WBDragHandles extends WBShapeContainer
	{
		
		protected static const ROTATOR_START_Y:Number = -25;
		protected static const DASH_SPACING:Number = 3;
		protected static const HANDLE_SIZE:Number = 8;
		protected static const DOUBLE_CLICK_TIME:Number = 500;

		[Embed (source = 'whiteboardAssets/Cursors.swf#ResizeCursor_Vertical')]
		protected var _verticalResizeCursor:Class;
		[Embed (source = 'whiteboardAssets/Cursors.swf#ResizeCursor_BottomUp')]
		protected var _bottomUpResizeCursor:Class;
		[Embed (source = 'whiteboardAssets/Cursors.swf#ResizeCursor_Horizontal')]
		protected var _horizontalResizeCursor:Class;
		[Embed (source = 'whiteboardAssets/Cursors.swf#ResizeCursor_TopDown')]
		protected var _topDownResizeCursor:Class;

		[Embed (source = 'whiteboardAssets/Cursors.swf#RotateCursor')]
		protected var _rotateCursor:Class;

		protected var _handleContainer:UIComponent;
		
		protected var _tLHandle:UIComponent;
		protected var _tMHandle:UIComponent;
		protected var _tRHandle:UIComponent;
		protected var _mLHandle:UIComponent;
		protected var _mRHandle:UIComponent;
		protected var _bLHandle:UIComponent;
		protected var _bMHandle:UIComponent;
		protected var _bRHandle:UIComponent;
		
		protected var _rotateHandle:UIComponent;
		protected var _centerCircle:UIComponent;
		
		protected var _cursorTable:Dictionary;
		protected var _currentHandle:UIComponent;

		protected var _mouseBlocking:Boolean = true;
		protected var _isMoving:Boolean = false;
		
		protected var _handlesEnabled:Boolean = true;
		
		protected var _dblClickTimer:Timer;

		public function set mouseBlocking(p_val:Boolean):void
		{
			if (p_val==_mouseBlocking) {
				return;
			}
			_mouseBlocking = p_val;
			invalidateDisplayList();
		}

		public function get mouseBlocking():Boolean
		{
			return _mouseBlocking;
		}

		public function beginMouseTracking():void
		{
			_isMoving = true;
			beginMove();
			_dblClickTimer.reset();
			_dblClickTimer.start();
		}

		public function set handlesVisible(p_val:Boolean):void
		{
			if (p_val) {
				throwFocus();
			} else {
				if (_content) {
					_content.finishEditingText();
				}
			}
			_handleContainer.visible = p_val;
		}
		
		public function get handlesVisible():Boolean
		{
			return _handleContainer.visible;
		}
		
		public override function clearAllEvents():void
		{
			super.clearAllEvents();
			clearRotateEvents();
			clearSizeEvents();
		}
		
		public function set handlesEnabled(p_value:Boolean):void
		{
			if (p_value!=_handlesEnabled) {
				_handlesEnabled = p_value;
				if (!_handlesEnabled && _tLHandle) {
					_tLHandle.removeEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
					_tMHandle.removeEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
					_tRHandle.removeEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
					_mLHandle.removeEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
					_mRHandle.removeEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
					_bLHandle.removeEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
					_bMHandle.removeEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
					_bRHandle.removeEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
					_rotateHandle.removeEventListener(MouseEvent.ROLL_OVER, rotateRollOver);
				} else if (_handlesEnabled && _tLHandle) {
					_tLHandle.addEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
					_tMHandle.addEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
					_tRHandle.addEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
					_mLHandle.addEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
					_mRHandle.addEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
					_bLHandle.addEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
					_bMHandle.addEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
					_bRHandle.addEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
					_rotateHandle.addEventListener(MouseEvent.ROLL_OVER, rotateRollOver);
					
				}
			}
		}
		
		public function get handlesEnabled():Boolean
		{
			return _handlesEnabled;
		}
		
		protected function throwFocus():void
		{
			if (owner is WBCanvas) {
				WBCanvas(owner).setFocus();
			}
		}
		
		override protected function createChildren():void
		{
			_cursorTable = new Dictionary();
			
			_handleContainer = new UIComponent();
			addChild(_handleContainer);
			_handleContainer.visible = false;
			
			_centerCircle = createCircleHandle();
			
			super.createChildren();
			var resizeTip:String = Localization.impl.getString("Resize Shape");
			_tLHandle = createSquareHandle();
			_tLHandle.toolTip = resizeTip;
			_cursorTable[_tLHandle] = _topDownResizeCursor;
			_tLHandle.addEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
			
			_tMHandle = createSquareHandle();
			_tMHandle.toolTip = resizeTip;
			_cursorTable[_tMHandle] = _verticalResizeCursor;
			_tMHandle.addEventListener(MouseEvent.ROLL_OVER, resizeRollOver);
			
			_tRHandle = createSquareHandle();
			_tRHandle.toolTip = resizeTip;
			_cursorTable[_tRHandle] = _bottomUpResizeCursor;
			_tRHandle.addEventListener(MouseEvent.ROLL_OVER, resizeRollOver);

			_mLHandle = createSquareHandle();
			_mLHandle.toolTip = resizeTip;
			_cursorTable[_mLHandle] = _horizontalResizeCursor;
			_mLHandle.addEventListener(MouseEvent.ROLL_OVER, resizeRollOver);

			_mRHandle = createSquareHandle();
			_mRHandle.toolTip = resizeTip;
			_cursorTable[_mRHandle] = _horizontalResizeCursor;
			_mRHandle.addEventListener(MouseEvent.ROLL_OVER, resizeRollOver);

			_bLHandle = createSquareHandle();
			_bLHandle.toolTip = resizeTip;
			_cursorTable[_bLHandle] = _bottomUpResizeCursor;
			_bLHandle.addEventListener(MouseEvent.ROLL_OVER, resizeRollOver);

			_bMHandle = createSquareHandle();
			_bMHandle.toolTip = resizeTip;
			_cursorTable[_bMHandle] = _verticalResizeCursor;
			_bMHandle.addEventListener(MouseEvent.ROLL_OVER, resizeRollOver);

			_bRHandle = createSquareHandle();
			_bRHandle.toolTip = resizeTip;
			_cursorTable[_bRHandle] = _topDownResizeCursor;
			_bRHandle.addEventListener(MouseEvent.ROLL_OVER, resizeRollOver);

			_rotateHandle = createCircleHandle();
			_rotateHandle.toolTip = Localization.impl.getString("Rotate Shape");
			_rotateHandle.addEventListener(MouseEvent.ROLL_OVER, rotateRollOver);

			_dblClickTimer = new Timer(DOUBLE_CLICK_TIME, 1);
		}
		

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			
			var adjustPos:Number = HANDLE_SIZE/2;
			_tLHandle.x = _mLHandle.x = _bLHandle.x = -adjustPos;
			_tMHandle.x = _bMHandle.x = _rotateHandle.x = _centerCircle.x = shapeWidth/2-adjustPos;
			_tRHandle.x = _mRHandle.x = _bRHandle.x = shapeWidth-adjustPos;
			_tLHandle.y = _tMHandle.y = _tRHandle.y = -adjustPos;
			_mLHandle.y = _mRHandle.y = _centerCircle.y = shapeHeight/2-adjustPos;
			_bLHandle.y = _bMHandle.y = _bRHandle.y = shapeHeight-adjustPos;
			
			_tLHandle.visible = _tMHandle.visible = _tRHandle.visible = _mLHandle.visible = _mRHandle.visible = _bLHandle.visible = _bMHandle.visible = _bRHandle.visible = resizable;
			
			_rotateHandle.y = ROTATOR_START_Y-adjustPos;
			_hitArea.visible = _mouseBlocking;
			drawOutline();
			
		}
		
		protected function drawOutline():void
		{
			var g:Graphics = _handleContainer.graphics;
			g.clear();
			var lastColor:int;
			// top and bottom borders
			lastColor = 0x6a6a6a;
			for (var i:int=0; i<shapeWidth; i+=DASH_SPACING) {
				lastColor = (lastColor==0x6a6a6a) ? 0xfaeaea : 0x6a6a6a;
				g.lineStyle(2, lastColor, 1, true);
				g.moveTo(i, 0);
				g.lineTo(i+DASH_SPACING, 0);
				g.moveTo(i, shapeHeight);
				g.lineTo(i+DASH_SPACING, shapeHeight);
			}
			// left and right borders
			lastColor = 0x6a6a6a;
			for (i=0; i<shapeHeight; i+=DASH_SPACING) {
				lastColor = (lastColor==0x6a6a6a) ? 0xfaeaea : 0x6a6a6a;
				g.lineStyle(2, lastColor, 1, true);
				g.moveTo(0, i);
				g.lineTo(0, i+DASH_SPACING);
				g.moveTo(shapeWidth, i);
				g.lineTo(shapeWidth, i+DASH_SPACING);
			}
			// rotation bar
			var endY:Number = shapeHeight/2;
			var midX:Number = shapeWidth/2;
			lastColor = 0x6a6a6a;
			for (i=ROTATOR_START_Y; i<endY; i+=DASH_SPACING) {
				lastColor = (lastColor==0x6a6a6a) ? 0xfaeaea : 0x6a6a6a;
				g.lineStyle(2, lastColor, 1, true);
				g.moveTo(midX, i);
				g.lineTo(midX, i+DASH_SPACING);
			}

		}

		protected function createSquareHandle():UIComponent
		{
			var sp:UIComponent = new UIComponent();
			var g:Graphics = sp.graphics;
			g.clear();
			g.lineStyle(1, 0x666666);
			g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xdadada], [1,1], [100,255]);
			g.drawRect(0, 0, HANDLE_SIZE, HANDLE_SIZE);
			
			_handleContainer.addChild(sp);
			return sp;
		}

		protected function createCircleHandle():UIComponent
		{
			var sp:UIComponent = new UIComponent();
			var g:Graphics = sp.graphics;
			g.clear();
			g.lineStyle(1, 0x666666);
			g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xdadada], [1,1], [100,255]);
			var adjustPos:Number = HANDLE_SIZE/2;
			g.drawCircle(adjustPos, adjustPos, adjustPos);
			
			_handleContainer.addChild(sp);
			return sp;
		}


		protected function rotateRollOver(p_evt:MouseEvent):void
		{
			if (cursorManager.currentCursorID==CursorManager.NO_CURSOR) {
				trackRotateCursor(p_evt);
				_rotateHandle.addEventListener(MouseEvent.MOUSE_MOVE, trackRotateCursor);
				stage.addEventListener(MouseEvent.MOUSE_DOWN, beginRotate);
				_rotateHandle.addEventListener(MouseEvent.ROLL_OUT, rotateRollOut);
			}			
		}

		protected function rotateRollOut(p_evt:MouseEvent):void
		{
			cursorManager.removeAllCursors();
			clearRotateEvents();
		}
		
		protected function trackRotateCursor(p_evt:MouseEvent):void
		{
			cursorManager.removeAllCursors();
			cursorManager.setCursor(_rotateCursor);
		}
		
		protected function beginRotate(p_evt:MouseEvent):void
		{
			clearRotateEvents();
			stage.addEventListener(MouseEvent.MOUSE_UP, endRotate);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, trackRotate);
			// find the center of the box in the parent's space
			_originalPt = parent.globalToLocal(localToGlobal(new Point(shapeWidth/2, shapeHeight/2)));
		}

		protected function endRotate(p_evt:MouseEvent):void
		{
			rotateRollOut(p_evt);
			var rotRads:Number = Math.PI*rotation/180;
			_rotCos = Math.cos(rotRads);
			_rotSin = Math.sin(rotRads);
			throwFocus();			
			dispatchEvent(new WBShapeEvent(WBShapeEvent.POSITION_SIZE_ROTATE_END));
		}
		
		protected function trackRotate(p_evt:MouseEvent):void
		{
			var localPoint:Point = parent.globalToLocal(stage.localToGlobal(new Point(p_evt.stageX, p_evt.stageY)));
			var diffX:Number = localPoint.x-_originalPt.x;
			var diffY:Number = localPoint.y-_originalPt.y;
			var rotRads:Number = -Math.atan(diffX/diffY);
			var rotDegs:Number = Math.round(36*rotRads/Math.PI)*5;
			if (diffY>=0) {
				if (diffX>=0) {
					// bottom-right quad
					rotation = 180+rotDegs;
				} else {
					// bottom-left quad
					rotation = -180+rotDegs;
				}
			} else {
				rotation = rotDegs;
			}
			validateNow();
			_rotCos = Math.cos(rotRads);
			_rotSin = Math.sin(rotRads);
			var centerPt:Point = parent.globalToLocal(localToGlobal(new Point(shapeWidth/2, shapeHeight/2)));
			var diffPt:Point = _originalPt.subtract(centerPt);
			moveShape(shapeX+diffPt.x, shapeY+diffPt.y);
			
			dispatchEvent(new WBShapeEvent(WBShapeEvent.ROTATION_CHANGE));
		}

		protected function resizeRollOver(p_evt:MouseEvent):void
		{
			if (cursorManager.currentCursorID==CursorManager.NO_CURSOR) {
				_currentHandle = p_evt.target as UIComponent;
				trackResizeCursor(p_evt);
				_currentHandle.addEventListener(MouseEvent.MOUSE_MOVE, trackResizeCursor);
				stage.addEventListener(MouseEvent.MOUSE_DOWN, beginResize);
				_currentHandle.addEventListener(MouseEvent.ROLL_OUT, resizeRollOut);
			}
		}
		
		protected function resizeRollOut(p_evt:MouseEvent):void
		{
			cursorManager.removeAllCursors();
			clearSizeEvents();
		}
		
		protected function beginResize(p_evt:MouseEvent):void
		{
			clearSizeEvents();
			_currentHandle = p_evt.target as UIComponent;
			_originalPt = globalToLocal(stage.localToGlobal(new Point(p_evt.stageX, p_evt.stageY)));
			stage.addEventListener(MouseEvent.MOUSE_UP, endResize);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, trackResize);
		}

		protected function endResize(p_evt:MouseEvent):void
		{
			resizeRollOut(p_evt);
			throwFocus();
			dispatchEvent(new WBShapeEvent(WBShapeEvent.POSITION_SIZE_ROTATE_END));
		}
		
		protected function trackResizeCursor(p_evt:MouseEvent):void
		{
			cursorManager.removeAllCursors();
			cursorManager.setCursor(_cursorTable[_currentHandle]);
		}

		protected function trackResize(p_evt:MouseEvent):void
		{
			var localPoint:Point = globalToLocal(stage.localToGlobal(new Point(p_evt.stageX, p_evt.stageY)));
			var aspectRatio:Number;
			var oldH:Number;

			var sizeDir:String;
			
			if (_currentHandle==_tLHandle) {
				localPoint.x = Math.min(localPoint.x, shapeWidth-5);
				// constrained aspect ratio - choose the most changed
				aspectRatio = shapeWidth/shapeHeight;
				width = shapeWidth - localPoint.x;
				oldH = shapeHeight;
				height = shapeWidth/aspectRatio;				
				shapeX += localPoint.x*_rotCos - (oldH-shapeHeight)*_rotSin;
				shapeY += (oldH-shapeHeight)*_rotCos + localPoint.x*_rotSin;
				sizeDir = WBShapeEvent.SIZING_BOTH;

			} else if (_currentHandle==_tRHandle) {
				localPoint.x = Math.max(localPoint.x, 5);
				aspectRatio = shapeWidth/shapeHeight;
				width = localPoint.x;
				oldH = shapeHeight;
				height = shapeWidth/aspectRatio;
				shapeY += (oldH-shapeHeight)*_rotCos;
				shapeX -= (oldH-shapeHeight)*_rotSin;
				sizeDir = WBShapeEvent.SIZING_BOTH;
				
			} else if (_currentHandle==_bLHandle) {
				localPoint.x = Math.min(localPoint.x, shapeWidth-5);
				aspectRatio = shapeWidth/shapeHeight;
				width = shapeWidth - localPoint.x;
				height = shapeWidth/aspectRatio;				
				shapeX += localPoint.x*_rotCos;
				shapeY += localPoint.x*_rotSin;
				sizeDir = WBShapeEvent.SIZING_BOTH;

			} else if (_currentHandle==_bRHandle) {
				localPoint.x = Math.max(localPoint.x, 5);
				aspectRatio = shapeWidth/shapeHeight;
				width = localPoint.x;
				height = shapeWidth/aspectRatio;
				sizeDir = WBShapeEvent.SIZING_BOTH;
				
			} else if (_currentHandle==_tMHandle) {
				localPoint.y = Math.min(localPoint.y, shapeHeight-5);
				shapeY += localPoint.y*_rotCos;
				shapeX -= localPoint.y*_rotSin;
				height = shapeHeight - localPoint.y;
				sizeDir = WBShapeEvent.SIZING_HEIGHT;
				
			} else if (_currentHandle==_mRHandle) {
				localPoint.x = Math.max(localPoint.x, 5);
				width = localPoint.x;
				sizeDir = WBShapeEvent.SIZING_WIDTH;
				
			} else if (_currentHandle==_bMHandle) {
				localPoint.y = Math.max(localPoint.y, 5);
				height = localPoint.y;
				sizeDir = WBShapeEvent.SIZING_HEIGHT;

			} else if (_currentHandle==_mLHandle) {
				localPoint.x = Math.min(localPoint.x, shapeWidth-5);
				shapeX += localPoint.x*_rotCos;
				shapeY += localPoint.x*_rotSin;
				width = shapeWidth - localPoint.x;
				sizeDir = WBShapeEvent.SIZING_WIDTH;
			}
			validateNow();

			var evt:WBShapeEvent = new WBShapeEvent(WBShapeEvent.SIZE_CHANGE);
			evt.sizingDirection = sizeDir;
			dispatchEvent(evt);
		}
		
		protected function clearSizeEvents():void
		{
			if (_currentHandle) {
				_currentHandle.removeEventListener(MouseEvent.MOUSE_MOVE, trackResizeCursor);
				_currentHandle.removeEventListener(MouseEvent.ROLL_OUT, resizeRollOut);
			}
			stage.removeEventListener(MouseEvent.MOUSE_UP, endResize);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, trackResize);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, beginResize);
			_currentHandle = null;
		}

		protected function clearRotateEvents():void
		{
			_rotateHandle.removeEventListener(MouseEvent.MOUSE_MOVE, trackRotateCursor);
			_rotateHandle.removeEventListener(MouseEvent.ROLL_OUT, rotateRollOut);
			stage.removeEventListener(MouseEvent.MOUSE_UP, endRotate);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, trackRotate);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, beginRotate);
		}
		
		protected override function moveRollOver(p_evt:MouseEvent):void
		{
			if (_isMoving || !handlesEnabled) {
				return;
			}
			super.moveRollOver(p_evt);
			_hitArea.addEventListener(MouseEvent.MOUSE_DOWN, beginMove);
		}

		
		protected function beginMove(p_evt:MouseEvent=null):void
		{
			if (!handlesEnabled) {
				return;
			}
			if (_dblClickTimer.running) {
				dispatchDoubleClick();
			}
			clearMoveEvents();
			stage.addEventListener(MouseEvent.MOUSE_UP, endMove);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, trackMove);
			_originalPt = parent.globalToLocal(stage.localToGlobal(new Point(stage.mouseX, stage.mouseY))).subtract(new Point(shapeX,shapeY));
		}
		
		protected function trackMove(p_evt:MouseEvent):void
		{
			if (cursorManager.currentCursorID==CursorManager.NO_CURSOR) {
				cursorManager.setCursor(_moveCursor);
			}
			var localPoint:Point = parent.globalToLocal(stage.localToGlobal(new Point(stage.mouseX, stage.mouseY)));
			var ptDiff:Point = localPoint.subtract(_originalPt);

			
			moveShape(ptDiff.x, ptDiff.y);

			move(Math.min(Math.max(0, x), parent.width-width), Math.min(Math.max(0, y), parent.height-height));

			dispatchEvent(new WBShapeEvent(WBShapeEvent.POSITION_CHANGE));
		}
		
		protected function endMove(p_evt:MouseEvent):void
		{
			moveRollOut(p_evt);
			_isMoving = false;
			moveRollOver(p_evt);
			throwFocus();
			dispatchEvent(new WBShapeEvent(WBShapeEvent.POSITION_SIZE_ROTATE_END));
		}
		

		protected override function clearMoveEvents():void
		{
			super.clearMoveEvents();
			stage.removeEventListener(MouseEvent.MOUSE_UP, endMove);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, trackMove);
			_hitArea.removeEventListener(MouseEvent.MOUSE_DOWN, beginMove);
		}
		
		protected function dispatchDoubleClick(p_evt:MouseEvent=null):void
		{
			dispatchEvent(new MouseEvent(MouseEvent.DOUBLE_CLICK));
		}

	}
}