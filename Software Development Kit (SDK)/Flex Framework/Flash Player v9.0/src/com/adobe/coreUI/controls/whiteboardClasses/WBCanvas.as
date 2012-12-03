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
	import com.adobe.coreUI.controls.EditorToolBar;
	import com.adobe.coreUI.controls.whiteboardClasses.commands.WBAddShapes;
	import com.adobe.coreUI.controls.whiteboardClasses.commands.WBRemoveShapes;
	import com.adobe.coreUI.controls.whiteboardClasses.commands.WBSelectionChange;
	import com.adobe.coreUI.controls.whiteboardClasses.commands.WBShapeContainersChange;
	import com.adobe.coreUI.controls.whiteboardClasses.commands.WBShapesPropertyChange;
	import com.adobe.coreUI.controls.whiteboardClasses.shapes.WBTextToolBar;
	import com.adobe.coreUI.events.WBCanvasEvent;
	import com.adobe.coreUI.events.WBModelEvent;
	import com.adobe.coreUI.events.WBShapeEvent;
	import com.adobe.coreUI.localization.ILocalizationManager;
	import com.adobe.coreUI.localization.Localization;
	import com.adobe.rtc.events.CollectionNodeEvent;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.getQualifiedClassName;
	
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	import mx.effects.Blur;
	import mx.effects.Fade;
	import mx.events.EffectEvent;
	import mx.managers.PopUpManager;

	/**
	 * Dispatched when one selects a different shape on the canvas.
	 */
	[Event(name="selectionChange", type="flash.events.Event")]
	/**
	 * Dispatched when the property tool bar is added.
	 */
	[Event(name="propertiesToolbarAdd", type="com.adobe.events.WBCanvasEvent")]
	/**
	 * Dispatched when the property tool bar is removed.
	 */
	[Event(name="propertiesToolbarRemove", type="com.adobe.events.WBCanvasEvent")]
	/**
	 * Dispatched when the type of cursor changes.
	 */
	[Event(name="cursorChange", type="com.adobe.events.WBCanvasEvent")]
	

	/**
	 * This is a standalone whiteboard canvas component. The various shapes and figures drawn on whiteboard are added as children to this component.
	 */
   public class  WBCanvas extends Canvas
	{
		/**
		 * @private
		 */
		[Embed (source = 'whiteboardAssets/Cursors.swf#CrosshairsCursor')]
		protected var _crosshairsCursor:Class;
		/**
		 * @private
		 */
		protected var _drawingSurface:Sprite;
		/**
		 * @private
		 */
		protected var _tmpHitSurface:UIComponent;
		/**
		 * @private
		 */
		protected var _selectionRect:UIComponent;
		/**
		 * @private
		 */
		protected var _selectionOrigin:Point;
		/**
		 * @private
		 */
		protected var _selectionGroup:Array;
		/**
		 * @private
		 */
		protected var _selectionGroupDetails:Array;
		/**
		 * @private
		 */
		protected var _groupSelectionHandles:WBDragHandles;
		/**
		 * @private
		 */
		protected var _enableSelection:Boolean = true;
		/**
		 * @private
		 */
		protected var _shapeFactory:IWBShapeFactory;
		/**
		 * @private
		 */
		protected var _currentDrawingShape:WBShapeBase;
		/**
		 * @private
		 */
		protected var _currentTextShape:WBShapeBase;
		/**
		 * @private
		 */
		protected var _registeredFactories:Object = new Object();
		/**
		 * @private
		 */
		protected var _pendingAddedShapes:Array = new Array();
		/**
		 * @private
		 */
		protected var _invSelectionChange:Boolean = false;
		/**
		 * @private
		 */
		protected var _invDontMoveShape:Boolean = false;
		/**
		 * @private
		 */
		protected var _invNewShapeFactory:Boolean = false;
		/**
		 * @private
		 */
		protected var _invEnableSelection:Boolean = true;
		/**
		 * @private
		 */
		protected var _isClosing:Boolean = false;
		/**
		 * @private
		 */
		protected var _isShiftDown:Boolean = false;
		/**
		 * @private
		 */
		protected var _isControlDown:Boolean = false;
		/**
		 * @private
		 */
		protected var _model:WBModel;
		/**
		 * @private
		 */
		protected var _shapeContainersByID:Object;
		/**
		 * @private
		 */
		protected var _commandMgr:WBCommandManager;
		/**
		 * @private
		 */
		protected var _cursorID:int=-1;
		/**
		 * @private
		 */
		protected var _currentCursorClass:Class;
		/**
		 * @private
		 */
		protected var _currentShapeToolBar:IWBPropertiesToolBar;
		/**
		 * @private
		 */
		public var selectionHandlesContainer:DisplayObjectContainer;
		/**
		 * @private
		 */
		public var popupPropertiesToolBar:Boolean = true;
		/**
		 * @private
		 */
		protected var _lm:ILocalizationManager = Localization.impl;
		/**
		 * @private
		 */
		protected var _previousTextFormat:TextFormat;
		/**
		 * @private
		 */		
		protected var _drawCustomShapes:Boolean = false;
		
		/**
		 * @private
		 */
		protected override function createChildren():void
		{
			horizontalScrollPolicy = verticalScrollPolicy = "off";
			_commandMgr = new WBCommandManager(this);
			_shapeContainersByID = new Object();
			_drawingSurface = new Sprite();
			rawChildren.addChild(_drawingSurface);
			_drawingSurface.addEventListener(MouseEvent.MOUSE_DOWN, beginDrawingShape);
			_drawingSurface.addEventListener(MouseEvent.MOUSE_OVER, showCursor);
			_drawingSurface.addEventListener(MouseEvent.MOUSE_OUT, hideCursor);
			
			super.createChildren();
			addEventListener(FocusEvent.FOCUS_IN, focusInHandler);
			addEventListener(FocusEvent.FOCUS_OUT, focusOutHandler);
			initializeSelection();
		}
		
		/**
		 * @private
		 */
		protected function initializeSelection():void
		{
			_selectionGroup = new Array();
			_selectionGroupDetails= new Array();
		}
		
		/**
		 * @private
		 */
		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			drawHitArea();
		}
		
		/**
		 * @private
		 */
		protected function drawHitArea():void
		{
			var g:Graphics = _drawingSurface.graphics;
			g.clear();
			g.beginFill(0xffffff, 0);
			if (!isNaN(unscaledHeight)) {
				g.drawRect(0, 0, unscaledWidth, unscaledHeight);
			}
		}
		
		/**
		 * @private
		 */
		protected function showCursor(p_evt:MouseEvent):void
		{
			if (_currentCursorClass) {
				cursorManager.removeAllCursors();
				_cursorID = cursorManager.setCursor(_currentCursorClass);
			}
		}
		
		/**
		 * @private
		 */
		protected function hideCursor(p_evt:MouseEvent=null):void
		{
			if (_cursorID!=-1) {
				cursorManager.removeCursor(_cursorID);
				_cursorID = -1;
			}		
		}
		
		/**
		 * @private
		 */
		protected function beginDrawingShape(p_evt:MouseEvent):void
		{
			if (!_shapeFactory || _currentDrawingShape) {
				return;
			}
			_currentDrawingShape = _shapeFactory.newShape();
			_currentDrawingShape.canvas = this;
			_currentDrawingShape.addEventListener(WBShapeEvent.DRAWING_COMPLETE, endDrawingShape);
			_currentDrawingShape.addEventListener(WBShapeEvent.TEXT_EDITOR_CREATE, textEditorCreate);
			_currentDrawingShape.addEventListener(WBShapeEvent.DRAWING_CANCEL, drawCancelled);
			_currentDrawingShape.popupTextToolBar = popupPropertiesToolBar;
			addChild(_currentDrawingShape);
			_currentDrawingShape.move(p_evt.localX, p_evt.localY);
			_currentDrawingShape.beginDrawing();
		}
		
		/**
		 * @private
		 */
		protected function endDrawingShape(p_evt:WBShapeEvent):void
		{
			_currentDrawingShape.removeEventListener(WBShapeEvent.DRAWING_COMPLETE, endDrawingShape);
			_currentDrawingShape.removeEventListener(WBShapeEvent.DRAWING_CANCEL, drawCancelled);
			_currentDrawingShape.removeEventListener(WBShapeEvent.TEXT_EDITOR_CREATE, textEditorCreate);
			var bounds:Rectangle = _currentDrawingShape.getBounds(this);
//			removeChild(_currentDrawingShape);
			_pendingAddedShapes.push(_currentDrawingShape);
			if (bounds.width==0 || bounds.height==0) {
				_currentDrawingShape = null;
				return;
			}

			var shapeDesc:WBShapeDescriptor = new WBShapeDescriptor();
			shapeDesc.x = bounds.x;
			shapeDesc.y = bounds.y;
			shapeDesc.width = bounds.width;
			shapeDesc.height = bounds.height;
			shapeDesc.factoryID = getFactoryID(_shapeFactory);
			shapeDesc.definitionData = _currentDrawingShape.definitionData;
			shapeDesc.propertyData = _currentDrawingShape.propertyData;
			// send it down to the model in order to get an ID
			_model.createShape(shapeDesc);
			setFocus();
			dispatchEvent(new WBCanvasEvent(WBCanvasEvent.END_DRAWING_SHAPE));
			_currentDrawingShape = null;
		}
		
		/**
		 * @private
		 */
		protected function drawCancelled(p_evt:WBShapeEvent):void
		{
			_currentDrawingShape.removeEventListener(WBShapeEvent.DRAWING_COMPLETE, endDrawingShape);
			_currentDrawingShape.removeEventListener(WBShapeEvent.DRAWING_CANCEL, drawCancelled);
			_currentDrawingShape.removeEventListener(WBShapeEvent.TEXT_EDITOR_CREATE, textEditorCreate);
			removeChild(_currentDrawingShape);
			_currentDrawingShape = null;
		}
		
		/**
		 * API for removing event handlers and cleaning up the canvas
		 */
		public function close():void
		{
			_isClosing = true;
			if (_currentDrawingShape) {
				_currentDrawingShape.removeEventListener(WBShapeEvent.DRAWING_COMPLETE, endDrawingShape);
				_currentDrawingShape.removeEventListener(WBShapeEvent.TEXT_EDITOR_CREATE, textEditorCreate);
				_currentDrawingShape.finishEditingText();
			}
			if (stage) {
				if(_selectionRect){
					PopUpManager.removePopUp(_selectionRect);
				}
				stage.removeEventListener(MouseEvent.MOUSE_UP, endGroupSelection);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, trackSelection);
			}
			_selectionGroup = new Array();
			cursorManager.removeAllCursors();
		}
		
		/**
		 * Adds a shape as a child to the canvas.
		 */
		public override function addChild(child:DisplayObject):DisplayObject
		{
			var retObj:DisplayObject = super.addChild(child);
			rawChildren.removeChild(_drawingSurface);
			rawChildren.addChild(_drawingSurface);
			var container:WBShapeContainer = retObj as WBShapeContainer;
			if (container) {
				container.addEventListener(MouseEvent.MOUSE_DOWN, shapeContainerMouseDown);
			}
			
			return retObj;
		}
		
		/**
		 * Sets the X Scale.
		 */
		public override function set scaleX(value:Number):void
		{
			super.scaleX = value;
			_invSelectionChange = true;
			_invDontMoveShape = true;
			invalidateProperties();
		}
		
		
		/**
		 * Sets the Y Scale.
		 */
		public override function set scaleY(value:Number):void
		{
			super.scaleY = value;
			_invSelectionChange = true;
			_invDontMoveShape = true;
			invalidateProperties();
		}
		
		
		/**
		 * Enables/disables Shape Selection on Canvas.
		 */
		public function set enableShapeSelection(p_val:Boolean):void
		{
			if (p_val!=_enableSelection) {
				_enableSelection = p_val;
				_invEnableSelection = true
				invalidateProperties();
				
			}
		}
		
		/**
		 * Sets the model.
		 */
		public function set model(p_model:WBModel):void
		{
			if (p_model == _model) {
				return;
			}
			clearCanvas();
			_model = p_model;
			if (_model.isSynchronized) {
				onModelSync();
			} else {
				_model.addEventListener(WBModelEvent.SYNCHRONIZATION_CHANGE, onModelSync);
			}
		}
		
		/**
		 * @private
		 */
		public function get model():WBModel
		{
			if (!_model) { 
				model = new WBModel();
			}
			return _model;
		}
		
		/**
		 * Clears all shapes and selection from the WBCanvas 
		 */
		public function clearCanvas():void
		{
			clearSelection();
			for (var shapeID:String in _shapeContainersByID) {
				var container:WBShapeContainer = _shapeContainersByID[shapeID];
				container.content.removeEventListener(WBShapeEvent.PROPERTY_CHANGE, shapePropertyChange);
				container.content.removeEventListener(WBShapeEvent.TEXT_EDITOR_CREATE, textEditorCreate);
				removeChild(container);
			}
			_shapeContainersByID = new Object();
		}
		
		/**
		 * @private
		 */
		public function get enableShapeSelection():Boolean
		{
			return _enableSelection;
		}

		/**
		 * Undo whiteboard command. 
		 */
		public function undo():void
		{
			_commandMgr.undo();
		}
		
		/**
		 * Redo whiteboard command. 
		 */
		public function redo():void
		{
			_commandMgr.redo();
		}
		
		/**
		 * Gets the ID's of selected shapes.
		 */
		public function get selectedShapeIDs():Array
		{
			return _selectionGroup;
		}
		
		/**
		 * @private
		 */
		public function set selectedShapeIDs(p_selected:Array):void
		{
			_selectionGroup = p_selected;
			_invSelectionChange = true;
			_invDontMoveShape = true;
			invalidateProperties();
		}
		
		/**
		 * Registers the factory class for creating the shape.
		 */
		public function registerFactory(p_factory:IWBShapeFactory):void
		{
			var factoryID:String;
			if (p_factory.factoryId) {
				factoryID = p_factory.factoryId;
				_registeredFactories[factoryID] = p_factory;
				_drawCustomShapes = true;
				invalidateProperties();
			} else {
				factoryID = flash.utils.getQualifiedClassName(p_factory);
				_registeredFactories[factoryID] = p_factory;
			}
		}
		
		/**
		 * Returns the Properties ToolBar.
		 */
		public function get currentPropertiesToolBar():IWBPropertiesToolBar
		{
			return _currentShapeToolBar;
		}
		
		/**
		 * @private
		 */
		public function clearTextEditor():void
		{
			if (_currentTextShape) {
				_currentTextShape.disposeTextChanges();
			}
		}
		
		/**
		 * @private
		 */
		protected function getFactoryID(p_factory:IWBShapeFactory):String
		{
			for (var i:String in _registeredFactories) {
				if (_registeredFactories[i]==p_factory) {
					return i;
				}
			}
			return null;
		}
		
		/**
		 * @private
		 */
		internal function updateSelectionRect():void
		{
			_invSelectionChange = _invDontMoveShape = true;
			commitProperties();
		}
		
		/**
		 * @private
		 */
		protected function onToolBarChange(p_evt:Event):void
		{
			var shape:WBShapeBase = WBShapeContainer(_shapeContainersByID[_selectionGroup[0]]).content;

			var desc:WBShapeDescriptor = _model.getShapeDescriptor(shape.shapeID).clone();
			var shapeData:Object = shape.propertyData;
			var toolData:Object = _currentShapeToolBar.propertyData;
			for (var i:String in toolData) {
				shapeData[i] = toolData[i];
			}
			desc.propertyData = shapeData;
			_commandMgr.addCommand(new WBShapesPropertyChange([desc]));
		}
		
		/**
		 * @private
		 */
		protected function addToolBar():void
		{
			if (popupPropertiesToolBar) {
				PopUpManager.addPopUp(_currentShapeToolBar, this);
				var uiToolBar:UIComponent = _currentShapeToolBar as UIComponent;
				if (uiToolBar) {
					uiToolBar.validateNow();
					uiToolBar.setActualSize(uiToolBar.measuredWidth, uiToolBar.measuredHeight);
				}
				
				var pt:Point = new Point(Math.round((width-_currentShapeToolBar.width)/2), height-_currentShapeToolBar.height);
				pt = _currentShapeToolBar.parent.globalToLocal(localToGlobal(pt));
				_currentShapeToolBar.move(pt.x, pt.y);
			}
			dispatchEvent(new WBCanvasEvent(WBCanvasEvent.PROPERTIES_TOOLBAR_ADD));
		}
		
		/**
		 * @private
		 */
		protected function removeToolBar():void
		{
			if (popupPropertiesToolBar) {
				PopUpManager.removePopUp(_currentShapeToolBar);
			}
			if (_currentShapeToolBar) {
				_currentShapeToolBar.removeEventListener("shapePropertyChange", onToolBarChange);
				_currentShapeToolBar = null;
			}
			dispatchEvent(new WBCanvasEvent(WBCanvasEvent.PROPERTIES_TOOLBAR_REMOVE));
		}
		
		/**
		 * @private
		 */
		protected override function commitProperties():void
		{
			super.commitProperties();
			
			if (!_model) {
				_model = new WBModel();
			} 
			_drawingSurface.visible = !_enableSelection;
			
			if (_invEnableSelection) {
				_drawingSurface.visible = !_enableSelection;
				if (_enableSelection) {
					addEventListener(MouseEvent.MOUSE_DOWN, beginGroupSelection);
				} else {
					if (selectedShapeIDs.length>0) {
						selectedShapeIDs = [];
					}
					removeEventListener(MouseEvent.MOUSE_DOWN, beginGroupSelection);
					if (stage) {
						stage.removeEventListener(MouseEvent.MOUSE_UP, endGroupSelection);
					}
				}
			}			
			if (_invSelectionChange) {
				_invSelectionChange = false;
				
				if (_currentShapeToolBar && !((_currentShapeToolBar is WBTextToolBar) && _tmpHitSurface!=null) && !_shapeFactory) {
					removeToolBar();
				}

				for (var s:int=_selectionGroup.length-1; s>=0; s--) {
					if (_shapeContainersByID[_selectionGroup[s]]==null) {
						var t:Boolean = true;
						_selectionGroup.splice(s, 1);
					}
				}

				if (_selectionGroup.length>0) {


					if (!_groupSelectionHandles) {
						_groupSelectionHandles = new WBDragHandles();
	
						_groupSelectionHandles.addEventListener(WBShapeEvent.POSITION_CHANGE, groupMove);
						_groupSelectionHandles.addEventListener(WBShapeEvent.ROTATION_CHANGE, groupRotation);
						_groupSelectionHandles.addEventListener(WBShapeEvent.SIZE_CHANGE, groupResize);
						_groupSelectionHandles.addEventListener(WBShapeEvent.POSITION_SIZE_ROTATE_END, commitPositionSizeRotation);
						
						if (selectionHandlesContainer==null) {
							PopUpManager.addPopUp(_groupSelectionHandles, this);
						} else {
							selectionHandlesContainer.addChild(_groupSelectionHandles);
						}
					}

					var minPt:Point;
					var maxPt:Point;
					var kid:WBShapeContainer;
					if (_selectionGroup.length==1) {
						// fit to the one shape
						kid = _shapeContainersByID[_selectionGroup[0]] as WBShapeContainer;
						if (kid.content) {
							kid.content.validateNow();
						}
						kid.validateNow();
						minPt = _groupSelectionHandles.parent.globalToLocal(localToGlobal(new Point(kid.shapeX, kid.shapeY)));
						maxPt = _groupSelectionHandles.parent.globalToLocal(localToGlobal(new Point(kid.shapeX+kid.shapeWidth, kid.shapeY+kid.shapeHeight)));
						_groupSelectionHandles.width = maxPt.x-minPt.x;
						_groupSelectionHandles.height = maxPt.y-minPt.y;
						_groupSelectionHandles.moveShape(minPt.x, minPt.y);
						_groupSelectionHandles.rotation = kid.rotation;
						_groupSelectionHandles.doubleClickEnabled = true;
						_groupSelectionHandles.addEventListener(MouseEvent.DOUBLE_CLICK, shapeDoubleClick);
						_groupSelectionHandles.toolTip = _lm.getString("Double-Click to Add or Edit Text");

						// TODO : nigel : yikes?
						_currentShapeToolBar = kid.content.shapeFactory.toolBar;
						if (_currentShapeToolBar) {
							_currentShapeToolBar.addEventListener("shapePropertyChange", onToolBarChange);
							_currentShapeToolBar.propertyData = kid.content.propertyData;
							addToolBar();
						}
						
					} else {
						_groupSelectionHandles.toolTip = _lm.getString("Shift-Click to Select or Deselect Shapes");
						_groupSelectionHandles.doubleClickEnabled = false;
						_groupSelectionHandles.removeEventListener(MouseEvent.DOUBLE_CLICK, shapeDoubleClick);
						_groupSelectionHandles.rotation = 0;
						// recalculate the bounds of selection
						var minX:Number = Number.POSITIVE_INFINITY;
						var minY:Number = Number.POSITIVE_INFINITY;
						var maxX:Number = 0;
						var maxY:Number = 0;
	
						var l:int = _selectionGroup.length;
						for (var i:uint=0; i<l; i++) {
							kid = _shapeContainersByID[_selectionGroup[i]] as WBShapeContainer;
							minX = Math.min(minX, kid.x);
							minY = Math.min(minY, kid.y);
							maxX = Math.max(maxX, kid.x+kid.width);
							maxY = Math.max(maxY, kid.y+kid.height);
						}
						minPt = _groupSelectionHandles.parent.globalToLocal(localToGlobal(new Point(minX, minY)));
						maxPt = _groupSelectionHandles.parent.globalToLocal(localToGlobal(new Point(maxX, maxY)));
						_groupSelectionHandles.moveShape(minPt.x, minPt.y);
						_groupSelectionHandles.width = maxPt.x-minPt.x;
						_groupSelectionHandles.height = maxPt.y-minPt.y;
					}
					_groupSelectionHandles.handlesVisible = true;
					cursorManager.removeAllCursors();
					if (isModifierDown) {
						_groupSelectionHandles.mouseBlocking = false;
					}
					if (!_invDontMoveShape) {
						_groupSelectionHandles.beginMouseTracking();
					} else {
						_invDontMoveShape = false;
					}
					_groupSelectionHandles.validateNow();
					normalizeGroupSelection();

				} else {
					disposeGroupSelection();
				}
				dispatchEvent(new Event("selectionChange"));
				
			}
			if (_invNewShapeFactory) {
				_invNewShapeFactory = false;
				if (_shapeFactory) {
					if (_currentShapeToolBar) {
						removeToolBar();
					}
					_currentShapeToolBar = _shapeFactory.toolBar;
					if (_currentShapeToolBar) {
						addToolBar();
					}
				} else if (_currentShapeToolBar) {
					removeToolBar();
				}
			}
			
			if (_drawCustomShapes) {
				_drawCustomShapes = false;
				drawRemainingItems();
			}
			
		}
		
		/**
		 * Sets the current Shape Factory.
		 */
		public function set currentShapeFactory(p_shapeFactory:IWBShapeFactory):void
		{
			if (_shapeFactory!=p_shapeFactory) {
				_shapeFactory = p_shapeFactory;
				_invNewShapeFactory = true;
				invalidateProperties();
			}
			if (_shapeFactory) {
				_currentCursorClass = _shapeFactory.cursor;
			} else {
				_currentCursorClass = null;
				cursorManager.removeAllCursors();
			}
			dispatchEvent(new WBCanvasEvent(WBCanvasEvent.CURSOR_CHANGE));
		}
		
		/**
		 * Returns the current class for Cursor.
		 */
		public function get currentCursorClass():Class
		{
			return _currentCursorClass;
		}
		
		/**
		 * Add a shape to list of selected shapes.
		 */
		public function addToSelection(p_shapeID:String):void
		{
			var idx:int = _selectionGroup.indexOf(p_shapeID);
			if (idx!=-1) {
				return;
			}
			_selectionGroup.push(p_shapeID);
			_invSelectionChange = true;
			invalidateProperties();
		}
		
		/**
		 * Remove a shape from list of selected shapes.
		 */
		public function removeFromSelection(p_shapeID:String):void
		{
			var idx:int = _selectionGroup.indexOf(p_shapeID);
			if (idx==-1) {
				return;
			}
			_selectionGroup.splice(idx, 1);
			_invSelectionChange = true;
			invalidateProperties();
		}
		
		/**
		 * Clear list of selected shapes.
		 */
		public function clearSelection():void
		{
			initializeSelection();
			_invSelectionChange = true;
			invalidateProperties();
		}
		
		/**
		 * Delete all selected shapes.
		 */
		public function removeSelectedShapes():void
		{
			if (!_groupSelectionHandles) {
				// no op
				return;
			}
			// delete all selected items
			_groupSelectionHandles.clearAllEvents();
			var selectedDescriptors:Array = new Array();
			var i:int = 0;
			while (i<_selectionGroup.length) {
				var kid:WBShapeContainer = _shapeContainersByID[_selectionGroup[i]] as WBShapeContainer;

				selectedDescriptors.push(_model.getShapeDescriptor(kid.content.shapeID));
				removeFromSelection(kid.content.shapeID);
				
			}
			_commandMgr.removeRecentCommands(WBSelectionChange);
			_commandMgr.addCommand(new WBRemoveShapes(selectedDescriptors));
			cursorManager.removeAllCursors();
		}		
		
		/**
		 * Returns the container of the given shape.
		 */
		public function getShapeContainer(p_shapeID:String):WBShapeContainer
		{
			return _shapeContainersByID[p_shapeID] as WBShapeContainer;
		}
		
		/**
		 * @private
		 */
		protected function drawFromExistingModel():void
		{
			var shapeIDs:Array = _model.getShapeIDs();
			var l:uint = shapeIDs.length;
			for (var i:uint=0; i<l; i++) {
				drawShape(_model.getShapeDescriptor(shapeIDs[i]));
			}
		}
		
		/**
		 * @private
		 */
		protected function drawRemainingItems():void
		{
			if (_model) {
				var shapeIDs:Array = _model.getShapeIDs();
				var l:uint = shapeIDs.length;
				for (var i:uint=0; i<l; i++) {
					if (!_shapeContainersByID[shapeIDs[i]]){
						drawShape(_model.getShapeDescriptor(shapeIDs[i]));
					}
				}
			}
		}
		
		/**
		 * @private
		 */
		protected function drawShape(p_desc:WBShapeDescriptor, p_animate:Boolean=false):void
		{
			var newContainer:WBShapeContainer = new WBShapeContainer();
			addChild(newContainer);
//			newContainer.setActualSize(p_desc.width, p_desc.height);
			var factory:IWBShapeFactory = _registeredFactories[p_desc.factoryID] as IWBShapeFactory;
			if (!factory) {
				// we should not get here, but a little defensive coding to prevent RTEs
				return;
			}
			var shape:WBShapeBase = factory.newShape();
			shape.definitionData = p_desc.definitionData;
			shape.canvas = this;
			shape.propertyData = p_desc.propertyData;
			shape.shapeFactory = factory;
			shape.animateEntry = p_animate;
			newContainer.content = shape;
			shape.shapeID = p_desc.shapeID;
			_shapeContainersByID[p_desc.shapeID] = newContainer;
			shape.addEventListener(WBShapeEvent.PROPERTY_CHANGE, shapePropertyChange);
			shape.addEventListener(WBShapeEvent.TEXT_EDITOR_CREATE, textEditorCreate);
			shape.addEventListener(WBShapeEvent.TEXT_EDITOR_DESTROY, textEditorDestroy);
			shape.popupTextToolBar = popupPropertiesToolBar;

			newContainer.rotation = p_desc.rotation;
			newContainer.validateNow();
			newContainer.width = p_desc.width;
			newContainer.height = p_desc.height;
			newContainer.move(p_desc.x, p_desc.y);
			newContainer.validateNow();
			
		}
		
		/**
		 * @private
		 */
		protected function textEditorCreate(p_evt:WBShapeEvent):void
		{
			if (_currentShapeToolBar) {
				removeToolBar();
			}
			_tmpHitSurface = new UIComponent();
			addChild(_tmpHitSurface);
			var g:Graphics = _tmpHitSurface.graphics;
			g.beginFill(0, 0);
			g.drawRect(0,0,unscaledWidth, unscaledHeight);
			if (_groupSelectionHandles) {
				_groupSelectionHandles.handlesEnabled = false;
			}
			_tmpHitSurface.addEventListener(MouseEvent.CLICK, onTmpHit);
			_currentTextShape = WBShapeBase(p_evt.target);
			if (_previousTextFormat && _currentTextShape.textEditor) {
				_currentTextShape.textEditor.defaultTextFormat = _previousTextFormat;
			}
			_currentTextShape.addEventListener(WBShapeEvent.TEXT_EDITOR_DESTROY, textEditorDestroy);
			_currentShapeToolBar = _currentTextShape.textToolBar as IWBPropertiesToolBar;
			dispatchEvent(new WBCanvasEvent(WBCanvasEvent.PROPERTIES_TOOLBAR_ADD));
		}
		
		/**
		 * @private
		 */
		protected function onTmpHit(p_evt:Event):void
		{
			
		}
		
		/**
		 * @private
		 */
		protected function textEditorDestroy(p_evt:Event):void
		{
			if (_currentTextShape) {
				_currentTextShape.removeEventListener(WBShapeEvent.TEXT_EDITOR_DESTROY, textEditorDestroy);
				_previousTextFormat = _currentTextShape.currentTextFormat;
				
				if(_tmpHitSurface) {
					_tmpHitSurface.removeEventListener(MouseEvent.CLICK, onTmpHit);
					removeChild(_tmpHitSurface);
					_tmpHitSurface = null;
				}
				removeToolBar();
				if (_groupSelectionHandles) {
					_groupSelectionHandles.handlesEnabled = true;
				}
				_currentTextShape = null;
			}
		}
		
		//::: MODEL LISTENERS. 
		/**
		 * @private
		 */
		protected function onModelSync(p_evt:WBModelEvent=null):void
		{
			if (_model.isSynchronized) {
				// when the model is ready for us, we build from what's there already
				drawFromExistingModel();
				_model.addEventListener(WBModelEvent.SHAPE_CREATE, onShapeCreate);
				_model.addEventListener(WBModelEvent.SHAPE_ADD, onShapeAdd);
				_model.addEventListener(WBModelEvent.SHAPE_POSITION_SIZE_ROTATION_CHANGE, onShapePositionSizeRotate);
				_model.addEventListener(WBModelEvent.SHAPE_PROPERTIES_CHANGE, onShapePropertiesChange);
				_model.addEventListener(WBModelEvent.SHAPE_REMOVE, onShapeRemove);
				_model.addEventListener(CollectionNodeEvent.RECONNECT, onReconnect);
			}
		}
		
		/**
		 * @private
		 */
		protected function onReconnect(p_evt:CollectionNodeEvent):void
		{
			clearCanvas();
			_model.removeEventListener(WBModelEvent.SHAPE_CREATE, onShapeCreate);
			_model.removeEventListener(WBModelEvent.SHAPE_ADD, onShapeAdd);
			_model.removeEventListener(WBModelEvent.SHAPE_POSITION_SIZE_ROTATION_CHANGE, onShapePositionSizeRotate);
			_model.removeEventListener(WBModelEvent.SHAPE_PROPERTIES_CHANGE, onShapePropertiesChange);
			_model.removeEventListener(WBModelEvent.SHAPE_REMOVE, onShapeRemove);
			_model.removeEventListener(CollectionNodeEvent.RECONNECT, onReconnect);
		}
		
		/**
		 * @private
		 */
		protected function onShapeCreate(p_evt:WBModelEvent):void
		{
			if (p_evt.isLocalChange) {
				var shapeDesc:WBShapeDescriptor = _model.getShapeDescriptor(p_evt.shapeID);
				// really, this is just testing code. Only the canvas that really drew the shape should add the shape. 
				// Won't be used in shared canvases, only if there's 2 canvases on the same local model.
				if (!_model.getIsAdded(p_evt.shapeID)) {
					// we got a shape back from the model. Use its ID to add
					_commandMgr.addCommand(new WBAddShapes([shapeDesc]));
				}
			}
		}
		
		/**
		 * @private
		 */
		protected function onShapeAdd(p_evt:WBModelEvent):void
		{
			var shapeDesc:WBShapeDescriptor = _model.getShapeDescriptor(p_evt.shapeID);
			var factory:IWBShapeFactory = _registeredFactories[shapeDesc.factoryID] as IWBShapeFactory;
			drawShape(shapeDesc, !p_evt.isLocalChange);
			if (p_evt.isLocalChange) {
				if (_pendingAddedShapes.length>0) {
					var oldShape:WBShapeBase = _pendingAddedShapes.shift() as WBShapeBase;
					removeChild(oldShape);
				}
				if (factory.toggleSelectionAfterDraw) {
					_commandMgr.addCommand(new WBSelectionChange([p_evt.shapeID]));
				}				
			}
		}
		
		/**
		 * @private
		 */
		protected function onShapePositionSizeRotate(p_evt:WBModelEvent):void
		{
			var sContainer:WBShapeContainer = _shapeContainersByID[p_evt.shapeID] as WBShapeContainer;
			var shapeDesc:WBShapeDescriptor = _model.getShapeDescriptor(p_evt.shapeID);

			if (!p_evt.isLocalChange && (sContainer.x!=shapeDesc.x || sContainer.y!=shapeDesc.y || 
					sContainer.shapeWidth!=shapeDesc.width || sContainer.shapeHeight!=shapeDesc.height || sContainer.rotation!=shapeDesc.rotation)) {
				var shapeTween:WBShapeTween = new WBShapeTween(sContainer, shapeDesc, this);
			}
		}
		
		/**
		 * @private
		 */
		protected function onShapePropertiesChange(p_evt:WBModelEvent):void
		{
			var data:* = _model.getShapeDescriptor(p_evt.shapeID).propertyData;
			WBShapeContainer(_shapeContainersByID[p_evt.shapeID]).content.propertyData = data;
		}
		
		/**
		 * @private
		 */
		protected function onShapeRemove(p_evt:WBModelEvent):void
		{
			var removedShapeContainer:WBShapeContainer = _shapeContainersByID[p_evt.shapeID] as WBShapeContainer;
			removedShapeContainer.content.removeEventListener(WBShapeEvent.PROPERTY_CHANGE, shapePropertyChange);
			removedShapeContainer.content.removeEventListener(WBShapeEvent.TEXT_EDITOR_CREATE, textEditorCreate);
			if (false) {
				removeChild(removedShapeContainer);
			} else {
				var f:Fade = new Fade(removedShapeContainer);
				f.alphaFrom = 1;
				f.alphaTo = 0;
				f.duration = 350;
				f.play();
				var b:Blur = new Blur(removedShapeContainer);
				b.blurXFrom = b.blurYFrom = 0;
				b.blurXTo = b.blurYTo = 30;
				b.duration = 250;
				b.play();
				f.addEventListener(EffectEvent.EFFECT_END, fadeOutEnd);
			}
			delete _shapeContainersByID[p_evt.shapeID];
			if (_selectionGroup.length>0) {
				updateSelectionRect();
			}
		}
		
		/**
		 * @private
		 */
		protected function fadeOutEnd(p_evt:EffectEvent):void
		{
			removeChild(DisplayObject(Fade(p_evt.target).target));
		}

		// ::: SHAPE listeners
		/**
		 * @private
		 */
		protected function shapePropertyChange(p_evt:WBShapeEvent):void
		{
			if (_isClosing) {
				return;
			}
			var shape:WBShapeBase = WBShapeBase(p_evt.target);
			var desc:WBShapeDescriptor = _model.getShapeDescriptor(shape.shapeID).clone();
			desc.propertyData = shape.propertyData;
			_commandMgr.addCommand(new WBShapesPropertyChange([desc]));
			_invSelectionChange = true;
			invalidateProperties();
		}
		
		/**
		 * @private
		 */
		protected function shapeDoubleClick(p_evt:MouseEvent):void
		{
			if (_currentShapeToolBar) {
				removeToolBar();
			}
			var toolBar:EditorToolBar = WBShapeContainer(_shapeContainersByID[_selectionGroup[0]]).content.focusTextEditor();
			if (popupPropertiesToolBar) {
				var pt:Point = new Point(Math.round((width-toolBar.width)/2), height-toolBar.height);
				pt = toolBar.parent.globalToLocal(localToGlobal(pt));
				toolBar.move(pt.x, pt.y);			
			}
		}
		
		/**
		 * @private
		 */
		protected function shapeContainerMouseDown(p_evt:MouseEvent):void
		{
			var shapeIDClicked:String = WBShapeContainer(p_evt.currentTarget).content.shapeID;
			var newSelection:Array;
			var selChange:WBSelectionChange;
			if (isModifierDown) {
				newSelection = _selectionGroup.slice();
				p_evt.stopImmediatePropagation();
				// adding or removing from current selection
				var idx:int = _selectionGroup.indexOf(shapeIDClicked);
				if (idx!=-1) {
					// it's selected - unselect
					newSelection.splice(idx,1);
					selChange = new WBSelectionChange(newSelection);
					_commandMgr.addCommand(selChange);
				} else {
					newSelection.push(shapeIDClicked);
					selChange = new WBSelectionChange(newSelection);
					_commandMgr.addCommand(selChange);
				}

			} else {
				
				newSelection = [shapeIDClicked];
				selChange = new WBSelectionChange(newSelection);
				_commandMgr.addCommand(selChange);
				_invDontMoveShape = false;
				validateNow();
			}
			setFocus();
		}
		
		/**
		 * @private
		 */
		protected function beginGroupSelection(p_evt:MouseEvent):void
		{
			if (p_evt.target!=this) {
				return;
			}
			var newSelection:Array;
			var selChange:WBSelectionChange;
			if (p_evt.ctrlKey || p_evt.shiftKey) {
				// TODO : nig - dunno what I'm doing here yet
			} else {
				newSelection = new Array();
				selChange = new WBSelectionChange(newSelection);
				_commandMgr.addCommand(selChange);
			}
			if (stage) {
				if (stage.hasEventListener(MouseEvent.MOUSE_UP)) {
					if(_selectionRect) {
						_selectionRect.graphics.clear();
						PopUpManager.removePopUp(_selectionRect);
						_selectionRect = null;
					}
					stage.removeEventListener(MouseEvent.MOUSE_UP, endGroupSelection);
				}
				stage.addEventListener(MouseEvent.MOUSE_UP, endGroupSelection);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, trackSelection);
			}
			cursorManager.setCursor(_crosshairsCursor);
			_selectionRect = new UIComponent();
			PopUpManager.addPopUp(_selectionRect, this);
			_selectionRect.move(0,0);
			_selectionOrigin = new Point(p_evt.stageX, p_evt.stageY);
		}
		
		/**
		 * @private
		 */
		protected function endGroupSelection(p_evt:MouseEvent):void
		{
			cursorManager.removeAllCursors();
			if(stage){
				stage.removeEventListener(MouseEvent.MOUSE_UP, endGroupSelection);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, trackSelection);
			}
			var newSelection:Array = new Array();
			var selectionBounds:Rectangle = _selectionRect.getBounds(this);
			var originPt:Point = _selectionRect.parent.globalToLocal(this.localToGlobal(new Point(selectionBounds.x, selectionBounds.y)));
			var lowerRightPt:Point = _selectionRect.parent.globalToLocal(this.localToGlobal(new Point(selectionBounds.x+selectionBounds.width, selectionBounds.y+selectionBounds.height)));
			var leftX:int = Math.round(originPt.x);
			var rightX:int = Math.round(lowerRightPt.x);
			var topY:int = Math.round(originPt.y);
			var botY:int = Math.round(lowerRightPt.y);

			var l:int = numChildren;
			for (var i:int=0; i<l; i++) {
				var kid:WBShapeContainer = getChildAt(i) as WBShapeContainer;
				if (kid!=null && kid.content && kid.content.hitTestObject(_selectionRect)) {
					// ok, there's some overlap. Scan the borders of the selection
					var intersectsEdge:Boolean = false;					
					var j:int;
					// unfortunately, we're forced to scan using hitTestPoint.. sampling every 3 pixels 
					// assume the right edge is most likely to hit the shape. 					
					for (j=topY; j<=botY; j+=3) {
						if (kid.content.hitTestPoint(rightX, j, true)) {
							intersectsEdge = true;
							break;
						}
					}
					if (intersectsEdge) {
						// no need to keep looking at this shape
						continue;
					}
					// next, assume the bottom edge is most likely
					for (j=leftX; j<=rightX; j+=3) {
						if (kid.content.hitTestPoint(j, botY, true)) {
							intersectsEdge = true;
							break;
						}
					}
					if (intersectsEdge) {
						// no need to keep looking at this shape
						continue;
					}
					// next, left edge
					for (j=topY; j<=botY; j+=3) {
						if (kid.content.hitTestPoint(leftX, j, true)) {
							intersectsEdge = true;
							break;
						}
					}
					if (intersectsEdge) {
						// no need to keep looking at this shape
						continue;
					}
					// last, top edge
					for (j=leftX; j<=rightX; j+=3) {
						if (kid.content.hitTestPoint(j, topY, true)) {
							intersectsEdge = true;
							break;
						}
					}
					if (intersectsEdge) {
						// no need to keep looking at this shape
						continue;
					}
					_invDontMoveShape = true;
					newSelection.push(kid.content.shapeID);
					// wow, we found a shape legitimately in the selection. 
					// TODO : nigel - we need to eliminate possible false positives (wait until someone complains)
				}
			}
			if (_selectionGroup.length!=0 || newSelection.length!=0) {
				var selChange:WBSelectionChange = new WBSelectionChange(newSelection);
				_commandMgr.addCommand(selChange);
			}
			setFocus();
			_selectionRect.graphics.clear();
			PopUpManager.removePopUp(_selectionRect);
			_selectionRect = null;
		}
		
		/**
		 * @private
		 */
		protected function groupMove(p_evt:WBShapeEvent=null):void
		{
			var l:int = _selectionGroup.length;
			for (var i:int=0; i<l; i++) {
				var kid:WBShapeContainer = _shapeContainersByID[_selectionGroup[i]] as WBShapeContainer;
				var details:Object = _selectionGroupDetails[i];
				var tmpX:Number = details.x*_groupSelectionHandles.shapeWidth;
				var tmpY:Number = details.y*_groupSelectionHandles.shapeHeight;
				var localPt:Point = globalToLocal(_groupSelectionHandles.localToGlobal(new Point(tmpX, tmpY)));
				kid.move(localPt.x-kid.width/2, localPt.y-kid.height/2);
			}
			setFocus();
		}
		
		/**
		 * @private
		 */
		protected function groupRotation(p_evt:WBShapeEvent=null):void
		{
			var l:int = _selectionGroup.length;
			for (var i:int=0; i<l; i++) {
				var kid:WBShapeContainer = _shapeContainersByID[_selectionGroup[i]] as WBShapeContainer;
				var details:Object = _selectionGroupDetails[i];
				var tmpX:Number = details.x*_groupSelectionHandles.shapeWidth;
				var tmpY:Number = details.y*_groupSelectionHandles.shapeHeight;
				var localPt:Point = globalToLocal(_groupSelectionHandles.localToGlobal(new Point(tmpX, tmpY)));
				
				kid.rotation = normalizeRotation(details.rotation + _groupSelectionHandles.rotation);
				kid.validateNow();
				kid.move(localPt.x-kid.width/2, localPt.y-kid.height/2);
			}
			setFocus();
		}
		
		/**
		 * @private
		 */
		protected function groupResize(p_evt:WBShapeEvent=null):void
		{
			var l:int = _selectionGroup.length;
			for (var i:int=0; i<l; i++) {
				var kid:WBShapeContainer = _shapeContainersByID[_selectionGroup[i]] as WBShapeContainer;
				var details:Object = _selectionGroupDetails[i];
				var tmpX:Number = details.x*_groupSelectionHandles.shapeWidth;
				var tmpY:Number = details.y*_groupSelectionHandles.shapeHeight;
				
				var localPt:Point;
				if (p_evt.sizingDirection==WBShapeEvent.SIZING_WIDTH) {
					if ((details.rotation>45 && details.rotation<135) || (details.rotation>-135 && details.rotation<-45)) {
						// the axes are lined up such that when sizing with, we should size shapeHeight
						kid.height = details.width*_groupSelectionHandles.shapeWidth;
					} else {
						kid.width = details.width*_groupSelectionHandles.shapeWidth;
					}
				} else if (p_evt.sizingDirection==WBShapeEvent.SIZING_HEIGHT) {
					if ((details.rotation>45 && details.rotation<135) || (details.rotation>-135 && details.rotation<-45)) {
						kid.width = details.height*_groupSelectionHandles.shapeHeight;
					} else {
						kid.height = details.height*_groupSelectionHandles.shapeHeight;
					}
				} else {
					if ((details.rotation>45 && details.rotation<135) || (details.rotation>-135 && details.rotation<-45)) {
						kid.width = details.height*_groupSelectionHandles.shapeHeight;
						kid.height = details.width*_groupSelectionHandles.shapeWidth;
					} else {
						kid.width = details.width*_groupSelectionHandles.shapeWidth;
						kid.height = details.height*_groupSelectionHandles.shapeHeight;
					}
					
				}
				localPt = globalToLocal(_groupSelectionHandles.localToGlobal(new Point(tmpX, tmpY)));
				kid.validateNow();
				kid.move(localPt.x-kid.width/2,localPt.y-kid.height/2);
			}
			setFocus();
		}
		
		/**
		 * @private
		 */
		protected function commitPositionSizeRotation(p_evt:Event=null):void
		{
			var l:int = _selectionGroup.length;
			var selectedDescs:Array = new Array();
			for (var i:int=0; i<l; i++) {
				var kid:WBShapeContainer = _shapeContainersByID[_selectionGroup[i]] as WBShapeContainer;
				var shapeDesc:WBShapeDescriptor = _model.getShapeDescriptor(kid.content.shapeID).clone();
				if (shapeDesc.x!=kid.x || shapeDesc.y!=kid.y || shapeDesc.width!=kid.shapeWidth
					 || shapeDesc.height!=kid.shapeHeight || shapeDesc.rotation!=kid.rotation) {
					shapeDesc.x = kid.x;
					shapeDesc.y = kid.y;
					shapeDesc.width = kid.shapeWidth;
					shapeDesc.height = kid.shapeHeight;
					shapeDesc.rotation = kid.rotation;
					selectedDescs.push(shapeDesc);
				}
			}
			if (selectedDescs.length>0) {
				_commandMgr.addCommand(new WBShapeContainersChange(selectedDescs));
			}
		}
		
		/**
		 * @private
		 */
		protected function normalizeGroupSelection():void
		{
			// store the center point, width, height, and rotation, relative to the group handles
			_selectionGroupDetails = new Array();
			var l:int = _selectionGroup.length;
			for (var i:int=0; i<l; i++) {
				var kid:WBShapeContainer = _shapeContainersByID[_selectionGroup[i]] as WBShapeContainer;
				var relativeRotation:Number = normalizeRotation(kid.rotation - _groupSelectionHandles.rotation);
				var kidCenter:Point = _groupSelectionHandles.globalToLocal(localToGlobal(new Point(kid.x + kid.width/2, kid.y+kid.height/2)));
				var relativeCenterX:Number = kidCenter.x/_groupSelectionHandles.shapeWidth;
				var relativeCenterY:Number = kidCenter.y/_groupSelectionHandles.shapeHeight;
				var relativeWidth:Number;
				var relativeHeight:Number;
				if ((relativeRotation>45 && relativeRotation<135) || (relativeRotation>-135 && relativeRotation<-45)) {
					relativeWidth = kid.shapeHeight/_groupSelectionHandles.shapeWidth;
					relativeHeight = kid.shapeWidth/_groupSelectionHandles.shapeHeight;
				} else {
					relativeWidth = kid.shapeWidth/_groupSelectionHandles.shapeWidth;
					relativeHeight = kid.shapeHeight/_groupSelectionHandles.shapeHeight;
				}
				_selectionGroupDetails.push({x:relativeCenterX, y:relativeCenterY, width:relativeWidth, height:relativeHeight, rotation:relativeRotation});
			}
		}
		
		/**
		 * @private
		 */
		protected function trackSelection(p_evt:MouseEvent):void
		{
			var g:Graphics = _selectionRect.graphics;
			g.clear();
			g.lineStyle(1, 0x3a3a6a, 0.6, true);
			g.beginGradientFill("linear", [0x6a6a9a, 0x595989], [0.2, 0.2], [0, 255]);
			g.drawRect(Math.min(_selectionOrigin.x, p_evt.stageX), Math.min(_selectionOrigin.y, p_evt.stageY),
						Math.abs(p_evt.stageX-_selectionOrigin.x), Math.abs(p_evt.stageY-_selectionOrigin.y));
		}
		
		/**
		 * @private
		 */
		protected function disposeGroupSelection():void
		{
			if (_groupSelectionHandles) {
				_groupSelectionHandles.clearAllEvents();
				
				if (selectionHandlesContainer==null) {
					PopUpManager.removePopUp(_groupSelectionHandles);
				} else {
					selectionHandlesContainer.removeChild(_groupSelectionHandles);
				}
				_groupSelectionHandles.removeEventListener(WBShapeEvent.POSITION_CHANGE, groupMove);
				_groupSelectionHandles.removeEventListener(WBShapeEvent.ROTATION_CHANGE, groupRotation);
				_groupSelectionHandles.removeEventListener(WBShapeEvent.SIZE_CHANGE, groupResize);
				_groupSelectionHandles.removeEventListener(MouseEvent.DOUBLE_CLICK, shapeDoubleClick);
				_groupSelectionHandles.removeEventListener(WBShapeEvent.POSITION_SIZE_ROTATE_END, commitPositionSizeRotation);
				_groupSelectionHandles = null;
			}
		}
		
		/**
		 * @private
		 */
		protected function normalizeRotation(p_val:Number):Number
		{
			if (p_val>=360) {
				return normalizeRotation(p_val-360);
			} else if (p_val<=-360) {
				return normalizeRotation(p_val+360); 
			} else if (p_val<-180) {
				return p_val+360;
			} else if (p_val>180) {
				return p_val-360;
			} else {
				return p_val;
			}
		}
		
		/**
		 * @private
		 */
		protected override function focusInHandler(p_evt:FocusEvent):void
		{
			super.focusInHandler(p_evt);
			addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
		
		}
		
		/**
		 * @private
		 */
		protected override function focusOutHandler(p_evt:FocusEvent):void
		{
			super.focusOutHandler(p_evt);
			removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			removeEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			_isShiftDown = false;
			_isControlDown = false;		
		}


		/**
		 * @private
		 */
		protected override function keyDownHandler(p_evt:KeyboardEvent):void
		{
			super.keyDownHandler(p_evt);
			if (p_evt.keyCode==Keyboard.SHIFT) {
				_isShiftDown = true;
			} else if (p_evt.keyCode==Keyboard.CONTROL) {
				_isControlDown = true;
			}
			
			if (p_evt.ctrlKey) {//if one presses the ctrl key
				switch (p_evt.charCode) {
					case 90:	//CTRL+z
					case 122:	//CTRL+Z
						undo();
						break;
					case 89:	//CTRL+y
					case 121:	//CTRL+Y
						redo();
						break;
				}
			}			
			if (_groupSelectionHandles) {
				if (p_evt.keyCode==Keyboard.DELETE || p_evt.keyCode==Keyboard.BACKSPACE) {
					removeSelectedShapes();	
				} else if (p_evt.keyCode==Keyboard.RIGHT) {
					_groupSelectionHandles.move(Math.min(width-_groupSelectionHandles.width, _groupSelectionHandles.x + ((_isShiftDown) ? 10 : 2)), _groupSelectionHandles.y);
					_groupSelectionHandles.validateNow();
					groupMove();
//					commitPositionSizeRotation();
				} else if (p_evt.keyCode==Keyboard.LEFT) {
					_groupSelectionHandles.move(Math.max(0, _groupSelectionHandles.x - ((_isShiftDown) ? 10 : 2)), _groupSelectionHandles.y);
					_groupSelectionHandles.validateNow();
					groupMove();
//					commitPositionSizeRotation();
				} else if (p_evt.keyCode==Keyboard.UP) {
					_groupSelectionHandles.move(_groupSelectionHandles.x, Math.max(0, _groupSelectionHandles.y - ((_isShiftDown) ? 10 : 2)));
					_groupSelectionHandles.validateNow();
					groupMove();
//					commitPositionSizeRotation();
				} else if (p_evt.keyCode==Keyboard.DOWN) {
					_groupSelectionHandles.move(_groupSelectionHandles.x, Math.min(height-_groupSelectionHandles.height, _groupSelectionHandles.y + ((_isShiftDown) ? 10 : 2)));
					_groupSelectionHandles.validateNow();
					groupMove();
//					commitPositionSizeRotation();
				}
			}
			if (_isControlDown && (p_evt.keyCode==97 || p_evt.keyCode==4294967295)) {
				for (var j:int=0; j<numChildren; j++) {
					var sContainer:WBShapeContainer = getChildAt(j) as WBShapeContainer;
					if (sContainer) {
						addToSelection(sContainer.content.shapeID);
					}
					_invDontMoveShape = true;
				}
			}
			if (isModifierDown && _groupSelectionHandles) {
				_groupSelectionHandles.mouseBlocking = false;
			}

		}
		/**
		 * @private
		 */
		protected override function keyUpHandler(p_evt:KeyboardEvent):void
		{
			super.keyUpHandler(p_evt);
			if (p_evt.keyCode==Keyboard.SHIFT) {
				_isShiftDown = false;
			} else if (p_evt.keyCode==Keyboard.CONTROL) {
				_isControlDown = false;
			}
			if (p_evt.keyCode==Keyboard.RIGHT || p_evt.keyCode==Keyboard.LEFT || p_evt.keyCode==Keyboard.UP || p_evt.keyCode==Keyboard.DOWN) {
				commitPositionSizeRotation();
			}
			if (_groupSelectionHandles && !_groupSelectionHandles.mouseBlocking && !_isShiftDown) {
				_groupSelectionHandles.mouseBlocking = true;
			}
		}
		
		/**
		 * @private
		 */
		protected function get isModifierDown():Boolean
		{
			return (_isShiftDown || _isControlDown);
		}
	}
}