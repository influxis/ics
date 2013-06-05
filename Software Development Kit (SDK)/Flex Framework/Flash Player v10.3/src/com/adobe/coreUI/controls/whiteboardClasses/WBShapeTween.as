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
	import mx.effects.Tween;
	
	/**
	 * @private
	 */
   public class  WBShapeTween
	{
		public var shapeContainer:WBShapeContainer;
		public var canvas:WBCanvas;
		
		public function WBShapeTween(p_shapeContainer:WBShapeContainer, p_shapeDescriptor:WBShapeDescriptor, p_canvas:WBCanvas)
		{
			canvas = p_canvas;
			shapeContainer = p_shapeContainer;
			var t:Tween = new Tween(this, [shapeContainer.x, shapeContainer.y, shapeContainer.shapeWidth, 
											shapeContainer.shapeHeight, shapeContainer.rotation],
										[p_shapeDescriptor.x, p_shapeDescriptor.y, p_shapeDescriptor.width, p_shapeDescriptor.height,
											p_shapeDescriptor.rotation], 250);
		}
		
		public function onTweenUpdate(p_vals:Array):void
		{
			shapeContainer.rotation = p_vals[4];
			shapeContainer.validateNow();
			shapeContainer.move(p_vals[0], p_vals[1]);
			shapeContainer.width = p_vals[2];
			shapeContainer.height = p_vals[3];
			shapeContainer.validateNow();
			canvas.updateSelectionRect();
		}
		
		public function onTweenEnd(p_vals:Array):void
		{
			onTweenUpdate(p_vals);
		}
	}
}