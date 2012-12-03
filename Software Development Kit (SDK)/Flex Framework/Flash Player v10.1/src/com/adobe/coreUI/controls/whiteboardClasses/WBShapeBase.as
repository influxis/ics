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
	import com.adobe.coreUI.controls.CustomTextEditor;
	import com.adobe.coreUI.controls.EditorToolBar;
	import com.adobe.coreUI.controls.whiteboardClasses.shapes.WBTextToolBar;
	import com.adobe.coreUI.events.WBShapeEvent;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	
	import mx.controls.TextArea;
	import mx.core.EdgeMetrics;
	import mx.core.UIComponent;
	import mx.events.FlexMouseEvent;
	import mx.managers.PopUpManager;

	[Event(name="textEditorCreate", type="com.adobe.events.WBShapeEvent")]
	[Event(name="textEditorDestroy", type="com.adobe.events.WBShapeEvent")]
	[Event(name="drawingComplete", type="com.adobe.events.WBShapeEvent")]
	[Event(name="drawingCancel", type="com.adobe.events.WBShapeEvent")]
	[Event(name="propertyChange", type="com.adobe.events.WBShapeEvent")]


	/**
	 * @private
	 * WBShapeBase is the base for all the shapes drawn by the whiteboard. A shape includes some fill (say, a rectangle, circle, star, etc)
	 * and a textArea in which to type. WBShapes are typically placed in WBShapeContainers to allow draggable moving, resizing, and rotation.
	 * 
	 * @author npegg
	 */
   public class  WBShapeBase extends UIComponent
	{
	    public static const NULL_COLOR:uint = 0xFFFFFFE;
		
		protected var _textArea:TextArea;
		protected var _tempEditor:CustomTextEditor;
		protected var _textToolBar:EditorToolBar;
		protected var _htmlText:String = "";
		protected var _isRotated:Boolean = false;
		protected var _isDrawing:Boolean = false;

		protected var _tEBitmap:Bitmap;

		protected var _invTextChange:Boolean = false;
		protected var _invRotationChange:Boolean = false;
		protected var _currentTextFormat:TextFormat;

		public var shapeID:String;
		public var shapeFactory:IWBShapeFactory;
		public var popupTextToolBar:Boolean = true;
		public var animateEntry:Boolean = false;

		public var canvas:WBCanvas;

		public function get propertyData():*
		{
			var returnObj:Object = new Object();
			returnObj.htmlText = htmlText;
			return returnObj;
		}
		
		public function set propertyData(p_data:*):void
		{
			if (p_data!=null) {
				if (p_data.htmlText!=null) {
					htmlText = p_data.htmlText;
				}
			}
		}
		
		public function get definitionData():*
		{
			return null;
		}
		
		public function set definitionData(p_data:*):void
		{
			
		}

		public function get htmlText():String
		{
			return _htmlText;
		}
		
		public function get textEditor():CustomTextEditor
		{
			return _tempEditor;
		}
		
		public function set htmlText(p_value:String):void
		{
			_htmlText = p_value;
			_invTextChange = true;
			invalidateProperties();
			invalidateDisplayList();
		}
		
		public function set isRotated(p_value:Boolean):void
		{
			if (p_value!=_isRotated) {
				_isRotated = p_value;
				_invRotationChange = true;
				invalidateDisplayList();
			}
		}
		
		public function get textToolBar():UIComponent
		{
			return _textToolBar;
		}
		
		public function get isRotated():Boolean
		{
			return _isRotated;
		}
		
		public final function beginDrawing():void
		{
			_isDrawing = true;
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpHandler);
			setupDrawing();
		}
		
		public final function endDrawing():void
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpHandler);
			cleanupDrawing();
			_isDrawing = false;
			dispatchEvent(new WBShapeEvent(WBShapeEvent.DRAWING_COMPLETE));
		}
		
		public function focusTextEditor():EditorToolBar
		{
			if (_textArea) {
				_textArea.visible = false;
			}
			if (_tEBitmap) {
				_tEBitmap.visible = false;
			}
			createTextEditor(true);
			_tempEditor.htmlText = htmlText;
			sizeTextEditor();
			positionTextEditor();
			_tempEditor.addEventListener(Event.CHANGE, textEditing);

			_textToolBar = new WBTextToolBar();
			_textToolBar.textEditor = _tempEditor;
			if (htmlText=="") {
				_tempEditor.setTextStyles("size", 16);
			}
			if (popupTextToolBar) {
				PopUpManager.addPopUp(_textToolBar, this);
				_textToolBar.validateNow();
				_textToolBar.width = _textToolBar.measuredWidth;
				_textToolBar.height = _textToolBar.measuredHeight;
			}
			var evt:WBShapeEvent = new WBShapeEvent(WBShapeEvent.TEXT_EDITOR_CREATE);
			evt.textEditor = _tempEditor;
			dispatchEvent(evt);
			if (_tempEditor.parent) {
				_tempEditor.setFocus();
				_tempEditor.selectAllText();
				_tempEditor.getTextStyles();
				_textToolBar.invalidateProperties();
				_textToolBar.validateNow();
			}
			return _textToolBar;
		}
		
		public function finishEditingText(p_evt:FlexMouseEvent=null):void
		{
			var editorPoint:Point;
			var mousePoint:Point;
			// we need to see if the click happened in our toolbar, which is the only exception to clicking needing to dispose the editor
			if (p_evt) {
				var currTarget:Object = p_evt.relatedObject;
				while (currTarget!=null) {
					if (currTarget is WBTextToolBar) {
						return;
					}
					if (currTarget.hasOwnProperty("owner")) {
						currTarget = currTarget.owner;
					} else {
						currTarget = currTarget.parent;
					}
				}
				// Hack to prevent the self-destruction of the text-editor ie if point on editor equals mouse coordinates
				//then plz dont destroy the editor.
				editorPoint = absPoint(globalToLocal(new Point(p_evt.currentTarget.x , p_evt.currentTarget.y)));
				mousePoint = absPoint(contentToLocal(new Point(p_evt.localX , p_evt.localY)));
			}
			
			
			if (_textArea) {
				_textArea.visible = true;
			}
			if (_tEBitmap) {
				_tEBitmap.visible = true;
			}
			
			if (_tempEditor) {
				if(editorPoint && !editorPoint.equals(mousePoint)) {
					htmlText = _tempEditor.htmlText;
					disposeTextEditor();
					dispatchEvent(new WBShapeEvent(WBShapeEvent.PROPERTY_CHANGE));
				} else if(p_evt == null) {
					htmlText = _tempEditor.htmlText;
					disposeTextEditor();
					dispatchEvent(new WBShapeEvent(WBShapeEvent.PROPERTY_CHANGE));
				}
			}
		}
		
		protected function absPoint(p_point:Point):Point
		{
			return new Point(Math.abs(p_point.x), Math.abs(p_point.y));
		}
		
		public function get toolBar():UIComponent
		{
			if (_textToolBar) {
				return _textToolBar;
			}
			return null;
		}
		
		public var shapeContainer:WBShapeContainer;
		
		public override function parentChanged(p:DisplayObjectContainer):void
		{
			super.parentChanged(p);
			shapeContainer = p as WBShapeContainer;
		}
		
		public function disposeTextChanges():void
		{
 			if (_textArea) {
				_textArea.visible = true;
			}
			if (_tEBitmap) {
				_tEBitmap.visible = true;
			}
			if (_tempEditor) {
				disposeTextEditor();
			}
		}
		
		public function get currentTextFormat():TextFormat
		{
			return _currentTextFormat;
		}
		
		protected function setupDrawing():void
		{
		}
		
		protected function cleanupDrawing():void
		{
		}
		
		protected function onMouseUpHandler(p_evt:MouseEvent):void
		{
			endDrawing();
		}
		
		protected override function createChildren():void
		{
		}
		
		protected override function commitProperties():void
		{
			if (_htmlText && !_textArea) {
				createTA();
			}
			if (_invTextChange && _textArea) {
				_textArea.htmlText = _htmlText;
				sizeTA();
				_invTextChange = false;
				_invRotationChange = true;
			}
		}
		
		protected override function updateDisplayList(p_w:Number, p_h:Number):void
		{
			super.updateDisplayList(p_w, p_h);
			if (_textArea) {
				if (_invRotationChange) {
					_invRotationChange = false;
					if (_isRotated) {
						if (_tEBitmap) {
							removeChild(_tEBitmap);
							_tEBitmap = null;
						}
						var bitmapData:BitmapData = new BitmapData(_textArea.width, _textArea.height, true, 0xffffff);
			 			bitmapData.draw(_textArea, null, null, null, null, true);
						_tEBitmap = new Bitmap(bitmapData);
						addChild(_tEBitmap);
					} else if (_tEBitmap) {
						removeChild(_tEBitmap);
						_tEBitmap = null;
					}
				}
				positionTA();
			}
		}
		
		protected function createTA():void
		{
			_textArea = new TextArea();
			addChild(_textArea);
			_textArea.verticalScrollPolicy = _textArea.horizontalScrollPolicy = "off";
			_textArea.wordWrap = false;
			_textArea.setStyle("borderStyle", "none");
			_textArea.setStyle("backgroundAlpha", 0);
		}
		
		protected function sizeTA():void
		{
			if (_isRotated) {
				// if the shape is rotated, we pop up a text area in the popUpmanager, to get an unadulterated snapshot
				// of what size the text really is. Turns out the text editor does most of this, so we use it.
				createTextEditor();
				_tempEditor.htmlText = htmlText;
				sizeTextEditor();
				_textArea.width = _tempEditor.width;
				_textArea.height = _tempEditor.height - lastLineHeightHack(_tempEditor);
				disposeTextEditor();
			} else {
				_textArea.validateNow();
				var eM:EdgeMetrics = _textArea.viewMetrics;
				var posWidth:Number = _textArea.textWidth + eM.left + eM.right + 10;
				_textArea.width = Math.max(posWidth,utilHtmlTextLength(_textArea.htmlText));
				_textArea.height = _textArea.textHeight + eM.top + eM.bottom + 8 - lastLineHeightHack(_textArea); // TODO : MAGIC NUMBER?
			}
			_textArea.verticalScrollPosition = _textArea.horizontalScrollPosition = 0;
			positionTA();
			_textArea.validateNow();
		}
		

		/**
		 * So, yeah. When you add HTMLText to a TA, the closing <p> tag causes a newline. When we want to 
		 * display nicely auto-fit text boxes, we need to shave off the height of that newline. This would be how.
		 */
		protected function lastLineHeightHack(p_tA:TextArea):Number
		{
			var lastHeight:Number;
			for (var i:int=0; i<2000; i++) {
				try {
					lastHeight = _textArea.getLineMetrics(i).height;
				} catch (e:Error) {
					// HOLY COW IS THIS STUPID! I want to shave off the last line of text, but TA gives me 
					// no way to see what the last line is. So, iterate through them, and once we get
					// an error (index out-of-bounds), it's time to stop.
					break;
				}
			}
			return (i>1) ? lastHeight : 0;
		}
		
		protected function positionTA():void
		{
			_textArea.x = Math.round((width-_textArea.width)/2);
			_textArea.y = Math.round((height-_textArea.height)/2);
			if (_tEBitmap) {
				_tEBitmap.x = _textArea.x;
				_tEBitmap.y = _textArea.y;
			}
		}
		
		protected function createTextEditor(p_forEditing:Boolean=false):void
		{
			if (_tempEditor) {
				disposeTextEditor();
			}
			_tempEditor = new CustomTextEditor();
			_tempEditor.setStyle("modalTransparency", false);
			_tempEditor.setStyle("modalTransparencyBlur", false);
			_tempEditor.addEventListener(FlexMouseEvent.MOUSE_DOWN_OUTSIDE, finishEditingText);
			_tempEditor.setStyle("borderStyle", "inset");
			_tempEditor.setStyle("backgroundColor", 0xffffff);
			_tempEditor.setStyle("backgroundAlpha", 1);
			PopUpManager.addPopUp(_tempEditor, this);
			_tempEditor.scaleX = canvas.scaleX;
			_tempEditor.scaleY = canvas.scaleY;
			_tempEditor.verticalScrollPolicy = _tempEditor.horizontalScrollPolicy = "off";
			_tempEditor.wordWrap = false;
			if (!p_forEditing) {
				_tempEditor.setStyle("borderStyle", "none");
				_tempEditor.setStyle("backgroundAlpha", 0);
			}
		}		
		
		protected function sizeTextEditor():void
		{
			if (!_tempEditor) {
				return;
			}
			_tempEditor.validateNow();
			var eM:EdgeMetrics = _tempEditor.viewMetrics;
			var lastLine:Number = 0;
//			var lastLine:Number = (htmlText=="") ? 0 : lastLineHeightHack(_tempEditor);
			_tempEditor.height = canvas.scaleY * (_tempEditor.textHeight + eM.top + eM.bottom + 8 - lastLine); // TODO : MAGIC NUMBER?
			var possWidth:Number = canvas.scaleX * (_tempEditor.textWidth + eM.left + eM.right + 10);
			_tempEditor.width = Math.max(possWidth,utilHtmlTextLength(_tempEditor.htmlText)) + 30 ;
			_tempEditor.verticalScrollPosition = _tempEditor.horizontalScrollPosition = 0;
			_tempEditor.editorTextField.autoSize = TextFieldAutoSize.CENTER;
			_tempEditor.validateNow();
		}
		
		protected function utilHtmlTextLength(p_htmlText:String):Number
		{
			var tempTxt:TextField = new TextField();
			tempTxt.multiline = true;
			tempTxt.autoSize = TextFieldAutoSize.LEFT;
			tempTxt.wordWrap = false;
			tempTxt.htmlText = p_htmlText;
			if (_tempEditor) {
				var eM:EdgeMetrics = _tempEditor.viewMetrics;
				// Adding the magic number 10 to prevent truncation. Wish I had a logical reason for choosing 10 :(
				return tempTxt.width+eM.left + eM.right + 10;
			}else {
				return tempTxt.width+ 14;
			}
		}
		
		protected function positionTextEditor():void
		{
			if (!_tempEditor) {
				return;
			}
			var centerPt:Point = new Point(width/2, height/2);
			var popUpPt:Point = _tempEditor.parent.globalToLocal(localToGlobal(centerPt));
			_tempEditor.x = popUpPt.x-_tempEditor.width/2;
			_tempEditor.y = popUpPt.y-_tempEditor.height/2;
			_tempEditor.validateNow();
		}
		
		protected function disposeTextEditor(p_evt:Event=null):void
		{
			_currentTextFormat = _tempEditor.editorTextField.defaultTextFormat;
			_tempEditor.removeEventListener(FlexMouseEvent.MOUSE_DOWN_OUTSIDE, finishEditingText);
			PopUpManager.removePopUp(_tempEditor);
			PopUpManager.removePopUp(_textToolBar);
			_textToolBar = null;
			_tempEditor = null;
			dispatchEvent(new WBShapeEvent(WBShapeEvent.TEXT_EDITOR_DESTROY));
		}
		
		protected function textEditing(p_evt:Event):void
		{
			sizeTextEditor();
			positionTextEditor();
		}
	}
}