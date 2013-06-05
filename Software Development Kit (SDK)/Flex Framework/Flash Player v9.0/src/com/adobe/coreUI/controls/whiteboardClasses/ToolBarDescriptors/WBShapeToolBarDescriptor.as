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
package com.adobe.coreUI.controls.whiteboardClasses.ToolBarDescriptors
{
	import com.adobe.coreUI.controls.whiteboardClasses.IWBShapeFactory;
   public class  WBShapeToolBarDescriptor extends Object
	{
		public static const LABEL:String = "label";
		public static const TOOL:String = "tool";
		public static const COMMAND:String = "command";
		
		/**
		 * The type of the WhiteBoard element. You use the following constants to set this property WBShapeToolBarDescriptor.LABEL or WBShapeToolBarDescriptor.TOOL or WBShapeToolBarDescriptor.COMMAND
		 */ 
		public var type:String;
		
		/**
		 * The text of the Label if the type is WBShapeToolBarDescriptor.LABEL
		 */ 
		public var label:String;
		
		/**
		 * The tooltip of the toolBar component
		 */ 
		public var toolTip:String;
		
		/**
		 * The Icon of the toolBar component
		 */ 
		public var icon:Class;
		
		/**
		 * @private
		 */ 
		public var shapeData:String;
		
		/**
		 * The shape factory associated with the shape.
		 */ 
		public var shapeFactory:IWBShapeFactory;
		
		/**
		 * The children of a toolBar component. This would enable a toolBar component to have a sub ToolBar.
		 * Example
		 * <pre>
		 *	var shapeSubToolBar:WBToolBarDescriptor = new WBToolBarDescriptor(false); //SubTool Bar
		 *	
		 *	var shapesLabelShape:WBShapeToolBarDescriptor = new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.LABEL); // Label Shape
		 *	shapesLabelShape.label = _lm.getString("Shapes");
		 *	shapeSubToolBar.addShapeToolBar(shapesLabelShape);
		 *	
		 *	var undoCommand:WBShapeToolBarDescriptor  =  new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.COMMAND); //Command ToolBar component
		 *	undoCommand.toolTip="Undo";
		 *	undoCommand.icon=ICON_UNDO;
		 *	undoCommand.command="undo";
		 *	shapeSubToolBar.addShapeToolBar(undoCommand);
		 *	            
		 *	var rectangleToolShape:WBShapeToolBarDescriptor = new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.TOOL);
		 *	rectangleToolShape.toolTip = "Rectangle Tool";
		 *	rectangleToolShape.shapeFactory = simpleShapeFactory; //Rectangle Shape Factory
		 *	rectangleToolShape.icon = ICON_RECTANLGE;
		 *	shapeSubToolBar.addShapeToolBar(rectangleToolShape);
		 *	            
		 *	var shapesToolShape:WBShapeToolBarDescriptor  =  new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.TOOL);
		 *	shapesToolShape.toolTip = "Shapes";
		 *	shapesToolShape.icon = ICON_SHAPES;
		 *	shapesToolShape.children = shapeSubToolBar.children; // Adding the children of the shapeSubToolBar to the ToolBar Component
		 *	addShapeToolBar(shapesToolShape); // This toolBar component would have the sub Tool bar when clicked.
		 * </pre>
		 */ 
		public var children:Array;
		
		/**
		 * The command that would be dispatched by the toolBar. Used if the type is WBShapeToolBarDescriptor.COMMAND 
		 */ 
		public var command:String;

		/**
		 * Constructor. 
		 *
		 * Example
		 * <pre>
		 *			var triangleShape:WBShapeToolBarDescriptor = new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.TOOL); //Shape is of type tool
		 *			triangleShape.toolTip ="Triangle";
		 *			triangleShape.shapeFactory = new WBCustomShapeFactory(WBTriangleShape, CURSOR_PEN, new WBTrianglePropertiesToolBar());
		 *			triangleShape.icon = ICON_TRIANGLE;
		 *			toolBar.addCustomShapeToToolBar(triangleShape);
		 * </pre>
		 * @param p_type Type of the toolBar component. Possible values would be WBShapeToolBarDescriptor.LABEL or WBShapeToolBarDescriptor.TOOL or WBShapeToolBarDescriptor.COMMAND
		 */ 
		public function WBShapeToolBarDescriptor(p_type:String)
		{
			type = p_type;
		}
		
	}
}