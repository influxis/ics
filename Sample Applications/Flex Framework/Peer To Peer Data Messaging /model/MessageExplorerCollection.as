package model
{
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.sharedModel.CollectionNode;
	
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IViewCursor;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;

	public class MessageExplorerCollection extends EventDispatcher
	{
		protected var _name:String;
		protected var _collectionNode:CollectionNode;
		
		[Bindable]
		public var nodes:ArrayCollection;
		
		public var nodesCursor:IViewCursor;
		
		public var connectSession:IConnectSession = ConnectSession.primarySession;
		
		public function MessageExplorerCollection(p_name:String):void
		{
			_name = p_name;

			nodes = new ArrayCollection();
			var sort:Sort = new Sort();
			sort.fields = [new SortField("nodeName", true)];
			nodes.sort = sort;
			nodes.refresh();
			nodesCursor = nodes.createCursor();
		}

		public function subscribe():void
		{
			_collectionNode = new CollectionNode();
			_collectionNode.sharedID = _name ;
			_collectionNode.connectSession = connectSession;
			_collectionNode.addEventListener(CollectionNodeEvent.CONFIGURATION_CHANGE, onConfigurationChange);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			_collectionNode.addEventListener(CollectionNodeEvent.NODE_CREATE, onNodeCreate);
			_collectionNode.addEventListener(CollectionNodeEvent.NODE_DELETE, onNodeDelete);
			_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			_collectionNode.addEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onUserRoleChange)
			_collectionNode.subscribe();
		}

		public function destroy():void
		{
			_collectionNode.removeEventListener(CollectionNodeEvent.CONFIGURATION_CHANGE, onConfigurationChange);	
			_collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			_collectionNode.removeEventListener(CollectionNodeEvent.NODE_CREATE, onNodeCreate);
			_collectionNode.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			_collectionNode.removeEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onUserRoleChange);
			_collectionNode.unsubscribe();			
		}	
			
		public function removeNode(p_nodeName:String):void
		{
			_collectionNode.removeNode(p_nodeName);
		}
		
		public function removeItem(p_nodeName:String, p_itemID:String):void
		{
			_collectionNode.retractItem(p_nodeName, p_itemID);
		}
		
		public function createNode(p_nodeName:String, p_configuration:NodeConfiguration=null):void
		{
			_collectionNode.createNode(p_nodeName, p_configuration);
		}

		public function setNodeConfiguration(p_nodeName:String, p_configuration:NodeConfiguration=null):void
		{
			_collectionNode.setNodeConfiguration(p_nodeName, p_configuration);
		}
		
		public function addItem(p_nodeName:String, p_item:MessageItem, p_overWrite:Boolean=false):void
		{
			p_item.nodeName = p_nodeName;
			if (_collectionNode.getNodeConfiguration(p_nodeName).itemStorageScheme == NodeConfiguration.STORAGE_SCHEME_SINGLE_ITEM) {
				p_item.itemID = null;
			}
			_collectionNode.publishItem(p_item, p_overWrite);
		}
		
		protected function onConfigurationChange(p_evt:CollectionNodeEvent):void
		{
			if (nodesCursor.findFirst({nodeName:p_evt.nodeName})) {
				var n:MessageExplorerNode = nodesCursor.current.node as MessageExplorerNode;
				n.onConfigurationChange(_collectionNode.getNodeConfiguration(p_evt.nodeName));
			}
		}

		protected function onItemReceive(p_evt:CollectionNodeEvent):void
		{
			if (nodesCursor.findFirst({nodeName:p_evt.nodeName})) {
				var n:MessageExplorerNode = nodesCursor.current.node as MessageExplorerNode;
				n.onItemReceive(p_evt.item);
				dispatchEvent(p_evt);
			}
		}

		protected function onItemRetract(p_evt:CollectionNodeEvent):void
		{
			if (nodesCursor.findFirst({nodeName:p_evt.nodeName})) {
				var n:MessageExplorerNode = nodesCursor.current.node as MessageExplorerNode;
				n.onItemRetract(p_evt.item.itemID);
			}
		}

		protected function onNodeCreate(p_evt:CollectionNodeEvent):void
		{
			
			if (!nodesCursor.findAny({nodeName:p_evt.nodeName})) {									
				var c:MessageExplorerNode = new MessageExplorerNode(_name, p_evt.nodeName, _collectionNode.getNodeConfiguration(p_evt.nodeName));
				c.addEventListener(MessageExplorerEvent.NODE_ITEM_ADD, onEvent);
				c.addEventListener(MessageExplorerEvent.NODE_ITEM_RECEIVE, onEvent);
				c.addEventListener(MessageExplorerEvent.NODE_ITEM_RETRACT, onEvent);
				c.addEventListener(MessageExplorerEvent.NODE_CONFIGURATION_CHANGE, onEvent);
				c.addEventListener(MessageExplorerEvent.NODE_USER_ROLE_CHANGE, onEvent);
				nodes.addItem({nodeName:p_evt.nodeName, node:c});
				nodesCursor = nodes.createCursor();

				var e:MessageExplorerEvent = new MessageExplorerEvent(MessageExplorerEvent.COLLECTION_NODE_CREATE);
				e.collection = _name;
				e.node = p_evt.nodeName;
				e.comment = "New node created" ;
				dispatchEvent(e);
			}
		}

		protected function onNodeDelete(p_evt:CollectionNodeEvent):void
		{
			if (nodesCursor.findFirst({nodeName:p_evt.nodeName})) {
				nodesCursor.remove();

				var e:MessageExplorerEvent = new MessageExplorerEvent(MessageExplorerEvent.COLLECTION_NODE_DELETE);
				e.collection = _name;
				e.node = p_evt.nodeName;
				e.comment = "Node deleted" ;
				dispatchEvent(e);		
						
			}
		}

		protected function onSynchronizationChange(p_evt:CollectionNodeEvent):void
		{
			var e:MessageExplorerEvent = new MessageExplorerEvent(MessageExplorerEvent.COLLECTION_SYNCHRONIZATION_CHANGE);
			e.collection = _name;
			e.node = p_evt.nodeName;
			e.comment = (_collectionNode.isSynchronized) ? "Collection Synchronized" : "Collection not Synchronizated";
			dispatchEvent(e);
		}

		protected function onUserRoleChange(p_evt:CollectionNodeEvent):void
		{
			var e:MessageExplorerEvent = new MessageExplorerEvent(MessageExplorerEvent.COLLECTION_USER_ROLE_CHANGE);
			e.collection = _name;
			e.node = p_evt.nodeName;
			e.comment = p_evt.userID + " Changed User Role to "+_collectionNode.getUserRole(p_evt.userID, p_evt.nodeName);
			dispatchEvent(e);
		}

		protected function onEvent(p_evt:MessageExplorerEvent):void
		{
			dispatchEvent(p_evt);	//bubble it
		}

		protected function myTrace(p_msg:String):void
		{
			trace("	#Collection "+_name+"# "+p_msg);
		}
		
		public function get isSynchronized():Boolean
		{
			return _collectionNode.isSynchronized ;
		}
	}
}