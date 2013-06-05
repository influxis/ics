// ActionScript file
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
package com.adobe.rtc.pods.noteClasses
{
	import mx.controls.Button;
	import flash.events.MouseEvent;
	import com.adobe.coreUI.controls.EditorToolBar;
	import mx.controls.ComboBox;
	import mx.events.FlexEvent;
	import mx.events.DropdownEvent;
	import flash.events.Event;
	import com.adobe.rtc.clientManagers.PlayerCapabilities;
	import com.adobe.rtc.events.NoteEvent;
	import com.adobe.coreUI.localization.Localization;
	import com.adobe.coreUI.localization.ILocalizationManager;
	

	/**
	 * @private
	 */
   public class  NotepodToolBar extends EditorToolBar
    {

    	[Embed(source="../noteAssets/fontSizeDecrease.png")]
 		private var FontSizeDecreaseIcon:Class;

    	[Embed(source="../noteAssets/fontSizeIncrease.png")]
 		private var FontSizeIncreaseIcon:Class;

    	[Embed(source="../noteAssets/save.png")]
 		private var SaveIcon:Class;

    	protected var _showSaveButton:Boolean = false;
    	
    	protected var _increaseFontSize:Button;
    	protected var _decreaseFontSize:Button;
    	protected var _save:Button;
    	    	
    	public function set showSaveButton(p_showIt:Boolean):void
    	{
    		_showSaveButton = p_showIt;
    		//TODO: commitProperties and stuff
    	}
    	
    	public function NotepodToolBar()
    	{
    		super();	
    	}
    	
   		override protected function createChildren():void
    	{
    		super.createChildren();
    		 
    		_showFontSize = false;
    		_showAlign = false;
    		_showUnderline = false;
    		    	
    		if (!_increaseFontSize) {
    			_increaseFontSize = new Button();
    			_increaseFontSize.addEventListener(MouseEvent.CLICK,onIncreaseFontSize);
    			_increaseFontSize.setStyle("icon", FontSizeIncreaseIcon);
    			_increaseFontSize.width = 24;
    			_increaseFontSize.height = 22;
				_increaseFontSize.toolTip = _lm.getString("Grow font");
    		}
    	
    		if ( !_decreaseFontSize ) {
    			_decreaseFontSize = new Button();
    			_decreaseFontSize.addEventListener(MouseEvent.CLICK,onDecreaseFontSize);
    			_decreaseFontSize.setStyle("icon", FontSizeDecreaseIcon);
    			_decreaseFontSize.width = 24;
    			_decreaseFontSize.height = 22;
				_decreaseFontSize.toolTip = _lm.getString("Shrink font");
    		}
    		
    		if ( !_save && _showSaveButton) {
    			_save = new Button();
    			_save.addEventListener(MouseEvent.CLICK,onSaveBtnClick);
    			_save.setStyle("icon", SaveIcon);
    			_save.width = 24;
    			_save.height = 22;
    			_save.toolTip = _lm.getString("Save as Doc");
    		}
    	}

    	protected function onIncreaseFontSize(p_evt:MouseEvent):void
    	{
    		if ( parseInt(_customTextEditor.fontSizeText) > 48 )  {
    			return;
    		}
    			
    		var newSize:Number = parseInt(_customTextEditor.fontSizeText) + 2;
    		_customTextEditor.setTextStyles('size', newSize.toString() );
    		dispatchEvent(new NoteEvent(NoteEvent.INCREASE_FONT));
    	}
    
    	protected function onDecreaseFontSize(p_evt:MouseEvent):void
    	{
			if ( parseInt(_customTextEditor.fontSizeText) < 8 ) {
				return;
			}
			
			var newSize:Number = parseInt(_customTextEditor.fontSizeText) - 2;
    		_customTextEditor.setTextStyles('size', newSize.toString() );
    		dispatchEvent(new NoteEvent(NoteEvent.DECREASE_FONT));
    	}
    	
    	protected function onSaveBtnClick(p_evt:MouseEvent):void
    	{
    		dispatchEvent(new NoteEvent(NoteEvent.SAVE));
    	}
    	
    	override protected function commitProperties():void
    	{
    		if (_increaseFontSize ) {
    			_toolsContainer.addChild(_increaseFontSize);
    		}
    		
    		if (_decreaseFontSize ) {
    			_toolsContainer.addChild(_decreaseFontSize);
    		}
    		
    		super.commitProperties();
    		
    		if ( _save ) {
    			_toolsContainer.addChild(_save);
    		}
    	}
    
    	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth,unscaledHeight);
			_toolsContainer.setActualSize(unscaledWidth, unscaledHeight);			 
		}
	
    }
    
}