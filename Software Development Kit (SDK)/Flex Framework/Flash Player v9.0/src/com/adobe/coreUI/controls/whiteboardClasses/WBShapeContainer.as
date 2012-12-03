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
	import mx.core.UIComponent;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.display.GradientType;
	import flash.utils.Dictionary;
	import flash.events.MouseEvent;
	import mx.managers.CursorManager;
	import flash.geom.Point;
	import mx.core.IDeferredInstance;
	import com.adobe.coreUI.events.WBShapeEvent;
	import mx.core.Application;
	import flash.events.Event;
	import mx.effects.Tween;
	import mx.effects.Fade;
	import flash.display.DisplayObjectContainer;
	import com.adobe.coreUI.localization.Localization;

	[Event(name="textEditorCreated", type="com.adobe.events.WBShapeEvent")]

	[Event(name="rotationChange", type="com.adobe.events.WBShapeEvent")]
	[Event(name="positionChange", type="com.adobe.events.WBShapeEvent")]
	[Event(name="sizeChange", type="com.adobe.events.WBShapeEvent")]
	[Event(name="mouseDown", type="flash.events.MouseEvent")]

	[DefaultProperty("deferredComponent")]

	/**
	 * @private
	 */
   public class  WBShapeContainer extends UIComponent
	{

		public var deferredComponent:IDeferredInstance;
		
		protected var _content:WBShapeBase;
		protected var _hitArea:Sprite;
		
		[Embed (source = 'whiteboardAssets/Cursors.swf#MoveCursor')]
		protected var _moveCursor:Class;

		protected var _originalPt:Point;
		
		protected var _rotCos:Number=1;
		protected var _rotSin:Number=0;
		
		protected var _rotation:Number = 0;
		
		protected var _resizable:Boolean = true;
		protected var _hitAreaFade:Fade;

		public function clearAllEvents():void
		{
			clearMoveEvents();
		}

		public function set resizable(p_val:Boolean):void
		{
			if (p_val==_resizable) {
				return;
			}
			_resizable = p_val;
			invalidateDisplayList();
		}
		
		public function get resizable():Boolean
		{
			return _resizable;
		}


		override public function move(p_x:Number, p_y:Number):void
		{
			
			if (_rotation==0) {
				moveShape(p_x, p_y);
			} else {
				if (_rotation>0 && _rotation<=90) {
					moveShape(p_x + _rotSin*shapeHeight, p_y);
				} else if (_rotation>90 && _rotation<=180) {
					moveShape(p_x+width, p_y-_rotCos*shapeHeight);
				} else if (_rotation>-90 && _rotation<=0) {
					moveShape(p_x, p_y-_rotSin*shapeWidth);
				} else if (_rotation>=-180 && _rotation<=-90) {
					moveShape(p_x-_rotCos*shapeWidth, p_y+height);
				}
			}
		}

		public function moveShape(p_x:Number, p_y:Number):void
		{
			super.move(p_x, p_y);
		}

		override public function get x():Number
		{
			if (_rotation==0) {
				return shapeX;
			} else {
				if (_rotation>0 && _rotation<=90) {
					return shapeX - _rotSin*shapeHeight;
				} else if (_rotation>90 && _rotation<=180) {
					return shapeX - width;
				} else if (_rotation>-90 && _rotation<=0) {
					return shapeX;
				} else if (_rotation>=-180 && _rotation<=-90) {
					return shapeX + _rotCos*shapeWidth;
				}
			}
			return 0;
		}

		override public function get width():Number
		{
			if (_rotation==0) {
				return shapeWidth;
			} else {
				if (_rotation>-90 && _rotation<=90) {
					return Math.abs(_rotSin)*shapeHeight + _rotCos*shapeWidth;
				} else { //if (_rotation>90 && _rotation<=180) {
					return Math.abs(_rotSin)*shapeHeight - _rotCos*shapeWidth;
				}
				return 0;
			}
		}

		override public function get y():Number
		{
			if (_rotation==0) {
				return shapeY;
			} else {
				if (_rotation>0 && _rotation<=90) {
					return shapeY;
				} else if (_rotation>90 && _rotation<=180) {
					return shapeY + _rotCos*shapeHeight;
				} else if (_rotation>-90 && _rotation<=0) {
					return shapeY + _rotSin*shapeWidth;
				} else if (_rotation>=-180 && _rotation<=-90) {
					return shapeY - height;
				}
				return 0;
			}
		}
		
		override public function get height():Number
		{
			if (_rotation==0) {
				return shapeHeight;
			} else {
				if (_rotation>-90 && _rotation<=90) {
					return _rotCos*shapeHeight + Math.abs(_rotSin)*shapeWidth;
				} else { //if (_rotation>90 && _rotation<=180) {
					return Math.abs(_rotSin)*shapeWidth - _rotCos*shapeHeight;
				}
				return 0;
			}
		}
		
		override public function set rotation(p_value:Number):void
		{
			_rotation = p_value;
			invalidateDisplayList();
		}
		
		override public function get rotation():Number
		{
			return super.rotation;
		}
		
		public function get shapeX():Number
		{
			return super.x;
		}
		
		public function set shapeX(p_x:Number):void
		{
			super.x = p_x;
		}
		
		public function get shapeY():Number
		{
			return super.y;
		}
		
		public function set shapeY(p_y:Number):void
		{
			super.y = p_y;
		}

		public function get shapeWidth():Number
		{
			return super.width;
		}

		public function get shapeHeight():Number
		{
			return super.height;
		}

		public function set content(p_content:WBShapeBase):void
		{
			_content = p_content;
			invalidateDisplayList();
		}
		
		public function get content():WBShapeBase
		{
			if (deferredComponent && !_content) {
				_content = deferredComponent.getInstance() as WBShapeBase;
				_content.visible = false;
			}
			return _content;
		}
		

		
		
		override protected function createChildren():void
		{
			_hitArea = new Sprite();
			addChild(_hitArea);
			_hitArea.addEventListener(MouseEvent.ROLL_OVER, moveRollOver);
			if (!(this is WBDragHandles)) {
				toolTip = Localization.impl.getString("Double-Click to Add or Edit Text");
			}
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{

			if (deferredComponent && !_content) {
				_content = deferredComponent.getInstance() as WBShapeBase;
				_content.addEventListener(WBShapeEvent.TEXT_EDITOR_CREATE, editorCreated);
			}
			if (_content && !contains(_content)) {
				addChildAt(_content, 0);
				_content.move(0,0);
			}
			if (_content) {
				_content.setActualSize(shapeWidth, shapeHeight);
				_content.validateDisplayList();
			}
			
			if (_rotation!=super.rotation) {
				if (_content) {
					_content.isRotated = (_rotation!=0);
					_content.validateNow();
				}
				super.rotation = _rotation;
				var rotRads:Number = Math.PI*_rotation/180;
				_rotCos = Math.cos(rotRads);
				_rotSin = Math.sin(rotRads);
			}


			_hitArea.graphics.clear();
			_hitArea.graphics.beginFill(0xb9d9f2, 0.1);
			_hitArea.graphics.drawRoundRect(0, 0, shapeWidth, shapeHeight, 10, 10);
			
			_hitArea.alpha = 0;
		}
		
		protected function editorCreated(p_evt:WBShapeEvent):void
		{
			dispatchEvent(p_evt);
		}
		

		protected function moveRollOver(p_evt:MouseEvent):void
		{
			if (cursorManager.currentCursorID==CursorManager.NO_CURSOR) {
				trackMoveCursor(p_evt);
				_hitArea.addEventListener(MouseEvent.MOUSE_MOVE, trackMoveCursor);
				_hitArea.addEventListener(MouseEvent.ROLL_OUT, moveRollOut);
				if (_hitAreaFade) {
					_hitAreaFade.pause();
				}
				_hitAreaFade = new Fade(_hitArea);
				_hitAreaFade.alphaFrom = _hitArea.alpha;
				_hitAreaFade.alphaTo = 1;
				_hitAreaFade.duration = 250;
				_hitAreaFade.play();
			}
		}

		protected function moveRollOut(p_evt:MouseEvent):void
		{
			cursorManager.removeAllCursors();
			clearMoveEvents();
			if (_hitAreaFade) {
				_hitAreaFade.pause();
			}
			_hitAreaFade = new Fade(_hitArea);
			_hitAreaFade.alphaFrom = _hitArea.alpha;
			_hitAreaFade.alphaTo = 0;
			_hitAreaFade.duration = 250;
			_hitAreaFade.play();
		}

		protected function trackMoveCursor(p_evt:MouseEvent):void
		{
			cursorManager.removeAllCursors();
			cursorManager.setCursor(_moveCursor);
		}

		protected function clearMoveEvents():void
		{
			_hitArea.removeEventListener(MouseEvent.MOUSE_MOVE, trackMoveCursor);
			_hitArea.removeEventListener(MouseEvent.ROLL_OUT, moveRollOut);
		}
	}
}