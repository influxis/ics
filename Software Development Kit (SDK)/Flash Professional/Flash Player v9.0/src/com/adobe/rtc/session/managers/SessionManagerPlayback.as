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
package com.adobe.rtc.session.managers
{
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.events.ArchiveEvent;
	import com.adobe.rtc.events.SessionEvent;
	import com.adobe.rtc.session.sessionClasses.FMSConnector;
	import com.adobe.rtc.session.sessionClasses.PlaybackSeekClient;
	import com.adobe.rtc.util.DebugUtil;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.net.NetStream;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;

	use namespace session_internal;

	/**
	 * 
	 * SessionManagerPlayback is fiendishly constructed. 
	 * 
	 * Sequence : 
	 * 1) Connect to FMS
	 * 2) Wait for receiveLogin(), called when archive is loaded on FMS. 
	 * 2) Play the pacingStream in order to get the total time of the recording
	 * 3) PacingStream's onMetadata will tell you the total. Stop the pacing stream from here.
	 * 4) Flush the offsets stream to get a table of all the streams in this recording, and their offsets. (see definition of "flushing")
	 * 5) set a timeout to realReceiveLogin
	 * 6) Start the pacing timer
	 * 7) ConnectSession will start subscribing the rootCollection and managers
	 * 8) Once that's done, the app logic will start subscribing the individual collections
	 */
	public class SessionManagerPlayback extends SessionManagerAdobeHostedServices
	{
		protected static const OFFSET_FILE_NAME:String = "__StreamOffsets";
		protected static const PACING_FILE_NAME:String = "__PacingStream";
		
		protected static var PACING_INTERVAL:int = 250;
		
		protected var _dataStreams:Object = new Object();
		protected var _avStreams:Object = new Object();
		protected var _streamSeekTable:Object = new Object();
		
		private static const Adobe_patent_B1112:String = "AdobePatentID='B1112'";
		
		protected var _offsetStream:NetStream;
		protected var _offsetsRead:Boolean = false;
		protected var _offsetTable:Object = new Object();
		protected var _lengthPaceStream:NetStream;
		protected var _pacingTimer:Timer = new Timer(PACING_INTERVAL, 0);
		protected var _isPlaying:Boolean = true;
		public var _archiveID:String ;
		public var totalTime:Number = -1;
		public var currentTime:Number = 0; // current play time, in ms
		
		protected const ARCHIVE_IN_INSTANCE:Boolean = true;
		
		protected var _startTime:Number = getTimer();
		protected var _lastTime:Number;
		protected var _isDisconnected:Boolean = false ;
		
		public function SessionManagerPlayback()
		{
			super();
			
			_fmsConnector.appName = "playback";
			_fmsConnector.addEventListener("connected", onConnected);
			_fmsConnector.methodHandlerObject = this;

			_lastTime = _startTime;
			_pacingTimer.addEventListener(TimerEvent.TIMER, onPacing);
		}
		
		public function get archiveID():String {
			return _archiveID;
		}
		
		public function set archiveID(p_archiveID:String):void {
			_archiveID = p_archiveID;
		}
		
		protected function getStreamPath(p_name:String):String
		{
			if (ARCHIVE_IN_INSTANCE || archiveID == null)
				return p_name;
			else
				return archiveID + "/" + p_name;
		}
		
		override protected function getInstancePath(p_name:String):String
		{
			if (ARCHIVE_IN_INSTANCE && archiveID != null) {
				return p_name + "/" + archiveID;
			} else {
				return p_name;
			}
		}
		
		override protected function getFMSXML(p_suffix:String=""):void
		{
			if (archiveID != null) {
				p_suffix += "&playback=" + archiveID;
			}
			
			super.getFMSXML(p_suffix);
		}
		
		override public function receiveLogin(p_userData:Object):void
		{
			myTrace("receiveLogin: ", p_userData);

			_lengthPaceStream = new NetStream(session_internal::connection);
			_lengthPaceStream.bufferTime = 1;
			_lengthPaceStream.client = this;
			_lengthPaceStream.play(getStreamPath(PACING_FILE_NAME));
			
			myTrace("======= onConnected: play " + getStreamPath(PACING_FILE_NAME));
			//setTimeout(receiveLogin, asynchTimer, {descriptor:{userID:0, affiliation:10}});
		}

		private function realReceiveLogin(p_userData:Object):void
		{
			myTrace("realReceiveLogin: ", p_userData);
			
			super.receiveLogin(p_userData);
		}
		
		override public function receiveError(p_error:Object /*contains .message and .name*/):void
		{
			myTrace("receiveError: ", p_error.message);
			
			if (p_error.name == "FAILED_TO_FETCH_ARCHIVE") {
				// TODO: bailing out...
				super.receiveError(p_error);
			} else {
				super.receiveError(p_error);
			}
		}
		
		override session_internal function subscribeCollection(p_collectionName:String=null, p_nodeNames:Array=null):void
		{
			if (p_collectionName==null) {
				myTrace("======= subscribeCollection root");
				p_collectionName = "__RootCollection";
			}
				
			var stream:NetStream = _dataStreams[p_collectionName] = new NetStream(session_internal::connection);
			stream.bufferTime = 1;

			// NB : in this case, we're mirroring the if statement down in FMS when recording the collectionName 
			var collName:String = (archiveID) ? archiveID + "/" + p_collectionName : p_collectionName;
			var seekTime:Number = currentTime-_offsetTable[collName];
			if (seekTime>PACING_INTERVAL) {
				// this is really a seek!
				seekTime = seekTime/1000;
				
				stream.client = new PlaybackSeekClient(p_collectionName, seekTime, onSeekComplete);
				stream.play(getStreamPath(p_collectionName), 0, seekTime, 3);
				myTrace("======= subscribeCollection " + p_collectionName + " - seek and play " + seekTime);
			} else {
				stream.client = this;
				stream.play(getStreamPath(p_collectionName));
				myTrace("======= subscribeCollection " + p_collectionName + " - play");
			}
		}	
		
		override session_internal function getAndPlayAVStream(p_streamID:String, p_peerID:String=null):NetStream
		{
			if ( p_streamID == null ) {
				return null ;
			}
			var stream:NetStream = _avStreams[p_streamID] = new NetStream(session_internal::connection);
			
			// NB : in this case, we're mirroring the if statement down in FMS when recording the collectionName 
			var collName:String = (archiveID) ? archiveID + "/" + p_streamID : p_streamID;
			var seekTime:Number = currentTime-_offsetTable[collName];

			stream.client = this;
			stream.bufferTime = 1 ;
			
			trace("SeekTime: " + seekTime);
			if (seekTime>PACING_INTERVAL) {
				// this is really a seek!
				seekTime = seekTime/1000;
				
				stream.play(getStreamPath(p_streamID), seekTime);
			} else {
				stream.play(getStreamPath(p_streamID));
			}
			if (!_isPlaying) {
				setTimeout(onAVSeekPause, 100, stream);
			}
			myTrace("======= getAndPlayAVStream " + p_streamID + " - " + (seekTime > 250) ? "seek and play" : "play");
			return stream ;
		}	
		
		session_internal function onAVSeekPause(p_stream:NetStream):void
		{
			p_stream.pause();
		}
		
		session_internal function isPaused():Boolean
		{
			return ! _isPlaying;
		}
		
		session_internal function pause(p_toggle:Boolean):void
		{
			myTrace("======= pause at " + currentTime);
			
			_isPlaying = !p_toggle;
			var collectionName:String;
			var streamID:String;
			
			if (p_toggle) {
				for (collectionName in _dataStreams) {
					NetStream(_dataStreams[collectionName]).pause();
				}
				for (streamID in _avStreams) {
					NetStream(_avStreams[streamID]).pause();
				}
				_pacingTimer.stop();
			} else {
				if ( _isDisconnected ) {
					login();
					_isDisconnected = false ;
					seek(currentTime);
				}else {
					seek(currentTime);
				}
			}
		}
		
		session_internal function seek(p_time:Number):void
		{
			myTrace("======= seek " + p_time);
			
			if ( _isDisconnected ) {
				login();
				_isDisconnected = false ;
				seek(p_time);
			}
			
			var streamID:String;
			var stream:NetStream;
			for (streamID in _dataStreams) {
				stream = _dataStreams[streamID] as NetStream;
				stream.close();
			}
			for (streamID in _avStreams) {
				stream = _avStreams[streamID] as NetStream;
				stream.close();
			}
			currentTime = p_time;
			_pacingTimer.stop();
			_isPlaying = true ;
			dispatchEvent(new SessionEvent(SessionEvent.DISCONNECT));
			setTimeout(realReceiveLogin, asynchTimer, {descriptor:{userID:0, affiliation:10}});
		}
		
		public function streamRecordingStart(p_collectionName:String):void
		{
//			myTrace("======= streamRecordingStart " + p_collectionName);
		}

		/**
		 * called when a seek ends and the SeekClient receives an onPlayStatus "switch"
		 */ 
		public function onSeekComplete(p_client:PlaybackSeekClient):void
		{
//			myTrace("======= onStreamRecordingStart " + p_client.collectionName);

			if (p_client.collectionName != OFFSET_FILE_NAME) {
				// any other stream
				// we are done seeking
				var stream:NetStream = NetStream(_dataStreams[p_client.collectionName]);
				stream.close();
				if (p_client.nodes) {
					myTrace("...calling receiveNodes");
					super.receiveNodes(p_client.nodes);
				}
				if (p_client.itemsData) {
					myTrace("...calling receiveItems");
					super.receiveItems(p_client.itemsData);
				}
				myTrace("seekTime " + p_client.collectionName + " " + p_client.seekTime);
				if (_isPlaying) {
					stream.client = this;
					stream.play(getStreamPath(p_client.collectionName), p_client.seekTime);
				}
			}
		}
				
		override session_internal function set isSynchronized(p_toggle:Boolean):void
		{
			if (p_toggle && _isPlaying) {
				_lastTime = getTimer();
				_pacingTimer.start();
			}
		}
	
	
		public function receiveStreamOffset(p_name:String, p_offset:Number):void
		{
			myTrace("======= receiveStreamOffset " + p_name + ", " + p_offset);

			_offsetTable[p_name] = p_offset;
		}
		
		protected function onConnected(p_evt:Event):void
		{
			myTrace("fms connected: " + p_evt);

			var f:FMSConnector = p_evt.target as FMSConnector;
			session_internal::connection = f.nc;
		}
		
		
		override protected function onFmsConnectorDisconnect(p_evt:Event):void
		{
			super.onFmsConnectorDisconnect(p_evt);
			_isDisconnected = true ;
			logout();
		}
		
		public function onMetaData(info:Object):void
		{
//			myTrace("======= onMetadata: " + (info.duration*1000));
			
			if (_lengthPaceStream) {
				totalTime = info.duration*1000;
				_lengthPaceStream.close();
				_lengthPaceStream = null;
				_offsetStream = new NetStream(session_internal::connection);
				_offsetStream.bufferTime = 1;
				_offsetStream.client = new Object();
				_offsetStream.client["onPlayStatus"] = onOffsetStreamPlayStatus;
				_offsetStream.client["receiveStreamOffset"] = receiveStreamOffset;
				_offsetStream.play(getStreamPath(OFFSET_FILE_NAME), 0, -1, 3);
				dispatchEvent(new ArchiveEvent(ArchiveEvent.TOTAL_TIME_CHANGE));
				myTrace("======= onMetadata: play " + getStreamPath(OFFSET_FILE_NAME));
			}
		}
		
		public function onPlayStatus(info:Object):void
		{
			myTrace("======= onPlayStatus ", info);
		}
		
		public function onOffsetStreamPlayStatus(info:Object):void {
			myTrace("======= onOffsetStreamPlayStatus ", info);
			if (info.code == "NetStream.Play.Complete") {
				_offsetStream.close();
				_offsetStream = null;
				setTimeout(realReceiveLogin, asynchTimer, {descriptor:{userID:0, affiliation:10}});
			}
		}
		
		public function streamRecordingStop():void
		{
			
		}
		
		protected function onPacing(p_evt:TimerEvent):void
		{
			var curTimer:Number = getTimer();
			currentTime += curTimer - _lastTime ;
			
			if (currentTime >= totalTime) {
				currentTime = totalTime;
				_isPlaying = false;
				_pacingTimer.stop();
				dispatchEvent(new ArchiveEvent(ArchiveEvent.CURRENT_TIME_CHANGE));
				dispatchEvent(new Event(Event.COMPLETE));
			} else {
				_lastTime = curTimer;
				dispatchEvent(new ArchiveEvent(ArchiveEvent.CURRENT_TIME_CHANGE));
			}
			
//			myTrace("======= onPacing: " + currentTime);
		}
		
		/********************************************************************/
		
		/**
		 * @private
		 * The MessageManager's internal method for unsubscribing to a collectionNode on the server.
		 */		
		override session_internal function unsubscribeCollection(p_collectionName:String=null):void
		{
			//do nothing, this has no receive equivalent (none needed)
		}

		/**
		 * @private
		 * The MessageManager's internal method for creating a new node on a collectionNode on the server.
		 * (response : receiveNode)
		 */		
		override session_internal function createNode(p_collectionName:String, p_nodeName:String, p_nodeConfigurationVO:Object=null):void
		{
			// Reference implementation : echoing the request back to the collection
			setTimeout(receiveNode, asynchTimer, p_collectionName, p_nodeName, p_nodeConfigurationVO);
		}

		/**
		 * @private
		 * The MessageManager's internal method for configuring a node on a collectionNode on the server.
		 * (response : receiveNodeConfiguration)
		 */		
		override session_internal function configureNode(p_collectionName:String, p_nodeName:String, p_nodeConfigurationVO:Object):void
		{
			// Reference implementation : echoing the request back to the collection
			setTimeout(receiveNodeConfiguration, asynchTimer, p_collectionName, p_nodeName, p_nodeConfigurationVO);
		}


		/**
		 * @private
		 * The MessageManager's internal method for removing a node on a collectionNode on the server.
		 * (response : receiveNodeDeletion)
		 */		
		override session_internal function removeNode(p_collectionName:String, p_nodeName:String=null):void
		{
			// Reference implementation : echoing the request back to the collection
			setTimeout(receiveNodeDeletion, asynchTimer, p_collectionName, p_nodeName);
		}


		/**
		 * @private
		 * The MessageManager's internal method for publishing an item on a node on a collectionNode on the server.
		 * (response : receiveItem)
		 */		
		override session_internal function publishItem(p_collectionName:String, p_nodeName:String, p_itemVO:Object, p_overWrite:Boolean=false):void
		{
			// Reference implementation : echoing the request back to the collection
			var data:Object = new Object();
			data.collectionName = p_collectionName ;
			data.nodeName = p_nodeName ;
			data.item = p_itemVO ;
			setTimeout(receiveItem, asynchTimer, data);
		}


		/**
		 * @private
		 * The MessageManager's internal method for retracting an item on a node on a collectionNode on the server.
		 * (response : receiveItemRetraction)
		 */		
		override session_internal function retractItem(p_collectionName:String, p_nodeName:String, p_itemID:String=null):void
		{
			// Reference implementation : echoing the request back to the collection
			var data:Object = new Object();
			data.collectionName = p_collectionName ;
			data.nodeName = p_nodeName ;
			data.item = p_itemID ;
			setTimeout(receiveItemRetraction, asynchTimer, data);
		}

		/**
		 * @private
		 * The MessageManager's internal method for fetching items on a node on a collectionNode on the server.
		 * (response : receiveItems)
		 */		
		override session_internal function fetchItems(p_collectionName:String, p_nodeName:String, p_itemIDs:Array):void
		{
		}
		
		/**
		 * @private
		 * The MessageManager's internal method for setting a user role on a collectionNode / node on the server.
		 */
		override session_internal function setUserRole(p_userID:String, p_role:int, p_collectionName:String=null, p_nodeName:String=null):void
		{
			// Reference implementation : echoing the request back to the collection
			setTimeout(receiveUserRole, asynchTimer, p_userID, p_role, p_collectionName, p_nodeName);
		}
		
		protected function myTrace(...args):void
		{
			var message:Object = args.length > 0 ? args[0] : "<no message>";
			var obj:Object = args.length > 1 ? args[1] : null;
			DebugUtil.debugTrace("#SessionManagerPlayback " + (getTimer()-_startTime) + " " + message);
			if (obj != null)
				DebugUtil.dumpObjectShallow("", obj);
		}
	}
}
