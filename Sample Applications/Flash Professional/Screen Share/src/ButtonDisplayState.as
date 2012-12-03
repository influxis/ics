package
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	 /**********************************************************
	  * ADOBE SYSTEMS INCORPORATED
	  * Copyright [2007-2010] Adobe Systems Incorporated
	  * All Rights Reserved.
	  * NOTICE: Adobe permits you to use, modify, and distribute this file in accordance with the 
	  * terms of the Adobe license agreement accompanying it.If you have received this file from a 
	  * source other than Adobe, then your use, modification, or distribution of it requires the prior 
	  * written permission of Adobe.
	  * *********************************/
	
	public class ButtonDisplayState extends Sprite
	{

		protected var _textField:TextField = new TextField();
		protected var rollOverFlag:Boolean = false;
	
	    public function ButtonDisplayState(p_bgColor:uint, p_width:uint, p_height:uint, p_label:String, p_rollOver:Boolean=false)
	    {
	        _textField.backgroundColor = p_bgColor;
	        _textField.width = p_width;
			_textField.textColor = 0xFFFFFF;

			var format:TextFormat = new TextFormat();
			format.font = "Verdana";
			format.color = 0xFFFFFF;
			format.size = 12;
			format.align = TextFormatAlign.CENTER;
			_textField.autoSize = TextFieldAutoSize.CENTER;
			
			_textField.defaultTextFormat = format;
			 
			_textField.text = p_label;
			_textField.height = _textField.textHeight;
			if (p_rollOver) {
				drawBG();
				rollOverFlag = true;
			}
	        draw();
	    }
		
		public function set label(p_label:String):void
		{
			_textField.text = p_label;
		}
		
		public function get label():String
		{
			return _textField.text;
			_textField.height = _textField.textHeight;
		}
		
		protected function drawBG():void
		{
			graphics.clear();
			graphics.beginFill(0x0000FF); 
			graphics.drawRect(0, 0, _textField.width + 5, _textField.height);
			graphics.endFill();
		}

		
	    private function draw():void
	    {
			buttonMode = true;
			mouseChildren = false;
			addChild(_textField);
	    }
	}
}