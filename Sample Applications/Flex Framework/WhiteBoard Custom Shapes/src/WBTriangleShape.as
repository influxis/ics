package 
{
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapeBase;
	
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import mx.utils.ColorUtil;
	
	/**
	 * @private
	 */
	public class WBTriangleShape extends WBShapeBase
	{
		
		protected var _shapeType:String;
		protected var _lineThickness:Number = 1;
		protected var _lineColor:uint = 0x3a3a3a;
		protected var _primaryColor:uint = 0xeaeaea;
		protected var _dropShadow:Boolean = true;
		protected var _gradientFill:Boolean = true;
		protected var _fillAlpha:Number = 1;
		protected var _lineAlpha:Number = 1;
		
		public override function get definitionData():*
		{
			return _shapeType;
		}
		
		public override function set definitionData(p_data:*):void
		{
			_shapeType = p_data;
		}
		
		//Set the property data from the toolBar
		public override function set propertyData(p_data:*):void
		{
			super.propertyData = p_data;
			if (p_data.lineThickness!=null) {
				_lineThickness = p_data.lineThickness as Number;
			} 
			if (p_data.lineColor!=null) {
				_lineColor = p_data.lineColor as uint;
			}
			if (p_data.primaryColor!=null) {
				_primaryColor = p_data.primaryColor as uint;
			}
			if (p_data.dropShadow!=null) {
				_dropShadow = p_data.dropShadow as Boolean;
			}
			if (p_data.gradientFill!=null) {
				_gradientFill = p_data.gradientFill as Boolean;
			}
			if (p_data.alpha!=null) {
				_fillAlpha = p_data.alpha as Number
			}
			if (p_data.alpha!=null) {
				_lineAlpha = p_data.alpha as Number;
			}
			invalidateDisplayList();
		}
		
		//Set the property data of the shape
		public override function get propertyData():*
		{
			var returnObj:Object = super.propertyData;
			returnObj.lineThickness = _lineThickness;
			returnObj.lineColor = _lineColor;
			returnObj.primaryColor = _primaryColor;
			returnObj.dropShadow = _dropShadow;
			returnObj.gradientFill  = _gradientFill;
			returnObj.alpha = _fillAlpha;
			return returnObj;
		}
		
		// Add event listener for mouse dragging and draw the shape in the listener
		protected override function setupDrawing():void
		{
			stage.addEventListener(MouseEvent.MOUSE_MOVE, trackMouse);
		}
		
		protected override function cleanupDrawing():void
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, trackMouse);
		}
		
		protected function trackMouse(p_evt:MouseEvent):void
		{
			var pt:Point = globalToLocal(stage.localToGlobal(new Point(p_evt.stageX, p_evt.stageY)));
			width = pt.x;
			height = pt.y;
			validateNow();
		}
		
		// What happens to the shape when we drag the mouse is defined here. So the triangle is drawn here based
		// on the width and height of the drag co-ordinates
		protected override function updateDisplayList(p_w:Number, p_h:Number):void
		{
			super.updateDisplayList(p_w, p_h);
			var g:Graphics = graphics;
			g.clear();
			var lineAlpha:Number = (_lineThickness==0 || _lineColor==NULL_COLOR) ? 0 : _lineAlpha;
			g.lineStyle(_lineThickness, _lineColor, lineAlpha, true);
			var fillAlpha:Number = (_primaryColor==NULL_COLOR) ? 0 : _fillAlpha;
			if (_gradientFill) {
				var secondColor:uint = ColorUtil.adjustBrightness(_primaryColor, -55);
				var rotationMatrix:Matrix = new Matrix();
				rotationMatrix.createGradientBox(p_w, p_h, Math.PI/2);
				g.beginGradientFill(GradientType.LINEAR, [_primaryColor, secondColor], [fillAlpha,fillAlpha], [0,255], rotationMatrix);
			} else {
				g.beginFill(_primaryColor, fillAlpha);
			}
			var pX:Number = (p_w<0) ? p_w : 0;
			var pY:Number = (p_h<0) ? p_h : 0;
			p_w = Math.abs(p_w);
			p_h = Math.abs(p_h);
			//The triangle drawing part..
			g.moveTo(pX , pY+p_h);
			g.lineTo((pX+(p_w/2)) , pY);
			g.lineTo(pX+p_w, pY+p_h);
			g.lineTo(pX , pY+p_h);		
			if (_dropShadow) {
				filters = [new DropShadowFilter(4, 45, 0, 0.3)];
			} else {
				filters = null;
			}
			
		}
	}
}