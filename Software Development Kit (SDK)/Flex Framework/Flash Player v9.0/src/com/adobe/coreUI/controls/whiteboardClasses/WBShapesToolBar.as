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
	import com.adobe.coreUI.controls.whiteboardClasses.ToolBarDescriptors.WBShapeToolBarDescriptor;
	import com.adobe.coreUI.controls.whiteboardClasses.ToolBarDescriptors.WBToolBarDescriptor;
	import com.adobe.coreUI.controls.whiteboardClasses.shapes.WBArrowShapeFactory;
	import com.adobe.coreUI.controls.whiteboardClasses.shapes.WBHighlightAreaShapeFactory;
	import com.adobe.coreUI.controls.whiteboardClasses.shapes.WBMarkerShapeFactory;
	import com.adobe.coreUI.controls.whiteboardClasses.shapes.WBSimpleShapeFactory;
	import com.adobe.coreUI.controls.whiteboardClasses.shapes.WBTextShapeFactory;
	import com.adobe.coreUI.events.WBCanvasEvent;
	import com.adobe.coreUI.events.WBToolBarEvent;
	import com.adobe.coreUI.localization.ILocalizationManager;
	import com.adobe.coreUI.localization.Localization;
	
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.xml.XMLNode;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.collections.ListCollectionView;
	import mx.collections.XMLListCollection;
	import mx.controls.Button;
	import mx.controls.menuClasses.IMenuDataDescriptor;
	import mx.controls.treeClasses.DefaultDataDescriptor;
	import mx.core.UIComponent;
	import mx.core.UITextField;
	import mx.events.CollectionEvent;
	import mx.managers.ToolTipManager;
	import mx.skins.halo.HaloBorder;
	
	[Event(name="toolBarClick", type="com.adobe.events.WBToolBarEvent")]
	[Event(name="toolBarChange", type="com.adobe.events.WBToolBarEvent")]
	
	/**
	 * @private
	 */
   public class  WBShapesToolBar extends UIComponent
	{
		
		[Embed (source = 'whiteboardAssets/toolBarIcons.swf#com.adobe.controls.buttonBarUp')]
		protected static var SKIN_UP:Class;
		[Embed (source = 'whiteboardAssets/toolBarIcons.swf#com.adobe.controls.buttonBarOver')]
		protected static var SKIN_OVER:Class;
		[Embed (source = 'whiteboardAssets/toolBarIcons.swf#com.adobe.controls.buttonBarDown')]
		protected static var SKIN_DOWN:Class;
		[Embed (source = 'whiteboardAssets/toolBarIcons.swf#buttonBarSelected')]
		protected static var SKIN_SELECTED:Class;
		
		protected static const TITLE_HEIGHT:int = 10;
		protected static const SIDE_BUFFERS:int = 6;
		
		public var useTitleBar:Boolean = true;
		public var allowSave:Boolean = true;
		
		protected var _backgroundSkin:HaloBorder;
		protected var _titleBar:Sprite;
		
		protected var _lm:ILocalizationManager;
		
		protected var _dataDescriptor:IMenuDataDescriptor = new DefaultDataDescriptor();
		protected var _rootModel:ICollectionView;
		protected var _invDataProviderChanged:Boolean = false;
		protected var _hasRoot:Boolean = false;
		protected var _selectedButt:Button;
		protected var _currentSubToolBar:WBShapesToolBar;
		
		protected var _controls:Array = new Array();
		protected var _buttonHeight:int = 32;
		protected var _buttonWidth:int = 42;
		
		protected var markerFactory:IWBShapeFactory = new WBMarkerShapeFactory();
		protected var textFactory:IWBShapeFactory = new WBTextShapeFactory();
		protected var simpleShapeFactory:WBSimpleShapeFactory = new WBSimpleShapeFactory();
		protected var arrowFactory:WBArrowShapeFactory = new WBArrowShapeFactory();
		protected var highlightAreaFactory:WBSimpleShapeFactory = new WBHighlightAreaShapeFactory();
		
		public static const COMMAND_SAVE:String = WBToolBarDescriptor.COMMAND_SAVE;
		public static var ICON_SAVE:Class = WBToolBarDescriptor.ICON_SAVE;
		
		protected var _wbCanvas:WBCanvas;
		
		public function set wbCanvas(p_canvas:WBCanvas):void
		{
			_wbCanvas = p_canvas;
			invalidateProperties();
			//			_wbCanvas.addEventListener("selectionChange", switchToSelectionTool);
		}		
		
		override protected function createChildren():void
		{
			_backgroundSkin = new HaloBorder();
			setStyle("backgroundColor", 0x000000);
			setStyle("borderStyle", "outset");
			setStyle("dropShadowEnabled", true);
			setStyle("shadowDistance", 3);
			setStyle("shadowDirection", "right");
			setStyle("color", 0xeaeaea);
			_backgroundSkin.styleName = this;
			addChild(_backgroundSkin);
			_titleBar = new Sprite();
			_titleBar.addEventListener(MouseEvent.MOUSE_DOWN, startDragging);
			addChild(_titleBar);
			_lm = Localization.impl;
		}
		
		protected function startDragging(p_evt:MouseEvent):void
		{
			stage.addEventListener(MouseEvent.MOUSE_UP, stopDragging, false, 0, true);
			var rect:Rectangle;
			if (parent is UIComponent) {
				rect = new Rectangle(0,0,Math.max(0,parent.width-width),Math.max(0,parent.height-30));
			}
			startDrag(false, rect);
		}
		
		protected function stopDragging(p_evt:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopDragging);
			stopDrag();
		}
		
		override protected function commitProperties():void
		{
			if (!_rootModel) {
				var data:WBToolBarDescriptor = new WBToolBarDescriptor(true);
				processDP(data);
				_invDataProviderChanged = true;
			}
			
			if (_invDataProviderChanged) {
				_invDataProviderChanged = false;
				
				if (_currentSubToolBar) {
					closeSubToolBar();
				}
				for (var i:int=0; i<_controls.length; i++) {
					var b:Button = _controls[i] as Button;
					if (b) {
						b.removeEventListener(MouseEvent.CLICK, processClick);
					}
					removeChild(_controls[i]);
				}
				_controls = new Array();
				
				
				var topLevel:ICollectionView;
				
				var rootItem:* = _rootModel.createCursor().current;
				if (rootItem != null &&
					_dataDescriptor.isBranch(rootItem, _rootModel) &&
					_dataDescriptor.hasChildren(rootItem, _rootModel))
				{
					// then get rootItem children
					topLevel = _dataDescriptor.getChildren(rootItem, _rootModel);
				} else {
					topLevel = _rootModel;
				}
				
				var theY:int = (useTitleBar) ? TITLE_HEIGHT + 5 : 5;
				var cursor:IViewCursor = topLevel.createCursor();
				var curr:Object = cursor.current;
				while (curr) {
					if (curr.shapeFactory) {
						var factory:IWBShapeFactory = curr.shapeFactory as IWBShapeFactory;
						// TODO : need to traverse child branches to reg factories
						if (_wbCanvas) {
							_wbCanvas.registerFactory(factory);
						}
					}
					
					if (curr.type=="label") {
						var lbl:UITextField = new UITextField();
						addChild(lbl);
						lbl.text = curr.label;
						measuredWidth = Math.max(measuredWidth, lbl.textWidth + 4 + 2*SIDE_BUFFERS);
						lbl.setActualSize(lbl.textWidth+4, lbl.textHeight+4);
						lbl.move(SIDE_BUFFERS, theY+3);
						_controls.push(lbl);
						theY += lbl.textHeight + 8;
					} else {
						if (curr.icon==WBToolBarDescriptor.ICON_SAVE && !allowSave) {
							cursor.moveNext();
							curr = cursor.current;
							continue
						}
						var butt:Button = new Button();
						butt.setStyle("upSkin", SKIN_UP);
						butt.setStyle("overSkin", SKIN_OVER);
						butt.setStyle("downSkin", SKIN_DOWN);
						butt.setStyle("selectedUpSkin", SKIN_SELECTED);
						butt.setStyle("selectedOverSkin", SKIN_SELECTED);
						butt.setStyle("selectedDownSkin", SKIN_SELECTED);
						addChild(butt);	
						
						butt.styleName = "buttonBar";
						butt.toggle = (curr.type=="tool");
						butt.setActualSize(_buttonWidth, _buttonHeight);
						butt.move(SIDE_BUFFERS, theY);
						butt.data = curr;
						butt.addEventListener(MouseEvent.CLICK, processClick);
						_controls.push(butt);
						if (curr.icon) {
							butt.setStyle("icon", curr.icon);
						}
						if (curr.toolTip) {
							butt.toolTip = curr.toolTip;
						}
						
						if (_dataDescriptor.hasChildren(butt.data, _rootModel)) {
							// it's a sub-toolbar creator. 
							openSubToolBar(butt);
							closeSubToolBar();
						}
						
						theY += butt.height+1;
					}
					measuredHeight = theY+5;
					if (measuredWidth<20) { 
						measuredWidth = _buttonWidth + 2*SIDE_BUFFERS;
					}
					cursor.moveNext();
					curr = cursor.current;
				}
			}
		}
		
		override protected function measure():void
		{
			//
		}
		
		override protected function updateDisplayList(p_w:Number, p_h:Number):void
		{
			_backgroundSkin.setActualSize(p_w, p_h);
			
			
			var buttW:int = p_w - 2*SIDE_BUFFERS;
			for (var i:int=0; i<_controls.length; i++) {
				var b:Button = _controls[i] as Button;
				if (b) {
					b.setActualSize(buttW, b.height);
				}
			}
			
			if (useTitleBar) {
				var g:Graphics = _titleBar.graphics;
				g.clear();		
				
				var gradMatr:Matrix = new Matrix();
				gradMatr.createGradientBox(p_w, TITLE_HEIGHT, Math.PI/2);			
				g.beginGradientFill(GradientType.LINEAR, [0x4C4C4C,0x393939],[1,1],[0,255],gradMatr);
				g.moveTo(1,TITLE_HEIGHT);
				g.lineStyle(1, 0x868686);			
				g.lineTo(1,1);
				g.lineTo(p_w-2,1);
				g.lineStyle(1,0x1C1C1C);
				g.lineTo(p_w-2,TITLE_HEIGHT);
				g.lineTo(1,TITLE_HEIGHT);
				g.endFill();			
			}
		}
		
		protected function closeSubToolBar():void
		{
			removeChild(_currentSubToolBar);
			_currentSubToolBar = null;
		}
		
		protected function openSubToolBar(p_button:Button):void
		{
			_currentSubToolBar = new WBShapesToolBar();
			_currentSubToolBar.dataProvider = _dataDescriptor.getChildren(p_button.data, _rootModel);
			_currentSubToolBar.useTitleBar = false;
			_currentSubToolBar.wbCanvas = _wbCanvas;
			addChild(_currentSubToolBar);
			_currentSubToolBar.validateNow();
			_currentSubToolBar.setActualSize(_currentSubToolBar.measuredWidth, _currentSubToolBar.measuredHeight);
			_currentSubToolBar.move(p_button.x+p_button.width+2, p_button.y-10);
		}
		
		protected function processClick(p_evt:Event):void
		{
			ToolTipManager.enabled = false;
			var target:Button = p_evt.target as Button;
			if (target.data.type=="tool") {
				if (_currentSubToolBar) {
					closeSubToolBar();
				}
				if (_dataDescriptor.hasChildren(target.data, _rootModel)) {
					// it's a sub-toolbar creator. 
					openSubToolBar(target);
				} else {
					_wbCanvas.enableShapeSelection = (target.data.shapeFactory==null);
					var factory:IWBShapeFactory = target.data.shapeFactory as IWBShapeFactory;
					if (target.data.shapeData) {
						factory.shapeData = target.data.shapeData;
					}
					_wbCanvas.currentShapeFactory = factory;
				}
				if (_selectedButt) {
					_selectedButt.selected = false;
				}
				_selectedButt = target;
				_selectedButt.selected = true;
			} else if (target.data.type=="command") {
				var command:String = target.data.command;
				if (command==WBToolBarDescriptor.COMMAND_UNDO) {
					_wbCanvas.undo();
				} else if (command==WBToolBarDescriptor.COMMAND_REDO) {
					_wbCanvas.redo();
				} else if (command==WBToolBarDescriptor.COMMAND_DELETE_SELECTED) {
					_wbCanvas.removeSelectedShapes();
				}
			}
			dispatchEvent(new WBToolBarEvent(WBToolBarEvent.TOOL_BAR_CLICK, target.data));
			ToolTipManager.enabled = true;
		}
		
		public function set dataProvider(p_data:Object):void
		{
			if (_rootModel) {
				//	            _rootModel.removeEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler);
			}
			//flag for processing in commitProps
			processDP(p_data);
			_invDataProviderChanged = true;
			invalidateProperties();			
		}
		
		/**
		 * Add a toolBar component to the Toolbar
		 * 
		 * @param p_WBShapesToolBarDescriptor Descriptor for the tool bar component.
		 */ 
		public function addCustomShapeToToolBar(p_WBShapeToolBarDescriptor:WBShapeToolBarDescriptor):void
		{
			if (_rootModel) {
				var topLevel:ListCollectionView;
				
				var rootItem:* = _rootModel.createCursor().current;
				if (rootItem != null &&
					_dataDescriptor.isBranch(rootItem, _rootModel) &&
					_dataDescriptor.hasChildren(rootItem, _rootModel))
				{
					// then get rootItem children
					topLevel = _dataDescriptor.getChildren(rootItem, _rootModel) as ListCollectionView;
				} else {
					topLevel = _rootModel as ListCollectionView;
				}
				topLevel.addItem(p_WBShapeToolBarDescriptor);
			}
			processDP(_rootModel);
			_invDataProviderChanged = true;
			commitProperties();
			dispatchEvent(new WBToolBarEvent(WBToolBarEvent.TOOLBAR_CHANGE));
		}
		
		public function get dataProvider():Object
		{
			return _rootModel;
		}
		
		public function get dataDescriptor():IMenuDataDescriptor
		{
			return _dataDescriptor;
		}
		
		protected function collectionChangeHandler(p_evt:CollectionEvent):void
		{
			// TODO: rebuild!
		}
		
		protected function processDP(p_data:Object):void
		{
			
			// handle strings and xml
			if (typeof(p_data)=="string")
				p_data = new XML(p_data);
			else if (p_data is XMLNode)
				p_data = new XML(XMLNode(p_data).toString());
			else if (p_data is XMLList)
				p_data = new XMLListCollection(p_data as XMLList);
			
			if (p_data is XML)
			{
				_hasRoot = true;
				var xl:XMLList = new XMLList();
				xl += p_data;
				_rootModel = new XMLListCollection(xl);
			}
				//if already a collection dont make new one
			else if (p_data is ICollectionView)
			{
				_rootModel = ICollectionView(p_data);
				
				if (_rootModel.length == 1)
					_hasRoot = true;
			}
			else if (p_data is Array)
			{
				_rootModel = new ArrayCollection(p_data as Array);
			}
				//all other types get wrapped in an ArrayCollection
			else if (p_data is Object)
			{
				_hasRoot = true;
				// convert to an array containing this one item
				var tmp:Array = [];
				tmp.push(p_data);
				_rootModel = new ArrayCollection(tmp);
			}
			else
			{
				_rootModel = new ArrayCollection();
			}
		}
		
	}
}