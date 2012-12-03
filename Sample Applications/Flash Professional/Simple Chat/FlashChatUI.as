package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
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

	public class FlashChatUI extends Sprite
	{
		protected var _histTextArea:TextField;
		protected var _inputTextArea:TextField;
		protected var _sendButton:CustomSimpleButton = new CustomSimpleButton("Send");
		protected var _clearButton:CustomSimpleButton = new CustomSimpleButton("Clear");
		protected var _chatWidth:Number;
		protected var _chatHeight:Number;

		public function FlashChatUI(p_width:Number, p_height:Number)
		{
			_histTextArea = new TextField();
			_inputTextArea = new TextField();
			_chatHeight = p_height;
			_chatWidth = p_width;
			positionTextFields();
			addSendButton();
			addClearButton();
		}
		
		public function get histTextArea():TextField
		{
			return _histTextArea;
		}
		
		public function get inputTextArea():TextField
		{
			return _inputTextArea;
		}
		
		public function get sendButton():CustomSimpleButton
		{
			return _sendButton;
		}
		
		public function get clearButton():CustomSimpleButton
		{
			return _clearButton;
		}
		
		protected function positionTextFields():void
		{
			_histTextArea.width = _chatWidth - 5;
			_histTextArea.height = _chatHeight - 30;
			_histTextArea.x = 5;
			_histTextArea.y = 0;
			_histTextArea.backgroundColor = 0xFFFFFF;
			_histTextArea.selectable = false;
			_histTextArea.multiline = true;
			_histTextArea.wordWrap = true;
			_histTextArea.type = TextFieldType.DYNAMIC;
			
			_inputTextArea.width = _chatWidth - 100;
			_inputTextArea.height = 20;
			_inputTextArea.x = 5;
			_inputTextArea.y = _chatHeight - 25;
			_inputTextArea.backgroundColor = 0xFFFFFF;
			_inputTextArea.type = TextFieldType.INPUT;
			
			var format:TextFormat = new TextFormat();
			format.font = "Verdana";
			format.color = 0x000000;
			format.size = 10;
			
			_inputTextArea.defaultTextFormat = format;

			addChild(_histTextArea);
			addChild(_inputTextArea);
			drawWhiteBG(_histTextArea.x, _histTextArea.y, _histTextArea.width, _histTextArea.height);
			drawWhiteBG(_inputTextArea.x, _inputTextArea.y, _inputTextArea.width, _inputTextArea.height);
		}
		
		protected function drawWhiteBG(p_x:uint, p_y:uint, p_width:Number, p_height:Number):void
		{
			graphics.beginFill(0xFFFFFF); 
			graphics.drawRect(p_x, p_y, p_width, p_height);
			graphics.endFill();

		}
		
		protected function addSendButton():void
		{
			_sendButton.x = _inputTextArea.width + 5;
			_sendButton.y = _histTextArea.height + 5;
			addChild(_sendButton);
		}
		
		protected function addClearButton():void
		{
			_clearButton.x = _sendButton.x + _sendButton.width + 5;
			_clearButton.y = _histTextArea.height + 5;
			addChild(_clearButton);
		}
	}
}