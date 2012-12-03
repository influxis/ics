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

	public class FlashSSPublisherUI extends Sprite
	{
		//protected var _histTextArea:TextField;
		//protected var _inputTextArea:TextField;
		protected var _startSharingButton:CustomSimpleButton = new CustomSimpleButton("Start Screen Sharing");
		protected var _pauseSharingButton:CustomSimpleButton = new CustomSimpleButton("Pause Screen Sharing");
		protected var _stopSharingButton:CustomSimpleButton = new CustomSimpleButton("Stop Screen Sharing");
		protected var _ssWidth:Number;
		protected var _ssHeight:Number;

		public function FlashSSPublisherUI(p_width:Number, p_height:Number)
		{
			_ssHeight = p_height;
			_ssWidth = p_width;
			addStartSharingButton();
			addPauseSharingButton();
			addStopSharingButton();
		}
		
		public function get startSharingButton():CustomSimpleButton
		{
			return _startSharingButton;
		}
		
		public function get pauseSharingButton():CustomSimpleButton
		{
			return _pauseSharingButton;
		}
	
		public function get stopSharingButton():CustomSimpleButton
		{
			return _stopSharingButton;
		}
	
		
		protected function drawWhiteBG(p_x:uint, p_y:uint, p_width:Number, p_height:Number):void
		{
			graphics.beginFill(0xFFFF00); 
			graphics.drawRect(p_x, p_y, p_width, p_height);
			graphics.endFill();

		}
		
		protected function addStartSharingButton():void
		{
			_startSharingButton.x = _ssWidth - _startSharingButton.width - _pauseSharingButton.width/2;
			_startSharingButton.y = _ssHeight + 5;
			addChild(_startSharingButton);
		}
		
		protected function addPauseSharingButton():void
		{
			_pauseSharingButton.x = _startSharingButton.x + _startSharingButton.width + 15;
			_pauseSharingButton.y = _ssHeight + 5;
			addChild(_pauseSharingButton);
		}
		
		protected function addStopSharingButton():void
		{
			_stopSharingButton.x = _pauseSharingButton.x + _pauseSharingButton.width + 15;
			_stopSharingButton.y = _ssHeight + 5;
			addChild(_stopSharingButton);
		}
	}
}