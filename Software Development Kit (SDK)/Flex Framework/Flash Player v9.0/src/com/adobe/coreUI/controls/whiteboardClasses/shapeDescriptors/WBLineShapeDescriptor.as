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
package com.adobe.coreUI.controls.whiteboardClasses.shapeDescriptors
{
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapeDescriptor;
	import com.adobe.coreUI.controls.whiteboardClasses.shapes.WBArrowShape;
	
	/**
	 * Descriptor class for a Line shape
	 * 
	 * @see com.adobe.coreUI.controls.whiteboardClasses.WBShapeDescriptor
	 */
   public class  WBLineShapeDescriptor extends WBShapeDescriptor
	{

		public function WBLineShapeDescriptor()
		{
			super();
			initialize();
		}

		/**
		 *@private
		 */		
		protected function initialize():void
		{
			var arrowShape:WBArrowShape = new WBArrowShape();
			propertyData =  arrowShape.propertyData;
			var tmpObj:Object = arrowShape.definitionData;
			tmpObj.arrowHead = false;
			definitionData = tmpObj;
			factoryID = "com.adobe.coreUI.controls.whiteboardClasses.shapes::WBArrowShapeFactory";
		}
		
		
		/**
		 * Specifies the line thickness of the Line shape
		 * 
		 * @default "10"
		 */
		public function get lineThickness():Number
		{
			return propertyData.lineThickness;
		}

		/**
		 *@private
		 */
		public function set lineThickness(p_lineThickness:Number):void
		{
			propertyData.lineThickness = p_lineThickness;
		}
		
		/**
		 * Specifies the line color
		 * 
		 * @default "#3815994"
		 */
		public function get lineColor():uint
		{
			return propertyData.lineColor;
		}
		
		/**
		 *@private
		 */		
		public function set lineColor(p_lineColor:uint):void
		{
			propertyData.lineColor = p_lineColor;
		}

		/**
		 * Specifies whether the drop shadow is set or not
		 * 
		 * @default "true"
		 */
		public function get dropShadow():Boolean
		{
			return propertyData.dropShadow;
		}
		
		/**
		 *@private
		 */		
		public function set dropShadow(p_dropShadow:Boolean):void
		{
			propertyData.dropShadow = p_dropShadow;
		}
		
		/**
		 * Specifies whether the gradient fill of the line is set or not
		 * 
		 * @default "true"
		 */
		public function get gradientFill():Boolean
		{
			return propertyData.gradientFill;
		}

		/**
		 *@private
		 */		
		public function set gradientFill(p_gradientFill:Boolean):void
		{
			propertyData.gradientFill = p_gradientFill;
		}
		
		/**
		 * Specifies the foreground alpha of the lines
		 * 
		 * @default "1"
		 */
		public function get alpha():Number
		{
			return propertyData.alpha;
		}
		
		/**
		 *@private
		 */
		public function set alpha(p_lineAlpha:Number):void
		{
			propertyData.alpha = p_lineAlpha;
		}
		

	}
}