////////////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2003-2006 Adobe Macromedia Software LLC and its licensors.
//  All Rights Reserved. The following is Source Code and is subject to all
//  restrictions on such code as contained in the End User License Agreement
//  accompanying this product.
//
////////////////////////////////////////////////////////////////////////////////

package com.adobe.coreUI.controls.nullColorPickerClasses
{

import com.adobe.coreUI.controls.NullColorPicker;

import flash.display.Graphics;

import mx.collections.IList;
import mx.core.FlexVersion;
import mx.core.UIComponent;
import mx.core.mx_internal;
import mx.styles.CSSStyleDeclaration;
import mx.styles.StyleManager;

use namespace mx_internal;

/**
 * @private
 *  The skin used for all color swatches in a ColorPicker.
 */
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
   public class  NullSwatchSkin extends UIComponent
{
//    include "../../core/Version.as";

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
	 *  Constructor.
     */    
    public function NullSwatchSkin()
    {
        super();
    }
    
    
    private static var _cssStyleDefined:Boolean = true ;
    
    
	private static var classConstructed:Boolean = classConstruct();

	private static function classConstruct():Boolean
	{
		var styleDeclaration:CSSStyleDeclaration = StyleManager.getStyleDeclaration("NullSwatchSkin");

		// If there's no style declaration already, create one.
		if (!styleDeclaration) {
			styleDeclaration = new CSSStyleDeclaration();
			_cssStyleDefined = false ;
			if ( FlexVersion.compatibilityVersion > FlexVersion.VERSION_3_0) {
				styleDeclaration["setStyle"]("nullSwatchWidth",12);
				styleDeclaration["setStyle"]("nullSwatchHeight", 12);
			}
		}
		
		styleDeclaration.defaultFactory = function ():void {
			this.nullSwatchWidth = 12;
			this.nullSwatchHeight = 12;
			_cssStyleDefined = true ;
		}
		
		StyleManager.setStyleDeclaration("NullSwatchSkin", styleDeclaration, false);
	
		return true;
	}    
    
    
    
    

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     */   
    mx_internal var color:uint = 0x000000;
     
    /**
     *  @private
     */
    mx_internal var colorField:String = "color";

    //--------------------------------------------------------------------------
    //
    //  Overridden methods
    //
    //--------------------------------------------------------------------------    

    /**
     *  @private
     */
    override protected function updateDisplayList(w:Number, h:Number):void
    {
		super.updateDisplayList(w, h);

		mx_internal::updateSkin(mx_internal::color);
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */    
    mx_internal function updateGrid(dp:IList):void 
    {
        if (name == "swatchGrid")
        {
            graphics.clear();
            drawGrid(dp, mx_internal::colorField);
        }
    }
    
    /**
     *  @private
     */    
    mx_internal function updateSkin(c:Number):void
    {
        var g:Graphics = graphics;
		var nullSwatchPanelCSS:CSSStyleDeclaration ;
		switch (name)
        {
            case "colorPickerSwatch":
            {
                var w:Number = UIComponent(parent).width /
							   Math.abs(UIComponent(parent).scaleX);
                var h:Number = UIComponent(parent).height /
							   Math.abs(UIComponent(parent).scaleY);
                
				g.clear();
                drawSwatch(0, 0, w, h, (c == NullColorPicker.NULL_COLOR) ? 0xFFFFFF : c);
				if(c == NullColorPicker.NULL_COLOR) {
			        g.lineStyle(1, 0xff0000);
			        g.moveTo(0, 0);
			        g.lineTo(w, h);				   
				 }                
                
                break;
            }

            case "swatchPreview":
            {
				var previewWidth:Number ;
				var previewHeight:Number ;
				if ( FlexVersion.compatibilityVersion > FlexVersion.VERSION_3_0 && !_cssStyleDefined ) {
					nullSwatchPanelCSS = StyleManager.getStyleDeclaration("NullSwatchPanel");
					previewWidth = nullSwatchPanelCSS.getStyle("previewWidth");
					previewHeight = nullSwatchPanelCSS.getStyle("previewHeight");
				}else {
                	previewWidth = getStyle("previewWidth");
                	previewHeight = getStyle("previewHeight");
				}
				
                g.clear();
                
                drawSwatch(0, 0, previewWidth, previewHeight, (c == NullColorPicker.NULL_COLOR) ? 0xFFFFFF : c);
                drawBorder(0, 0, previewWidth, previewHeight,
						   0x999999, 0xFFFFFF, 1, 1.0);
						   
				if(c == NullColorPicker.NULL_COLOR) {
			        g.lineStyle(1, 0xff0000);
			        g.moveTo(0, 0);
			        g.lineTo(previewWidth, previewHeight);				   
				 }
						   
                break;
            }

            case "swatchHighlight":
            {
				var swatchWidth:Number ;
				var swatchHeight:Number ;
				var swatchHighlightColor:uint ;
				var swatchHighlightSize:Number ;
				if ( FlexVersion.compatibilityVersion > FlexVersion.VERSION_3_0 && !_cssStyleDefined ) {
					nullSwatchPanelCSS = StyleManager.getStyleDeclaration("NullSwatchPanel");
					swatchWidth = nullSwatchPanelCSS.getStyle("swatchWidth");
					swatchHeight = nullSwatchPanelCSS.getStyle("swatchHeight");
					swatchHighlightColor = nullSwatchPanelCSS.getStyle("swatchHighlightColor");
					swatchHighlightSize = nullSwatchPanelCSS.getStyle("swatchHighlightSize");
				}else {
                	swatchWidth = getStyle("swatchWidth");
                	swatchHeight = getStyle("swatchHeight");
                	swatchHighlightColor = getStyle("swatchHighlightColor");
                	swatchHighlightSize = getStyle("swatchHighlightSize");
				}
				
                g.clear();
                drawBorder(0, 0, swatchWidth, swatchHeight,
						   swatchHighlightColor, swatchHighlightColor,
						   swatchHighlightSize, 1.0);
                break;
            }
            case "nullSwatch":
            {
            	g.clear();
				if ( FlexVersion.compatibilityVersion > FlexVersion.VERSION_3_0 && !_cssStyleDefined ) {
					var nullSwatchSkinCSS:CSSStyleDeclaration = StyleManager.getStyleDeclaration("NullSwatchSkin");
					drawSwatch(0, 0, nullSwatchSkinCSS.getStyle("nullSwatchWidth"), nullSwatchSkinCSS.getStyle("nullSwatchHeight"), NaN);
				}else {
					drawSwatch(0, 0, getStyle("nullSwatchWidth"), getStyle("nullSwatchHeight"), NaN);
				}
				break;
            }
			
        }
    }

    /**
     *  @private
     */    
    protected function drawGrid(dp:IList, cf:String):void
    {
		var columnCount:int ;
		var horizontalGap:Number ;
		var previewWidth:Number ;
		var swatchGridBackgroundColor:uint ;
		var swatchGridBorderSize:Number ;
		var swatchHeight:Number ;
		var swatchWidth:Number ;
		var textFieldWidth:Number ;
		var verticalGap:Number ;
		if ( FlexVersion.compatibilityVersion > FlexVersion.VERSION_3_0 && !_cssStyleDefined ) {
			var nullSwatchPanelCSS:CSSStyleDeclaration = StyleManager.getStyleDeclaration("NullSwatchPanel");
			columnCount =  nullSwatchPanelCSS.getStyle("columnCount");
			horizontalGap = nullSwatchPanelCSS.getStyle("horizontalGap");
			previewWidth = nullSwatchPanelCSS.getStyle("previewWidth");
			swatchGridBackgroundColor = nullSwatchPanelCSS.getStyle("swatchGridBackgroundColor");
			swatchGridBorderSize = nullSwatchPanelCSS.getStyle("swatchGridBorderSize");
			swatchHeight = nullSwatchPanelCSS.getStyle("swatchHeight");
			swatchWidth = nullSwatchPanelCSS.getStyle("swatchWidth");
			textFieldWidth =  nullSwatchPanelCSS.getStyle("textFieldWidth");
			verticalGap = nullSwatchPanelCSS.getStyle("verticalGap");
		}else {
			columnCount = getStyle("columnCount");
			horizontalGap = getStyle("horizontalGap");
			previewWidth = getStyle("previewWidth");
			swatchGridBackgroundColor = getStyle("swatchGridBackgroundColor");
			swatchGridBorderSize = getStyle("swatchGridBorderSize");
			swatchHeight = getStyle("swatchHeight");
			swatchWidth = getStyle("swatchWidth");
			textFieldWidth = getStyle("textFieldWidth");
			verticalGap = getStyle("verticalGap");
		}

        var cellOffset:int = 1;
        var itemOffset:int = 3;

        // Adjust for dataProviders that are less than the columnCount.
        var length:int = dp.length;
        if (columnCount > length)
            columnCount = length;

        // Define local values.
        var rows:Number = Math.ceil(length / columnCount);
        if (isNaN(rows))
        	rows = 0;
        var totalWidth:Number = columnCount * (swatchWidth - cellOffset) +
								cellOffset +
								(columnCount - 1) * horizontalGap +
								2 * swatchGridBorderSize;
        var totalHeight:Number = rows * (swatchHeight - cellOffset) +
								 cellOffset +
								 (rows - 1) * verticalGap +
								 2 * swatchGridBorderSize;

        // Adjust width if it falls shorter than the width of the preview area.
        var previewArea:Number = previewWidth + textFieldWidth + itemOffset;
        if (totalWidth < previewArea)
            totalWidth = previewArea;

        // Draw the background for the swatches
        drawFill(0, 0, totalWidth, totalHeight, swatchGridBackgroundColor, 100);
		setActualSize(totalWidth, totalHeight);

        // Draw the swatches
        var cNum:int = 0;
		var rNum:int = 0;
		for (var n:int = 0; n < length; n++)
        {
            var swatchX:Number = swatchGridBorderSize + cNum *
								(swatchWidth + horizontalGap - cellOffset);
            
			var swatchY:Number = swatchGridBorderSize + rNum *
								 (swatchHeight + verticalGap - cellOffset);
            
			var c:Number = typeof(dp.getItemAt(n)) != "object" ?
						   Number(dp.getItemAt(n)) :
						   Number((dp.getItemAt(n))[mx_internal::colorField]);

            // Draw rectangle...
            drawSwatch(swatchX, swatchY, swatchWidth, swatchHeight, c);
            
			if (cNum < columnCount - 1)
            {
                cNum++
            }
            else
            {
                cNum = 0;
                rNum++
            }
        }
    }

    /**
     *  @private
     */    
    protected function drawSwatch(x:Number, y:Number, w:Number, h:Number,
							    c:Number):void
    {
        // Load styles...
		var swatchBorderColor:uint ;
		var swatchBorderSize:Number ;
		if ( FlexVersion.compatibilityVersion > FlexVersion.VERSION_3_0 && !_cssStyleDefined ) {
			var nullSwatchPanelCSS:CSSStyleDeclaration = StyleManager.getStyleDeclaration("NullSwatchPanel");
			if ( nullSwatchPanelCSS ) {
				swatchBorderColor = nullSwatchPanelCSS.getStyle("swatchBorderColor");
				swatchBorderSize = nullSwatchPanelCSS.getStyle("swatchBorderSize");
			}else {
				swatchBorderColor = 0 ;
			}
		}else {
	        swatchBorderColor = getStyle("swatchBorderColor");
	        swatchBorderSize = getStyle("swatchBorderSize");
		}
			
		if(name == "nullSwatch") {
			var g:Graphics = graphics;
	        g.moveTo(x, y);
	        g.beginFill(0xffffff, 1.0);
	        g.lineTo(x + w, y);
	        g.lineTo(x + w, h + y);
	        g.lineTo(x, h + y);
	        g.lineTo(x, y);
	        g.endFill();
	        
	        // Diagonal stripe
	        g.lineStyle(1, 0xff0000);
	        g.moveTo(x, y);
	        g.lineTo(x + w, y + h);
	        
	        // Draw borders
	        g.lineStyle(1, 0);
	        g.moveTo(x, y);       
	        g.lineTo(x, y + h);
	        g.lineTo(x + w, y + h);
	        g.lineTo(x + w, y);
	        g.lineTo(x, y);
		}
        else if (swatchBorderSize == 0)
        {
            // Don't show a border...
            drawFill(x, y, w, h, c, 1.0);
        }
        else if (swatchBorderSize < 0 || isNaN(swatchBorderSize))
        {
            // Default to a border size of 1 if invalid.
            drawFill(x, y, w, h, swatchBorderColor, 1.0);
            drawFill(x + 1, y + 1, w - 2, h - 2, c, 1.0);
        }
        else
        {
            // Otherwise use specified border size.
            drawFill(x, y, w, h, swatchBorderColor, 1.0);
            drawFill(x + swatchBorderSize, y + swatchBorderSize,
					 w - 2 * swatchBorderSize, h - 2 * swatchBorderSize,
					 c, 1.0);
        }
    }

    /**
     *  @private
     */    
    protected function drawBorder(x:Number, y:Number, w:Number, h:Number,
								c1:Number, c2:Number, s:Number, a:Number):void
    {
        // border line on the left side
        drawFill(x, y, s, h, c1, a);

        // border line on the top side
        drawFill(x, y, w, s, c1, a);

        // border line on the right side
        drawFill(x + (w - s), y, s, h, c2, a);

        // border line on the bottom side
        drawFill(x, y + (h - s), w, s, c2, a);
    }

    /**
     *  @private
     */    
    protected function drawFill(x:Number, y:Number, w:Number, h:Number,
							  c:Number, a:Number):void
    {
        var g:Graphics = graphics;
        g.moveTo(x, y);
        g.beginFill(c, a);
        g.lineTo(x + w, y);
        g.lineTo(x + w, h + y);
        g.lineTo(x, h + y);
        g.lineTo(x, y);
        g.endFill();
    }
}

}








