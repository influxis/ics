package model
{
	import flash.events.Event;

	public class MessageExplorerEvent extends Event
	{

		public static const ROOT_COLLECTION_CREATE:String = "ROOT_COLLECTION_CREATE";
		public static const ROOT_COLLECTION_DELETE:String = "ROOT_COLLECTION_DELETE";
		public static const ROOT_SYNCHRONIZATION_CHANGE:String = "ROOT_SYNCHRONIZATION_CHANGE";
		public static const ROOT_USER_ROLE_CHANGE:String = "ROOT_USER_ROLE_CHANGE";

		public static const COLLECTION_SYNCHRONIZATION_CHANGE:String = "COLLECTION_SYNCHRONIZATION_CHANGE";
		public static const COLLECTION_USER_ROLE_CHANGE:String = "COLLECTION_USER_ROLE_CHANGE";
		public static const COLLECTION_NODE_CREATE:String = "COLLECTION_NODE_CREATE";
		public static const COLLECTION_NODE_DELETE:String = "COLLECTION_NODE_DELETE";
		public static const COLLECTION_CREATE:String = "COLLECTION_CREATE" ;
		public static const COLLECTION_DELETE:String = "COLLECTION_DELETE" ;

		public static const NODE_CONFIGURATION_CHANGE:String = "NODE_CONFIGURATION_CHANGE";
		public static const NODE_USER_ROLE_CHANGE:String = "NODE_USER_ROLE_CHANGE";
		public static const NODE_ITEM_ADD:String = "NODE_ITEM_ADD";
		public static const NODE_ITEM_RECEIVE:String = "NODE_ITEM_RECEIVE";
		public static const NODE_ITEM_RETRACT:String = "NODE_ITEM_RETRACT";

		public static const LOG:String = "log";
		
		public var collection:String;
		public var node:String;
		public var item:String;
		public var comment:String;
		public var kind:String;
		
		public function MessageExplorerEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = true):void {
			super(type, bubbles, cancelable);
		}

		public override function clone():Event
		{
			var e:MessageExplorerEvent = new MessageExplorerEvent(type, bubbles, cancelable);
			e.collection = collection;
			e.node = node;
			e.item = item;
			e.comment = comment;
			e.kind = kind;
			return e;
		}
	}
}