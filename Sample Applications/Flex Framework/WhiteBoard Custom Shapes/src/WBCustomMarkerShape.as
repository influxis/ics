package 
{
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapeBase;
	
	import flash.display.Bitmap;
	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	import mx.effects.Tween;
	
	/**
	 * @private
	 */
	public class WBCustomMarkerShape extends WBShapeBase
	{
		public static const MARKER_SIZE:int = 10;
		public static const MARKER_COLOR:int = 0x3a3a3a;
		public static const TRACKING_INTERVAL:int = 10;
		
		protected var _markerTimer:Timer;
		protected var _points:Array;
		protected var _lastPtIndexRendered:int = -1;
		protected var _animationIndex:int = 0;
		protected var _animating:Boolean = false;
		
		protected var _primaryColor:uint = 0x3a3a3a;
		protected var _lineThickness:uint = 2;
		protected var _numLines:uint = 2;
		protected var _lineAlpha:Number = 0.5;
		protected var _dropShadow:Boolean = true;
		
		protected var _drawingSprite:Sprite;
		protected var _drawingBitmap:Bitmap;
		
		public override function initialize():void
		{
			super.initialize();
			if (!_points) {
				_points = new Array();
			}
		}
		
		
		protected override function createChildren():void
		{
			_drawingSprite = new Sprite();
			addChild(_drawingSprite);
		}
		
		//Get the definition data of the shape
		public override function get definitionData():*
		{
			return _points;
		}
		
		//Set the property data of the shape
		public override function set definitionData(p_data:*):void
		{
			_points = p_data as Array;
		}
		
		//Get the property data of the shape
		public override function get propertyData():*
		{
			var returnObj:Object = super.propertyData;
			returnObj.lineColor = _primaryColor;
			returnObj.numLines = _numLines;
			returnObj.alpha = _lineAlpha;
			return returnObj;
		}
		
		//Set the property data from the toolBar
		public override function set propertyData(p_data:*):void
		{
			super.propertyData = p_data;
			if (p_data) {
				_primaryColor = p_data.lineColor;
				_numLines = p_data.numLines;
				_lineAlpha = p_data.alpha;
				invalidateDisplayList();
			}
		}
		
		
		//Use a timer to store array of points and then draw a line connecting the points
		//Line Attributes are defined by the toolBar
		//Code reused from com.adobe.coreUI.controls.whiteboardClasses.shapes.WBMarkerShape
		protected override function setupDrawing():void
		{
			_markerTimer = new Timer(TRACKING_INTERVAL);
			_markerTimer.addEventListener(TimerEvent.TIMER, trackMarker);
			_markerTimer.start();
		}
		
		protected override function cleanupDrawing():void
		{
			if (_markerTimer) {
				_markerTimer.stop();
				_markerTimer.removeEventListener(TimerEvent.TIMER, trackMarker);
				_markerTimer = null;
			}
			normalizePoints();
		}
		
		
		protected function trackMarker(p_evt:Event):void
		{
			var l:int = _points.length;
			if (l!=0) {
				var lastPt:Object = _points[l-1];
				if (lastPt.x==mouseX && lastPt.y==mouseY) {
					return;
				}
			}
			_points.push({x:mouseX, y:mouseY});
			renderPoints(0);
		}
		
		protected override function updateDisplayList(p_w:Number, p_h:Number):void
		{
			super.updateDisplayList(p_w, p_h);
			if (animateEntry) {
				animateEntry = false;
				_animationIndex = 0;
				_animating = true;
				animateSegment();
			}	else if (!_isDrawing && !_animating) {
				renderPoints();
			}
			if (_dropShadow) {
				filters = [new DropShadowFilter(4, 45, 0, 0.3)];
			} else {
				filters = null;
			}
		}
		
		protected function renderPoints(p_startIndex:uint=0):void
		{
			var lastPt:Object;
			var g:Graphics = _drawingSprite.graphics;
			var l:int = _points.length;
			if (p_startIndex<_lastPtIndexRendered) {
				// we're backtracking - start over
				_drawingSprite.visible = true;
				g.clear();
				p_startIndex = 0;
			}
			
			if (p_startIndex==0) {
				lastPt = _points[0];
			} else {
				lastPt = _points[_lastPtIndexRendered];
			}
			
			var pt:Object;
			g.lineStyle(_lineThickness, _primaryColor, _lineAlpha, true, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND, 8);
			var multiplierW:Number = (_isDrawing) ? 1 : width;
			var multiplierH:Number = (_isDrawing) ? 1 : height;
			for (var i:int=0; i< _numLines; i++){
				if (p_startIndex==0) {
					lastPt = _points[0];
				} else {
					lastPt = _points[_lastPtIndexRendered];
				}
				for (var j:int=p_startIndex; j<l; j++) {
					if (j==0) {
						g.moveTo((lastPt.x*multiplierW)+(i*(_lineThickness+4)), (lastPt.y*multiplierH)+(i*(_lineThickness+4)));
						continue;
					}
					pt = _points[j];
					g.lineTo((pt.x*multiplierW)+(i*(_lineThickness+4)), (pt.y*multiplierH)+(i*(_lineThickness+4)));
					lastPt = pt;
				}
			}
			_lastPtIndexRendered = i-1;
		}
		

		
		protected function normalizePoints():void
		{
			var bounds:Rectangle = getBounds(this);
			var l:int = _points.length;

				for (var j:int=0; j<l; j++) {
					var pt:Object = _points[j];
					pt.x = ((pt.x+(0*4))-bounds.x)/bounds.width;
					pt.y = ((pt.y+(0*4))-bounds.y)/bounds.height;
				}

		}
		
		protected function animateSegment():void
		{
			var segmentTween:Tween = new Tween(this, 0, 1, 20);
			
		}
		
		public function onTweenUpdate(p_val:Object):void
		{
			var g:Graphics = _drawingSprite.graphics;
			g.clear();
			g.lineStyle(_lineThickness, _primaryColor, _lineAlpha, true, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND, 8);
			
			var lastPt:Object = _points[0];
			var pt:Object;
			
			for (var i:int=0; i< _numLines; i++){
				lastPt = _points[0];
				for (var j:int=0; j<_animationIndex; j++) {
					if (j==0) {
						g.moveTo((lastPt.x*width)+(i*(_lineThickness+4)), (lastPt.y*height)+(i*(_lineThickness+4)));
						continue;
					}
					pt = _points[j];
					g.lineTo((pt.x*width)+(i*(_lineThickness+4)), (pt.y*height)+(i*(_lineThickness+4)));
					lastPt = pt;
				}
			}
			
			lastPt = _points[_animationIndex];
			var nextPt:Object = _points[_animationIndex+1];
			var newY:Number = lastPt.y + (nextPt.y-lastPt.y)*Number(p_val);
			var newX:Number = lastPt.x + (nextPt.x-lastPt.x)*Number(p_val);
			g.lineTo(newX*width, newY*height);
		}
		
		public function onTweenEnd(p_val:Object):void
		{
			onTweenUpdate(p_val);
			if (_animationIndex<_points.length-2) {
				_animationIndex++;
				animateSegment();
			} else {
				_animationIndex = 0;
				_animating = false;
				_lastPtIndexRendered = _points.length-1;
				updateDisplayList(width, height);
			}
		}
		
	}
}