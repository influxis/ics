package model
{
	import flash.events.EventDispatcher;
	import mx.collections.ArrayCollection;
	import com.adobe.rtc.messaging.MessageItem;
	import flash.utils.Dictionary;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import mx.utils.ObjectUtil;
	import mx.collections.IViewCursor;
	import mx.collections.SortField;
	import mx.collections.Sort;
	import com.adobe.rtc.messaging.UserRoles;

	public class MessageExplorerNode extends EventDispatcher
	{
		protected var _name:String;
		protected var _collectionName:String;

		[Bindable]
		public var items:ArrayCollection;

		public var itemsCursor:IViewCursor;
				
		[Bindable]
		public var configuration:String;
		
		[Bindable]
		public var configurationObj:NodeConfiguration;
		
		public function MessageExplorerNode(p_collectionName:String, p_name:String, p_configuration:NodeConfiguration):void
		{
			_collectionName = p_collectionName;
			_name = p_name;
			
			configurationObj = p_configuration;
			updateConfigurationString();
			
			items = new ArrayCollection();
			var sort:Sort = new Sort();
			sort.fields = [new SortField("itemID", true)];
			items.sort = sort;
			items.refresh();
			itemsCursor = items.createCursor();
		}
		
		public function onItemReceive(p_item:MessageItem):void
		{
			var e:MessageExplorerEvent;
			if (!itemsCursor.findFirst({itemID:p_item.itemID})) {
				var i:MessageExplorerItem = new MessageExplorerItem(p_item);
				items.addItem({itemID:p_item.itemID, item:i});

				e = new MessageExplorerEvent(MessageExplorerEvent.NODE_ITEM_ADD);
				e.collection = _collectionName;
				e.node = _name;
				e.item = p_item.itemID;
				if ( p_item.body != null )
					e.comment = "itemID:" + ObjectUtil.toString(p_item.body).split("\n").join(" ");
				else 
					e.comment = "itemID:null" ;
				dispatchEvent(e);
			} else {
				(itemsCursor.current.item as MessageExplorerItem).onItemReceive(p_item);

				e = new MessageExplorerEvent(MessageExplorerEvent.NODE_ITEM_RECEIVE);
				e.collection = _collectionName;
				e.node = _name;
				e.item = p_item.itemID;
				if ( p_item.body != null )
					e.comment = "itemID:" + p_item.body.toString();
				else 
					e.comment = "itemID:null"
				dispatchEvent(e);
			}
		}

		public function onConfigurationChange(p_configuration:NodeConfiguration):void
		{
			configurationObj = p_configuration;
			updateConfigurationString();
			
			var e:MessageExplorerEvent = new MessageExplorerEvent(MessageExplorerEvent.NODE_CONFIGURATION_CHANGE);
			e.collection = _collectionName;
			e.node = _name;
			e.comment = p_configuration.toString();
			dispatchEvent(e);
		}

		public function onItemRetract(p_itemID:String):void
		{
			if (itemsCursor.findAny({itemID:p_itemID})) {
				itemsCursor.remove();

				var e:MessageExplorerEvent = new MessageExplorerEvent(MessageExplorerEvent.NODE_ITEM_RETRACT);
				e.collection = _collectionName;
				e.node = _name;
				e.item = p_itemID;
				dispatchEvent(e);	
			}
		}

		protected function updateConfigurationString():void
		{
			configuration = "<b>accessModel:</b> ";
			switch (configurationObj.accessModel) {
				case UserRoles.VIEWER:
					configuration+="NONE";
					break;
				case UserRoles.PUBLISHER:
					configuration+="PUBLISHER";
					break;
				case UserRoles.OWNER:
					configuration+="OWNER";
					break;				
			}
			configuration+="<br>";

			configuration+= "<b>publishModel:</b> ";
			switch (configurationObj.publishModel) {
				case UserRoles.VIEWER:
					configuration+="NONE";
					break;
				case UserRoles.PUBLISHER:
					configuration+="PUBLISHER";
					break;
				case UserRoles.OWNER:
					configuration+="OWNER";
					break;				
			}
			configuration+="<br>";
			configuration+= "<b>modifyAnyItem:</b> "+configurationObj.modifyAnyItem.toString();
			configuration+="<br>";
			configuration+= "<b>persistItems:</b> "+configurationObj.persistItems.toString();
			configuration+="<br>";
			configuration+= "<b>userDependentItems:</b> "+configurationObj.userDependentItems.toString();
			configuration+="<br>";

			configuration+= "<b>itemStorageScheme:</b> ";
			switch (configurationObj.itemStorageScheme) {
				case NodeConfiguration.STORAGE_SCHEME_SINGLE_ITEM:
					configuration+="SINGLE_ITEM";
					break;
				case NodeConfiguration.STORAGE_SCHEME_MANUAL:
					configuration+="MANUAL";
					break;
				case NodeConfiguration.STORAGE_SCHEME_QUEUE:
					configuration+="QUEUE";
					break;
			}			
		}
		
	}
}