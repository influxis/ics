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
	import com.adobe.coreUI.controls.whiteboardClasses.shapes.WBTextShape;
	
	/**
	 * Descriptor class for a Text-Area Shape
	 * 
	 * @see com.adobe.coreUI.controls.whiteboardClasses.WBShapeDescriptor
	 */
   public class  WBTextShapeDescriptor extends WBShapeDescriptor
	{

		public function WBTextShapeDescriptor()
		{
			super();
			initialize();
		}

		/**
		 *@private
		 */		
		protected function initialize():void
		{
			var textShape:WBTextShape = new WBTextShape();
			propertyData =  textShape.propertyData;
			definitionData = textShape.definitionData;
			factoryID = "com.adobe.coreUI.controls.whiteboardClasses.shapes::WBTextShapeFactory";
		}
		
		
		/**
		 * Specifies the htmlText of the TextShape. Please specify the text in HTML tags if you need specific formatting.
		 */
		public function get htmlText():String
		{
			return propertyData.htmlText;
		}

		/**
		 *@private
		 */
		public function set htmlText(p_htmlText:String):void
		{
			propertyData.htmlText = p_htmlText;
		}
		
	}
}