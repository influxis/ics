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
	import com.adobe.coreUI.controls.whiteboardClasses.IWBPropertiesToolBar;
	import com.adobe.coreUI.controls.whiteboardClasses.WBCanvas;
	import com.adobe.coreUI.controls.whiteboardClasses.WBModel;
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapesToolBar;
	import com.adobe.coreUI.events.WBCanvasEvent;
	import com.adobe.coreUI.events.WBToolBarEvent;
	
	import flash.geom.Point;
	
	import mx.core.UIComponent;
	
	/**
	 * Dispatched when the property tool bar is added.
	 */
	[Event(name="propertiesToolbarAdd", type="com.adobe.events.WBCanvasEvent")]
	/**
	 * Dispatched when the property tool bar is removed.
	 */
	[Event(name="propertiesToolbarRemove", type="com.adobe.events.WBCanvasEvent")]
	/**
	 * Dispatched when one is finished drawing a shape on the  canvas.
	 */	
	[Event(name="endDrawingShape", type="com.adobe.events.WBCanvasEvent")]
	/**
 	*  Alpha level of the color defined by the <code>backgroundColor</code>
 	*  property, of the image or SWF file defined by the <code>backgroundImage</code>
 	*  style.
 	*  Valid values range from 0.0 to 1.0.
 	*  
 	*  @default 1.0
 	*/
	[Style(name="backgroundAlpha", type="Number", inherit="no")]
	/**
	 *  Background color of a component.
	 *  You can have both a <code>backgroundColor</code> and a
	 *  <code>backgroundImage</code> set.
	 *  Some components do not have a background.
	 *  The DataGrid control ignores this style.
	 *  The default value is <code>undefined</code>, which means it is not set.
	 *  If both this style and the <code>backgroundImage</code> style
	 *  are <code>undefined</code>, the component has a transparent background.
	 *
	 *  <p>For the Application container, this style specifies the background color
	 *  while the application loads, and a background gradient while it is running. 
	 *  Flex calculates the gradient pattern between a color slightly darker than 
	 *  the specified color, and a color slightly lighter than the specified color.</p>
	 * 
	 *  <p>The default skins of most Flex controls are partially transparent. As a result, the background color of 
	 *  a container partially "bleeds through" to controls that are in that container. You can avoid this by setting the 
	 *  alpha values of the control's <code class="property">fillAlphas</code> property to 1, as the following example shows:
	 *  <pre>
	 *  &lt;mx:<i>Container</i> backgroundColor="0x66CC66"/&gt;
	 *      &lt;mx:<i>ControlName</i> ... fillAlphas="[1,1]"/&gt;
	 *  &lt;/mx:<i>Container</i>&gt;</pre>
	 *  </p>
	 */
	[Style(name="backgroundColor", type="uint", format="Color", inherit="no")]

	/**
	 * This is a standalone whiteboard component. The SharedWhiteBoard component extends this component.
	 * This has API's for setting the shapes tool bar , properties tool bar, zoom level, selection.
	 * It has a white board model that does bookkeeping of all the shapes.
	 */
   public class  WhiteBoard extends UIComponent
	{
		/**
		 * @private
		 */
		protected var _toolBar:WBShapesToolBar;
		/**
		 * @private
		 */
		protected var _propsBar:UIComponent;
		/**
		 * @private
		 */
		protected var _canvas:WBCanvas;
		/**
		 * @private
		 */
		protected var _model:WBModel;
		/**
		 * @private
		 */
		protected var _zoomLevel:Number = 1;
		/**
		 * @private
		 */
		protected var _invZoom:Boolean = false;
		/**
		 * @private
		 */
		protected var _toolDP:Object;
		/**
		 * @private
		 */
		protected var _propsPt:Point;
		/**
		 * @private
		 */
		protected var _allowSave:Boolean = false;
		/**
		 * @private
		 */
		protected var _selectionContainer:UIComponent;
		
		/**
		 * Returns if the properties tool bar is popped up.
		 */
		public var popupPropertiesToolBar:Boolean = true;
		/**
		 * Returns if the shapes tool bar is popped up.
		 */
		public var popupShapesToolBar:Boolean = true;
		
		
		/**
		 * Determines the model used in this white board
		 */
		public function get model():WBModel
		{
			return _model;
		}
		
		/**
		 * @private
		 */
		public function set model(p_wbModel:WBModel):void
		{
			_model = p_wbModel;
			invalidateProperties();
		}
		
		
		
		/**
		 * The shapes tool Bar
		 */
		public function get shapesToolBar():UIComponent
		{
			return _toolBar;
		}
		
		/**
		 * @private
		 */
		public function set shapesToolBar(p_toolBar:UIComponent):void
		{
			if ( p_toolBar != null ) {
				_toolBar = WBShapesToolBar(p_toolBar);
				_toolBar.wbCanvas = _canvas;
				_toolBar.allowSave = _allowSave;
				invalidateProperties();
			} else {
				_toolBar = null ;
			}
		}

		/**
		 * The current properties tool bar
		 */
		public function get currentPropertiesToolBar():IWBPropertiesToolBar
		{
			return _canvas.currentPropertiesToolBar;
		}

		/**
		 * @private
		 */
		public function set zoomLevel(p_level:Number):void
		{
			if (p_level!=_zoomLevel) {
				_zoomLevel = p_level;
				_invZoom = true;
				invalidateDisplayList();
			}
		}
		
		/**
		 * Returns the zoom level
		 */
		public function get zoomLevel():Number
		{
			return _zoomLevel;
		}

		/**
		 * @private
		 */
		public function set allowSave(p_allow:Boolean):void
		{
			_allowSave = p_allow;
		}
		
		/**
		 * Returns true if saving is allowed
		 */
		public function get allowSave():Boolean
		{
			return _allowSave;
		}

		/**
		 * Hides the selection container
		 */
		public function hideSelection():void
		{
			if (_selectionContainer) {
				_selectionContainer.visible = false;
			}
		}
		
		/**
		 * Shows the selection
		 */
		public function showSelection():void
		{
			if (_selectionContainer) {
				_selectionContainer.visible = true;
			}
		}

		/**
		 * @private
		 */
		override protected function createChildren():void
		{
			_canvas = new WBCanvas();
			addChild(_canvas);
			_selectionContainer = new UIComponent();
			addChild(_selectionContainer);
			_canvas.selectionHandlesContainer = _selectionContainer;
			_canvas.popupPropertiesToolBar = false;
			_canvas.addEventListener(WBCanvasEvent.PROPERTIES_TOOLBAR_ADD, addProps);
			_canvas.addEventListener(WBCanvasEvent.PROPERTIES_TOOLBAR_REMOVE, removeProps);
			_canvas.addEventListener(WBCanvasEvent.END_DRAWING_SHAPE, endDrawingShape);
			_canvas.styleName = this;
			if ( getStyle("backgroundColor") ==null ) {
				_canvas.setStyle("backgroundColor", 0xeaeaea);
			}else {
				_canvas.setStyle("backgroundColor",getStyle("backgroundColor"));
			}
			shapesToolBar = new WBShapesToolBar();
		}
		
		/**
		 * @private
		 */
		protected function endDrawingShape(p_evt:WBCanvasEvent):void
		{
			dispatchEvent(p_evt);
		}
		/**
		 * @private
		 */
		protected function addProps(p_evt:WBCanvasEvent):void
		{
			if (popupPropertiesToolBar ) {
				if ( !_propsBar ) {
					_propsBar = UIComponent(_canvas.currentPropertiesToolBar);
					addChild(_propsBar);
				}
				_propsBar.validateNow();
				_propsBar.setActualSize(_propsBar.measuredWidth, _propsBar.measuredHeight);
				if (_propsPt) {
					_propsBar.move(_propsPt.x, _propsPt.y);
				} else {
					_propsBar.move(_toolBar.x+_toolBar.width+2, _toolBar.y);
				}
			}
			dispatchEvent(p_evt);
		}
		
		/**
		 * @private
		 */
		protected function removeProps(p_evt:WBCanvasEvent):void
		{
			if (popupPropertiesToolBar && _propsBar && contains(_propsBar)) {
				_propsPt = new Point(_propsBar.x, _propsBar.y);
				removeChild(_propsBar);
				_propsBar = null ;
				validateNow();
				
			}
			dispatchEvent(p_evt);
		}
		
		/**
		 * @private
		 */
		override protected function commitProperties():void
		{
			if (!_model) {
				_model = new WBModel();
			}
			_canvas.model = _model;
			if (popupShapesToolBar && !contains(_toolBar)) {
				addChild(_toolBar);
				_toolBar.x = _toolBar.y = 25;
//				_toolBar.setActualSize(200, 500)
			} else if (contains(_toolBar) && !popupShapesToolBar) {
				removeChild(_toolBar);
			}
		}
		
		/**
		 * @private
		 */
		override protected function updateDisplayList(p_width:Number, p_height:Number):void
		{
			_selectionContainer.setActualSize(p_width, p_height);
			_toolBar.setActualSize(_toolBar.measuredWidth, _toolBar.measuredHeight);
			_toolBar.x = Math.min(_toolBar.x, width-_toolBar.width);
			_toolBar.y = Math.min(_toolBar.y, height-50);
			if (_invZoom) {
				_invZoom = false;
				_canvas.scaleX = _canvas.scaleY = _zoomLevel;
				_canvas.validateNow();
			}
			_canvas.setActualSize(p_width, p_height);
		}
		
		/**
		 * @private
		 */
		override protected function measure():void
		{
			super.measure();
			
			minWidth = _toolBar.measuredWidth + 100 ;
			minHeight = _toolBar.measuredHeight ;
		}

	}
}