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
package com.adobe.coreUI.controls.customMenuClasses
{
	import mx.skins.halo.HaloBorder;
	import mx.core.EdgeMetrics;
	import mx.utils.GraphicsUtil;
	import flash.display.GradientType;

	/**
	 * @private
	 */
   public class  CustomMenuBorder extends HaloBorder
	{
		public function CustomMenuBorder():void
		{
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			

			var radius:Number = getStyle("cornerRadius");



			// If there's a header area, draw its gradient background.
			var headerHeight:Number = getStyle("headerHeight");
			if(headerHeight) {
				graphics.beginGradientFill(GradientType.LINEAR, getStyle("fillColors"),
					getStyle("fillAlphas"), [ 0, 0xFF ],
					verticalGradientMatrix(0, 0, unscaledWidth, headerHeight + borderMetrics.top));
				GraphicsUtil.drawRoundRectComplex(graphics, 0, 0, unscaledWidth, headerHeight + borderMetrics.top, radius, radius, 0, 0);
				graphics.endFill();
			}
			


			// Draw a border around the edge of the menu.
			var borderThickness:Number = getStyle("borderThickness");
			var holeRadius:Number =
						Math.max(radius - borderThickness, 0);
			var hole:Object	= { x: borderThickness,
							 y: borderThickness,
							 w: unscaledWidth - borderThickness * 2,
							 h: unscaledHeight - borderThickness * 2,
							 r: holeRadius };
			drawRoundRect(
				0, 0, unscaledWidth, unscaledHeight, getStyle("cornerRadius"),
				getStyle("borderColor"), 1,
				null, null, null, hole);
				
				
			
			
			
			
			
			var panelHeight:Number = getStyle("panelHeight");
			
			if(isNaN(panelHeight) || panelHeight == 0){
				
			}
			else {
				// There's a panel area that sits on top of the menu area.
				
				
			}
		}
		
		
		
		override public function get borderMetrics():EdgeMetrics
		{
			var bm:EdgeMetrics = super.borderMetrics.clone();

/*			var borderThickness:Number = getStyle("borderThickness");
			var bm:EdgeMetrics = new EdgeMetrics(borderThickness, borderThickness, borderThickness, borderThickness);
			
			// Add extra space on the top border if there's a panelHeight style.
			var panelHeight:Number = getStyle("panelHeight");
			
			if(!isNaN(panelHeight) && panelHeight > 0) {
				bm.top += panelHeight;
			}*/

			return bm;
		}
		
		
		override public function getStyle(styleProp:String):*
		{
/*			if(styleProp == "borderStyle") {
				return "default";
			}*/
/*			if(styleProp == "fillColors") {
				return [0x00ff00, 0x00B000];
			}*/
			return super.getStyle(styleProp);
		}
	}
}