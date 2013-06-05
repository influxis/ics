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
		import flash.events.Event;
		import flash.events.KeyboardEvent;
		import flash.events.MouseEvent;
		import flash.text.TextFormat;
		import flash.ui.Keyboard;
		
		import mx.controls.textClasses.TextRange;
		import mx.core.IUITextField;
		import mx.core.ScrollPolicy;
		import mx.core.mx_internal;
		import mx.events.FlexEvent;
		
		use namespace mx_internal;
		
		/**
		 * @private
		 * This is the rich text editor component <br>
		 * <ul>
		 * <li> This class is the implementation of the text Editor  It has a child as text Area and set of bindable variables 
		 * that contains values like type of font , bold/italic/Underline, also font size , the alignment and other information </li>
		 * <li>We can add all the controls from an mxml file or actionscript class that can bind the variables here</li>
		 * <li>This class is a subclass of EmoticonTextEditor which contains a textArea and can display
		 * emoticons</li>
		 * <li>This class adds all control features like alignment,font size and font type 
		 * The setTextStyle and getTextStyle are the main functions adding these features</li>
		 * <li>It uses the textField and the textFormat to establish these features</li>
		 * </ul>
		 * 
		 * @inheritDocs com.adobe.rtc.ui.CustomTextEditor
	 	 * @see author Hironmay Basu 
		 */
   public class  CustomTextEditor extends RichTextArea
		{	
			/**
			 * Bindable variable boldSelected gives whether the text is bold .
			 */
			[Bindable(event="change")]
			[Inspectable(defaultValue="false")]
			public var boldSelected:Boolean;
			
			/**
			 * Bindable variable italicSelected gives whether the text is italic .
			 */
			[Bindable(event="change")]
			[Inspectable(defaultValue="false")]
			public var italicSelected:Boolean;
			
			/**
			 * Bindable variable underlineSelected gives whether the text is underline .
			 */
			[Bindable(event="change")]
			[Inspectable(defaultValue="false")]
			public var underlineSelected:Boolean;
			
			/**
			 * Bindable variable bulletButtonSelected gives whether the text is bulleted or not .
			 */
			[Bindable(event="change")]
			[Inspectable(defaultValue="false")]
			public var bulletButtonSelected:Boolean;
			
			/**
			 * Bindable variable colorSelectd gives the color of the selected text .
			 */
			[Bindable(event="change")]
			[Inspectable(category="General")]
			public var colorSelected:Number;
			/**
			 * It gives the index of alingnedButtonIndex , it is 0 for left, 1 for middle , 2 for right and 3 for justify
			 */
			[Bindable(event="change")]
			[Inspectable(category="General")]
			public var alignButtonsSelectedIndex:Number=0;
			
			/**
			 * Bindable variable fontSizeText which gives the size of the font.
			 */
			[Bindable(event="change")]
			[Inspectable(category="General")]
			public var fontSizeText:String;
			
			/**
			 * Bindable variable fontType gives which is the type of font i.e. verdana/arial/timesNew Roman etc  .
			 */
			[Bindable(event="change")]
			[Inspectable(category="General")]
			public var fontType:String;

			protected var _textFormatChanged:Boolean = false;
				
			/**
			 *@private
			 * Private variable for keeping changedText
			 */
			protected var _textChanged:Boolean = false;
			 /**
			 *@private
			 * Private variable for keeping changedText
			 */ 
			protected var _htmlTextChanged:Boolean = false;
			/**
			 *@private
			 * Private variable for keeping previousTextFormat
			 */
			protected var _previousTextFormat:TextFormat = null;
			
			/**
			 *  -1 is used to force updation of the ToolBar styles
			 */
			protected var _lastCaretIndex:int = -1;
			/**
			 * @private
			 * Variable for invalidating ToolBar
			 */
			protected var _invalidateToolBarFlag:Boolean = false;
			
			
			protected var _defaultTextFormatChanged:Boolean = false ;
			protected var _defaultTextFormat:TextFormat ;
			protected var _textFormatCommited:Boolean = false;
			
			/**
			 * @private
			 * Flex internal values, variable for the text 
			 */
			 private var _text:String = "";	
			
			/**
			 * @private
			 * Flex internal values, variable for the htmltext 
			 */
			private var _htmlText:String = "";
			protected var _copiedText:String = "" ;
			
			public function CustomTextEditor()
			{
				super();
				restrict = "^\x18\x19\x15\x02";//\x2";
				addEventListener(Event.CHANGE, onChange_CustomTextEditor);
				addEventListener(MouseEvent.MOUSE_UP,systemManager_mouseUpHandler);
				addEventListener(MouseEvent.MOUSE_DOWN, onClick);
			}	


    		//----------------------------------
    		//  selection
    		//----------------------------------

			/**
     		*  The selected text.
     		*/
			public function get selection():TextRange
			{
				return new TextRange(this, true);
			}

    		/**
    		 * Property for Text 
    		 */
			[Bindable("valueCommit")]
			[CollapseWhiteSpace]
			[NonCommittingChangeEvent("change")]
			[Inspectable(category="General")]
			override public function get text():String
			{
				return super.text;
			}
			/**
			 * @private
			 * @param value
			 * 
			 */			
			override public function set text(value:String):void
			{
				super.text= value;
				_text=value;
				_textChanged = true;	
				invalidateProperties();	
				
			}

			/**
			 * Property for htmlText
			 */		
			[Bindable("valueCommit")]
			[CollapseWhiteSpace]
			[NonCommittingChangeEvent("change")]
			[Inspectable(category="General")]
			override public function get htmlText():String
			{
				return super.htmlText;
			}
			/**
			 * @private
			 * @param value
			 * 
			 */			
			override public function set htmlText(value:String):void
			{
				super.htmlText = value;
				_htmlText=value;
				_htmlTextChanged = true;
				invalidateProperties();
			}
			
			/**
			 * @private
			 * 
			 */
			public function removeAndAddTextField():void
			{
				//Hack to render HTMLText properly. 
				//Warning - If this method is used then the TextAreas properties are reset.
				mx_internal::removeTextField();
				mx_internal::createTextField(-1);
			}

			/**
			 * @private
			 * Getter and Setter function for editable Property
			 */
			override public function get editable():Boolean
			{
				return super.editable;
			}
			/**
			 *  Editable property
			 * @param p_editable
			 * 
			 */			
			override public function set editable(p_editable:Boolean):void
			{
				super.editable=p_editable;
			}
			
				
			[Inspectable(category="General", defaultValue="true")]
			/**
			 * @private
			 * @return 
			 * 
			 */			
		
			/**
			* @private
			 * Variable indicating multiline
			*/			
			protected var _multiLine:Boolean = true ;
			/**
			 * MultiLine Property
			 * @return 
			 * 
			 */			
			public function get multiline():Boolean
			{
				return _multiLine;	
			}
			
			/**
			 * @private
			 * @param p_multiline
			 * 
			 */			
			public function set multiline(p_multiLine:Boolean):void
			{
				if ( p_multiLine == _multiLine) {
					return;
				}
				
				_multiLine = p_multiLine ;
				invalidateProperties();
			}
			
			public function get editorTextField():IUITextField
			{
				return textField;
			}
						
			
			/**
			 * gets the current caret index
			 * @return 
			 * 
			 */			
			public function get caretIndex():Number 
			{
				return textField.caretIndex;
			} 

			public function set defaultTextFormat(p_tf:TextFormat):void
			{
				_defaultTextFormat = p_tf;
				_defaultTextFormatChanged = true  ;
				invalidateProperties();
			}
			
			
			
			public function deleteText():void
			{
				//textField.replaceSelectedText("");
				textField.replaceText(textField.selectionBeginIndex, textField.selectionEndIndex, "");
				super.htmlText = textField.htmlText;
				_htmlText = textField.htmlText;
				_htmlTextChanged = true;
				invalidateProperties();
				dispatchEvent(new Event(Event.CHANGE));				
			}
			
			public function selectAllText():void
			{
				textField.setSelection(0,textField.length);
			}
			
			/**
			 * Function to replace some html Text at the current caret index
			 * @param p_text
			 * 
			 */			
			public function replaceText(p_text:String):void
			{
				textField.replaceText(caretIndex,caretIndex,p_text);	
				super.htmlText = textField.htmlText;
				_htmlText = textField.htmlText;
				_htmlTextChanged = true;
				invalidateProperties();
			}
			
			
			
		    /**
		     *  @private
		     */
		    override protected function keyDownHandler(event:KeyboardEvent):void
		    {
		        switch (event.keyCode)
		        {
		            case Keyboard.ENTER:
		            {
		                if (!multiline) {
							dispatchEvent(new FlexEvent(FlexEvent.ENTER));
						} else {
							if (textField.length -1 > -1 && _previousTextFormat && _textFormatCommited) {
								textField.setTextFormat(_previousTextFormat,textField.length -1);
								textField.defaultTextFormat = _previousTextFormat;
								_textFormatCommited = false;
							}
						}
		                break;
		            }
		        }

				if (_multiLine) {
		    		return;
		    	}
		    	
		    }
		
			override protected function keyUpHandler(event:KeyboardEvent):void
			{
					if (event.ctrlKey) {//if one presses the ctrl key
						switch (event.charCode) {
							case 66:
							case 98:
								setTextStyles('bold',!boldSelected);
								break;
							case 73:
							case 105: 
								setTextStyles('italic',!italicSelected);
								break;
							case 85:
							case 117:
								setTextStyles('underline',!underlineSelected);
								break;
						}
					}
			}
						
			/**
			 * @private
			 * The event listener for the textArea on keyDown , it checks whether the the format is same , then updates the textFormat
			 */ 
			protected function onChange_CustomTextEditor(event:Event):void
			{
				if (_textFormatChanged) {
				 	textField.defaultTextFormat = _previousTextFormat;
					if (textField.selectionBeginIndex == textField.selectionEndIndex && (textField.text.charAt(textField.length -1) == " " || textField.text.charAt(textField.length -1) == "\r")) {
						var length:int = (textField.text.charAt(textField.length -1) == "\r") ? hackedTextLength(textField.text) : textField.length -1;
						if (textField.text.substr(length -1) == " \r") {
							textField.setTextFormat(_previousTextFormat, length-1);
						} else {
							textField.setTextFormat(_previousTextFormat, length);
						}
						textField.defaultTextFormat = _previousTextFormat;
						_textFormatCommited = true;
					}
				 	if ( !bulletButtonSelected ) {
				 		textField.defaultTextFormat.bullet = false ;
				 	}
				 	_textFormatChanged = false;
				}
			}
			
			protected function onClick(event:MouseEvent):void 
			{
				getTextStyles();
				dispatchEvent(new Event(Event.CHANGE));
			}
			
		
			/**
			 * Overridding the createChilden of UIComponent , we add the textArea as a child here 
			 * and then set the textAreaStyleName and make the alwaysShowSelection as true for the textArea's textField
			 */ 
			override protected function createChildren():void
			{
				super.createChildren();
				var textAreaStyleName:String = getStyle("textAreaStyleName");
				if (textAreaStyleName)
					styleName = textAreaStyleName;
				textField.alwaysShowSelection = true;
	            textField.addEventListener("textFormatChange", onTextFormatChange);
			}

			protected function onTextFormatChange(p_evt:Event):void
			{
				dispatchEvent(p_evt);
			}
			
			
			

			/**
			 * Overriding the commitProperties, it checks whether the text or the HtmlText has changed and updates 
			 * the textField of the textArea accordingly
			 */
			override protected function commitProperties():void
			{
				// Because of Internal call of handlers , the scrollposition was getting reset when we set the
				//htmltext
				var oldVerticalScrollPos:Number = verticalScrollPosition ;
				var oldHorizontalScrollPos:Number = horizontalScrollPosition ;
				
				super.commitProperties();
				
				if ( _defaultTextFormatChanged ) {
					_defaultTextFormatChanged = false ;
					textField.defaultTextFormat = _defaultTextFormat ;
				}
				
				if ( textField.multiline != _multiLine ) {
					textField.multiline = _multiLine ;
					if ( _multiLine ) {
						verticalScrollPolicy = ScrollPolicy.AUTO ;
						wordWrap = true ;
					} else {
						verticalScrollPolicy = ScrollPolicy.OFF ;
						wordWrap = false;
					}
				}
				
				if (_textChanged || _htmlTextChanged){
					
					if ( _previousTextFormat != null ) {
						var tf:TextFormat = _previousTextFormat;
						textField.defaultTextFormat = tf;
					}
					if (_textChanged){
						if(_text !== null)
						 super.text = _text;
						_textChanged = false;
					}
					else{
						//Why are we setting this again!!?!?!??
						/*if (_htmlText !== null){
							super.htmlText = _htmlText;
						}*/
						_htmlTextChanged = false;
						
					}
					
					
				}
				if ( !bulletButtonSelected )
					textField.defaultTextFormat.bullet = false;
				// We again take the vertical and horizontal scroll position back ...
				verticalScrollPosition = oldVerticalScrollPos ;
				horizontalScrollPosition = oldHorizontalScrollPos ;
				
			}
		
			/**
	 		*when the style has changed, this function is called 
	 		*/
			override public function styleChanged(styleProp:String):void
			{
				super.styleChanged(styleProp);
				
				
				if (styleProp == null || styleProp == "textAreaStyleName"){
					var textAreaStyleName:String = getStyle("textAreaStyleName");
					styleName = textAreaStyleName;
				}
				
				// when we are setting background alphas on maximizing/minimizing , we do not want to call the getTextStyle
				
				
				if (!_invalidateToolBarFlag){
					_invalidateToolBarFlag = true;
					callLater(getTextStyles);
				}
			}

			
			/**
			 * This along with getTextStyles are the most important function. It takes two arguements
			 * the type of change and the value. The type will be font/size/align/bold/italic and type is the actual size/font/alignment
			 * we create a textFormat  and see which of the styles have changed. This function is called when we press any bottom like
			 * bold/italic/underline or when we select a particular alignment or when we select bullet , a different fornt size of type
			 * This acts as setStyles for any such changes
			 */

			public function setTextStyles(type:String, value:Object = null, keepFocus:Boolean = true):void
			{
				var tf:TextFormat;
				var beginIndex:int = textField.selectionBeginIndex;
				var endIndex:int = textField.selectionEndIndex;
				
				if (beginIndex == endIndex && _previousTextFormat!=null){
					// If we have not done anything and begin index is same as end index, then revert to previous format
					tf = _previousTextFormat;
				}
				else {	
					tf = new TextFormat(); // otherwise create the new format
				}
				
				// If we  have modified(clicked ) the bold, italic or underline button, then depending on button clicked , change the button's state and update the text format
				if (type == "bold" || type == "italic" || type == "underline"){
					tf[type] = value;
					if( type == "bold" ) {
						// if its bold
						boldSelected = value;
					}
					else if (type == "italic" ) {
						// if its italic
						italicSelected=value;
					}
					else if ( type =="underline" ) {
						// if its underline
						underlineSelected=value;
					}
				}
				else if (type == "align" || type == "bullet"){
					// since alignment and bulleting are applied even without the change in index
					if (beginIndex == endIndex){
						tf = new TextFormat();
					}
					beginIndex = textField.getFirstCharInParagraph(beginIndex) - 1;
					beginIndex = Math.max(0, beginIndex);
					endIndex = textField.getFirstCharInParagraph(endIndex) +
					textField.getParagraphLength(endIndex) - 1;
					tf[type] = value;
					if(type=="bullet"){
						bulletButtonSelected=value;
					}
					else{
						if(value=="left")
							alignButtonsSelectedIndex=0;
						else if(value=="center")
							alignButtonsSelectedIndex=1;
						else if(value=="right")
							alignButtonsSelectedIndex=2;	
					}
					_previousTextFormat[type] = value;
					if (!endIndex)
						textField.defaultTextFormat = tf;
				}
				else if (type == "font"){
					// If the font has been changed , like arial to times Roman
					tf[type] = value;
					fontType=value.toString();
				}
				else if (type == "size"){
					// if the size of font has been changed 
					fontSizeText=value.toString();
					var fontSize:uint = uint(value);
					if (fontSize > 0)
						tf[type] = fontSize;
				}
				else if (type == "color"){
					tf[type] = uint(value);
					colorSelected=uint(value);
				}
			
				_textFormatChanged = true;
				if (beginIndex == endIndex){
					_previousTextFormat = tf;
				}
				else {
					if (textField.length >= endIndex) { 
						textField.setTextFormat(tf, beginIndex, endIndex);
						_previousTextFormat = textField.getTextFormat(beginIndex,endIndex);
					}
				}
				dispatchEvent(new Event(Event.CHANGE));
				var caretIndex:int = textField.caretIndex;
				var lineIndex:int =	textField.getLineIndexOfChar(caretIndex);
				invalidateDisplayList();
				validateDisplayList();
				// Scroll to make the line containing the caret under viewable area
				while (lineIndex >= textField.bottomScrollV){
					verticalScrollPosition++;
				}
				if(keepFocus)
					callLater(this.setFocus); // for details of call Focus, see UI Component
			}


			/**
			 * This function gives the TextStyles, the font size, type , alignment bulleting etc. All the bindable values declared are 
			 * set here. When we move different parts of the text, this function gets called and we get the state of values 
			 * of those variables. For eg. if any font is italic , if we take the cursor there, the italic button is highlighted
			 * indicating the text next to cursor is italic
			 * 
			 */ 
			public function getTextStyles():TextFormat
			{
				var tf:TextFormat;
				var beginIndex:int = textField.selectionBeginIndex;
				var endIndex:int = textField.selectionEndIndex; 
			
				if (_textFormatChanged )
					_previousTextFormat = null;
				if (beginIndex == endIndex ){
					if ( !_defaultTextFormatChanged ) {
						tf = textField.defaultTextFormat;
					}else {
						tf = _defaultTextFormat ;
					}
					
					if (tf.url != ""){
						var carIndex:int = textField.caretIndex;
						if (carIndex < textField.length){
							var tfNext:TextFormat=textField.getTextFormat(carIndex, carIndex + 1);
							if (!tfNext.url || tfNext.url == "")
								tf.url = tf.target = "";
						}
						else
							tf.url = tf.target = ""; 
					}
				}
				else
					tf = textField.getTextFormat(beginIndex,endIndex);
				if (!_previousTextFormat || _previousTextFormat.font != tf.font){
					if(tf.font!=null){
						fontType=tf.font;
					}
					else{
						fontType="";
					}
				}
				if (!_previousTextFormat || _previousTextFormat.size != tf.size){
					if(tf.size!=null){
						fontSizeText=String(tf.size);
					}
					else
						fontSizeText="";
				}		
				if (!_previousTextFormat || _previousTextFormat.color != tf.color)
					colorSelected = Number(tf.color);
				if (!_previousTextFormat || _previousTextFormat.bold != tf.bold)
					boldSelected = tf.bold;
				if (!_previousTextFormat || _previousTextFormat.italic != tf.italic)
					italicSelected = tf.italic;
				if (!_previousTextFormat || _previousTextFormat.underline != tf.underline)
					underlineSelected = tf.underline;
				if (!_previousTextFormat || _previousTextFormat.align != tf.align){
					if (tf.align == "left")
						alignButtonsSelectedIndex = 0;
					else if (tf.align == "center")
						alignButtonsSelectedIndex = 1;
					else if (tf.align == "right")
						alignButtonsSelectedIndex = 2;
					else if (tf.align == "justify")
						alignButtonsSelectedIndex = 3;
				}
				
				if (!_previousTextFormat || _previousTextFormat.bullet != tf.bullet) {
					bulletButtonSelected = tf.bullet;
				}
				if (textField.defaultTextFormat != tf) {
					textField.defaultTextFormat = tf;
				}
				_previousTextFormat = tf;
				_textFormatChanged = false;
				_lastCaretIndex = textField.caretIndex;
				_invalidateToolBarFlag = false;
				
				if ( !bulletButtonSelected ) {
					tf.bullet = false ;
				}
				
				return tf;
			}
	
			/**
	 		*  @private
	 		*  This method is called when the user clicks on the textArea, drags
	 		*  out of it and releases the mouse button outside the TextArea.
	 		*/
			private function systemManager_mouseUpHandler(event:MouseEvent):void
			{
				if (_lastCaretIndex != textField.caretIndex)
					getTextStyles();
			}
			
			private function hackedTextLength(p_text:String):int
			{
				for (var i:int = p_text.length -1; i <= 0 ; i--) {
					if (p_text.charAt(i) != "\r") {
						return i;
					}
				}
				return p_text.length -1;
			}
		}
}
