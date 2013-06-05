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
import com.adobe.coreUI.localization.Localization;

import flash.events.Event;
import flash.events.EventPhase;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.ui.Keyboard;

import mx.collections.ArrayList;
import mx.collections.IList;
import mx.controls.TextInput;
import mx.core.FlexVersion;
import mx.core.IFlexDisplayObject;
import mx.core.UIComponent;
import mx.core.mx_internal;
import mx.events.ColorPickerEvent;
import mx.managers.IFocusManagerContainer;
import mx.styles.CSSStyleDeclaration;
import mx.styles.StyleManager;

use namespace mx_internal;

//--------------------------------------
//  Events
//--------------------------------------

/**
 *  Dispatched when the selected color changes.
 *
 *  @eventType flash.events.Event.CHANGE
 */
[Event(name="change", type="flash.events.Event")]

/**
 *  Dispatched when the user presses the Enter key.
 *
 *  @eventType mx.events.FlexEvent.ENTER
 */
[Event(name="enter", type="flash.events.Event")]

/**
 *  Dispatched when the mouse rolls over a color.
 *
 *  @eventType mx.events.ColorPickerEvent.ITEM_ROLL_OVER
 */
[Event(name="itemRollOver", type="mx.events.ColorPickerEvent")]

/**
 *  Dispatched when the mouse rolls out of a color.
 *
 *  @eventType mx.events.ColorPickerEvent.ITEM_ROLL_OUT
 */
[Event(name="itemRollOut", type="mx.events.ColorPickerEvent")]

//--------------------------------------
//  Styles
//--------------------------------------

//include "../styles/GapStyles.as"
//include "../styles/PaddingStyles.as"

/**
 *  Background color of the component.
 *  You can either have a <code>backgroundColor</code> or a
 *  <code>backgroundImage</code>, but not both.
 *  Note that some components, like a Button, do not have a background
 *  because they are completely filled with the button face or other graphics.
 *  The DataGrid control also ignores this style.
 *  The default value is <code>undefined</code>. If both this style and the
 *  backgroundImage style are undefined, the control has a transparent background.
 */
[Style(name="backgroundColor", type="uint", format="Color", inherit="no")]

/**
 *  Black section of a three-dimensional border, or the color section
 *  of a two-dimensional border.
 *  The following components support this style: Button, CheckBox,
 *  ComboBox, MenuBar,
 *  NumericStepper, ProgressBar, RadioButton, ScrollBar, Slider, and all
 *  components that support the <code>borderStyle</code> style.
 *  The default value depends on the component class;
 *  if not overriden for the class, it is <code>0xAAB3B3</code>.
 */
[Style(name="borderColor", type="uint", format="Color", inherit="no")]

/**
 *  Number of columns in the swatch grid.
 *  The default value is 20.
 */
[Style(name="columnCount", type="int", inherit="no")]

/**
 *  Color of the control border highlight.
 *  The default value is <code>0xC4CCCC</code> (medium gray) .
 */
[Style(name="highlightColor", type="uint", format="Color", inherit="yes")]

/**
 *  Color for the left and right inside edges of a component's skin.
 *  The default value is <code>0xD5DDDD</code>.
 */
[Style(name="shadowCapColor", type="uint", format="Color", inherit="yes")]

/**
 *  Bottom inside color of a button's skin.
 *  A section of the three-dimensional border.
 *  The default value is <code>0xEEEEEE</code> (light gray).
 */
[Style(name="shadowColor", type="uint", format="Color", inherit="yes")]

/**
 *  Height of the larger preview swatch that appears above the swatch grid on
 *  the top left of the SwatchPanel object.
 *  The default value is 22.
 */
[Style(name="previewHeight", type="Number", format="Length", inherit="no")]

/**
 *  Width of the larger preview swatch.
 *  The default value is 45.
 */
[Style(name="previewWidth", type="Number", format="Length", inherit="no")]

/**
 *  Size of the swatchBorder outlines.
 *  The default value is 1.
 */
[Style(name="swatchBorderSize", type="Number", format="Length", inherit="no")]

/**
 *  Color of the swatch borders.
 *  The default value is <code>0x000000</code>.
 */
[Style(name="swatchBorderColor", type="uint", format="Color", inherit="no")]

/**
 *  Size of the single border around the grid of swatches.
 *  The default value is 0.
 */
[Style(name="swatchGridBorderSize", type="Number", format="Length", inherit="no")]

/**
 *  Color of the background rectangle behind the swatch grid.
 *  The default value is <code>0x000000</code>.
 */
[Style(name="swatchGridBackgroundColor", type="uint", format="Color", inherit="no")]

/**
 *  Height of each swatch.
 *  The default value is 12.
 */
[Style(name="swatchHeight", type="Number", format="Length", inherit="no")]

/**
 *  Color of the highlight that appears around the swatch when the user
 *  rolls over a swatch.
 *  The default value is <code>0xFFFFFF</code>.
 */
[Style(name="swatchHighlightColor", type="uint", format="Color", inherit="no")]

/**
 *  Size of the highlight that appears around the swatch when the user
 *  rolls over a swatch.
 *  The default value is 1.
 */
[Style(name="swatchHighlightSize", type="Number", format="Length", inherit="no")]

/**
 *  Width of each swatch.
 *  The default value is 12.
 */
[Style(name="swatchWidth", type="Number", format="Length", inherit="no")]

/**
 *  Width of the hexadecimal text box that appears above the swatch grid.
 *  The default value is 72.
 */
[Style(name="textFieldWidth", type="Number", format="Length", inherit="no")]

//--------------------------------------
//  Other metadata
//--------------------------------------

[ExcludeClass]

/**
 *  @private
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
   public class  NullSwatchPanel extends UIComponent implements IFocusManagerContainer
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
    public function NullSwatchPanel() 
    {
        super();
        
        // Register for events.
        addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
        addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);   
		this.setStyle("backgroundColor","0xffffff");
    }

	private static var classConstructed:Boolean = classConstruct();

	private static function classConstruct():Boolean
	{
		var styleDeclaration:CSSStyleDeclaration = StyleManager.getStyleDeclaration("NullSwatchPanel");

		// If there's no style declaration already, create one.
		if (!styleDeclaration) {
			styleDeclaration = new CSSStyleDeclaration();
			if ( FlexVersion.compatibilityVersion > FlexVersion.VERSION_3_0) {
				styleDeclaration["setStyle"]("backgroundColor","0xE5E6E7");
				styleDeclaration["setStyle"]("borderColor", "0xA5A9AE");
				styleDeclaration["setStyle"]("columnCount", 20);
				styleDeclaration["setStyle"]("fontSize", 11);
				styleDeclaration["setStyle"]("highlightColor", "0xFFFFFF");;
				styleDeclaration["setStyle"]("horizontalGap", 0);;
				styleDeclaration["setStyle"]("paddingBottom", 5);
				styleDeclaration["setStyle"]("paddingLeft", 5);
				styleDeclaration["setStyle"]("paddingRight", 5);
				styleDeclaration["setStyle"]("paddingTop", 4);
				styleDeclaration["setStyle"]("previewHeight", 22);
				styleDeclaration["setStyle"]("previewWidth", 45);
				styleDeclaration["setStyle"]("shadowColor", "0x4D555E");
				styleDeclaration["setStyle"]("swatchBorderColor", 0);
				styleDeclaration["setStyle"]("swatchBorderSize", 1);
				styleDeclaration["setStyle"]("swatchGridBackgroundColor", 0);
				styleDeclaration["setStyle"]("swatchGridBorderSize", 0);
				styleDeclaration["setStyle"]("swatchHeight", 12);
				styleDeclaration["setStyle"]("swatchHighlightColor", "0xFFFFFF");
				styleDeclaration["setStyle"]("swatchHighlightSize", 1);
				styleDeclaration["setStyle"]("swatchWidth",12);
				styleDeclaration["setStyle"]("textFieldWidth", 72);
				styleDeclaration["setStyle"]("verticalGap", 0);
			}
		}
		
		styleDeclaration.defaultFactory = function ():void {
			this.backgroundColor = 0xE5E6E7;
			this.borderColor = 0xA5A9AE;
			this.columnCount = 20;
			this.fontSize = 11;
			this.highlightColor = 0xFFFFFF;
			this.horizontalGap = 0;
			this.paddingBottom = 5;
			this.paddingLeft = 5;
			this.paddingRight = 5;
			this.paddingTop = 4;
			this.previewHeight = 22;
			this.previewWidth = 45;
			this.shadowColor = 0x4D555E;
			this.swatchBorderColor = 0;
			this.swatchBorderSize = 1;
			this.swatchGridBackgroundColor = 0;
			this.swatchGridBorderSize = 0;
			this.swatchHeight = 12;
			this.swatchHighlightColor = 0xFFFFFF;
			this.swatchHighlightSize = 1;
			this.swatchWidth = 12;
			this.textFieldWidth = 72;
			this.verticalGap = 0;
		}
		
		StyleManager.setStyleDeclaration("NullSwatchPanel", styleDeclaration, false);
	
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
    protected var textInput:TextInput;

    /**
     *  @private
     */    
    protected var border:NullSwatchPanelSkin;

    /**
     *  @private
     */    
    protected var preview:NullSwatchSkin;
    
    protected var nullSwatch:NullSwatchSkin;

    /**
     *  @private
     */    
    protected var swatches:NullSwatchSkin;

    /**
     *  @private
     */    
    protected var highlight:NullSwatchSkin;

    /**
     *  @private
     *  Used by NullColorPicker
     */   
    mx_internal var isOverGrid:Boolean = false;

    /**
     *  @private
     *  Used by NullColorPicker
     */   
    mx_internal var isOpening:Boolean = false;

    /**
     *  @private
     *  Used by NullColorPicker
     */   
    mx_internal var focusedIndex:int = -1;

    /**
     *  @private
     *  Used by NullColorPicker
     */   
    mx_internal var tweenUp:Boolean = false;
    
    /**
     *  @private
     */    
    protected var initializing:Boolean = true;
 
    /**
     *  @private
     */    
    protected var indexFlag:Boolean = false;
 
    /**
     *  @private
     */    
    protected var lastIndex:int = -1;
 
    /**
     *  @private
     */    
    protected var grid:Rectangle;

    protected var nullSwatchArea:Rectangle;

	protected var _allowNull:Boolean = true;
	protected var _allowNullChanged:Boolean;

 
    /**
     *  @private
     */    
    protected var rows:int;
    
    /**
     *  @private
	 *  Cached style.
     */        
    protected var horizontalGap:Number;
    
    /**
     *  @private
	 *  Cached style.
     */        
    protected var verticalGap:Number;
    
    /**
     *  @private
	 *  Cached style.
     */        
    protected var columnCount:int;
    
    /**
     *  @private
	 *  Cached style.
     */        
    protected var paddingLeft:Number;
    
    /**
     *  @private
	 *  Cached style.
     */        
    protected var paddingRight:Number;
    
    /**
     *  @private
	 *  Cached style.
     */        
    protected var paddingTop:Number;
    
    /**
     *  @private
	 *  Cached style.
     */        
    protected var paddingBottom:Number;
    
    /**
     *  @private
	 *  Cached style.
     */        
    protected var textFieldWidth:Number;
     
    /**
     *  @private
	 *  Cached style.
     */        
    protected var previewWidth:Number;
    
    /**
     *  @private
	 *  Cached style.
     */        
    protected var previewHeight:Number;
    
    /**
     *  @private
	 *  Cached style.
     */        
    protected var swatchWidth:Number;
    
    /**
     *  @private
	 *  Cached style.
     */        
    protected var swatchHeight:Number;
    
    /**
     *  @private
	 *  Cached style.
     */        
    protected var swatchGridBorderSize:Number;
    
    /**
     *  @private
     */        
	protected var cellOffset:Number = 1;
 
    /**
     *  @private
     */        
    protected var itemOffset:Number = 3;
    
    //--------------------------------------------------------------------------
    //
    //  Overridden Properties
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  height
    //----------------------------------
    
    /**
     *  @private
     *  We set our size internally based on style values.
	 *  Setting height has no effect on the panel.
	 *  Override to return the preferred width and height of our contents.
     */    
    override public function get height():Number
    {
        return getExplicitOrMeasuredHeight();
    }

    /**
     *  @private
     */
    override public function set height(value:Number):void 
    {
        // do nothing...
    }
    
    //----------------------------------
    //  width
    //----------------------------------
    
    /**
     *  @private
     *  We set our size internally based on style values.
	 *  Setting width has no effect on the panel.
	 *  Override to return the preferred width and height of our contents.
     */    
    override public function get width():Number
    {
        return getExplicitOrMeasuredWidth();
    }

    /**
     *  @private
     */
    override public function set width(value:Number):void 
    {
        // do nothing...
    }
    
    
    public function get allowNull():Boolean
    {
    	return _allowNull;
    }
    
    public function set allowNull(p_value:Boolean):void
    {
    	if(_allowNull != p_value) {
    		_allowNull = p_value;
    		_allowNullChanged = true;
    		invalidateProperties();
    	}
    }
    
    
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  colorField
    //----------------------------------
    
    /**
	 *  Storage for the colorField property.
	 */
    protected var _colorField:String = "color";

    /**
     *  @private
     */    
    public function get colorField():String
    {
        return _colorField;
    }

    /**
     *  @private
     */
    public function set colorField(value:String):void
    {
        _colorField = value;
    }

	
    //--------------------------------------------------------------------------
    //  defaultButton
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     */
    public function get defaultButton():IFlexDisplayObject
    {
        return null;
    }

    /**
     *  @private
     */
    public function set defaultButton(value:IFlexDisplayObject):void
    {
        
    }

    //----------------------------------
    //  dataProvider
    //----------------------------------
    
    /**
	 *  Storage for the dataProvider property.
	 */
	protected var _dataProvider:IList;

    /**
     *  @private
     */    
    public function get dataProvider():Object
    {
        return _dataProvider;
    }

    /**
     *  @private
     */
    public function set dataProvider(value:Object):void
    {
        if (value is IList)
        {
	        _dataProvider = IList(value);        
        }
        else if (value is Array)
		{
			var tmpDP:IList = new ArrayList(value as Array);
			value = tmpDP;
		}
		else
		{
	        _dataProvider = null;			
        }        

        if (!initializing)
        {
            // Adjust if dataProvider is empty
            if (length == 0 || isNaN(length))
            {
                highlight.visible = false;
                _selectedIndex = -1;
            }
            
			// Redraw using new dataProvider
            refresh();
        }
    }

    //----------------------------------
    //  editable
    //----------------------------------    
    
    /**
	 *  Storage for the editable property.
	 */
	protected var _editable:Boolean = true;

    /**
     *  @private
     */    
    public function get editable():Boolean
    {
        return _editable;
    }

    /**
     *  @private
     */
    public function set editable(value:Boolean):void
    {
        _editable = value;
        
		if (!initializing)
            textInput.editable = value;
    }

    //----------------------------------
    //  labelField
    //----------------------------------
    
    /**
	 *  Storage for the labelField property.
	 */
    protected var _labelField:String = "label";

    /**
     *  @private
     */    
    public function get labelField():String
    {
        return _labelField;
    }

    /**
     *  @private
     */
    public function set labelField(value:String):void
    {
        _labelField = value;
    }

    //----------------------------------
    //  length
    //----------------------------------
    
    /**
     *  @private
     */    
    public function get length():int
    {
        return _dataProvider ? _dataProvider.length : 0;
    }

    //----------------------------------
    //  selectedColor
    //----------------------------------
    
    /**
	 *  Storage for the selectedColor property.
	 */
    protected var _selectedColor:uint = 0x000000;

    /**
     *  @private
     */    
    public function get selectedColor():uint
    {
        return _selectedColor;
    }

    /**
     *  @private
     */
    public function set selectedColor(value:uint):void
    {
        // Set index unless it set us
        if (!indexFlag)
        {
            var SI:int = findColorByName(value);
            if (SI != -1)
            {
                focusedIndex = findColorByName(value);
                _selectedIndex = focusedIndex;
            }
            else
			{
                selectedIndex = -1;
			}
        }
        else
        {
            indexFlag = false;
        }
        
		if (value != selectedColor || !isOverGrid || isOpening)
        {
            _selectedColor = value;
            updateColor(value);

            if (isOverGrid || isOpening)
                setFocusOnSwatch(selectedIndex);
            if (isOpening)
                isOpening = false;
        }
    }

    //----------------------------------
    //  selectedIndex
    //----------------------------------
    
    /**
	 *  Storage for the selectedIndex property.
	 */
    protected var _selectedIndex:int = 0;

    /**
     *  @private
     */    
    public function get selectedIndex():int
    {
        return _selectedIndex;
    }

    /**
     *  @private
     */
    public function set selectedIndex(value:int):void
    {
        if (value != selectedIndex && !initializing)
        {
            focusedIndex = value;
            _selectedIndex = focusedIndex;
            
			if (value >= 0 || value == NullColorPicker.NULL_INDEX)
            {
                indexFlag = true;
                selectedColor = getColor(value);
            }
        }
    }

    //----------------------------------
    //  selectedItem
    //----------------------------------
    
    /**
     *  @private
     */    
    public function get selectedItem():Object
    {
        return dataProvider ? dataProvider.getItemAt(selectedIndex) : null;
    }

    /**
     *  @private
     */
    public function set selectedItem(value:Object):void
    {
        if (value != selectedItem)
        {
            var color:Number;
			if (typeof(value) == "object")
                color = Number(value[colorField]);
            else if (typeof(value) == "number")
                color = Number(value);
            
			selectedIndex = findColorByName(color);
        }
    }
    
    //----------------------------------
    //  showTextField
    //----------------------------------
    
    /**
	 *  Storage for the showTextField property.
	 */
    protected var _showTextField:Boolean = true;

    /**
     *  @private
     */        
    public function get showTextField():Boolean
    {
        return _showTextField;
    }

    /**
     *  @private
     */
    public function set showTextField(value:Boolean):void
    {
        _showTextField = value;

        if (!initializing)
            textInput.visible = value;
    }

    //--------------------------------------------------------------------------
    //
    //  Overridden methods: UIComponent
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */            
    override protected function createChildren():void
    {
        super.createChildren();
        
        // Create the panel background
        if (!border)
		{
			border = new NullSwatchPanelSkin();
			border.styleName = this;
			border.name = "swatchPanelBorder";
			addChild(border);  
			
		}      
                    
        // Create the preview swatch
        if (!preview)
		{
			preview = new NullSwatchSkin();
			
			preview.styleName = this;
			preview.color = selectedColor;
			preview.name = "swatchPreview";
			
			preview.setStyle("borderStyle", "swatchPreview");
			preview.setStyle("swatchBorderSize", 0);
			
			addChild(preview);        
		}   
		
        // Create the preview swatch
        if (!nullSwatch)
		{
			nullSwatch = new NullSwatchSkin();
			
			nullSwatch.styleName = this;
			nullSwatch.color = selectedColor;
			nullSwatch.name = "nullSwatch";
			
			nullSwatch.setStyle("borderStyle", "swatchPreview");
			nullSwatch.setStyle("swatchBorderSize", 0);
			
			nullSwatch.addEventListener(MouseEvent.CLICK, nullSwatch_clickHandler);		
			
			addChild(nullSwatch);        
		}    

		
		

        // Create the hex text field  
        if (!textInput)
		{
			textInput = new TextInput();
			
			textInput.editable = _editable;
			textInput.maxChars = 6;
			textInput.name = "inset";
			textInput.text = rgbToHex(selectedColor);
			textInput.restrict = "#xa-fA-F0-9";        

			if (FlexVersion.compatibilityVersion < FlexVersion.VERSION_3_0)
			{
				textInput.styleName = this;
				
				textInput.setStyle("borderCapColor", 0x919999);
				textInput.setStyle("buttonColor", 0x6F7777);
				textInput.setStyle("highlightColor", 0xC4CCCC);
				textInput.setStyle("shadowColor", 0xEEEEEE);
				textInput.setStyle("shadowCapColor", 0xD5DDDD);
				textInput.setStyle("borderStyle", "inset");
				textInput.setStyle("backgroundColor", 0xFFFFFF);
				textInput.setStyle("borderColor", 0xD5DDDD);
			}
			else
			{
				textInput.styleName = getStyle("textFieldStyleName");
			}
						
			textInput.addEventListener(Event.CHANGE, textInput_changeHandler);
			textInput.addEventListener(KeyboardEvent.KEY_DOWN, textInput_keyDownHandler);
			
			addChild(textInput);        
		}
        
        // Create the swatches grid
        if (!swatches)
		{
			swatches = new NullSwatchSkin();
			
			swatches.styleName = this;
			swatches.colorField = colorField;
			swatches.name = "swatchGrid";
			swatches.setStyle("borderStyle", "swatchGrid");
			
			swatches.addEventListener(MouseEvent.CLICK, swatches_clickHandler);
			
			addChild(swatches);        
		}
    
        // Create the swatch highlight for grid rollovers
        if (!highlight)
		{
			highlight = new NullSwatchSkin();
			
			highlight.styleName = this;
			highlight.visible = false;
			highlight.name = "swatchHighlight";
			
			highlight.setStyle("borderStyle", "swatchHighlight");
			
			addChild(highlight);        
		}

        refresh();

        initializing = false;
    }

    /**
     *  @private
     *  Change
     */    
    override protected function measure():void
    {
		super.measure();
        
        swatches.updateGrid(IList(dataProvider));
        
		measuredWidth = Math.max(
			paddingLeft + paddingRight + swatches.width, 50);
        
		measuredHeight = Math.max(
			paddingTop + previewHeight + itemOffset +
			paddingBottom + swatches.height, 50);
		
		
    }
    
    override protected function commitProperties():void
    {
    	super.commitProperties();
    	
    	if(_allowNullChanged) {
    		nullSwatch.visible = _allowNull;
    		_allowNullChanged = false;
    		invalidateDisplayList();
    	}
    }

    /**
     *  @private
     */    
	override protected function updateDisplayList(unscaledWidth:Number,
												  unscaledHeight:Number):void
    {
        super.updateDisplayList(unscaledWidth, unscaledHeight);
		
		if ( isNaN(unscaledHeight) || isNaN(unscaledWidth)) {
			return ;
		}
        
        var nullSwatchSkinCSS:CSSStyleDeclaration = StyleManager.getStyleDeclaration("NullSwatchSkin");
        var nullSwatchWidth:Number = (_allowNull) ? nullSwatchSkinCSS.getStyle("nullSwatchWidth") : 0;
        var nullSwatchHeight:Number = (_allowNull) ? nullSwatchSkinCSS.getStyle("nullSwatchHeight") : 0;

        // Layout preview position.
        preview.updateSkin(selectedColor);
        preview.move(paddingLeft, paddingTop);
        
        nullSwatch.updateSkin(0xFFFFFF);
        nullSwatch.move(unscaledWidth - paddingLeft - nullSwatchWidth, preview.y + previewHeight - nullSwatchHeight);

        // Layout hex text field position.
        textInput.setActualSize(textFieldWidth, previewHeight);
        textInput.move(paddingLeft + previewWidth + itemOffset, paddingTop);

        // Layout grid position.
        swatches.updateGrid(IList(dataProvider));
        swatches.move(paddingLeft, paddingTop + Math.max(previewHeight, nullSwatchHeight) + itemOffset);

        // Layout highlight skin.
		// Highlight doesn't require a color, hence we pass 0.
        highlight.updateSkin(0);

        // Layout panel skin.
        border.setActualSize(unscaledWidth, unscaledHeight);
        
        // Define area surrounding the swatches.
        if (!grid) 
            grid = new Rectangle();
        grid.left = swatches.x + swatchGridBorderSize;
        grid.top = swatches.y + swatchGridBorderSize;
        grid.right = swatches.x + swatchGridBorderSize +
					 (swatchWidth - 1) * columnCount + 1 +
					 horizontalGap * (columnCount - 1);
        grid.bottom = swatches.y + swatchGridBorderSize +
					  (swatchHeight - 1) * rows + 1 +
					  verticalGap * (rows - 1);
					  
					  
		// Define area surrounding null swatch.
		if(!nullSwatchArea)
            nullSwatchArea = new Rectangle();
        nullSwatchArea.left = nullSwatch.x;
        nullSwatchArea.top = nullSwatch.y;
        nullSwatchArea.right = nullSwatch.x + nullSwatchWidth;
        nullSwatchArea.bottom = nullSwatch.y + nullSwatchHeight;	
    }


    /**
     *  @private
     */    
    override public function styleChanged(styleProp:String):void
    {
        if (!initializing)
            refresh();
    }
    
    /**
     *  @private
     */    
    override public function drawFocus(isFocused:Boolean):void
    {  
        // do nothing...
    }
   
    /**
     *  @private
     */    
    override public function setFocus():void
    {
        // Our text field controls focus   
        if (showTextField && editable)
            textInput.setFocus();
    }
        
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */    
    protected function updateStyleCache():void
    {
		if ( FlexVersion.compatibilityVersion > FlexVersion.VERSION_3_0 ) {
			var nullSwatchPanelCSS:CSSStyleDeclaration = StyleManager.getStyleDeclaration("NullSwatchPanel");
			horizontalGap = nullSwatchPanelCSS.getStyle("horizontalGap");
	        verticalGap = nullSwatchPanelCSS.getStyle("verticalGap");
	        columnCount = nullSwatchPanelCSS.getStyle("columnCount");
	        paddingLeft = nullSwatchPanelCSS.getStyle("paddingLeft");
	        paddingRight = nullSwatchPanelCSS.getStyle("paddingRight");
	        paddingTop = nullSwatchPanelCSS.getStyle("paddingTop");
	        paddingBottom = nullSwatchPanelCSS.getStyle("paddingBottom");
	        textFieldWidth = nullSwatchPanelCSS.getStyle("textFieldWidth");
	        previewWidth = nullSwatchPanelCSS.getStyle("previewWidth");
	        previewHeight = nullSwatchPanelCSS.getStyle("previewHeight");
	        swatchWidth = nullSwatchPanelCSS.getStyle("swatchWidth");
	        swatchHeight = nullSwatchPanelCSS.getStyle("swatchHeight");
	        swatchGridBorderSize = nullSwatchPanelCSS.getStyle("swatchGridBorderSize");
		}else {
			horizontalGap = getStyle("horizontalGap");
			verticalGap = getStyle("verticalGap");
			columnCount = getStyle("columnCount");
			paddingLeft = getStyle("paddingLeft");
			paddingRight = getStyle("paddingRight");
			paddingTop = getStyle("paddingTop");
			paddingBottom = getStyle("paddingBottom");
			textFieldWidth = getStyle("textFieldWidth");
			previewWidth = getStyle("previewWidth");
			previewHeight = getStyle("previewHeight");
			swatchWidth = getStyle("swatchWidth");
			swatchHeight = getStyle("swatchHeight");
			swatchGridBorderSize = getStyle("swatchGridBorderSize");
		}
		

        // Adjust if columnCount is greater than # of swatches
        if (columnCount > length)
            columnCount = length;

        // Rows based on columnCount and list length
        rows = Math.ceil(length / columnCount);
    }

    /**
     *  @private
     */    
    protected function refresh():void
    {
        updateStyleCache();
        updateDisplayList(unscaledWidth, unscaledHeight);
    }
 
    /**
     *  @private
	 *  Update color values in preview
     */    
    protected function updateColor(color:uint):void
    {
        if (initializing || isNaN(color))
            return;

        // Update the preview swatch
        preview.updateSkin(color);
        
        // Set hex field
        if (isOverGrid)
        {            
            var label:String = null;
            
			if (focusedIndex >= 0 && 
                typeof(dataProvider.getItemAt(focusedIndex)) == "object")
            {
                label = dataProvider.getItemAt(focusedIndex)[labelField];
            }

			if(color == NullColorPicker.NULL_COLOR)
				textInput.text = Localization.impl.getString("empty");
			else
	            textInput.text = label != null && label.length != 0 ?
							 label :
                             rgbToHex(color);
        }
    }

    /**
     *  @private
	 *  Convert RGB offset to Hex.
     */    
    protected function rgbToHex(color:uint):String
    {
        // Find hex number in the RGB offset
        var colorInHex:String = color.toString(16);
        var c:String = "00000" + colorInHex;
        var e:int = c.length;
        c = c.substring(e - 6, e);
        return c.toUpperCase();
    }

    /**
     *  @private
     */    
    protected function findColorByName(name:Number):int
    {
        if (name == getColor(selectedIndex))
            return selectedIndex;

        for (var i:int = 0; i < length; i++)
		{
            if (name == getColor(i))
                return i;
		}

        return -1;
    }
    
    /**
     *  @private
     */    
    protected function getColor(index:int):uint
    {
		if (!dataProvider || dataProvider.length < 1 ||
			(index < 0 && index != NullColorPicker.NULL_INDEX)|| index >= length)
		{
			return StyleManager.NOT_A_COLOR;
		}
		
		if(index == NullColorPicker.NULL_INDEX) return NullColorPicker.NULL_COLOR;	// special handler for null
        
		return uint(typeof(dataProvider.getItemAt(index)) == "object" ?
        	   		dataProvider.getItemAt(index)[colorField] : 
					dataProvider.getItemAt(index));
    }

    /**
     *  @private
     */    
    protected function setFocusOnSwatch(index:int):void
    {
        if ((index < 0 && index != NullColorPicker.NULL_INDEX) || index > length - 1)
        {
            highlight.visible = false;
            return;
        }
        
        if(index != NullColorPicker.NULL_INDEX) {
			// Swatch highlight activated by mouse move or key events
	        var row:Number = Math.floor(index / columnCount);
	        var column:Number = index - (row * columnCount);
	        
			var xPos:Number = swatchWidth * column + horizontalGap * column -
							  cellOffset * column + paddingLeft +
							  swatchGridBorderSize;
	        var yPos:Number = swatchHeight * row + verticalGap * row -
							  cellOffset * row + paddingTop + previewHeight +
							  itemOffset + swatchGridBorderSize;
		}
		else {
			xPos = nullSwatch.x;
			yPos = nullSwatch.y;
		}
	        
		highlight.move(xPos, yPos);
        highlight.visible = true;
    
		isOverGrid = true;
        
		updateColor(getColor(index));
    }

    //--------------------------------------------------------------------------
    //
    //  Overridden event handlers: UIComponent
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     */    
    override protected function keyDownHandler(event:KeyboardEvent):void
    {
		// Ignore events that bubbling from the owner NullColorPicker.
		// through the textInput's keyDownHandler
		if (event.eventPhase != EventPhase.AT_TARGET || !enabled)
			return;
			
        if (focusedIndex == -1 || isNaN(focusedIndex))
            focusedIndex = 0;

        var currentRow:int = Math.floor(focusedIndex / columnCount);

        switch (event.keyCode)
        {
            case Keyboard.UP:
            {
                // Move up in column / jump to bottom of next column at end.
                focusedIndex = focusedIndex - columnCount < 0 ?
							   (rows - 1) * columnCount + focusedIndex + 1 :
							   focusedIndex - columnCount;
                isOverGrid = true;
                break;
            }

            case Keyboard.DOWN:
            {
                // Move down in column / jump to top of last column at end.
                focusedIndex = focusedIndex + columnCount > length ?
							   (focusedIndex - 1) - (rows - 1) * columnCount :
							   focusedIndex + columnCount;
                isOverGrid = true;
                break;
            }

            case Keyboard.LEFT:
            {
                // Move left in row / jump to right of last row at end.
                focusedIndex = focusedIndex < 1 ?
							   length - 1 :
							   focusedIndex - 1;
                isOverGrid = true;
                break;
            }

            case Keyboard.RIGHT:
            {
                // Move right in row / jump to left of next row at end.
                focusedIndex = focusedIndex >= length - 1 ?
							   0 :
							   focusedIndex + 1;
                isOverGrid = true;
                break;
            }

            case Keyboard.PAGE_UP:
            {
                // Move to first swatch in column.
                focusedIndex = focusedIndex - currentRow * columnCount;
                isOverGrid = true;
                break;
            }

            case Keyboard.PAGE_DOWN:
            {
                // Move to last swatch in column.
                focusedIndex = focusedIndex + (rows - 1) * columnCount -
							   currentRow * columnCount;
                isOverGrid = true;
                break;
            }

            case Keyboard.HOME:
            {
                // Move to first swatch in row.
                focusedIndex = focusedIndex -
							   (focusedIndex - currentRow * columnCount);
                isOverGrid = true;
                break;
            }

            case Keyboard.END:
            {
                // Move to last swatch in row.
                focusedIndex = focusedIndex +
							   (currentRow * columnCount - focusedIndex) +
							   (columnCount - 1);
                isOverGrid = true;
                break;
            }
        }

        // Draw focus on new swatch.
        if (focusedIndex < length && isOverGrid)
        {
            setFocusOnSwatch(focusedIndex);
			dispatchEvent(new Event("change")); 
        }
    }
    
    //--------------------------------------------------------------------------
    //
    //  Event handlers
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */    
    protected function mouseMoveHandler(event:MouseEvent):void
    {    
        if (NullColorPicker(owner).isDown && enabled)
        {
            var colorPickerEvent:ColorPickerEvent;
                    
            // Assess movements that occur over the swatch grid.
            if (mouseX > grid.left && mouseX < grid.right &&
                mouseY > grid.top && mouseY < grid.bottom)
            {
                // Calculate location
                var column:Number = Math.floor(
					(Math.floor(mouseX) - (grid.left + verticalGap)) /
					(swatchWidth + horizontalGap - cellOffset));
				var row:Number = Math.floor(
					(Math.floor(mouseY) - grid.top) /
					((swatchHeight + verticalGap) - cellOffset));
                var index:Number = row * columnCount + column;

                // Adjust for edges
                if (column == -1)
					index++;
                else if (column > (columnCount - 1))
				    index--;
                else if (row > (rows - 1))
					index -= columnCount;
                else if (index < 0)
					index += columnCount;

                // Set state
                if ((lastIndex != index || highlight.visible == false) &&
					index < length)
                {
                    if (lastIndex != -1 && lastIndex != index)
                    {
                        // Dispatch a ColorPickerEvent with type "itemRollOut".
						colorPickerEvent = new ColorPickerEvent(
                            ColorPickerEvent.ITEM_ROLL_OUT);
                        colorPickerEvent.index = lastIndex;
						colorPickerEvent.color = getColor(lastIndex);
                        dispatchEvent(colorPickerEvent);
                    }

                    focusedIndex = index;
                    lastIndex = focusedIndex;
                    setFocusOnSwatch(focusedIndex);
                    
                    // Dispatch a ColorPickerEvent with type "itemRollOver".
					colorPickerEvent = new ColorPickerEvent(
                        ColorPickerEvent.ITEM_ROLL_OVER);
                    colorPickerEvent.index =  focusedIndex;
					colorPickerEvent.color = getColor(focusedIndex);
                    dispatchEvent(colorPickerEvent); 
                }
            }
            else if(mouseX > nullSwatchArea.left && mouseX < nullSwatchArea.right &&
                mouseY > nullSwatchArea.top && mouseY < nullSwatchArea.bottom)
            {
            	index = NullColorPicker.NULL_INDEX;
            	
            	// Handlers for mousing over the null swatch.
            	// Basically we want to pretend like this is part of the swatch grid,
            	//   so fire the same events.
            	
                if ((lastIndex != index || highlight.visible == false) &&
					index < length)
                {
                    if (lastIndex != -1 && lastIndex != index)
                    {
                        // Dispatch a ColorPickerEvent with type "itemRollOut".
						colorPickerEvent = new ColorPickerEvent(
                            ColorPickerEvent.ITEM_ROLL_OUT);
                        colorPickerEvent.index = lastIndex;
						colorPickerEvent.color = getColor(lastIndex);
                        dispatchEvent(colorPickerEvent);
                    }

                    focusedIndex = index;
                    lastIndex = focusedIndex;
                    setFocusOnSwatch(focusedIndex);
                    
                    // Dispatch a ColorPickerEvent with type "itemRollOver".
					colorPickerEvent = new ColorPickerEvent(
                        ColorPickerEvent.ITEM_ROLL_OVER);
                    colorPickerEvent.index =  focusedIndex;
					colorPickerEvent.color = getColor(focusedIndex);
                    dispatchEvent(colorPickerEvent); 
                }
            }
            else
            {
                if (highlight.visible == true && isOverGrid && lastIndex != -1)
                {
                    highlight.visible = false;

                    // Dispatch a ColorPickerEvent with type "itemRollOut".
                    colorPickerEvent = new ColorPickerEvent(
                        ColorPickerEvent.ITEM_ROLL_OUT);
                    colorPickerEvent.index = lastIndex;
					colorPickerEvent.color = getColor(lastIndex);
                    dispatchEvent(colorPickerEvent); 
                }

                isOverGrid = false;
            }
        }
    }
    
    /**
     *  @private
     */    
    protected function swatches_clickHandler(event:MouseEvent):void
    {
		if (!enabled)
			return;
	
        if (mouseX > grid.left && mouseX < grid.right &&
            mouseY > grid.top && mouseY < grid.bottom)
        {
            selectedIndex = focusedIndex;
            
			if (NullColorPicker(owner).selectedIndex != selectedIndex)
            {
                NullColorPicker(owner).selectedIndex = selectedIndex;
                
				var cpEvent:ColorPickerEvent = 
                    new ColorPickerEvent(ColorPickerEvent.CHANGE);
                cpEvent.index = selectedIndex;
                cpEvent.color = getColor(selectedIndex);
                NullColorPicker(owner).dispatchEvent(cpEvent);
            }

            NullColorPicker(owner).close(); // owner = NullColorPicker
        }
    }
        
    protected function nullSwatch_clickHandler(event:MouseEvent):void
    {
		if (!enabled)
			return;
	
        if (mouseX > nullSwatchArea.left && mouseX < nullSwatchArea.right &&
            mouseY > nullSwatchArea.top && mouseY < nullSwatchArea.bottom)
        {
            selectedIndex = focusedIndex;
            
			if (NullColorPicker(owner).selectedIndex != selectedIndex)
            {
                NullColorPicker(owner).selectedIndex = selectedIndex;
                
				var cpEvent:ColorPickerEvent = 
                    new ColorPickerEvent(ColorPickerEvent.CHANGE);
                cpEvent.index = selectedIndex;
                cpEvent.color = getColor(selectedIndex);
                NullColorPicker(owner).dispatchEvent(cpEvent);
            }

            NullColorPicker(owner).close(); // owner = NullColorPicker
        }
    }
        
    /**
     *  @private
     */    
    protected function textInput_keyDownHandler(event:KeyboardEvent):void
    {
        // Redispatch the event from the NullColorPicker
		// and let its keyDownHandler() handle it.
        NullColorPicker(owner).dispatchEvent(event);
    }

    /**
     *  @private
     */    
    protected function textInput_changeHandler(event:Event):void
    {
        // Handle events from hex TextField.
        var color:String = TextInput(event.target).text;
        if (color.charAt(0) == "#")
        {
            textInput.maxChars = 7;
            color = "0x"+color.substring(1);
        }
        else if (color.substring(0,2) == "0x")
        {
            textInput.maxChars = 8;
        }
        else
        {
            textInput.maxChars = 6;
            color = "0x"+color;
        }
        
		highlight.visible = false;
        isOverGrid = false;
		selectedColor = Number(color);
        
		dispatchEvent(new Event("change"));   
    }
}

}
