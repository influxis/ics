package
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import com.adobe.rtc.sharedModel.CollectionNode;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.messaging.MessageItem;
	import flash.events.Event;
	import com.adobe.rtc.sharedModel.Baton;
	import com.adobe.rtc.events.SharedModelEvent;
	import com.yahoo.maps.api.core.location.LatLon;

	/**
	 * SharedYahooMapsModel is a LCCS-based shared model, which allows multiple users to share navigation control of a Yahoo Maps component.
	 * Latitude/Longitude, Zoom Level, and map mode (annotation or navigation) are shared. As well, the current controlling user is shared through
	 * a Baton component, so that only one user at a time can navigate the map, and a set of marker details is shared by exposing a shared CocomoCollection.
	 * APIs are supplied for setting all these properties over the network, and events for notifying users that a property has been changed.
	 * See the Shared Model documentation pdf for more details.
	 */
	public class SharedYahooMapsModel extends EventDispatcher
	{
		// fired when the position of the map has been changed
		[Event(name="latLonChange", type="flash.events.Event")]	
		// fired when the zoom level of the map has been changed
		[Event(name="zoomChange", type="flash.events.Event")]	
		// fired when the mode of the map (annotation or navigation) has been changed
		[Event(name="modeChange", type="flash.events.Event")]	
		// fired when the contolling user of the map has been changed
		[Event(name="batonChange", type="flash.events.Event")]

		
		protected var _latLon:LatLon;
		protected var _zoom:int;
		protected var _mode:String;
		protected var _collectionNode:CollectionNode;
		protected var _myUserID:String;
		protected var _controllingUser:String;
		protected var _baton:Baton;


		/**
		* Exposes a Collection through which details about markers can be shared
		*/
		public var markerCollection:CocomoCollection = new CocomoCollection();

		/**
		* Constants for the nodes over which various properties will be set
		*/		
		protected static const LAT_LON_NODE:String = "latLonNode";
		protected static const ZOOM_NODE:String = "zoomNode";
		protected static const MODE_NODE:String = "modeNode";
		
		
		public function SharedYahooMapsModel(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		/**
		 * Connects the shared model to the AFCS services, using the supplied unique ID for its destination on the service
		 * @param p_uniqueID the id to use on the service
		 */
		public function subscribe(p_uniqueID:String):void
		{
			_myUserID = ConnectSession.primarySession.userManager.myUserID;
			// set up the collectionNode
			_collectionNode = new CollectionNode();
			_collectionNode.sharedID = p_uniqueID ;
			_collectionNode.subscribe();
			_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			// set up the marker collection - CocomoCollection allows you to specify an existing
			// collectionNode to use for messaging, so we'll have it piggy-back on the same 
			// collectionNode as the one our model uses (to reduce the number of destinations on server)
			markerCollection.collectionNode = _collectionNode;
			// use the userID field as the unique ID for each item in the collection 
			markerCollection.idField = "userID";
			// use one node on our collectionNode for marker details
			markerCollection.subscribe("markers");

			// set up the baton. we'll also have it piggy-back on our existing collectionNode.
			_baton = new Baton();
			_baton.sharedID = "mapControl" ;
			_baton.timeOut = 5 ;
			_baton.collectionNode = _collectionNode ;
			_baton.subscribe();
			_baton.addEventListener(SharedModelEvent.BATON_HOLDER_CHANGE, onBatonChange);
		}
		
		/**
		 * Sets the position of the SharedMap model. Note that the value isn't updated until the resulting
		 * message returns from the service.
		 * @param p_val - the LatLon object corresponding to the map's position
		 */
		public function set latLon(p_val:LatLon):void
		{
			// baton management - if I've got the baton already, then keep it for a while longer,
			// if I don't but can grab it, do so. Otherwise, I'm not allowed to update this value.
			if (_baton.amIHolding) {
				_baton.extendTimer();
			} else if (_baton.canIGrab) {
				_baton.grab();
			} else {
				return;
			}
			// send a message (through our collectionNode) to the service to update the position.
			// note that LAT_LON_NODE is configured to only store a single item (see onSyncChange),
			// so only the last item published here gets stored
			var msg:MessageItem = new MessageItem(LAT_LON_NODE, {lat:p_val.lat, lon:p_val.lon});
			_collectionNode.publishItem(msg);
		}
		
		[Bindable("latLonChange")]
		public function get latLon():LatLon
		{
			return _latLon;
		}
		
		/**
		 * Sets the zoom level of the SharedMap model. Note that the value isn't updated until the resulting
		 * message returns from the service.
		 * @param p_val - the LatLon object corresponding to the map's position
		 */
		public function set zoom(p_val:int):void
		{
			// baton management - if I've got the baton already, then keep it for a while longer,
			// if I don't but can grab it, do so. Otherwise, I'm not allowed to update this value.
			if (_baton.amIHolding) {
				_baton.extendTimer();
			} else if (_baton.canIGrab) {
				_baton.grab();
			} else {
				return;
			}
			// send a message (through our collectionNode) to the service to update the zoom level.
			// note that ZOOM_NODE is configured to only store a single item (see onSyncChange),
			// so only the last item published here gets stored
			var msg:MessageItem = new MessageItem(ZOOM_NODE, p_val);
			_collectionNode.publishItem(msg);
		}
		
		[Bindable("zoomChange")]
		public function get zoom():int
		{
			return _zoom;
		}

		/**
		 * Sets the mode (annotation or navigation) of the SharedMap model. 
		 * Note that the value isn't updated until the resulting
		 * message returns from the service.
		 * @param p_val
		 * 
		 */		
		public function set mode(p_val:String):void
		{
			// baton management - if I've got the baton already, then keep it for a while longer,
			// if I don't but can grab it, do so. Otherwise, I'm not allowed to update this value.
			if (_baton.amIHolding) {
				_baton.extendTimer();
			} else if (_baton.canIGrab) {
				_baton.grab();
			} else {
				return;
			}
			// send a message (through our collectionNode) to the service to update the mode.
			// note that MODE_NODE is configured to only store a single item (see onSyncChange),
			// so only the last item published here gets stored
			var msg:MessageItem = new MessageItem(MODE_NODE, p_val);
			_collectionNode.publishItem(msg);
		}
		
		[Bindable("modeChange")]
		public function get mode():String
		{
			return _mode;
		}

		/**
		 * returns the userID of the user currently controlling the map
		 */
		[Bindable("batonChange")]
		public function get controllingUser():String
		{
			return _controllingUser;
		}
		
		/**
		 * Fired when the collectionNode has fully connected to the service and retrieved all information
		 * about its nodes and stored message items. Note that this is typically the time when an OWNER sets up
		 * the node structure of any CollectionNodes, after the CollectionNode has synched and the OWNER notices 
		 * it hasn't got the requisite nodes.
		 */
		protected function onSyncChange(p_evt:CollectionNodeEvent):void
		{
			// if I'm the OWNER and there's no node defined for LAT_LON, create one.
			// note we're using the default NodeConfiguration, which only stores one item and has default
			// publish/subscribe permissions.
			if (!_collectionNode.isNodeDefined(LAT_LON_NODE) && _collectionNode.canUserConfigure(_myUserID)) {
				_collectionNode.createNode(LAT_LON_NODE);
			}
			// if I'm the OWNER and there's no node defined for ZOOM, create one.
			if (!_collectionNode.isNodeDefined(ZOOM_NODE) && _collectionNode.canUserConfigure(_myUserID)) {
				_collectionNode.createNode(ZOOM_NODE);
			}
			// if I'm the OWNER and there's no node defined for MODE, create one.
			if (!_collectionNode.isNodeDefined(MODE_NODE) && _collectionNode.canUserConfigure(_myUserID)) {
				_collectionNode.createNode(MODE_NODE);
			}

		}
		
		/**
		 * Fired when an item is received from the service (whether from the current user's updates
		 * or a remote one).
		 */
		protected function onItemReceive(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName==LAT_LON_NODE) {
				// the latlon has been updated. Update our model value, and fire an event to notify of the change
				_latLon = new LatLon(p_evt.item.body.lat, p_evt.item.body.lon);
				if (p_evt.item.publisherID!=_myUserID) {
					dispatchEvent(new Event("latLonChange"));
				}
			} else if (p_evt.nodeName==ZOOM_NODE) {
				// the zoom has been updated. Update our model value, and fire an event to notify of the change
				_zoom = p_evt.item.body;
				dispatchEvent(new Event("zoomChange"));
			} else if (p_evt.nodeName==MODE_NODE) {
				// the mode has been updated. Update our model value, and fire an event to notify of the change
				_mode = p_evt.item.body;
				dispatchEvent(new Event("modeChange"));
			}
		}
		
		/**
		 * Fired when the holderID of the baton changes. We update our model value and fire an event to notify of the change 
		 */
		protected function onBatonChange(p_evt:Event):void
		{
			_controllingUser = _baton.holderID;
			dispatchEvent(new Event("batonChange"));
		}

				
		
	}
}