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
	import com.adobe.coreUI.controls.EditorToolBar;
	import flash.display.Sprite;
	import mx.skins.halo.HaloBorder;
	import flash.events.MouseEvent;
	import com.adobe.coreUI.localization.ILocalizationManager;
	import com.adobe.coreUI.localization.Localization;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.display.GradientType;
	import com.adobe.coreUI.controls.whiteboardClasses.IWBPropertiesToolBar;
	import flash.geom.Rectangle;
	import mx.core.UIComponent;
	import mx.controls.ColorPicker;

	/**
	 * @private
	 */
   public class  WBTextToolBar extends EditorToolBar implements IWBPropertiesToolBar
	{
		protected var _titleBar:Sprite;
		protected var _backgroundSkin:HaloBorder;
		protected var _backgroundRect:Sprite;

		protected static const TITLE_HEIGHT:int = 10;
		protected static const TITLE_BUFFER:int = 8;
		protected static const SIDE_BUFFERS:int = 8;
		protected static const HEIGHT_BUFFER:int = 20;


		public function set propertyData(p_data:*):void
		{
		}
		
		public function get propertyData():*
		{
			return null;
		}
		
		public function set isFilledShape(p_fill:Boolean):void
		{
		}

		override protected function createChildren():void
		{
			
			_backgroundSkin = new HaloBorder();
			setStyle("backgroundColor", 0x000000);
			setStyle("borderStyle", "outset");
			setStyle("dropShadowEnabled", true);
			setStyle("shadowDistance", 3);
			setStyle("shadowDirection", "right");
//			setStyle("color", 0xeaeaea);
			_backgroundSkin.styleName = this;
			addChild(_backgroundSkin);

			_backgroundRect = new Sprite();
			addChild(_backgroundRect);

			_titleBar = new Sprite();
			_titleBar.addEventListener(MouseEvent.MOUSE_DOWN, startDragging);
			_titleBar.addEventListener(MouseEvent.MOUSE_UP, stopDragging);
			addChild(_titleBar);
			_lm = Localization.impl;
			
			super.createChildren();
			var tmpPicker:ColorPicker = new ColorPicker();
			_colorPicker.dataProvider = tmpPicker.dataProvider;
			_colorPicker.styleName = null;
			
			_toolsContainer.setStyle("horizontalGap", 3);
		}

		protected function startDragging(p_evt:MouseEvent):void
		{
			var rect:Rectangle;
			if (parent is UIComponent) {
				rect = new Rectangle(0,0,Math.max(0,parent.width-width),Math.max(0,parent.height-30));
			}
			startDrag(false, rect);
		}
		
		protected function stopDragging(p_evt:MouseEvent):void
		{
			stopDrag();
		}

		override protected function measure():void
		{
			super.measure();
			measuredHeight += TITLE_HEIGHT + HEIGHT_BUFFER;
			measuredWidth += SIDE_BUFFERS*2;
		}

		override protected function updateDisplayList(p_w:Number, p_h:Number):void
		{
			super.updateDisplayList(p_w, p_h);
			_toolsContainer.move(SIDE_BUFFERS, TITLE_HEIGHT + TITLE_BUFFER + 3);
			_backgroundSkin.setActualSize(p_w, p_h);
			
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
			
			g = _backgroundRect.graphics;
			g.clear();
			
			gradMatr = new Matrix();
			gradMatr.createGradientBox(p_w, p_h-TITLE_HEIGHT-2*TITLE_BUFFER, Math.PI/2);			
			g.lineStyle(0, 0, 0);
			g.beginGradientFill(GradientType.LINEAR, [0x9a9a9a,0x838383],[1,1],[0,255],gradMatr);
			g.drawRect(Math.round(SIDE_BUFFERS/2), TITLE_HEIGHT+Math.round(TITLE_BUFFER/2), p_w-SIDE_BUFFERS, p_h-TITLE_HEIGHT-TITLE_BUFFER);
				
		}
	}
}