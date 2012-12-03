package
{
	import flash.display.SimpleButton;
	
	/**********************************************************
	 * ADOBE SYSTEMS INCORPORATED
	 * Copyright [2007-2010] Adobe Systems Incorporated
  	 * All Rights Reserved.
	 * NOTICE: Adobe permits you to use, modify, and distribute this file in accordance with the 
	 * terms of the Adobe license agreement accompanying it.If you have received this file from a 
	 * source other than Adobe, then your use, modification, or distribution of it requires the prior 
	 * written permission of Adobe.
	 * *********************************/

	public class CustomSimpleButton extends SimpleButton
	{
		private var upColor:uint   = 0xAFAFAF;
	    private var overColor:uint = 0xAFAFAF;
	    private var downColor:uint = 0xAFAFAF;
	    private var buttonWidth:uint      = 40;
		private var buttonHeight:uint      = 25;

	
	    public function CustomSimpleButton(p_label:String)
	    {
			var cButton:ButtonDisplayState   = new ButtonDisplayState(downColor, buttonWidth, buttonHeight, p_label);
	        overState      = new ButtonDisplayState(downColor, buttonWidth, buttonHeight, p_label,true);
			downState      = overState;
	        upState        = cButton;
	        hitTestState   = overState;
	        useHandCursor  = true;
	    }
		
		public function set label(p_label:String):void
		{
			ButtonDisplayState(overState).label = p_label;
			ButtonDisplayState(upState).label = p_label;
		}
		
		public function get label():String
		{
			return ButtonDisplayState(overState).label;
		}

	}
}