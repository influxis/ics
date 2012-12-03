// ActionScript file
package com.adobe.rtc.session.sessionClasses
{
	import com.adobe.rtc.events.NetGroupEvent;
	import com.adobe.rtc.util.DebugUtil;
	
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.net.GroupSpecifier;
	import flash.net.NetConnection;
	import flash.net.NetGroup;
	

	/**
	 * @private
	 */
	public class GroupCollectionManager extends EventDispatcher
	{
		/**
		 * NetGroup objects indexed by collection name.
		 * @private
		 */
		protected var _netGroupObjects:Object ;
		/**
		 * Group Specifier objects indexed by collection name.
		 * @private
		 */
		 protected var _groupSpecifierObjects:Object
		 /**
		 * The NetConnection associated with the room
		 * @private
		 */
		 public var netConnection:NetConnection ;
		 /**
		 * Assigns the message id in case its null for a p2p data message
		 */
		 public var messageIdObject:Object = new Object();
		 /**
		  * @private
		  */
		 private static const ALPHA_CHAR_CODES:Array = [48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69, 70];

		

		
		public function GroupCollectionManager():void
		{
			_netGroupObjects = new Object();
			_groupSpecifierObjects = new Object();
		}
		
		
		/**
		 * Function to create NetGroup from a collectionName
		 */
		public function createNetGroup(p_collectionName:String):void
		{
			if ( _groupSpecifierObjects[p_collectionName] == null ) {
				var groupSpecifier:GroupSpecifier = new GroupSpecifier(p_collectionName); // create a GroupSpecifier based on CollectionNode
				groupSpecifier.multicastEnabled = true ; // enables multicasting
				groupSpecifier.postingEnabled = true ; // enables posting
				groupSpecifier.serverChannelEnabled = true ; 
				_groupSpecifierObjects[p_collectionName] = groupSpecifier ;
				messageIdObject[p_collectionName] = 0 ;
				_netGroupObjects[p_collectionName] = new NetGroup(netConnection, groupSpecifier.toString());
				_netGroupObjects[p_collectionName].addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			}
			
			
		}
  		
  		/**
  		 * Function to do initial bootstrapping to the Group
  		 */
  		public function bootStrapPeer(p_collectionName:String,p_peerID:String):void
  		{
  			if ( _groupSpecifierObjects[p_collectionName] != null ) {
  				_groupSpecifierObjects[p_collectionName].addBootstrapPeer(p_peerID);
  			} else {
  				throw new Error("GroupCollectionManager:bootStrapPeer::The Net Group does not exisits") ;
				return ;
  			}
  		}
  		
  		/**
  		 * Add the array of Peers to a particular CollectionNode NetGroup
  		 */
  		public function addNeighbors(p_collectionName:String,p_peerIDs:Array):void
  		{
  			if ( _groupSpecifierObjects[p_collectionName] != null ) {
  				for ( var i:int = 0 ; i < p_peerIDs.length ; i++ ) {
  					if ( p_peerIDs[i] != netConnection.nearID ) {
  						// if  peerID is not of me, add as my neighbor
  						try {
  							_netGroupObjects[p_collectionName].addNeighbor(p_peerIDs[i]);
  						} catch(e:Error) {
  							// bootstrapping is not done ...
  							bootStrapPeer(p_collectionName,netConnection.nearID);
  							break ;
  						}	
  					}
  				}
  			}else {
  				throw new Error("GroupCollectionManager:addNeighbors::The Net Group does not exisits") ;
				return ;
  			}
  		}
  		
  		/**
  		 * Posts a Peer To Peer Data Message on a particular CollectionNode NetGroup
  		 */
  		public function postMessage(p_collectionName:String,p_messageObject:Object):void
  		{
  			if ( p_messageObject == null) {
  				throw new Error("Can't post a null Object");
  				return false ;
  			} 
  			
  			if ( _netGroupObjects[p_collectionName] == null ) {
  				throw new Error("GroupCollectionManager:postMessage::The Net Group does not exisits") ;
  				return false ;
  			}
  			
  			_netGroupObjects[p_collectionName].post(p_messageObject);
  			
  		}
  		
  		/**
  		 * Get the NetGroup specified by CollectionName
  		 */
  		public function getNetGroupByCollection(p_collectionName:String):NetGroup
  		{
  			return _netGroupObjects[p_collectionName] as NetGroup ;
  		}
  		
  		/**
  		 * Returns whether a NetGroup for a CollectionNode exists
  		 */
  		public function doesGroupExist(p_collectionName:String):Boolean	
  		{
  			return (_netGroupObjects[p_collectionName]!=null) ;
  		}
  		
  		protected function onNetStatus(e:NetStatusEvent):void
		{
			switch(e.info.code){
				case "NetGroup.Posting.Notify": // e.info.message, e.info.messageID
					//assigning the time at the receiving end d
					if ( e.info.message.item.timeStamp == null ) {
						e.info.message.item.timeStamp = getCurrentTime() ;
					}
					
					dispatchEvent(new NetGroupEvent(NetGroupEvent.ITEM_RECEIVE,e.info.message));
					break;
			}
		}
		
		public function getCurrentTime():Number
		{
			return (new Date()).getTime();
		}
		
		/**
		 * @private
		 * Internal function for generating the unique Ids
		 */
		public function createUID():String
		{
			var uid:Array = new Array(36);
			var index:int = 0;
			
			var i:int;
			var j:int;
			
			for (i = 0; i < 8; i++)
			{
				uid[index++] = ALPHA_CHAR_CODES[Math.floor(Math.random() *  16)];
			}
			
			for (i = 0; i < 3; i++)
			{
				uid[index++] = 45; // charCode for "-"
				
				for (j = 0; j < 4; j++)
				{
					uid[index++] = ALPHA_CHAR_CODES[Math.floor(Math.random() *  16)];
				}
			}
			
			uid[index++] = 45; // charCode for "-"
			
			var time:Number = new Date().getTime();
			// Note: time is the number of milliseconds since 1970,
			// which is currently more than one trillion.
			// We use the low 8 hex digits of this number in the UID.
			// Just in case the system clock has been reset to
			// Jan 1-4, 1970 (in which case this number could have only
			// 1-7 hex digits), we pad on the left with 7 zeros
			// before taking the low digits.
			var timeString:String = ("0000000" + time.toString(16).toUpperCase()).substr(-8);
			
			for (i = 0; i < 8; i++)
			{
				uid[index++] = timeString.charCodeAt(i);
			}
			
			for (i = 0; i < 4; i++)
			{
				uid[index++] = ALPHA_CHAR_CODES[Math.floor(Math.random() *  16)];
			}
			
			return String.fromCharCode.apply(null, uid);
		}

  		
	}
}