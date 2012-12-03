// ActionScript file
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
package com.adobe.coreUI.controls
{
	import mx.controls.CheckBox;
    import mx.controls.Button;
   	import mx.containers.HBox;
   	import mx.controls.ToggleButtonBar;
   	import mx.controls.ColorPicker;
    import flash.events.MouseEvent;
    import mx.core.UIComponent;
    import mx.containers.ViewStack;
    import mx.containers.Canvas;
    import mx.controls.Label;
    import mx.controls.ComboBox;
    import mx.controls.RichTextEditor;
    import flash.events.FocusEvent;
    import com.adobe.coreUI.localization.ILocalizationManager;
    import com.adobe.coreUI.localization.Localization;
    import mx.core.ClassFactory;
    import mx.controls.List;
     
	/**
	 * @private
	 */
   public class  ToolBar extends UIComponent
    {	 
    	/**
    	 * Adding the TextField for mutiple lines. Adding the format for the enabled text which is to be taken from the Breeze
    	 * Adding the format for the disabled text which is to be taken from Breeze.Adding a padding. Adding
    	 * _oldLabel value when it keeps the value and updates later
    	 */  

 		/**
         * @private	
         * Minimum Height of ToolBar
         * @return 
         */	
		protected const k_TOOLBAR_HEIGHT:Number = 22;
    	 
    	[Embed(source="toolBarAssets/bold.png")]
 		private var _icon_bold:Class;
 		
 		[Embed(source="toolBarAssets/italic.png")]
 		private var _icon_italic:Class;
 			
 		[Embed(source="textEditorClasses/assets/icon_style_underline.png")]
 		private var _icon_underline:Class;
 			
 		[Embed(source="toolBarAssets/bullets.png")]
 		private var _icon_bullet:Class;
 		
 		[Embed(source="textEditorClasses/assets/icon_align_left.png")]
 		private var _icon_leftAlign:Class;
 			
 		[Embed(source="textEditorClasses/assets/icon_align_center.png")]
 		private var _icon_centerAlign:Class;
 		
 		[Embed(source="textEditorClasses/assets/icon_align_right.png")]
 		private var _icon_rightAlign:Class;
 		
    	/**
    	 * @private
    	 * property variable for _boldButton
    	 */
    	protected var _boldButton:Button;
    	/**
    	 * @private
    	 * property variable for _italicButton
    	 */
    	protected var _italicButton:Button;
    	/**
    	 * @private
    	 * property variable for _underlineButton
    	 */
    	protected var _underlineButton:Button;
    	/**
    	 * @private
    	 * private variable for HBox containing the bold/italic/underline button
    	 */
    	//protected var _styleButtonHBox:HBox;
    	/**
    	 * @private
    	 * property variable for _colorPickerButton
    	 */
    	protected var _colorPicker:NullColorPicker;
    	/**
    	 * @private
    	 * property variable for _bulletButton
    	 */
    	protected var _bulletButton:Button;
		/**
		 * @private
    	 * property variable for _alignButtonBar, it contains the alignment buttons.
    	 */
		protected var _alignButtonBar:ToggleButtonBar;

        /**
		* @private
		*/		
		protected var _sizeComboBox:ComboBox;

		/**
		* @private
		*/		
		protected var _fontTypeComboBox:ComboBox;

		/**
		 * @private
		 */
		protected var _toolsContainer:CustomHBox;
		
		/**
		* @private
		*/		
		protected var _showFontType:Boolean = true;

		/**
		* @private
		*/
		protected var _showFontSize:Boolean = true;         

		/**
		* @private
		*/
		protected var _showAlign:Boolean = true;         

		/**
		 * @private
		 */
		protected var _showBullets:Boolean = true;
		
		protected var _showUnderline:Boolean = true;
		protected var _invShowChange:Boolean = true;
		
		protected var _fontSizes:Array;	//either of uint or of objects of the type {label:String, data:uint}
		protected var _defaultFontSize:uint;
		protected var _fontFaces:Array;
		
		protected var _colors:Array;
		
		[Bindable]
		protected var _typeFactory:ClassFactory ;
		
		[Bindable]
		protected var _sizeFactory:ClassFactory ;
		
		protected var _lm:ILocalizationManager = Localization.impl;
		
		/**
		 * Constructor
		 */
        public function ToolBar()
        { 
        	super();
        	
        	_typeFactory = new ClassFactory(List);
			_typeFactory.properties = {showDataTips:false, dataTipFunction:myTypeDataTipFunction} 
			
			_sizeFactory = new ClassFactory(List);
			_sizeFactory.properties = {showDataTips:false, dataTipFunction:mySizeDataTipFunction} 

        	_fontSizes = [8, 9, 10, 11, 12, 14, 16, 18, 20, 22, 24, 26, 28, 36, 48, 72];
        	_fontFaces = ["_sans","_serif","_typewriter","Arial","Courier","Courier New","Geneva","Georgia","Helvetica","Times New Roman","Times","Verdana"];
        	_defaultFontSize = 10;
        }
        
        
        protected function myTypeDataTipFunction(item:Object):String
        {
        	return item as String ;
        }
        
        protected function mySizeDataTipFunction(item:Object):String
        {
        	return item.toString()  ;
        }
        /**
    	 * Fires event when it gets the focus
    	 * @param p_evt
    	 * 
    	 */    	
    	protected function toolBar_onMouseOver(p_evt:MouseEvent):void
    	{
    		dispatchEvent(p_evt);
    	}
    	        
        /**
         * Property whether to show font sizes of not
         * @return 
         * 
         */        
        public function get showFontSize():Boolean
        {
        	return _showFontSize;
        }
        
        /**
         * @private
         * @param p_showFontSize
         * 
         */        
        public function set showFontSize(p_showFontSize:Boolean):void
        {
        	if (_showFontSize == p_showFontSize) {
        		return ;
        	}
        		
        	_showFontSize = p_showFontSize;
        	
        	invalidateProperties();
        }

        /**
         * Property whether to show font sizes of not
         * @return 
         * 
         */        
        public function get showAlign():Boolean
        {
        	return _showAlign;
        }
        
        /**
         * @private
         * @param p_showIt
         * 
         */        
        public function set showAlign(p_showIt:Boolean):void
        {
        	if (_showAlign == p_showIt) {
        		return;        		
        	}
        		
        	_showAlign = p_showIt;
        	
        	invalidateProperties();
        }

        /**
         *  Property whether to show Font Type or not. By default it is false
         * @return 
         * 
         */        
        public function get showFontType():Boolean
        {
        	return _showFontType;
        }
        /**
         * @private 
         * @param p_showFontType
         * 
         */        
        public function set showFontType(p_showFontType:Boolean):void
        {
        	if ( _showFontType == p_showFontType )
        		return ;
        		
        	_showFontType = p_showFontType;
        	
        	invalidateProperties();
        }

        public function get showBullets():Boolean
        {
        	return _showBullets;
        }
        public function set showBullets(p_showIt:Boolean):void
        {
        	if (_showBullets == p_showIt)
        		return ;
        		
        	_showBullets = p_showIt;
        	
        	invalidateProperties();
        }

        public function get showUnderline():Boolean
        {
        	return _showUnderline;
        }
        public function set showUnderline(p_showIt:Boolean):void
        {
        	if (_showUnderline == p_showIt)
        		return ;
        		
        	_showUnderline = p_showIt;
        	
        	invalidateProperties();
        }

     	/**
     	 * @private
     	 * All the buttons for styles,alignments,bulleting are currently created here
     	 */
		override protected function createChildren():void
		{
			super.createChildren();
		
			_toolsContainer = new CustomHBox();
			_toolsContainer.setStyle("horizontalGap",0);
			addChild(_toolsContainer);
			
			_boldButton=new Button();
			_boldButton.setStyle("icon",_icon_bold);
			_boldButton.toolTip = _lm.getString("bold");
			_boldButton.width = 24;
			_boldButton.height = 22;
			_boldButton.addEventListener(MouseEvent.MOUSE_OVER, toolBar_onMouseOver);
			
			_italicButton=new Button();
			_italicButton.setStyle("icon",_icon_italic);
			_italicButton.toolTip = _lm.getString("italic");
			_italicButton.width = 24;
			_italicButton.height = 22;
			_italicButton.addEventListener(MouseEvent.MOUSE_OVER, toolBar_onMouseOver);

			_colorPicker=new NullColorPicker();
			_colorPicker.allowNull = false;
			_colorPicker.styleName = getStyle("colorPickerStyleName");
			_colorPicker.dataProvider = [0x000000, 0x666666, 0x003366, 0x006699, 0x0033ff, 0x660066, 0x336666, 0x009933, 0x996600, 0x663300, 0xFF6600, 0xFF0000];
			_colorPicker.selectedColor = 0x000001;	//so that it'll throw a CHANGE if you select black;
			_colorPicker.showTextField = false;
			_colorPicker.toolTip = _lm.getString("color");
			_colorPicker.addEventListener(MouseEvent.MOUSE_OVER, toolBar_onMouseOver);
			
			invalidateProperties();
		}
		
		/**
		 * @private
		 * Overridding commit Properties, adding the text formatsfor enabled and disabled states
		 */
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if (_invShowChange) {
				_invShowChange = false;
				if ( _showFontType ) {
					_fontTypeComboBox = new ComboBox();
					_fontTypeComboBox.dataProvider=_fontFaces;
					_fontTypeComboBox.dropdownFactory = _typeFactory ;
					if (_fontFaces[0] is Object) {
						_fontTypeComboBox.labelField = "fontName";
					}
					_fontTypeComboBox.invalidateSize();
					_toolsContainer.addChild(_fontTypeComboBox);
					_fontTypeComboBox.validateNow();
					_fontTypeComboBox.dropdownWidth = _fontTypeComboBox.getExplicitOrMeasuredWidth()+5;
					_fontTypeComboBox.width = 70;
				} else {
					if (_fontTypeComboBox) {
						_toolsContainer.removeChild(_fontTypeComboBox); 
						_fontTypeComboBox = null ;
					}
				}
				
				if ( _showFontSize ) {
					_sizeComboBox=new ComboBox();
					_sizeComboBox.dataProvider=_fontSizes;
					_sizeComboBox.dropdownFactory = _sizeFactory ;
					if (_fontSizes.length>0 && _fontSizes[0] is Object) {
						_sizeComboBox.labelField = "label";
					} else {
						_sizeComboBox.labelField = null;
					}
					for (var i:uint=0; i<_fontSizes.length; i++) {
						var value:uint = ((_fontSizes[i]).hasOwnProperty("data")) ? _fontSizes[i].data : _fontSizes[i];
						if (value == _defaultFontSize) {
							_sizeComboBox.selectedIndex = i;
							break;
						}
					}
					_sizeComboBox.setActualSize(_sizeComboBox.getExplicitOrMeasuredWidth(), _sizeComboBox.getExplicitOrMeasuredHeight());
					_toolsContainer.addChild(_sizeComboBox);
				} else {
					if (_sizeComboBox) {
						_toolsContainer.removeChild(_sizeComboBox); 
						_sizeComboBox = null ;
					}
				}
	
				if (_boldButton) {
					_toolsContainer.addChild(_boldButton);
					_toolsContainer.addChild(_italicButton);
				}
				
				if (_showUnderline) {
					_underlineButton=new Button();
					_underlineButton.setStyle("icon",_icon_underline);
					_underlineButton.toolTip = _lm.getString("underline");
					_underlineButton.width = 24;
					_underlineButton.height = 22;
					_underlineButton.addEventListener(MouseEvent.MOUSE_OVER, toolBar_onMouseOver);
					_toolsContainer.addChild(_underlineButton);
				} else {
					if (_underlineButton) {
						_toolsContainer.removeChild(_underlineButton);
						_underlineButton = null;
					}
				}
				
				if (_colorPicker) {
					if (_colors != null) {
						_colorPicker.dataProvider = _colors;
					}
					_toolsContainer.addChild(_colorPicker);
				}
				
				
				if (_showBullets) {
					_bulletButton = new Button();
					_bulletButton.width = 24;
					_bulletButton.height = 22;
					_bulletButton.toolTip = _lm.getString("bullets");
					_bulletButton.setStyle("icon",_icon_bullet);
					_bulletButton.addEventListener(MouseEvent.MOUSE_OVER, toolBar_onMouseOver);
					_toolsContainer.addChild(_bulletButton);				
				} else {
					if (_bulletButton) {
						_toolsContainer.removeChild(_bulletButton);
						_bulletButton = null;
					}
				
				}
				
				
				
				if (_showAlign) {
					_alignButtonBar = new ToggleButtonBar();
					//_alignButtonBar.toolTip = _lm.getString("align");
					var leftObject:Object={icon:_icon_leftAlign , toolTip:_lm.getString("Left")};
					var centerObject:Object={icon:_icon_centerAlign , toolTip:_lm.getString("Center")};
					var rightObject:Object={icon:_icon_rightAlign , toolTip:_lm.getString("Right")};
					_alignButtonBar.dataProvider=[leftObject, centerObject, rightObject];
					_alignButtonBar.width= 24*3;
					_toolsContainer.addChild(_alignButtonBar);
				} else {
					if (_alignButtonBar) {
						_toolsContainer.removeChild(_alignButtonBar);
						_alignButtonBar = null;
					}
				}
			
				
	
				invalidateDisplayList();
			}
		}
		
		public function get fontSizes():Array
		{
			return _fontSizes;
		}
		public function set fontSizes(p_sizes:Array):void
		{
			_fontSizes = p_sizes;
			invalidateProperties();
		}
		
		public function get fontFaces():Array
		{
			return _fontFaces;
		}
		public function set fontFaces(p_faces:Array):void
		{
			_fontFaces = p_faces;
			invalidateProperties();
		}

		public function get colors():Array
		{
			return _colors;
		}
		public function set colors(p_colors:Array):void
		{
			_colors = p_colors;
			invalidateProperties();
		}
		
		public function get defaultFontSize():uint
		{
			return _defaultFontSize;
		}
		public function set defaultFontSize(p_def:uint):void
		{
			_defaultFontSize = p_def;
			invalidateProperties();
		}
		
		/**
		 * @private
		 *  Measure function for calculating the default height and width when no height or width is being set
		 * Based on the LabelPlacement Value, we are measuring the minWidth and minHeight based on labelText Width and Height.
		 * The function is written on the same pattern as of the measure function in its base class RadioButton.
		 */
		override protected function measure():void
		{
			super.measure();
			
			measuredWidth = measuredMinWidth = _toolsContainer.measuredWidth;
			measuredHeight = measuredMinHeight = k_TOOLBAR_HEIGHT;			
		}
		
		/**
		 * @private
		 *  Adding the function updateDisplayList for the calculating the sizes
		 * This function also sets the various properties which got changed. 
		 * Also , based on labelPlacement , we are positioning the labeltext accordingly. We also calculate the sizes when
		 * default sizes are set
		 */ 
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth,unscaledHeight);
			_toolsContainer.setActualSize(unscaledWidth, unscaledHeight);			 
		}
	
    }

}