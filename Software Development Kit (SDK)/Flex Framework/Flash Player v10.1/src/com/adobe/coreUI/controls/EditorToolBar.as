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
package com.adobe.coreUI.controls
{
	import com.adobe.coreUI.controls.ToolBar;
    import com.adobe.coreUI.controls.CustomTextEditor;
    import flash.events.Event;
    import mx.events.FlexEvent;
    import flash.events.FocusEvent;
    import mx.events.DropdownEvent;
    import flash.events.MouseEvent;
    import mx.events.ItemClickEvent;
    import mx.collections.ArrayCollection;
    
    /**
    * @private
    * This is the Editor ToolBar Component <br>
    * <ul>
     * <li>This class extends toolBar  It has a property that can set a customTextEditor This class listens to 
     * the property change events of the bindable variables of the ToolBar</li>
     * <li>The variables of ToolBar like _boldButton, _italicButton, _underlineButton and Alignment are inherited 
     * in it from the ToolBar</li>
     * <li> Whenever any of the toolBar Buttons is clicked , it changes the selection and sets the TextStyles in
     * our editor </li>
     * <li>Similarly, anywhere when the caretIndex is changed or the text is changed in the editor , it listens to the
     * editor and then sets the values to the control buttons of ToolBar </li>
     * </ul>
     * @inheritDocs com.adobe.rtc.ui.ToolBar
	 * @see author Hironmay Basu 
     */ 
   public class  EditorToolBar extends ToolBar
    {	 
    	/**
    	 * @private
    	 * We have a property to set the editor
    	 */
    	protected var _customTextEditor:CustomTextEditor;
    	/**
    	 * Constructor for this class
    	 */
    	public function EditorToolBar()
    	{
    		super();	
    		
    	}
    	/**
    	 * Setter for the textEditor.It sets the textEditor and then adds the
    	 * eventlistener for change
    	 */
    	public function set textEditor(p_editor:CustomTextEditor):void
    	{
    		if (p_editor) {
    			_customTextEditor=p_editor;
    			_customTextEditor.addEventListener("change",propertyChanageHandler);
    			invalidateProperties();
    		}else {
    			throw new Error("EditorToolBar.textEditor : Editor cannot be set as it is null");
    		}
    	}
    	
    	
    	/**
    	 * @private
    	 * Getter for the textEditor
    	 */ 
    	public function get textEditor():CustomTextEditor
    	{
    		return _customTextEditor;
    	}
    	/**
    	 * @private
    	 * Click Handler for all the buttons
    	 * and then it sets the TextStyles.
    	 * 
    	 */
    	protected function editorToolBar_clickHandler(event:Event):void
    	{
    		if(event.currentTarget==_boldButton){
    			_boldButton.selected=!_boldButton.selected;
    			textEditor.setTextStyles('bold',event.currentTarget.selected);
    		}
    		else if(event.currentTarget==_italicButton){
    			_italicButton.selected=!_italicButton.selected;
    			textEditor.setTextStyles('italic', event.currentTarget.selected);
    		}
    		else if(event.currentTarget==_underlineButton){
    			_underlineButton.selected=!_underlineButton.selected;
    			textEditor.setTextStyles('underline', event.currentTarget.selected);
    		}
    		else if(event.currentTarget==_bulletButton){
    			_bulletButton.selected=!_bulletButton.selected;
    			textEditor.setTextStyles('bullet', event.currentTarget.selected);
    		}
    		else if(event.currentTarget==_alignButtonBar){
    			if(event.currentTarget.selectedIndex==0){
    				textEditor.setTextStyles('align',"left");
    			}
    			else if(event.currentTarget.selectedIndex==1){
    				textEditor.setTextStyles('align',"center");
    			}
    			else if(event.currentTarget.selectedIndex==2){
    				textEditor.setTextStyles('align',"right");
    			}
    		}
    		dispatchEvent( new FlexEvent(FlexEvent.VALUE_COMMIT));
    		
    	}
    	
    	protected function getFontSizeAt(p_index:uint):uint
    	{
    		if (_sizeComboBox.dataProvider[p_index].hasOwnProperty("data")) {
    			return _sizeComboBox.dataProvider[p_index].data;
    		} else {
    			return _sizeComboBox.dataProvider[p_index];
    		}
    	}
    	protected function getSelectedFontSize():uint
    	{
    		return getFontSizeAt(_sizeComboBox.selectedIndex);
    	}
    	
    	/**
    	 * @private
    	 * Enter handlers for various targets
    	 * @param event
    	 * 
    	 */    	
    	protected function editorToolBar_enterHandler(event:Event):void
    	{
    		if(event.target == _sizeComboBox ) {
    			textEditor.setTextStyles('size', getSelectedFontSize());
    		}
    		if( event.target == _fontTypeComboBox ) {
    			textEditor.setTextStyles( 'font',_fontTypeComboBox.text );
    		}
    	}
    	/**
    	 * @private
    	 * Click Handler for the _colorPicker. It changes the selection change of the color 
    	 * and it sets the color
    	 */
    	protected function editorToolBar_closeHandler(event:Event):void
    	{
    		if( event.target == _colorPicker ) {
    			textEditor.setTextStyles('color', _colorPicker.selectedColor);	
    			dispatchEvent(new DropdownEvent(DropdownEvent.CLOSE));
    		} 
    		if ( event.target == _sizeComboBox ){
    			textEditor.setTextStyles('size', getSelectedFontSize());
    		}
    		if ( event.target == _fontTypeComboBox ){
    			textEditor.setTextStyles('font',_fontTypeComboBox.text);
    		}
    		
    		dispatchEvent( new FlexEvent(FlexEvent.VALUE_COMMIT));
    	}
    	
    	
    	protected function editorToolBar_openHandler(event:DropdownEvent):void
    	{
    		if (event.target == _colorPicker ) {
    			dispatchEvent(new DropdownEvent(DropdownEvent.OPEN));
    		}
    	}
    	
    	/**
    	 * @private
    	 * Catches the property change of the handler and passes on the values from the editor to
    	 * the control buttons.
    	 */
    	protected function propertyChanageHandler(event:Event=null):void
    	{
    		if(_boldButton){
    			_boldButton.selected=_customTextEditor.boldSelected;
    		}
    		if(_italicButton){
    			_italicButton.selected=_customTextEditor.italicSelected;
    		}
    		if(_underlineButton){
    			_underlineButton.selected=_customTextEditor.underlineSelected;
    		}
    		if(_colorPicker){
    			_colorPicker.selectedColor=_customTextEditor.colorSelected;
    		}
    		if(_bulletButton){
    			_bulletButton.selected=_customTextEditor.bulletButtonSelected;
    		}
    		if(_alignButtonBar){
       			_alignButtonBar.selectedIndex = _customTextEditor.alignButtonsSelectedIndex;
    		}
    		if(_sizeComboBox){
    			for ( var i:int=0; i< _sizeComboBox.dataProvider.length; i++){
    				if (getFontSizeAt(i) == Number(_customTextEditor.fontSizeText))
    				{
    					_sizeComboBox.selectedIndex = i;
    					break;
    				}
    			}
    		}
    		if(_fontTypeComboBox){
    			for ( i=0; i< _fontTypeComboBox.dataProvider.length; i++){
    				if ( _fontTypeComboBox.dataProvider.getItemAt(i)== _customTextEditor.fontType ){
    					_fontTypeComboBox.selectedIndex = i;
    					break;
    				}
    			}
    		}
    		
    	}
    
    	/**
    	 * @private
    	 * Creating the toolBar and its control buttons and then addind the event listeners
    	 */ 
    	override protected function createChildren():void
    	{
    		super.createChildren();	
    		_boldButton.addEventListener("click",editorToolBar_clickHandler);
    		_italicButton.addEventListener("click",editorToolBar_clickHandler);
    		
    	}
    	
    	override protected function commitProperties():void
    	{
    		super.commitProperties();
    		
    		if (_underlineButton) {
	    		_underlineButton.addEventListener("click",editorToolBar_clickHandler);
	    	}

    		if (_sizeComboBox) {
    			_sizeComboBox.removeEventListener(DropdownEvent.CLOSE, editorToolBar_closeHandler);
    			_sizeComboBox.addEventListener(DropdownEvent.CLOSE, editorToolBar_closeHandler);
    			_sizeComboBox.removeEventListener(FlexEvent.ENTER, editorToolBar_enterHandler);
    			_sizeComboBox.addEventListener(FlexEvent.ENTER, editorToolBar_enterHandler);
    		}    		
    		if ( _fontTypeComboBox ) {
    			_fontTypeComboBox.removeEventListener(DropdownEvent.CLOSE,editorToolBar_closeHandler);
    			_fontTypeComboBox.addEventListener(DropdownEvent.CLOSE,editorToolBar_closeHandler);
    			_fontTypeComboBox.removeEventListener(FlexEvent.ENTER,editorToolBar_enterHandler);
    			_fontTypeComboBox.addEventListener(FlexEvent.ENTER,editorToolBar_enterHandler);
    		}

    		if (_bulletButton) {
	    		_bulletButton.removeEventListener(MouseEvent.CLICK, editorToolBar_clickHandler);
	    		_bulletButton.addEventListener(MouseEvent.CLICK, editorToolBar_clickHandler);
	    	}
	    	if (_colorPicker) {
	    		_colorPicker.removeEventListener(DropdownEvent.CLOSE, editorToolBar_closeHandler);
	    		_colorPicker.removeEventListener(DropdownEvent.OPEN,editorToolBar_openHandler);
	    		_colorPicker.addEventListener(DropdownEvent.CLOSE, editorToolBar_closeHandler);
	    		_colorPicker.addEventListener(DropdownEvent.OPEN,editorToolBar_openHandler);
	    	}
	    	if (_alignButtonBar) {
	    		_alignButtonBar.removeEventListener(ItemClickEvent.ITEM_CLICK, editorToolBar_clickHandler);
	    		_alignButtonBar.addEventListener(ItemClickEvent.ITEM_CLICK, editorToolBar_clickHandler);
	    	}
	    	
	    	propertyChanageHandler();
    	}
    	
    }
}