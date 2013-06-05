package 
{
	import flash.geom.Rectangle;
	import mx.core.UIComponent;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import com.adobe.coreUI.controls.whiteboardClasses.IWBPropertiesToolBar;
	import mx.managers.ISystemManager;
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import mx.controls.ColorPicker;
	import mx.controls.ComboBox;
	import com.adobe.coreUI.localization.ILocalizationManager;
	import com.adobe.coreUI.localization.Localization;
	import flash.events.MouseEvent;
	import mx.skins.halo.HaloBorder;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.display.GradientType;
	import com.adobe.coreUI.controls.NullColorPicker;
	
	/**
	 * @private
	 */
	public class WBCustomMarkerToolBar extends UIComponent implements IWBPropertiesToolBar
	{
		[Embed (source = '../assets/propBarIcons.swf#icon_fill')]
		protected static var _fillIconClass:Class;
		[Embed (source = '../assets/propBarIcons.swf#icon_stroke')]
		protected static var _strokeIconClass:Class;
		[Embed (source = '../assets/propBarIcons.swf#icon_stroke_thickness')]
		protected static var _numLinesIconClass:Class;
		[Embed (source = '../assets/propBarIcons.swf#icon_alpha')]
		protected static var _alphaIconClass:Class;
		
		protected static const ICON_PADDING:int = 2;
		protected static const CONTROL_PADDING:int = 15;
		protected static const BORDER_PADDING:int = 10;
		protected static const TITLE_HEIGHT:int = 10;
		
		protected var _fillColorPicker:NullColorPicker;
		protected var _strokeColorPicker:NullColorPicker;
		protected var _numLinesCombo:ComboBox;
		protected var _alphaCombo:ComboBox;
		
		protected var _fillIcon:UIComponent;
		protected var _strokeIcon:UIComponent;
		protected var _thicknessIcon:UIComponent;
		protected var _alphaIcon:UIComponent;
		
		protected var _lm:ILocalizationManager;
		protected var _propertyData:Object;
		protected var _invPropsChanged:Boolean = false
		
		protected var _isFilledShape:Boolean = false;
		
		protected var _backgroundSkin:HaloBorder;
		protected var _titleBar:Sprite;
		protected var _backgroundRect:Sprite;
		
		public function get propertyData():*
		{
			var returnObj:Object = new Object();
			if (_isFilledShape) {
				returnObj.primaryColor = _fillColorPicker.selectedColor;
			}
			returnObj.lineColor = _strokeColorPicker.selectedColor;
			returnObj.numLines = _numLinesCombo.selectedItem;
			returnObj.alpha = Number(_alphaCombo.selectedItem) / 100;
			return  returnObj;
		}
		
		public function set propertyData(p_data:*):void
		{
			_propertyData = p_data;
			_invPropsChanged = true;
			invalidateProperties();
		}
		
		public function set isFilledShape(p_fill:Boolean):void
		{
			_isFilledShape = false;
		}
		
		override protected function commitProperties():void
		{
			if (_invPropsChanged) {
				_invPropsChanged = false;
				if (_isFilledShape) {
					_fillColorPicker.selectedColor = _propertyData.primaryColor;
				}
				_strokeColorPicker.selectedColor = _propertyData.lineColor;
				_numLinesCombo.dataProvider = [1, 2, 3, 4, 5];
				_numLinesCombo.selectedItem = _propertyData.lineThickness;
				_alphaCombo.selectedItem = _propertyData.alpha * 100;
			}
		}
		
		override protected function createChildren():void
		{
			_lm = Localization.impl;
			
			_backgroundSkin = new HaloBorder();
			setStyle("backgroundColor", 0x000000);
			setStyle("borderStyle", "outset");
			setStyle("dropShadowEnabled", true);
			setStyle("shadowDistance", 3);
			setStyle("shadowDirection", "right");
			_backgroundSkin.styleName = this;
			addChild(_backgroundSkin);
			
			_backgroundRect = new Sprite();
			addChild(_backgroundRect);
			
			_titleBar = new Sprite();
			_titleBar.addEventListener(MouseEvent.MOUSE_DOWN, startDragging);
			_titleBar.addEventListener(MouseEvent.MOUSE_UP, stopDragging);
			addChild(_titleBar);
			
			createControls();
			
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
		
		protected function createControls():void
		{
			
			
			var theX:int = BORDER_PADDING;
			var maxHeight:int = 0;
			var tmpIcon:DisplayObject;
			
			_fillIcon = new UIComponent();
			tmpIcon = new _fillIconClass();
			_fillIcon.addChild(tmpIcon);
			_fillIcon.setActualSize(tmpIcon.width, tmpIcon.height);
			_fillIcon.toolTip = _lm.getString("Fill Color");
			addChild(_fillIcon);
			maxHeight = Math.max(_fillIcon.height, maxHeight);
			_fillColorPicker = new NullColorPicker();
			_fillColorPicker.toolTip = _lm.getString("Fill Color");
			_fillColorPicker.addEventListener(Event.CHANGE, fireEvent);
			addChild(_fillColorPicker);
			_fillColorPicker.validateNow();
			_fillColorPicker.setActualSize(_fillColorPicker.measuredWidth, _fillColorPicker.measuredHeight);
			maxHeight = Math.max(_fillColorPicker.height, maxHeight);
			
			_strokeIcon = new UIComponent();
			tmpIcon = new _strokeIconClass();
			_strokeIcon.addChild(tmpIcon);
			addChild(_strokeIcon);
			_strokeIcon.setActualSize(tmpIcon.width, tmpIcon.height);
			maxHeight = Math.max(_strokeIcon.height, maxHeight);
			_strokeColorPicker = new NullColorPicker();
			_strokeColorPicker.addEventListener(Event.CHANGE, fireEvent);
			addChild(_strokeColorPicker);
			_strokeColorPicker.validateNow();
			_strokeColorPicker.setActualSize(_strokeColorPicker.measuredWidth, _strokeColorPicker.measuredHeight);
			maxHeight = Math.max(_strokeColorPicker.height, maxHeight);
			
			_thicknessIcon = new UIComponent();
			tmpIcon = new _numLinesIconClass();
			_thicknessIcon.addChild(tmpIcon);
			addChild(_thicknessIcon);
			_thicknessIcon.setActualSize(tmpIcon.width, tmpIcon.height);
			maxHeight = Math.max(_thicknessIcon.height, maxHeight);
			_numLinesCombo = new ComboBox();
			_numLinesCombo.dataProvider = [1,2,3,4,5];
			_numLinesCombo.selectedItem = 4;
			_numLinesCombo.addEventListener(Event.CHANGE, fireEvent);
			addChild(_numLinesCombo);
			_numLinesCombo.validateNow();
			_numLinesCombo.setActualSize(_numLinesCombo.minWidth, _numLinesCombo.measuredHeight);
			maxHeight = Math.max(_numLinesCombo.height, maxHeight);
			
			_alphaIcon = new UIComponent();
			tmpIcon = new _alphaIconClass();
			_alphaIcon.addChild(tmpIcon);
			_alphaIcon.setActualSize(tmpIcon.width, tmpIcon.height);
			_alphaIcon.toolTip = _lm.getString("Opacity");
			addChild(_alphaIcon);
			maxHeight = Math.max(_alphaIcon.height, maxHeight);
			_alphaCombo = new ComboBox();
			_alphaCombo.toolTip = _lm.getString("Opacity");
			_alphaCombo.dataProvider = [100, 75, 50, 25];
			_alphaCombo.addEventListener(Event.CHANGE, fireEvent);
			addChild(_alphaCombo);
			_alphaCombo.validateNow();
			_alphaCombo.setActualSize(_alphaCombo.minWidth, _alphaCombo.measuredHeight);
			maxHeight = Math.max(_alphaCombo.height, maxHeight);
			
			measuredHeight = maxHeight + 2*BORDER_PADDING + TITLE_HEIGHT;
		}
		
		override protected function measure():void
		{
			//
		}
		
		override protected function updateDisplayList(p_w:Number, p_h:Number):void
		{
			for (var i:int = 0; i<numChildren; i++) {
				var kid:DisplayObject = getChildAt(i);
				if (kid is UIComponent) {
					kid.y = Math.round((p_h-TITLE_HEIGHT-kid.height)/2) + TITLE_HEIGHT; 
				}
			}
			
			var theX:int = BORDER_PADDING;
			
			_fillIcon.visible = _fillColorPicker.visible = _isFilledShape;
			
			if (_fillIcon.visible) {
				_fillIcon.x = theX;
				theX += _fillIcon.width + ICON_PADDING;
				_fillColorPicker.x = theX;
				theX += _fillColorPicker.width + CONTROL_PADDING;
			}
			_strokeIcon.x = theX;
			_strokeIcon.toolTip = (_isFilledShape) ? _lm.getString("Border Color") : _lm.getString("Color");
			theX += _strokeIcon.width + ICON_PADDING;
			_strokeColorPicker.x = theX;
			_strokeColorPicker.allowNull = _isFilledShape;
			_strokeColorPicker.toolTip = (_isFilledShape) ? _lm.getString("Border Color") : _lm.getString("Color");
			theX += _strokeColorPicker.width + CONTROL_PADDING;
			_thicknessIcon.x = theX;
			_thicknessIcon.toolTip = (_isFilledShape) ? _lm.getString("Border Thickness") : _lm.getString("Line Thickness");
			theX += _thicknessIcon.width + ICON_PADDING;
			_numLinesCombo.x = theX;
			_numLinesCombo.toolTip = (_isFilledShape) ? _lm.getString("Border Thickness") : _lm.getString("Line Thickness");
			_numLinesCombo.validateNow();
			_numLinesCombo.setActualSize(_numLinesCombo.minWidth, _numLinesCombo.measuredHeight);
			theX += _numLinesCombo.width + CONTROL_PADDING;
			_alphaIcon.x = theX;
			theX += _alphaIcon.width + ICON_PADDING;
			_alphaCombo.x = theX;
			theX += _alphaCombo.width + BORDER_PADDING;
			
			measuredWidth = theX;
			
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
			gradMatr.createGradientBox(p_w, p_h-TITLE_HEIGHT-2*BORDER_PADDING, Math.PI/2);			
			g.lineStyle(0, 0, 0);
			g.beginGradientFill(GradientType.LINEAR, [0x9a9a9a,0x838383],[1,1],[0,255],gradMatr);
			g.drawRect(Math.round(BORDER_PADDING/2), TITLE_HEIGHT+Math.round(BORDER_PADDING/2), p_w-BORDER_PADDING, p_h-TITLE_HEIGHT-BORDER_PADDING);
		}
		
		protected function fireEvent(p_evt:Event):void
		{
			dispatchEvent(new Event("shapePropertyChange"));
		}
	}
}