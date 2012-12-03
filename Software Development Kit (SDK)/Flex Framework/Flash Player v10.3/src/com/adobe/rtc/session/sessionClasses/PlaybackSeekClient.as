/*
*
* ADOBE CONFIDENTIAL
* ___________________
*
* Copyright [2007-2010] Adobe Systems Incorporated
* All Rights Reserved.
*
* NOTICE:  All information contained herein is, and remains
* the property of Adobe Systems Incorporated and its suppliers,
* if any.  The intellectual and technical concepts contained
* herein are proprietary to Adobe Systems Incorporated and its
* suppliers and are protected by trade secret or copyright law.
* Dissemination of this information or reproduction of this material
* is strictly forbidden unless prior written permission is obtained
* from Adobe Systems Incorporated.
*/
package com.adobe.rtc.session.sessionClasses
{
	import com.adobe.rtc.util.DebugUtil;
	
	/**
	 * This class is a NetStream "client" used by SessionManagerPlayback while seeking.
	 * It stores the state for a collection until the seek point has been reached and then call the onSeekComplete callback.
	 */
	public class PlaybackSeekClient
	{
		public var collectionName:String;
		public var seekTime:Number;
		public var nodes:Object;
		public var itemsData:Object;
		public var onSeekComplete:Function;
		
		public function PlaybackSeekClient(p_collectionName:String, p_seekTime:Number, p_onSeekComplete:Function)
		{
			collectionName = p_collectionName;
			seekTime = p_seekTime;
			onSeekComplete = p_onSeekComplete;
		}
		
		public function onMetaData(info:Object):void
		{
//			myTrace("======= onMetadata: ", info);
		}
		
		public function onPlayStatus(info:Object):void
		{
			myTrace("======= onPlayStatus ", info);
			if (info.code == "NetStream.Play.Complete") {
				if (onSeekComplete != null)
					onSeekComplete(this);
			}
		}
		
		public function streamRecordingStart(p_collectionName:String):void
		{
//			myTrace("======= streamRecordingStart " + p_collectionName);
		}

		public function streamRecordingStop():void
		{
//			myTrace("======= streamRecordingStop");
		}
		
		public function receiveNodes(p_data:Object,p_peerIDs:Array = null):void
		{
			nodes = p_data;
		}
		
		public function receiveItems(p_data:Object):void
		{
			itemsData = p_data;
		}
		
		public function receiveNode(p_collectionName:String, p_nodeName:String=null, p_nodeConfigurationVO:Object=null,p_peerIDs:Array = null):void
		{
			// we're receiving this as part of a seek, flatten it into the state of what we've seen so far
			if (nodes==null) {
				nodes = new Object();
			}
			if (nodes.nodeConfigurations==null) {
					nodes.nodeConfigurations = new Object();
			}
			nodes.nodeConfigurations[p_nodeName] = p_nodeConfigurationVO;
		}
		
		public function receiveNodeConfiguration(p_collectionName:String, p_nodeName:String, p_nodeConfigurationVO:Object,p_peerIDs:Array = null):void
		{
			receiveNode(p_collectionName, p_nodeName, p_nodeConfigurationVO);
		}
		
		public function receiveNodeDeletion(p_collectionName:String, p_nodeName:String=null):void
		{
			if (p_nodeName!=null) {
				delete nodes.nodeConfigurations[p_nodeName];
				if (itemsData!=null && itemsData.items!=null) {
					delete itemsData.items[p_nodeName];
				}
				// TODO : private items
			}
		}
		
		public function receiveItem(p_itemData:Object):void
		{
			// we're seeking, fold it in
			//TODO : private items
			if (itemsData==null) {
				itemsData = new Object();
			}
			if (itemsData.items==null) {
				itemsData.items = new Object();
			}
			if (itemsData.items[p_itemData.nodeName]==null) {
				itemsData.items[p_itemData.nodeName] = new Object();
			}
			itemsData.items[p_itemData.nodeName][p_itemData.item.itemID] = p_itemData.item;
		}
		
		public function receiveItemRetraction(p_itemData:Object):void
		{
			// we're seeking, fold it in
			if (itemsData!=null && itemsData.items!=null &&
			 itemsData.items[p_itemData.nodeName]!=null) {
				delete itemsData.items[p_itemData.nodeName][p_itemData.item.itemID];
			}
		}
		
		
		protected function myTrace(...args):void
		{
			var message:Object = args.length > 0 ? args[0] : "<no message>";
			var obj:Object = args.length > 1 ? args[1] : null;
			DebugUtil.debugTrace("#SeekClient " + message);
			if (obj != null)
				DebugUtil.dumpObjectShallow("", obj);
		}
		
	}
}
