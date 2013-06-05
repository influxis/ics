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
		/**
		 * Importing the various UI libraries
		 */
		import flash.events.Event;
		import flash.geom.Rectangle;
		import flash.text.TextFormat;
		
		import mx.controls.Image;
		import mx.events.ResizeEvent;
		/**
		 * @private
		 * EmotioconTextArea is the implementation of our TextEditor with first level hierarchy
		 * This is actually a subclass of TextArea and supports all textArea features. Other than standard
		 * flex textArea features,it supports smileys(emoticons) . When we type a text it parses the strings
		 * that represent the emoticons and replaces those strings with emoticon images.It parses the strings
		 * using regular expressions
		 * It inherits the protected TextField of TextArea and uses it for determining the positions 
		 * and size of the characters. 
		 * When the text is scrolled , the emoticons present only in the visible area are shown. Currently,
		 * it supports vertical scrolling.It has a set of limited smileys.
		 * @see author hironmay basu
		 */
   public class  EmoticonTextArea extends RichTextArea
		{
			/**
			 * This Editor is called the emotioconeditor. It currentlyhas the text Editor and the set 
			 * of limited smileys within it. When we type anything in it , the text is replaced by the
			 * smileys
			 * Set of Bindable variables for the various .gif files 
			 */ 	
 			//[Embed(source="textEditorClasses/assets/emoticon_angry.png")]
 			[Embed(source='emoticonTextAreaAssets/emoticons.swf#angry')]
 			public static var emoticon_angry:Class;

 			[Embed(source='emoticonTextAreaAssets/emoticons.swf#laugh')]
 			public static var emoticon_laugh:Class;

 			[Embed(source='emoticonTextAreaAssets/emoticons.swf#sad')]
 			public static var emoticon_sad:Class;
 			
			[Embed(source='emoticonTextAreaAssets/emoticons.swf#smile')]
 			public static var emoticon_smile:Class;
 			
 			[Embed(source='emoticonTextAreaAssets/emoticons.swf#tongue')]
 			public static var emoticon_tongue:Class;
 			 		 			
 			[Embed(source='emoticonTextAreaAssets/emoticons.swf#wink')]
 			public static var emoticon_wink:Class;
 			
 			
 			 		
 			/**
 			 * @private
 			 * Gives number of Images that are present at any point in the display area
 			 */
 			protected var numberOfImages:Number=0;
 			
 			/**
 			 * @private
 			 * The regular expression for the smileys
 			 */
 			protected var _smileyExp:RegExp;
 			/**
 			 * @private
 			 * Shows if the text has changed
 			 */
 			protected var _emoticonTextChanged:Boolean = false ;

 			protected var _images:Object;
 			
			/**
			 * Should this try to match emoticon characters?
			 */
			protected var _matchEmoticons:Boolean = true;
		
 			 
 			public function EmoticonTextArea()
 			{
        		super();
        		_images = new Object();			
				_smileyExp = /(X\(|X-\(|:\)\)|:-\)\)|:D|:-D|:\(|:-\(|:\)|:-\)|:p|:-p|:P|:-P|;\)|;-\))/g;
				wordWrap = true ;
				this.addEventListener(ResizeEvent.RESIZE, onResize);
			}    
			
			public function get matchEmoticons():Boolean
			{
				return _matchEmoticons;
			}
			public function set matchEmoticons(p_matchThem:Boolean):void
			{
				_matchEmoticons = p_matchThem;
				invalidateProperties();
			}
			
			/**
			 * @private
			 * Overriding the createChildren. Added the TextArea here and its event Listeners
			 * The event listeners added for change and scroll. 
			 * The vertical scroll policy has been set to auto. This shows the scrollbar only when
			 * it is needed
			 */
			override protected function createChildren():void
			{
				super.createChildren();
				//addEventListener("change", changeHandler); 
				addEventListener("scroll",scrollEventHandler);
				for ( var id:String in _images ) {
					if ( _images[id]) {
						if ( !contains(_images[id])) {
							addChild(_images[id]);
						}
					}
						
				}
			}
		
			public function get allEmoticons():Object
			{
				var emoticons:Object = new Object();
				emoticons["emoticon_angry"] = emoticon_angry;
				emoticons["emoticon_laugh"] = emoticon_laugh;
				emoticons["emoticon_sad"] = emoticon_sad;
				emoticons["emoticon_smile"]= emoticon_smile;
				emoticons["emoticon_tongue"] = emoticon_tongue;
				emoticons["emoticon_wink"] = emoticon_wink;
				return emoticons;
			}
		
			
			/**
			 * @private
			 * Handles the event for the scroll.When the textarea is scrolled,
			 * it parses the strings present in the display area and then calls our internal function 
			 * for scrollHandling
			 */ 
			protected function scrollEventHandler(event:Event):void
			{
				//addRemoveImages();
				_emoticonTextChanged=true;
				invalidateProperties();
				invalidateDisplayList();
			} 
			
			protected function onResize(p_event:ResizeEvent):void
			{
				_emoticonTextChanged=true;
				invalidateProperties();
				invalidateDisplayList();
			} 
			
			/**
			 * Sets the text
			 * @param value
			 * 
			 */			
			override public function set text(value:String):void
			{
				super.text=value;
				_emoticonTextChanged=true;
				invalidateProperties();
				invalidateDisplayList();
			}
			
			/**
			 * Returns the number of emoticons
			 * @return 
			 * 
			 */			
			public function get numberOfSmileys():Number
			{
				return numberOfImages;
			}
			/**
			 * @private
			 * @return 
			 * 
			 */			
			override public function get text():String
			{
				return super.text;
			}
			
			/**
			 * Sets the html text
			 * @param value
			 * 
			 */			
			override public function set htmlText(value:String):void
			{
				super.htmlText=value;
				_emoticonTextChanged=true;
				invalidateProperties();
				invalidateDisplayList();
			}
			
	    	protected function makeMatchCharactersWhite():void
			{		
				var beginIndex:Number; var endIndex:Number;
				var results:Object=_smileyExp.exec(text);
				var tf:TextFormat = new TextFormat();
				while (results != null) {
					beginIndex = results.index;
					endIndex = results.index + results[0].length;
					if( beginIndex != endIndex && (endIndex >=0 && endIndex <= text.length)){
						tf["color"]=0xFFFFFF;
						textField.setTextFormat(tf, beginIndex, endIndex);
//						_textFormatChanged = true;
					}
					results = _smileyExp.exec(text);
				}
				super.invalidateDisplayList();
			}
			
			/**
			 * @private
			 * gets the html text
			 * @return 
			 * 
			 */			
			override public function get htmlText():String
			{
				return super.htmlText;
			} 
			
			/**
			 * @private
			 * Add or remove images. This is the main function that adds an image or
			 * deletes an image. 
			 * The function takes results an Object which contains the parsed value of the regular expressions
			 * and checks if its not null. If not, it first cleans up the images and then adds them at the right
			 * place.
			 * It also adds the right image based on the expression value.
			 * It positions the image based on the position of expression characters and their width and height.
			 */
			public function addRemoveImages():void
			{
				//checks if the result of regular expression is null or not and accordingly removes all 
				//the child
				removeAllImages();
				addVisibleImages();
				layoutEmoticons();
	
				invalidateDisplayList();
				
			} 
			 
			 
			public function removeAllImages():void
			{
				for (var id:String in _images ) {
					if ( _images[id]) {
						if ( contains(_images[id])) {
							removeChild(_images[id]);
							_images[id] = null ;
							numberOfImages--;
						}
					}
				}
			} 
			
			protected function loadImageSource(p_imageString:String,index:int):void
			{
				switch(p_imageString){
					case "X(":
					case "X-(":
						_images[index].source = emoticon_angry;
						break;
					case ":))":
					case ":-))":
					case ":D":
					case ":-D":
						_images[index].source = emoticon_laugh;
						break;
					case ":(":
					case ":-(":
						_images[index].source = emoticon_sad;
						break;
					case ":)":
					case ":-)":
						_images[index].source = emoticon_smile;
						break;
					case ":p":
					case ":-p":
					case ":P":
					case ":-P":
						_images[index].source = emoticon_tongue;
						break;
					case ";)":
					case ";-)":
						_images[index].source = emoticon_wink;
						break;
					default:
						break;
				}
			}
			
			
		
			public function addVisibleImages():void
			{
				this.validateNow();
				var results:Object=_smileyExp.exec(text);
				
				if (results == null ) {
					return ;
				}
				
				while(results!=null){
					var lineNumber:Number=textField.getLineIndexOfChar(results.index);
					var firstIndex:int = textField.getCharIndexAtPoint(0,height/2);
					var lastIndex:int = textField.getCharIndexAtPoint(width,0);
					if ( !textField.multiline && results.index > firstIndex && firstIndex > 0 ) {
						if ( !_images[results.index] ) {
							_images[results.index] = new Image();
							
						}
						loadImageSource(results[0],results.index);
						
						numberOfImages++;
					}
					else if(lineNumber>=textField.scrollV-1&&lineNumber<=textField.bottomScrollV-1){
						if ( !_images[results.index] ) {
							_images[results.index] = new Image();
							
						}
						loadImageSource(results[0],results.index);
						numberOfImages++;
					}
					results = _smileyExp.exec(text);
				}//end of while loop
				 createChildren();
				
			}
			 
			 
			 public function layoutEmoticons():void
			 {
			 	 var results:Object=_smileyExp.exec(text);
			 	 var lineNumber:Number;
			 	 
			 	 for (var id:String in _images) {
					lineNumber = textField.getLineIndexOfChar(parseInt(id));
					if (_images[id]) {
						if(lineNumber>=textField.scrollV-1 && lineNumber<=textField.bottomScrollV-1){
							_images[id].visible = true;
						} else {
							_images[id].visible = false;
						}
					}
				}
				
				var lineHeight:uint = textField.getLineMetrics(0).height;
				var emoticonSize:uint = Math.round(lineHeight*0.65);
								
			    while (results != null) {
					lineNumber = textField.getLineIndexOfChar(results.index);
					var firstIndex:int = textField.getCharIndexAtPoint(0,0);
					var currentEmoticon:Image = _images[results.index];
					if (currentEmoticon) {
						if (!textField.multiline && results.index>firstIndex && firstIndex>0) {
							//single line, we never use this
							currentEmoticon.x = textField.getCharBoundaries(results.index-firstIndex).left;
							currentEmoticon.y = textField.getCharBoundaries(results.index-firstIndex).top;
							currentEmoticon.width = (getLineMetrics(0).width/textField.getLineLength(0))*(results[0].length+1);
							currentEmoticon.height = textField.getLineMetrics(0).height;
						} 
						else if (lineNumber>=textField.scrollV-1 && lineNumber<=textField.bottomScrollV-1) {
							
							var rect:Rectangle = textField.getCharBoundaries(results.index);
							
							currentEmoticon.width = emoticonSize;
							currentEmoticon.height = emoticonSize;
							
							if (textField.scrollV <=1) {
								currentEmoticon.x = rect.left;
								currentEmoticon.y = rect.top+(rect.height-emoticonSize)/2;
							} else {
								var offset:Number = 0;
								if (textField.getCharBoundaries(textField.getLineOffset(textField.scrollV-1))==null) {
									offset=textField.getLineMetrics(textField.scrollV-1).height*(textField.scrollV-1);
								} else {
									offset=textField.getCharBoundaries(textField.getLineOffset(textField.scrollV-1)).top;	
								}
								currentEmoticon.x=rect.left;
								currentEmoticon.y=rect.top-offset+(rect.height-emoticonSize)/2;	
							}						
						} 
					}
					results = _smileyExp.exec(text);
			    }
			    
			 }
			 
			 
			 /**
			 * @private
			 * Overridding the commitProperties. The images are added or removed only 
			 * when the text is changed
			 */
			 override protected function commitProperties():void
			 {
			 	super.commitProperties();
			 
			 	if( _emoticonTextChanged && _matchEmoticons ){
			 		addRemoveImages();
			 		_emoticonTextChanged = false;	
			 		makeMatchCharactersWhite();
			 		invalidateDisplayList();
			 	}
			 }
			 
			 override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
			 {
			 	super.updateDisplayList(unscaledWidth,unscaledHeight);
			 	
			 	if ( _matchEmoticons ) {
			 		layoutEmoticons() ;
			 		makeMatchCharactersWhite();
			 	}
			 }
	 }
}