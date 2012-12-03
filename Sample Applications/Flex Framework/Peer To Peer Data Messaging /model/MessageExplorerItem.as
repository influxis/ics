package model
{
	import flash.events.EventDispatcher;
	import com.adobe.rtc.messaging.MessageItem;
	import mx.utils.ObjectUtil;

	public class MessageExplorerItem extends EventDispatcher
	{
		private var id:String;

		[Bindable]
		public var item:String;
		
		public var itemObj:MessageItem;
		
		public function MessageExplorerItem(p_item:MessageItem):void
		{
			id = p_item.itemID;
			itemObj = p_item;
			updateItemString();
		}
		
		public function onItemReceive(p_item:MessageItem):void
		{
			itemObj = p_item;
			updateItemString();	
		}
			
		public function updateItemString():void
		{
			item="";
			item+= "<b>publisherID:</b> "+itemObj.publisherID;
			item+="<br>";
			item+= "<b>associatedUserID:</b> "+itemObj.associatedUserID;
			item+="<br>";
			item+= "<b>timeStamp:</b> "+itemObj.timeStamp.toString();
			item+="<br>";
			item+= "<b>body:</b><br>"+ObjectUtil.toString(itemObj.body);
		}
		
	}
}