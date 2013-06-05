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
package com.adobe.rtc.collaboration.sharedCursorClasses
{
	import mx.core.UIComponent;
	import mx.effects.Move;
	import mx.effects.Blur;
	import mx.effects.Fade;
	import flash.display.DisplayObject;
	import mx.core.UITextField;
	import flash.display.Graphics;
	import mx.effects.easing.Linear;
	import mx.events.EffectEvent;

	/**
	 * @private
	 */
	
   public class  RemoteUserCursor extends UIComponent
	{

		protected var _cursorClass:Class;
		protected var _displayName:String;
		protected var _moveEffect:Move;
		protected var _blurEffect:Blur;
		protected var _fadeEffect:Fade;
		protected var _cursor:DisplayObject;
		protected var _labelField:UITextField;
		
		protected static const LABEL_PADDING:int = 3;
		protected static const MOVE_DURATION:int = 500;
		protected static const REVEAL_DURATION:int = 250;
		protected static const HIDE_DURATION:int = 500;
		
		public function set cursorClass(p_class:Class):void
		{
			_cursorClass = p_class;
			invalidateDisplayList();
		}
		
		public function get cursorClass():Class
		{
			return _cursorClass;
		}
		
		public function get displayName():String
		{
			return _displayName;
		}
		
		public function set displayName(p_name:String):void
		{
			_displayName = p_name;
			invalidateDisplayList();
		}
		

		public function reveal():void
		{
			_blurEffect = new Blur(this);
			_blurEffect.blurXFrom = 5;
			_blurEffect.blurYFrom = 5;
			_blurEffect.blurXTo = 0;
			_blurEffect.blurYTo = 0;
			_blurEffect.duration = REVEAL_DURATION;
			_blurEffect.play();
			_fadeEffect = new Fade(this);
			_fadeEffect.alphaFrom = 0;
			_fadeEffect.alphaTo = 1;
			_fadeEffect.duration = REVEAL_DURATION;
			_fadeEffect.play();
		}
		
		public function hide():void
		{
			_blurEffect = new Blur(this);
			_blurEffect.blurXFrom = 0;
			_blurEffect.blurYFrom = 0;
			_blurEffect.blurXTo = 5;
			_blurEffect.blurYTo = 5;
			_blurEffect.duration = HIDE_DURATION;
			_blurEffect.play();
			_fadeEffect = new Fade(this);
			_fadeEffect.alphaFrom = 1;
			_fadeEffect.alphaTo = 0;
			_fadeEffect.duration = HIDE_DURATION;
			_fadeEffect.play();
			_fadeEffect.addEventListener(EffectEvent.EFFECT_END, onFadeOut);
		}
		
		protected function onFadeOut(p_evt:EffectEvent):void
		{
			parent.removeChild(this);
		}
		
		public function moveTo(p_x:int, p_y:int):void
		{
			if (_moveEffect && _moveEffect.isPlaying) {
				_moveEffect.pause();
			}
//			if (!_moveEffect) {
				_moveEffect = new Move(this);
//			}
			_moveEffect.duration = MOVE_DURATION;
			_moveEffect.xFrom = x;
			_moveEffect.yFrom = y;
			_moveEffect.xTo = p_x;
			_moveEffect.yTo = p_y;
			
			_moveEffect.play();
		}
		
		override protected function createChildren():void
		{
			_labelField = new UITextField();
			addChild(_labelField);
		}
		
		override protected function updateDisplayList(p_w:Number, p_h:Number):void
		{
			if (!(_cursor is _cursorClass)) {
				if (_cursor) {
					removeChild(_cursor);
				}
				_cursor = new _cursorClass() as DisplayObject;
				addChild(_cursor);
			}
			if (_displayName!=_labelField.text) {
				_labelField.text = _displayName;
				_labelField.setActualSize(_labelField.textWidth+4, _labelField.textHeight+4);
				_labelField.move(Math.round((_cursor.width-_labelField.width)/2), _cursor.height + LABEL_PADDING);
				var g:Graphics = graphics;
				g.clear();
				g.lineStyle(1, 0xeaeaea, 0.6);
				g.beginFill(0xeaeaea, 0.4);
				g.drawRect(_labelField.x, _labelField.y, _labelField.width, _labelField.height);
			}
		}
		
	}
}