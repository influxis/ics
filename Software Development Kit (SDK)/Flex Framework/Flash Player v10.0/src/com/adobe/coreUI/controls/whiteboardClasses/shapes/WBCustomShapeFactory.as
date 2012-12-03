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
package com.adobe.coreUI.controls.whiteboardClasses.shapes
{
	import com.adobe.coreUI.controls.whiteboardClasses.IWBPropertiesToolBar;
	import com.adobe.coreUI.controls.whiteboardClasses.IWBShapeFactory;
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapeBase;
	
	import flash.utils.getQualifiedClassName;
	
	import mx.core.UIComponent;

   public class  WBCustomShapeFactory implements IWBShapeFactory
	{
		
		protected var _customShape:Class;
		protected var _toolBar:IWBPropertiesToolBar;
		protected var _customCursor:Class;
		protected var _shapeData:Object;
		protected var _factoryId:String;
		
		/**
		 * Constructor. WBCustomShapeFactory enables the new custom shape to be registered with the WhiteBoard and set the shapes cursor and its toolBar.
		 * The following example shows how a custom shape is added using the WBCustomShapeFactory
		 * 
		 * <pre>
		 *			var triangleShape:WBShapeToolBarDescriptor = new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.TOOL); //Shape is of type tool
		 *			triangleShape.toolTip ="Triangle";
		 *			triangleShape.shapeFactory = new WBCustomShapeFactory(WBTriangleShape, CURSOR_PEN, new WBTrianglePropertiesToolBar());
		 *			triangleShape.icon = ICON_TRIANGLE;
		 *			toolBar.addCustomShapeToToolBar(triangleShape);
		 * </pre>
		 *      
		 * @param p_customShape The shape Class that defines the display and action properties of the custom shape.
		 * @param p_customCursor The cursor that is to be diplayed when the shape is selected.
		 * @param p_customToolBar Set the ToolBar to be displayed associated with the shape.
		 */
		public function WBCustomShapeFactory(p_customShape:Class, p_customCursor:Class=null, p_customToolBar:IWBPropertiesToolBar=null)
		{
			_customShape = p_customShape;
			_factoryId = flash.utils.getQualifiedClassName(this) +":"+ flash.utils.getQualifiedClassName(p_customShape);
			if (p_customToolBar) {
				_toolBar = p_customToolBar;
			}
			if (p_customCursor) {
				_customCursor = p_customCursor;
			}
		}
		
		/**
		 * Return a new custom Shape Instance registered with the WhiteBoard. 
		 */ 
		public function newShape():WBShapeBase
		{
			var shape:WBShapeBase = new _customShape();
			if (_toolBar && UIComponent(_toolBar).initialized) {
				shape.propertyData = _toolBar.propertyData;
			}
			return shape;
		}
		
		/**
		 * The ToolBar of the shape 
		 */ 
		public function get toolBar():IWBPropertiesToolBar
		{
			return _toolBar;
		}
		
		/**
		 *  @private
		 */
		public function set toolBar(p_toolBar:IWBPropertiesToolBar):void
		{
			_toolBar = p_toolBar;	
		}
		
		/**
		 * The shape Class that defines the display and action properties of the custom shape.
		 */ 
		public function set shape(p_customShape:Class):void
		{
			_customShape = p_customShape;
		}
		
		/**
		 *  @private
		 */
		public function get shape():Class
		{
			return _customShape;	
		}
		
		/**
		 *  @private
		 */
		public function get toggleSelectionAfterDraw():Boolean
		{
			return false;	
		}

		/**
		 *  @private
		 */
		public function set shapeData(p_data:Object):void
		{
			_shapeData = p_data;
		}
		
		/**
		 * The cursor that is to be diplayed when the shape is selected.
		 */ 
		public function get cursor():Class
		{
			return _customCursor;
		}
		
		/**
		 *  @private
		 */
		public function set cursor(p_customCursor:Class):void
		{
			_customCursor = p_customCursor;
		}
		
		/**
		 * The factoryId of the shape. Usaul value would be Class-Name: Shapes Class-Name
		 */ 
		public function get factoryId():String
		{
			if (_factoryId) {
				return _factoryId;
			} else {
				return null;
			}
		}
	}
}