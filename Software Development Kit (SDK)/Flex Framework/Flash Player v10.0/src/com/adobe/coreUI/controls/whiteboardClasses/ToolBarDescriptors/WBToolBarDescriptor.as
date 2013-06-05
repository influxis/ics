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
	import com.adobe.coreUI.controls.whiteboardClasses.shapes.WBArrowShapeFactory;
	import com.adobe.coreUI.controls.whiteboardClasses.shapes.WBHighlightAreaShapeFactory;
	import com.adobe.coreUI.controls.whiteboardClasses.shapes.WBMarkerShapeFactory;
	import com.adobe.coreUI.controls.whiteboardClasses.shapes.WBSimpleShape;
	import com.adobe.coreUI.controls.whiteboardClasses.shapes.WBSimpleShapeFactory;
	import com.adobe.coreUI.controls.whiteboardClasses.shapes.WBTextShapeFactory;
	import com.adobe.coreUI.localization.ILocalizationManager;
	import com.adobe.coreUI.localization.Localization;

   public class  WBToolBarDescriptor extends Object
	{
		/**
		 * @private
		 */ 
		public static const COMMAND_UNDO:String = "undo";
		/**
		 * @private
		 */ 
		public static const COMMAND_REDO:String = "redo";
		/**
		 * @private
		 */ 
		public static const COMMAND_DELETE_SELECTED:String = "deleteSelected";
		/**
		 * @private
		 */ 
		public static const COMMAND_SAVE:String = "save";
		
		/**
		 * @private
		 */ 
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#tool_selection')]
		public static var ICON_SELECTION:Class;

		/**
		 * @private
		 */ 
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#tool_arrow')]
		public static var ICON_ARROW:Class;
		
		/**
		 * @private
		 */ 
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#tool_marker')]
		public static var ICON_HIGHLIGHTER_PEN:Class;
		
		/**
		 * @private
		 */ 
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#tool_highlight_area')]
		public static var ICON_HIGHLIGHT_RECTANGLE:Class;
		/**
		 * @private
		 */ 
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#tool_text')]
		public static var ICON_TEXT:Class;
		/**
		 * @private
		 */ 
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#tool_line')]
		public static var ICON_LINE:Class;
		/**
		 * @private
		 */ 
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#tool_shapes')]
		public static var ICON_SHAPES:Class;
		
		/**
		 * @private
		 */ 
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#tool_ellipse')]
		public static var ICON_ELLIPSE:Class;
		/**
		 * @private
		 */ 
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#tool_rectangle')]
		public static var ICON_RECTANLGE:Class;
		/**
		 * @private
		 */ 
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#tool_rounded_rectangle')]
		public static var ICON_ROUNDED_RECTANGLE:Class;
		
		/**
		 * @private
		 */ 
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#tool_undo')]
		public static var ICON_UNDO:Class;
		/**
		 * @private
		 */ 
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#tool_redo')]
		public static var ICON_REDO:Class;
		/**
		 * @private
		 */ 
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#tool_clear')]
		public static var ICON_DELETE_SHAPES:Class;
		/**
		 * @private
		 */ 
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#tool_save')]
		public static var ICON_SAVE:Class;
		
		protected var markerFactory:IWBShapeFactory = new WBMarkerShapeFactory();
		protected var textFactory:IWBShapeFactory = new WBTextShapeFactory();
		protected var simpleShapeFactory:WBSimpleShapeFactory = new WBSimpleShapeFactory();
		protected var arrowFactory:WBArrowShapeFactory = new WBArrowShapeFactory();
		protected var highlightAreaFactory:WBSimpleShapeFactory = new WBHighlightAreaShapeFactory();
		protected var _lm:ILocalizationManager;
		
		public var children:Array;
		
		/**
		 * Constructor.
		 * 
		 * @param  p_includeDefaultItems Flag indicating whether the default items that are in the standard whiteBoard ToolBar are required or not
		 */ 
		public function WBToolBarDescriptor(p_includeDefaultItems:Boolean=false)
		{
			children =  new Array();
			_lm = Localization.impl;
			if (p_includeDefaultItems) {
				addDefaultItems();
			}
		}
		
		/**
		 * Add a toolBar component to the the Toolbar
		 * 
		 * @param p_WBShapesToolBarDescriptor Descriptor for the tool bar component.
		 */ 
		public function addShapeToolBar(p_WBShapesToolBarDescriptor:WBShapeToolBarDescriptor):void
		{
			children.push(p_WBShapesToolBarDescriptor);
		}
		
		protected function addDefaultItems():void
		{
			var toolShape:WBShapeToolBarDescriptor = new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.LABEL);
			toolShape.label = _lm.getString("Tools");
			addShapeToolBar(toolShape);
			
			var selectionToolShape:WBShapeToolBarDescriptor = new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.TOOL);
			selectionToolShape.toolTip = _lm.getString("Selection Tool");
			selectionToolShape.icon = ICON_SELECTION;
			addShapeToolBar(selectionToolShape);
			
			var arrowToolShape:WBShapeToolBarDescriptor = new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.TOOL);
			arrowToolShape.toolTip = _lm.getString("Arrow Tool");
			arrowToolShape.shapeFactory = arrowFactory;
			arrowToolShape.shapeData = WBArrowShapeFactory.ARROW_HEAD;
			arrowToolShape.icon = ICON_ARROW;
			addShapeToolBar(arrowToolShape);
			
			var highLightPenToolShape:WBShapeToolBarDescriptor = new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.TOOL);
			highLightPenToolShape.toolTip =_lm.getString("Highlighter Pen Tool");
			highLightPenToolShape.shapeFactory = markerFactory;
			highLightPenToolShape.shapeData = WBMarkerShapeFactory.HIGHLIGHTER;
			highLightPenToolShape.icon = ICON_HIGHLIGHTER_PEN;
			addShapeToolBar(highLightPenToolShape);
			
			var highlightRectangleToolShape:WBShapeToolBarDescriptor = new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.TOOL);
			highlightRectangleToolShape.toolTip = _lm.getString("Highlight Rectangle Tool");
			highlightRectangleToolShape.shapeFactory = highlightAreaFactory;
			highlightRectangleToolShape.shapeData = WBSimpleShapeFactory.HIGHLIGHT_AREA;
			highlightRectangleToolShape.icon = ICON_HIGHLIGHT_RECTANGLE;
			addShapeToolBar(highlightRectangleToolShape);
			
			var textToolShape:WBShapeToolBarDescriptor = new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.TOOL);
			textToolShape.toolTip = _lm.getString("Text Tool");
			textToolShape.shapeFactory = textFactory;
			textToolShape.icon = ICON_TEXT;
			addShapeToolBar(textToolShape);
			
			var shapeSubToolBar:WBToolBarDescriptor = new WBToolBarDescriptor(false);
			var shapesLabelShape:WBShapeToolBarDescriptor = new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.LABEL);
			shapesLabelShape.label = _lm.getString("Shapes");
			shapeSubToolBar.addShapeToolBar(shapesLabelShape);
			
			var lineToolShape:WBShapeToolBarDescriptor  =  new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.TOOL);
			lineToolShape.toolTip = _lm.getString("Line Tool");
			lineToolShape.icon = ICON_LINE;
			lineToolShape.shapeFactory = arrowFactory;
			lineToolShape.shapeData = WBArrowShapeFactory.NO_ARROW_HEAD;
			shapeSubToolBar.addShapeToolBar(lineToolShape);
			
			var ellipseToolShape:WBShapeToolBarDescriptor = new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.TOOL);
			ellipseToolShape.toolTip = _lm.getString("Ellipse Tool");
			ellipseToolShape.shapeFactory = simpleShapeFactory;
			ellipseToolShape.shapeData = WBSimpleShape.ELLIPSE;
			ellipseToolShape.icon = ICON_ELLIPSE;
			shapeSubToolBar.addShapeToolBar(ellipseToolShape);
			
			var rectangleToolShape:WBShapeToolBarDescriptor = new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.TOOL);
			rectangleToolShape.toolTip = _lm.getString("Rectangle Tool");
			rectangleToolShape.shapeFactory = simpleShapeFactory;
			rectangleToolShape.shapeData = WBSimpleShape.RECTANGLE;
			rectangleToolShape.icon = ICON_RECTANLGE;
			shapeSubToolBar.addShapeToolBar(rectangleToolShape);
			
			var roundedRectangleToolShape:WBShapeToolBarDescriptor  =  new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.TOOL);
			roundedRectangleToolShape.toolTip = _lm.getString("Rounded Rectangle Tool");
			roundedRectangleToolShape.shapeFactory = simpleShapeFactory;
			roundedRectangleToolShape.shapeData = WBSimpleShape.ROUNDED_RECTANGLE;
			roundedRectangleToolShape.icon = ICON_ROUNDED_RECTANGLE;
			shapeSubToolBar.addShapeToolBar(roundedRectangleToolShape);
			
			var shapesToolShape:WBShapeToolBarDescriptor  =  new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.TOOL);
			shapesToolShape.toolTip = _lm.getString("Shapes");
			shapesToolShape.icon = ICON_SHAPES;
			shapesToolShape.children = shapeSubToolBar.children;
			addShapeToolBar(shapesToolShape);
			
			var actionLabel:WBShapeToolBarDescriptor =  new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.LABEL);
			actionLabel.label=_lm.getString("Actions");
			addShapeToolBar(actionLabel);
			
			var undoCommand:WBShapeToolBarDescriptor  =  new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.COMMAND);
			undoCommand.toolTip=_lm.getString("Undo");
			undoCommand.icon=ICON_UNDO;
			undoCommand.command=COMMAND_UNDO;
			addShapeToolBar(undoCommand);
			
			var redoCommand:WBShapeToolBarDescriptor  =  new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.COMMAND);
			redoCommand.toolTip=_lm.getString("Redo");
			redoCommand.icon=ICON_REDO;
			redoCommand.command=COMMAND_REDO;
			addShapeToolBar(redoCommand);
			
			var deleteCommand:WBShapeToolBarDescriptor  =  new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.COMMAND);
			deleteCommand.toolTip=_lm.getString("Delete Selected Items");
			deleteCommand.icon=ICON_DELETE_SHAPES;
			deleteCommand.command=COMMAND_DELETE_SELECTED;
			addShapeToolBar(deleteCommand);
			
			var saveCommand:WBShapeToolBarDescriptor  =  new WBShapeToolBarDescriptor(WBShapeToolBarDescriptor.COMMAND);
			saveCommand.toolTip=_lm.getString("Save as File");
			saveCommand.icon=ICON_SAVE;
			saveCommand.command=COMMAND_SAVE;
			addShapeToolBar(saveCommand);
		}
		
		protected function removeDefaultItems():void
		{
		}
	}
}