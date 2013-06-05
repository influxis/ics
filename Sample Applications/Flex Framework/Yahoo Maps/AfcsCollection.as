package
{
	import mx.collections.ArrayCollection;
	import com.adobe.rtc.sharedModel.CollectionNode;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import mx.core.IUID;
	import com.adobe.rtc.session.ConnectSession;

	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	


	public class AfcsCollection extends ArrayCollection
	{
		public function AfcsCollection(source:Array=null)
		{
			super(source);
		}
		
		public var collectionNode:CollectionNode;
		protected static const ITEM_NODE:String = "itemNode";
		protected var _nodeConfig:NodeConfiguration;
		protected var _nodeName:String = ITEM_NODE;
		protected var _myUserID:String;
		
		/**
		* what field in each item can be used as a unique identifier?
		*/
		public var idField:String;
		/**
		* what class is each item?
		*/
		public var itemClass:Class;

		[Bindable("synchronizationChange")]		
		public function get isSynchronized():Boolean
		{
			if (collectionNode) {
				return collectionNode.isSynchronized;
			} else {
				return false;
			}
		}

		public function subscribe(p_uniqueID:String, p_nodeConfig:NodeConfiguration=null):void
		{
			_nodeConfig = (p_nodeConfig) ? p_nodeConfig : new NodeConfiguration();
			_nodeConfig.itemStorageScheme = NodeConfiguration.STORAGE_SCHEME_MANUAL;
			_myUserID = ConnectSession.primarySession.userManager.myUserID;
			
			if (collectionNode==null) {
				collectionNode = new CollectionNode();
				collectionNode.sharedID = p_uniqueID ;
				collectionNode.subscribe();
			} else {
				_nodeName = p_uniqueID;
			}
			collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
			collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			collectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
		}
		
		override public function setItemAt(p_item:Object, p_index:int):Object
		{
			var oldItem:Object = getItemAt(p_index);
			var msg:MessageItem = new MessageItem(_nodeName, p_item, getItemID(oldItem));
			collectionNode.publishItem(msg, true);
			
			return oldItem;
		}
		
		override public function addItem(p_item:Object):void
		{
			var msg:MessageItem = new MessageItem(_nodeName, p_item, getItemID(p_item));
			collectionNode.publishItem(msg);
		}
		
		override public function removeItemAt(p_index:int):Object
		{
			var oldItem:Object = getItemAt(p_index);
			collectionNode.retractItem(_nodeName, getItemID(oldItem));
			return oldItem;
		}
		
		override public function removeAll():void
		{
			var l:int = length;
			for (var i:int=l-1; i>=0; i--) {
				removeItemAt(i);
			}
			
		}
		
		protected function onSyncChange(p_evt:CollectionNodeEvent):void
		{
			if (!collectionNode.isNodeDefined(_nodeName) && collectionNode.canUserConfigure(_myUserID, _nodeName)) {
				// this collectionNode has never been built, and I can add it...
				collectionNode.createNode(_nodeName, _nodeConfig);
			}
			dispatchEvent(p_evt);
		}
		
		protected function onItemReceive(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName!=_nodeName) {
				return;
			}
			var newItem:Object = p_evt.item.body;
			var itemID:String = (idField) ? newItem[idField] : newItem.uid;
			var oldItem:Object;
			var i:String;
			// yes, this is ugly. Improve later
			var l:int = length;
			for (var idx:int=0; idx<l; idx++) {
				if (itemID==getItemID(getItemAt(idx))) {
					oldItem = getItemAt(idx);
					break;
				}
			}
			if (oldItem) {
				// it's an item update
				for (i in newItem) {
					if (newItem[i]!=oldItem[i]) {
						var tmpOldValue:Object = oldItem[i];
						oldItem[i] = newItem[i];
						itemUpdated(oldItem, i, tmpOldValue, oldItem[i]);
					}
				}
				super.setItemAt(oldItem, idx);
			} else {
				// it's a brand new item
				if (itemClass) {
					// yeah, this wouldn't work if there are constructor args
					var newItemTyped:Object = new itemClass();
					for (i in newItem) {
						newItemTyped[i] = newItem[i];
					}
					super.addItem(newItemTyped);
				} else {
					super.addItem(newItem);
				}
			}
		}
		
		protected function onItemRetract(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName!=_nodeName) {
				return;
			}
			var newItem:Object = p_evt.item.body;
			var itemID:String = (idField) ? newItem[idField] : newItem.uid;
			
			var oldItem:Object;
			// yes, this is ugly. Improve later
			var l:int = length;
			for (var idx:int=0; idx<l; idx++) {
				if (itemID==getItemID(getItemAt(idx))) {
					oldItem = getItemAt(idx);
					break;
				}
			}
			if (oldItem) {
				super.removeItemAt(idx);
			}
		}
		
		protected function getItemID(p_item:Object):String
		{
			return (p_item is IUID) ? IUID(p_item).uid : p_item[idField] as String;
		}
		
	}
}