package
{
	import com.yahoo.maps.api.markers.SimpleMarker;
	import flash.events.MouseEvent;
	import mx.managers.PopUpManager;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import mx.events.CloseEvent;
	import flash.events.Event;
	import com.yahoo.maps.api.IYahooMap;
	import com.yahoo.maps.api.YahooMap;
	import com.yahoo.maps.api.core.location.BoundingBox;
	import mx.core.Application;
	import mx.core.UIComponent;
	import flash.display.Sprite;

	public class SharedMarker extends SimpleMarker
	{
		public var userName:String;
		public var addressString:String;
		protected var _bubble:MarkerBubble;
		protected static var _bubbles:Dictionary = new Dictionary();
		
		public static function addBubble(p_bubble:MarkerBubble, p_marker:SharedMarker, p_map:IYahooMap):void
		{
			_bubbles[p_bubble] = {marker:p_marker, map:p_map};
		}
		
		public static function moveBubbles():void
		{
			for (var b:* in _bubbles) {
				var bub:MarkerBubble = b as MarkerBubble;
				var marker:SharedMarker = _bubbles[b].marker as SharedMarker;
				var map:YahooMap = _bubbles[b].map as YahooMap;
				var bounds:BoundingBox = map.getMapBounds();
				var mLat:Number = marker.latlon.lat;
				var mLon:Number = marker.latlon.lon;
				if (mLat<bounds.minLat || mLat>bounds.maxLat ||	mLon<bounds.minLon || mLon>bounds.maxLon) {
					marker.closeBubble();
				} else {
					var bubbPt:Point = bub.parent.globalToLocal(marker.localToGlobal(new Point(marker.width, 0)));
					bub.move(bubbPt.x, bubbPt.y);
				}
			}
		}
		
		public static function clearBubbles():void
		{
			for (var b:* in _bubbles) {
				var marker:SharedMarker = _bubbles[b].marker as SharedMarker;
				marker.closeBubble();
			}
			
		}
		
		public static function removeBubble(p_bubble:MarkerBubble):void
		{
			delete _bubbles[p_bubble];
		}
		
		public function SharedMarker()
		{
			super();
			addEventListener(MouseEvent.MOUSE_OVER, onMouseOvr);
			var g:Sprite = new Sprite();
			addChild(g);
			g.graphics.lineStyle(1, 0xeaeaea, 1, true);
			g.graphics.beginFill(0x992222);
			g.graphics.drawCircle(6,-11,7);
		}
		
		protected function onMouseOvr(p_evt:MouseEvent):void
		{
			if (!_bubble) {
				clearBubbles();
				_bubble = new MarkerBubble();
				PopUpManager.addPopUp(_bubble, UIComponent(Application.application), false);
				var bubbPt:Point = _bubble.parent.globalToLocal(localToGlobal(new Point(width, 0)));
				_bubble.move(bubbPt.x, bubbPt.y);
				_bubble.validateNow();
				_bubble.addressField.text = addressString;
				_bubble.userField.text = userName;
				_bubble.addEventListener(CloseEvent.CLOSE, closeBubble);
				addBubble(_bubble, this, map);
			}
		}
		
		public function closeBubble(p_evt:Event=null):void
		{
			if (_bubble) {
				PopUpManager.removePopUp(_bubble)
				_bubble.removeEventListener(CloseEvent.CLOSE, closeBubble);
				removeBubble(_bubble);
				_bubble = null;
			}
		}
	}
}