package model
{
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.StreamEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.sharedManagers.FileManager;
	import com.adobe.rtc.sharedManagers.RoomManager;
	import com.adobe.rtc.sharedManagers.StreamManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.util.RootCollectionNode;
	
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IViewCursor;
	import mx.collections.Sort;
	import mx.collections.SortField;
	
	

	public class MessageExplorerModel extends EventDispatcher implements ISessionSubscriber
	{
			public var rootCollection:RootCollectionNode;
			
//			[Bindable]
//			public var collectionNames:ArrayCollection;
			
			[Bindable]
			public var collections:ArrayCollection;			
			public var collectionsCursor:IViewCursor;
			
			protected var tickTimer:Timer;
			protected var messageCounter_second:uint = 0;
			
			[Bindable]
			public var lastTwoMinutes_messages_per_second:ArrayCollection;
			
			[Bindable]
			public var messages_per_second_total:uint = 0;
			
			protected var seconds_elapsed:uint = 0;
			
			[Bindable]
			public var messages_per_second_running_average:int = 0;
			
			[Bindable]
			public var messages_per_second_peak:uint = 0;
			
			[Bindable]
			public var messages_per_node:ArrayCollection;
			
			private var collectionSort:Sort ;
			private var streamManager:StreamManager ;
			
			/**
			 * @private 
			 */		
			protected var _connectSession:IConnectSession = ConnectSession.primarySession;
			
			public function MessageExplorerModel():void
			{
				collections = new ArrayCollection();
				collectionSort = new Sort();
				collectionSort.fields = [new SortField("collectionName", true)];
				collections.sort = collectionSort;
				collections.refresh();
				collectionsCursor = collections.createCursor();

				messages_per_node = new ArrayCollection();
				var countSort:Sort = new Sort();
			    countSort.fields = [new SortField("messages", true, false, true)];
				messages_per_node.sort = countSort;
				messages_per_node.refresh();
				
				lastTwoMinutes_messages_per_second = new ArrayCollection();
				for (var i:uint=0; i<240; i++) {
					lastTwoMinutes_messages_per_second.addItem(0);
				}
				tickTimer = new Timer(1000);
				tickTimer.addEventListener(TimerEvent.TIMER, onTimer);
				tickTimer.start();

				
			}
			
			
			public function close():void
			{
				
			}
			
			
			public function get isSynchronized():Boolean
			{
				return rootCollection.isSynchronized ;
			}
			/**
			 * Tells the component to begin synchronizing with the service.  
			 * For "headless" components such as this one, this method must be called explicitly.
			 */
			public function subscribe():void
			{
				
				rootCollection = new RootCollectionNode();
				rootCollection.connectSession = _connectSession ;
				rootCollection.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
				rootCollection.addEventListener(CollectionNodeEvent.NODE_CREATE, onNodeCreate);
				rootCollection.addEventListener(CollectionNodeEvent.NODE_DELETE, onNodeDelete);
				rootCollection.addEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onUserRoleChange);
				rootCollection.subscribe();
				
				streamManager = _connectSession.streamManager ;
				streamManager.addEventListener(StreamEvent.STREAM_RECEIVE,onStreamEvent);
				streamManager.addEventListener(StreamEvent.STREAM_DELETE,onStreamEvent);
				streamManager.addEventListener(StreamEvent.STREAM_PAUSE,onStreamEvent);
				streamManager.addEventListener(StreamEvent.VOLUME_CHANGE, onStreamEvent);
				streamManager.addEventListener(StreamEvent.DIMENSIONS_CHANGE, onStreamEvent);
			}
			
			
			/**
			 * Defines the logical location of the component on the service - typically this assigns the sharedID of the collectionNode
			 * used by the component. sharedIDs should be unique within a room (if they're expressing 2 unique locations). Note that
			 * this can only be assigned once (before <code>subscribe()</code> is called). For components with an <code>id</code> property, 
			 * sharedID defaults to that value.
			 */
			public function set sharedID(p_id:String):void
			{
				//_sharedID = p_id;
			}
			
			/**
			 * @private
			 */
			public function get sharedID():String
			{
				return null;
			}
	
			
			
			/**
			 * The IConnectSession with which this component is associated. Note that this may only be set once before <code>subscribe</code>
			 * is called; re-sessioning of components is not supported. Defaults to the first IConnectSession created in the application.
			 */
			public function get connectSession():IConnectSession
			{
				return _connectSession;
			}
			
			public function set connectSession(p_session:IConnectSession):void
			{
				_connectSession = p_session;
			}
			
			
			
			public function deleteCollection(p_collectionName:String):void
			{
				rootCollection.removeNode(p_collectionName);
			}
			
			public function deleteNode(p_collectionName:String, p_nodeName:String):void
			{
				if (collectionsCursor.findFirst({collectionName:p_collectionName})) {
					var c:MessageExplorerCollection = collectionsCursor.current.collection as MessageExplorerCollection;
					c.removeNode(p_nodeName);
				}
			}
			
			public function deleteItem(p_collectionName:String, p_nodeName:String, p_itemID:String):void
			{
				if (collectionsCursor.findFirst({collectionName:p_collectionName})) {
					var c:MessageExplorerCollection = collectionsCursor.current.collection as MessageExplorerCollection;
					c.removeItem(p_nodeName, p_itemID);
				}
			}

			public function addCollection(p_collectionName:String):void
			{
				rootCollection.createNode(p_collectionName);
			}
			
			public function addNode(p_collectionName:String, p_nodeName:String, p_configuration:NodeConfiguration=null):void
			{
				if (collectionsCursor.findFirst({collectionName:p_collectionName})) {
					var c:MessageExplorerCollection = collectionsCursor.current.collection as MessageExplorerCollection;
					c.createNode(p_nodeName, p_configuration);
				}
			}

			public function configureNode(p_collectionName:String, p_nodeName:String, p_configuration:NodeConfiguration=null):void
			{
				if (collectionsCursor.findFirst({collectionName:p_collectionName})) {
					var c:MessageExplorerCollection = collectionsCursor.current.collection as MessageExplorerCollection;
					c.setNodeConfiguration(p_nodeName, p_configuration);
				}
			}

			public function addItem(p_collectionName:String, p_nodeName:String, p_item:MessageItem):void
			{
				if (collectionsCursor.findFirst({collectionName:p_collectionName})) {
					var c:MessageExplorerCollection = collectionsCursor.current.collection as MessageExplorerCollection;
					c.addItem(p_nodeName, p_item);
				}
			}

			public function editItem(p_collectionName:String, p_nodeName:String, p_item:MessageItem):void
			{
				if (collectionsCursor.findFirst({collectionName:p_collectionName})) {
					var c:MessageExplorerCollection = collectionsCursor.current.collection as MessageExplorerCollection;
					c.addItem(p_nodeName, p_item, true);
				}
			}

			protected function onTimer(p_evt:TimerEvent):void
			{
				seconds_elapsed++;
				messages_per_second_total+=messageCounter_second;
				messages_per_second_running_average = messages_per_second_total/seconds_elapsed;
				lastTwoMinutes_messages_per_second.removeItemAt(0);
				lastTwoMinutes_messages_per_second.addItem(messageCounter_second);
				messages_per_second_peak = Math.max(messages_per_second_peak, messageCounter_second);
				messageCounter_second = 0;
			}
			
			protected function onSynchronizationChange(p_evt:CollectionNodeEvent):void
			{
				if (!rootCollection.isSynchronized) {
					//I must clean my model
					for each (var o:Object in collections) {
						var c:MessageExplorerCollection = o.collection as MessageExplorerCollection;
						c.destroy();
					}
					collections.removeAll();					
				}
				var e:MessageExplorerEvent = new MessageExplorerEvent(MessageExplorerEvent.ROOT_SYNCHRONIZATION_CHANGE);
				e.comment = (rootCollection.isSynchronized) ? "Collection Synchronized" : "Collection not Synchronizated";
				dispatchEvent(e);
				onEvent(e);
			}

			public function onUserRoleChange(p_evt:CollectionNodeEvent):void
			{
				var e:MessageExplorerEvent = new MessageExplorerEvent(MessageExplorerEvent.ROOT_USER_ROLE_CHANGE);
				e.comment = p_evt.userID + " Changed User Role to "+rootCollection.getUserRole(p_evt.userID, p_evt.nodeName);
				dispatchEvent(e);
				onEvent(e);
			}
			
			//a new collection was created
			protected function onNodeCreate(p_evt:CollectionNodeEvent):void
			{
						
				if (p_evt.nodeName == UserManager.COLLECTION_NAME || 
					p_evt.nodeName == RoomManager.COLLECTION_NAME || 
					p_evt.nodeName == StreamManager.COLLECTION_NAME ||  
					p_evt.nodeName == FileManager.COLLECTION_NAME ) {
						return ;
					}
				
				if (!collectionsCursor.findAny({collectionName:p_evt.nodeName})) {									
					var c:MessageExplorerCollection = new MessageExplorerCollection(p_evt.nodeName);
					c.connectSession = connectSession;
					c.subscribe();
					c.addEventListener(MessageExplorerEvent.COLLECTION_SYNCHRONIZATION_CHANGE, onEvent);
					c.addEventListener(MessageExplorerEvent.COLLECTION_USER_ROLE_CHANGE, onEvent);
					c.addEventListener(MessageExplorerEvent.COLLECTION_NODE_CREATE, onEvent);
					c.addEventListener(MessageExplorerEvent.COLLECTION_NODE_DELETE, onEvent);
					c.addEventListener(MessageExplorerEvent.NODE_CONFIGURATION_CHANGE, onEvent);
					c.addEventListener(MessageExplorerEvent.NODE_USER_ROLE_CHANGE, onEvent);
					c.addEventListener(MessageExplorerEvent.NODE_ITEM_ADD, onEvent);
					c.addEventListener(MessageExplorerEvent.NODE_ITEM_RECEIVE, onEvent);
					c.addEventListener(MessageExplorerEvent.NODE_ITEM_RETRACT, onEvent);
					collections.addItem({collectionName:p_evt.nodeName, collection:c});
					collections.sort = collectionSort;
					var e:MessageExplorerEvent = new MessageExplorerEvent(MessageExplorerEvent.ROOT_COLLECTION_CREATE);
					e.collection = p_evt.nodeName;
					e.comment = "New Collection Node is created" ;
					dispatchEvent(e);
					onEvent(e);
				}
			}
			
			//a collection was deleted
			protected function onNodeDelete(p_evt:CollectionNodeEvent):void
			{
				//myTrace("onNodeDelete:"+p_evt.nodeName);
				if (collectionsCursor.findFirst({collectionName:p_evt.nodeName})) {
					collectionsCursor.remove();

					var l:int = messages_per_node.length;
					for (var i:uint=0; i<l; i++) {
						if (messages_per_node.getItemAt(i).nodeName == p_evt.nodeName) {
							messages_per_node.removeItemAt(i);
							break;
						}
					}
					
					var e:MessageExplorerEvent = new MessageExplorerEvent(MessageExplorerEvent.ROOT_COLLECTION_DELETE);
					e.collection = p_evt.nodeName;
					e.comment = "Collection Node is deleted" ;
					dispatchEvent(e);				
					onEvent(e);
				}
			}

			protected function onEvent(p_evt:MessageExplorerEvent):void
			{
				dispatchEvent(p_evt);
				
				myTrace("onEvent:"+p_evt.type);
				
				for( var j:int = 0 ; j < collections.length ; j ++ ) {
					if ( collections.getItemAt(j).collectionName == p_evt.collection 
						&& (collections.getItemAt(j).collection as MessageExplorerCollection).isSynchronized){
						
						messageCounter_second++;
						break ;
					}
				}
				
				var name:String = (p_evt.collection == null) ? "root" : p_evt.collection;//+" - "+p_evt.node;

				var l:int = messages_per_node.length;
				var found:Boolean = false;
				for (var i:uint=0; i<l; i++) {
					var current:Object = messages_per_node.getItemAt(i);
					if (current.nodeName == name) {
						var newObj:Object = {nodeName:name, messages:(current.messages+1)};
						messages_per_node.setItemAt(newObj, i);
						found = true;
						break;
					}
				}
				if (!found) {
		            messages_per_node.addItem({nodeName:name, messages:1});
				}
				
				var e:MessageExplorerEvent = new MessageExplorerEvent(MessageExplorerEvent.LOG);
				e.collection = p_evt.collection;
				e.node = p_evt.node;
				e.item = p_evt.item;
				e.comment = p_evt.comment;
				e.kind = p_evt.type;
				dispatchEvent(e);			
			}
					
			public function myTrace(p_msg:String):void
			{
				trace("#model# "+p_msg);
			}
			
			
			private function onStreamEvent(p_evt:StreamEvent):void
			{
				var e:MessageExplorerEvent = new MessageExplorerEvent(MessageExplorerEvent.LOG);
				e.collection = StreamManager.COLLECTION_NAME;
				
				if ( p_evt.streamDescriptor.type == StreamManager.AUDIO_STREAM ) {
					e.node = "audioStreams" ;
				}else if ( p_evt.streamDescriptor.type == StreamManager.CAMERA_STREAM ) {
					e.node = "cameraStreams" ;
				}else if ( p_evt.streamDescriptor.type == StreamManager.REMOTE_CONTROL_STREAM ) {
					e.node = "screenShareStreams" ;
				}
				
				e.item = p_evt.type ;
				
				if ( p_evt.type == StreamEvent.STREAM_RECEIVE ) {
					e.kind = "NODE_ITEM_RECEIVE" ;
					e.comment = p_evt.streamDescriptor.type + "stream received"  ;
				}
				else if ( p_evt.type == StreamEvent.STREAM_DELETE ) {
					e.kind = "NODE_ITEM_RETRACT" ;
					e.comment = p_evt.streamDescriptor.type + "stream deleted"  ;
				}
				else if ( p_evt.type == StreamEvent.STREAM_PAUSE ) {
					e.kind = "NODE_ITEM_RECEIVE" ;
					e.comment = p_evt.streamDescriptor.type + "stream paused/played"  ;
				}
				else if ( p_evt.type == StreamEvent.VOLUME_CHANGE ) {
					e.kind = "NODE_ITEM_RECEIVE" ;
					e.comment = p_evt.streamDescriptor.type + "streams volume changed"  ;
				}
				else if ( p_evt.type == StreamEvent.DIMENSIONS_CHANGE ) {
					e.kind = "NODE_ITEM_RECEIVE" ;
					e.comment = p_evt.streamDescriptor.type + "streams dimension changed"  ;
				}	
				
				dispatchEvent(e);
			}
			
	}
}