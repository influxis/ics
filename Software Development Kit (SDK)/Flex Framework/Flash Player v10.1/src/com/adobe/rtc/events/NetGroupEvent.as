// ActionScript file
package com.adobe.rtc.events
{
	
	import flash.events.Event;

	/**
	 * NetGroupEvent describes various types of events received by the NetGroup
	 * 
	 * @see flash.net.NetGroup
	 */	
	public class NetGroupEvent extends Event
	{

		/**
		 * 
		 * The type of event emitted when the NetGroup receives an data item posted by a peer in the group.
		 */
		public static const ITEM_RECEIVE:String = "itemReceive"; 
		
		/**
		* The Item received by the NetGroup
		* 
		*/
		public var itemObject:Object;

		public function NetGroupEvent(p_type:String, p_item:Object=null)
		{
			super(p_type);
			
			if (p_item != null ) {
				itemObject = p_item ;
			}
		}

		/**
		 * @private
		 */
		public override function clone():Event
		{
			return new NetGroupEvent(type, itemObject);
		}		
	}
}