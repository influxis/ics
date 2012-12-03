// ActionScript file
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
package com.adobe.rtc.collaboration
{
	import com.adobe.rtc.core.connect_internal;
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.StreamEvent;
	import com.adobe.rtc.events.StreamStatusEvent;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.managers.SessionManagerBase;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.sharedManagers.StreamManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor;
	import com.adobe.rtc.sharedManagers.descriptors.UserDescriptor;
	import com.adobe.rtc.sharedModel.CollectionNode;
	import com.adobe.rtc.util.DebugUtil;
	import com.adobe.rtc.util.Invalidator;
	
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.media.Microphone;
	import flash.media.SoundTransform;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.NetStreamInfo;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import flash.events.EventDispatcher;

	/**
	 * Dispatched when the component either loses its connection to the session or regains it
	 * and has finished re-synchronizing itself to the rest of the room.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	

	/**
	 * Dispatched when the current user's role with respect to this component changes.
	 */
	[Event(name="userRoleChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	
	/**
	 * Dispatched when a new audio stream is accepted by the subscriber and is about to play. 
	 */
	[Event(name="streamReceive", type="com.adobe.rtc.events.StreamEvent")]
	/**
	 * Dispatched when an audio stream is stopped and will cease playing from the subscriber.
	 */
	[Event(name="streamDelete", type="com.adobe.rtc.events.StreamEvent")]	

	/**
	 * Dispatched when an audio stream being played by this component is muted.
	 */
	[Event(name="streamPause", type="com.adobe.rtc.events.StreamEvent")]
	/**
	 * Dispatched when the type of connection changes from peer 2 peer 2 hub spoke
	 */
	[Event(name="connectionTypeChange", type="com.adobe.rtc.events.StreamEvent")]

	/**
	 * AudioSubscriber is the foundation class for receiving and playing VOIP audio in a LCCS room. 
	 * By default, AudioSubscriber simply subscribes to 
	 * StreamManager notifications and plays all audio streams present in the room. 
	 * It can also accept an array of userIDs, used for restricting the list of publishers that this subscriber should play audio for.
	 * 
	 * <p> 
	 * Like all stream components, AudioSubscriber has an API for setting and getting a 
	 * <code class="property">groupName</code>. This property can be used to create
	 * multiple VOIP groups, each being separate and having different access/publish models, 
	 * thereby allowing for multiple private conversations. For a subscriber to listen to a 
	 * particular VOIP stream from a publisher, both should have the same assigned 
	 * <code class="property">groupName</code>. If no <code class="property">groupName</code> is assigned, 
	 * the subscribe defaults to listening to the public group.
	 * </p>
	 *  
 	 * <p>
 	 * <h6>Starting and stopping VOIP audio in a room</h6>
 	 *	<listing>
	 *  &lt;session:ConnectSessionContainer 
	 * 			roomURL="http://connect.acrobat.com/exampleAccount/exampleRoom" 
	 * 			authenticator="{auth}"&gt;
	 * 			&lt;mx:VBox&gt;
	 *				&lt;collaboration:AudioPublisher id="audioPub"/&gt;
	 *				&lt;collaboration:AudioSubscriber/&gt;
	 * 				&lt;mx:Button label="Audio" toggle="true" id="audioButt" 
	 *				click="(audioButt.selected) ? audioPub.publish() : audioPub.stop()"/&gt;
	 * 			&lt;/mx:VBox&gt;
 	 *	&lt;/session:ConnectSessionContainer&gt;
	 * </listing>
	 * </p>
	 * @see com.adobe.rtc.collaboration.AudioPublisher
	 * @see com.adobe.rtc.sharedManagers.StreamManager
	 * @see com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor
	 */
	
   public class  AudioSubscriber extends EventDispatcher implements ISessionSubscriber
	{

		/**
		 * @private
		 */
		 protected var _streamManager:StreamManager;
		 
		 /**
		 * @private
		 */
		protected var _mic:Microphone;
		
		/**
		 * @private
		 * UserManager variable
		 */
		protected var _userManager:UserManager;
		
		/**
		 * @private
		 */
		protected var _audioStreamID:String;
		
		/**
		 * @private
		 */
		//protected var _stream:NetStream;
		
		/**
		 * @private
		 */
		protected var _netStreamTable:Object = new Object();
		
		/**
		 * @private
		 */
		protected var _streamDescriptorTable:Object = new Object();
		
		/**
		 * @private 
		 */
		protected var _publisherIDs:Array = new Array();
		
		/**
		 * @private 
		 */
		protected var _publisherIDTable:Object = new Object();

		/**
		 * @private
		 */
		protected var _groupName:String ;
		
		/**
		 * @private
		 */
		protected var _accessModel:int = -1 ;
		
		/**
		 * @private
		 */
		protected var _publishModel:int = -1 ;
		 
		 /**
		 * @private
		 */
		 protected const invalidator:Invalidator = new Invalidator();
		 
		 /**
		 * @private
		 */
		 protected var _sharedID:String;
		 
		 /**
		  * @private
		  */
		 protected var _subscribed:Boolean = false ;
		 
		 /**
		 * [read-only] returns the number of streams currently displayed by the subscriber.
		 */
		public var streamCount:int = 0;
		 
		 /**
		  * @private 
		  */		
		 protected var _connectSession:IConnectSession = ConnectSession.primarySession;
		 /**
		 * @private
		 */
		 protected var _connectionTypeChanged:Boolean = false ;
		  /**
		 * @private
		 */
		protected var _peerTimeoutTable:Object = new Object();	
		
		 
		 
		
		/**
		 * Constructor
		 */
		public function AudioSubscriber()
		{
			super();
			
			invalidator.addEventListener(Invalidator.INVALIDATION_COMPLETE,onInvalidate);
			
		}
		
		/**
		 * @private
		 */
		 
		
		
		/**
		 * Disposes of all listeners to the network and framework classes and assures the proper garbage collection of the component.
		 */
		public function close():void
		{
			_streamManager.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			_streamManager.removeEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onUserRoleChange);
			_streamManager.removeEventListener(StreamEvent.STREAM_DELETE,onStreamDelete);
			_streamManager.removeEventListener(StreamEvent.STREAM_PAUSE,onStreamMuted);
			_streamManager.removeEventListener(StreamEvent.VOLUME_CHANGE,onVolumeChanged);
			_streamManager.removeEventListener(StreamEvent.STREAM_RECEIVE, onStreamReceive);
			_streamManager.removeEventListener(StreamEvent.CONNECTION_TYPE_CHANGE,onConnectionTypeChange);
			
			
			for (var id:String in _streamDescriptorTable ) {
				deleteStream(_streamDescriptorTable[id]);
			}
		}

	
		/**
		 * @private
		 */
		public function set publisherIDs(p_publishers:Array):void
		{
			var tempNewPublisherTable:Object = new Object();
			
			// comparing the old list to the new list ...
			var i:int = 0 ;
			if ( StreamManager == null ) {
				_publisherIDs = p_publishers;
				var l:int = _publisherIDs.length;
				for (i=0; i<l; i++) {
					_publisherIDTable[_publisherIDs[i]] = true;
				}
			}else {
				for ( i= 0 ; i < p_publishers.length ; i++ ) {
					if ( _publisherIDTable[p_publishers[i]] == null ) {
						//_publisherIDTable[p_publishers[i]] = true ;
						if ( _streamManager.getStreamDescriptor(StreamManager.AUDIO_STREAM,p_publishers[i]) != null ){
							// we need to play only those that exists...
							playStream(p_publishers[i]);
						}
					}
					tempNewPublisherTable[p_publishers[i]] = true ;
					_publisherIDTable = tempNewPublisherTable;
				}
				
				for ( var id:String in _streamDescriptorTable ) {
					var remainingPublisher:String = (_streamDescriptorTable[id] as StreamDescriptor).streamPublisherID ;
					if ( tempNewPublisherTable[remainingPublisher] == null ) {
						deleteStream(_streamDescriptorTable[id]);
						delete _publisherIDTable[remainingPublisher] ;
					}
					
				}
				
				if ( _publisherIDs.length != p_publishers.length ) {
					dispatchEvent(new Event("numberOfStreamsChange"));
				}
				
				_publisherIDs = p_publishers ;
			}
		}
		
		/**
		 * Function for reseting and replaying all streams
		 */
		public function resetAllStreams():void
		{
			for(var id:String in _streamDescriptorTable){
				deleteStream(_streamDescriptorTable[id]);
 			}
 			playStreams();
		}
		
		
		public function resetStream(p_streamID:String):void
		{
			var streamPublisherID:String = _streamDescriptorTable[p_streamID].streamPublisherID ;
			deleteStream(_streamDescriptorTable[p_streamID]);
			playStream(streamPublisherID);
		}
		
		
		
		
		 /**
		 * An array of <code class="property">userIDs</code>, used for restricting the list of publishers 
		 * that this subscriber should play audio for. 
		 * If 0-length, all publishers' streams are played.
		 */
		public function get publisherIDs():Array
		{
			return _publisherIDs;
		}
		
		
		//[Bindable(event="synchronizationChange")]
		/**
		 * Returns whether or not the component is synchronized.
		 */
		public function get isSynchronized():Boolean
		{
			return _streamManager.isSynchronized ;
		}
		
		/**
		 * @private
		 */
		public function set groupName(p_groupName:String):void
		{
			if ( _groupName != p_groupName ) {
				// Set if group name and streamManager have not been initialized.
				if ( _streamManager == null ) {
					_groupName = p_groupName ;
					return ;
				}
				
				// Delete any existing stream when the room is changed.
				var streamDescriptors:Object=_streamManager.getStreamsOfType(StreamManager.AUDIO_STREAM,_groupName);
				for(var id:String in streamDescriptors){
					var streamDescriptor:StreamDescriptor = streamDescriptors[id];
					deleteStream(streamDescriptor);
 				}
				
				// After deleting the existing stream, go to change the groupName.
				_groupName = p_groupName ;
				
				// After the group name has been changed, we go ahead to play the streams in the newly given room.
				playStreams();
				invalidator.invalidate() ;	
			}
		}
		
		/**
		 * Components (pods) are assigned to a group via <code class="property">groupName</code>; if not specified, 
		 * the component is assigned to the default, public group (the room at large). Groups are like separate 
		 * conversations within the room, but each conversation could employ one or more pods; for example, one 
		 * "conversation" may use a web camera, chat, and whiteboard pod, with each pod using different access 
		 * and publish models. Users are members of and can only see components within the group they are assigned. 
		 * Room hosts can see all the groups and all the members in those groups.
		 */
		public function get groupName():String 
		{
			return _groupName ;
		}
		
		
		/**
		 * Gets the NodeConfiguration on a specific audio stream group. 
		 */
		public function getNodeConfiguration():NodeConfiguration
		{	
			return _streamManager.getNodeConfiguration(StreamManager.AUDIO_STREAM,_groupName).clone();
		}
		
		/**
		 * Sets the NodeConfiguration.
		 * @param p_nodeConfiguration The node Configuration of the group of Audio Stream.
		 * 
		 */
		public function setNodeConfiguration(p_nodeConfiguration:NodeConfiguration):void
		{	
			_streamManager.setNodeConfiguration(p_nodeConfiguration,StreamManager.AUDIO_STREAM,_groupName);
			
		}
		
		
		/**
		 * @private
		 */
		public function set publishModel(p_publishModel:int):void
		{	
			
			_publishModel = p_publishModel ;
			invalidator.invalidate() ;	
		}
		
		/**
		 * The role required for this component to publish to the group specified by <code class="property">groupName</code>. 
		 */
		public function get publishModel():int
		{
			return _streamManager.getNodeConfiguration(StreamManager.AUDIO_STREAM,_groupName).publishModel;
		}
		
		/**
		 * @private
		 */
		public function set accessModel(p_accessModel:int):void
		{	
			_accessModel = p_accessModel ;
			invalidator.invalidate() ;
		}
		
		/**
		 * The role value required for accessing audio streams for this component's group.
		 */
		public function get accessModel():int
		{
			return _streamManager.getNodeConfiguration(StreamManager.AUDIO_STREAM,_groupName).accessModel;
		}
		
		
		/**
		 * Gets the StreamInfo of the stream published by the .
		 */
		public function getNetStreamInfo(p_streamPublisherID:String):NetStreamInfo
		{
			var streamDesc:StreamDescriptor = _streamManager.getStreamDescriptor(StreamManager.AUDIO_STREAM,p_streamPublisherID,_groupName);
			if ( streamDesc != null && streamDesc.streamPublisherID != _userManager.myUserID) {
				return _netStreamTable[streamDesc.id].info ;
			}
			
			return null ;
		}
		
		/**
		 *  Returns the role of a given user for audio streams within this component's group.
		 * 
		 * @param p_userID The user ID of the user whose role we should get.
		 */
		public function getUserRole(p_userID:String):int
		{
			return _streamManager.getUserRole(p_userID,StreamManager.AUDIO_STREAM,_groupName);
		}
		
		/**
		 * Sets the role of a given user for subscribing to the component's group
		 * specified by <code class="property">groupName</code>.
		 * 
		 * @param p_userID The user ID of the user whose role should be set.
		 * @param p_userRole The role value to assign to the user with this user ID.
		 */
		public function setUserRole(p_userID:String ,p_userRole:int):void
		{
			if ( p_userID == null ) 
				return ;
				
			
			if ( (p_userRole < 0 || p_userRole > 100) && p_userRole != CollectionNode.NO_EXPLICIT_ROLE ) 
				return ; 
			
			
				
			_streamManager.setUserRole(p_userID,p_userRole,StreamManager.AUDIO_STREAM,_groupName);
		}
		
		/**
		 * Defines the logical location of the component on the service; typically this assigns the <code class="property">sharedID</code> of the collectionNode
		 * used by the component. <code class="property">sharedIDs</code> should be unique within a room if they're expressing two 
		 * unique locations. Note that this can only be assigned once before <code>subscribe()</code> is called. For components 
		 * with an <code class="property">id</code> property, <code class="property">sharedID</code> defaults to that value.
		 */
		public function set sharedID(p_id:String):void
		{
			_sharedID = p_id;
		}
		
		/**
		 * @private
		 */
		public function get sharedID():String
		{
			return _sharedID;
		}

		/**
		 * The IConnectSession with which this component is associated; 
		 * defaults to the first IConnectSession created in the application.
		 * Note that this may only be set once before <code>subscribe()</code>
		 * is called; re-sessioning of components is not supported.
		 */
		public function get connectSession():IConnectSession
		{
			return _connectSession;
		}
		
		public function set connectSession(p_session:IConnectSession):void
		{
			_connectSession = p_session;
		}
		
		/**
		 * Subscribes to a particular stream.
		 */
		public function subscribe():void
		{   			
			if ( !_streamManager) { 
				_streamManager = _connectSession.streamManager;	
			}
			
			_streamManager.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			_streamManager.addEventListener(StreamEvent.STREAM_RECEIVE, onStreamReceive);
			_streamManager.addEventListener(StreamEvent.STREAM_DELETE,onStreamDelete);
			_streamManager.addEventListener(StreamEvent.STREAM_PAUSE,onStreamMuted);
			_streamManager.addEventListener(StreamEvent.VOLUME_CHANGE,onVolumeChanged);
			_streamManager.addEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onUserRoleChange);
			_streamManager.addEventListener(StreamEvent.CONNECTION_TYPE_CHANGE,onConnectionTypeChange);
			
   			if ( ! _userManager ) {
   				_userManager = _connectSession.userManager;
   			}
   			
   			if (_streamManager.isSynchronized && _userManager.isSynchronized) {
   				playStreams();
   				// invalidateDisplayList();
   			}
		}
		
		/**
		 * @private
		 *
		 *  Plays the streams. If the user has provided a set of streams, it compares them with 
		 * 	the streams in streamManager and if they are available, plays them.
		 *  If the user has not provided any stream, then it plays all the streams available in the streamManager.
		 */
		protected function playStreams():void
		{
			
				var streamDescriptors:Object=_streamManager.getStreamsOfType(StreamManager.AUDIO_STREAM,_groupName);
				var id:String;
				var streamDescriptor:StreamDescriptor;
			
				for( id in streamDescriptors){
					 streamDescriptor=streamDescriptors[id];
					 if (shouldDisplayStream(streamDescriptor)  && streamDescriptor.finishPublishing) {
					 	if ( _userManager.myUserID != streamDescriptor.streamPublisherID || _publisherIDs.length !=0 )
							playStream(streamDescriptor.streamPublisherID); 
					 }
				}
				
				_connectionTypeChanged = false ;
				
		}
		
		/**
		 *  @private 
		 */
		protected function shouldDisplayStream(p_desc:StreamDescriptor):Boolean
		{
			return (_publisherIDs.length==0 || _publisherIDTable[p_desc.streamPublisherID]==true);
		}
		
		/**
		 * Sets the volume level of the Stream published by the specific publisher.
		 * 
		 * @param p_streamPublisherID The user ID of the publisher whose stream's volume is set.
		 * @param p_volume The volume, between 0 and 1: 0 for silent 1 for full volume.
		 */
		public function setLocalVolume( p_volume:Number , p_streamPublisherID:String = null):void
		{
			// Volume can be only between 0 and 1: 0 for silent and 1 for maximum.
			if ( p_volume > 1 || p_volume < 0 ) {
				return ;
			}
			
			var soundTransform:SoundTransform;
			// If the publisher ID is null, return.
			if ( p_streamPublisherID == null ) {
				for ( var id:String in _netStreamTable ) {
					soundTransform = (_netStreamTable[id] as NetStream).soundTransform ;
					soundTransform.volume = p_volume ;
					(_netStreamTable[id] as NetStream).soundTransform = soundTransform ;
				}
				
			}else {
			
				// Stream descriptors.
				var streamDescriptor:StreamDescriptor = _streamManager.getStreamDescriptor(StreamManager.AUDIO_STREAM,p_streamPublisherID,_groupName);
				
				// If the descriptor is null, just return.
				if ( streamDescriptor == null || _netStreamTable[streamDescriptor.id]== null ) 
					return ;
			
				soundTransform = (_netStreamTable[streamDescriptor.id] as NetStream).soundTransform ;
				soundTransform.volume = p_volume ;
				(_netStreamTable[streamDescriptor.id] as NetStream).soundTransform = soundTransform ;
			}
		}
		
		/**
		 * Plays the audio stream with the given stream <code class="property">publisherID</code>
		 * 
		 * @param p_streamPublisherID The publisher of the stream.
		 */
		public function playStream(p_streamPublisherID:String ):void
		{
			// Only playing those streams that are not being played currently.
			var streamDescriptor:StreamDescriptor = _streamManager.getStreamDescriptor(StreamManager.AUDIO_STREAM,p_streamPublisherID,_groupName);
			if ( streamDescriptor != null ) {
				var stream:NetStream ;
				_streamDescriptorTable[streamDescriptor.id] = streamDescriptor;
				if ( _netStreamTable[streamDescriptor.id] == null ) {
					_netStreamTable[streamDescriptor.id] = createNetStream(streamDescriptor);		
            		_netStreamTable[streamDescriptor.id].addEventListener(NetStatusEvent.NET_STATUS,onNetStatus);
					if(streamDescriptor.mute){
						_netStreamTable[streamDescriptor.id].close();
					}
            		streamCount++ ;  
	   			} else {
					if ( _connectionTypeChanged ) {
	   					_netStreamTable[streamDescriptor.id].close();
	   					delete _netStreamTable[streamDescriptor.id] ;
	            		_netStreamTable[streamDescriptor.id]= createNetStream(streamDescriptor);
	            		_netStreamTable[streamDescriptor.id].addEventListener(NetStatusEvent.NET_STATUS,onNetStatus);
	            		if(streamDescriptor.mute){
							_netStreamTable[streamDescriptor.id].close();
						}
	       			}
	   			}
	  		}
				    	
		}
		
		
		/**
		 *  @private
		 *
		 *	Plays the stream with the given stream ID. 
		 */
		public function deleteStream (p_streamDescriptor:StreamDescriptor):void
		{
			if ( _streamDescriptorTable[p_streamDescriptor.id] != null ) {
				_netStreamTable[p_streamDescriptor.id].close();		
				delete _netStreamTable[p_streamDescriptor.id];
				delete _streamDescriptorTable[p_streamDescriptor.id] ;
				delete _peerTimeoutTable[p_streamDescriptor.id] ;
				streamCount-- ;
			}
		}
		
		/**
		 *  @private 
		 *
		 *  Handles the stream receive events listening to the stream manager model.
		 */
		protected function onStreamReceive(p_evt:StreamEvent):void
		{	
			var streamDescriptor:StreamDescriptor;
			var playStream:Boolean=false;
			streamDescriptor = p_evt.streamDescriptor ;
			if ( streamDescriptor==null || (streamDescriptor.groupName && streamDescriptor.groupName != _groupName) ) {
				return ;
			} 
			
			if (!shouldDisplayStream(streamDescriptor)) {
				// Don't display the stream if it is not in the list.
				return;
			}
			if(	streamDescriptor.finishPublishing &&
				_userManager.myUserID !=p_evt.streamDescriptor.streamPublisherID &&
				streamDescriptor.type == StreamManager.AUDIO_STREAM){
					
            		this.playStream(streamDescriptor.streamPublisherID);
            		dispatchEvent(p_evt);
			}
		}
		
		/**
		 * @private
		 * 
		 * Handles the stream delete event listening to the stream manager model.
		 */
		protected function onStreamDelete(p_evt:StreamEvent):void
		{
			var streamDescriptor:StreamDescriptor=p_evt.streamDescriptor;
			
			if ( streamDescriptor==null || (streamDescriptor.groupName && streamDescriptor.groupName != _groupName) ) {
				return ;
			} 
			
			if (!shouldDisplayStream(streamDescriptor)) {
				// Don't display the stream if it is not in the list.
				return;
			}
			
			if(streamDescriptor!=null && streamDescriptor.finishPublishing){
				if(streamDescriptor.type==StreamManager.AUDIO_STREAM && _userManager.myUserID!=p_evt.streamDescriptor.streamPublisherID){
					deleteStream(streamDescriptor);
					dispatchEvent(p_evt);
    			}
            }
		}
		/**
		 * @private
		 * 
		 * Handles the stream muted event listening to the stream manager model.
		 */
		protected function onStreamMuted(p_evt:StreamEvent):void
		{
			var streamDescriptor:StreamDescriptor=p_evt.streamDescriptor;
			
			if ( streamDescriptor==null || (streamDescriptor.groupName && streamDescriptor.groupName != _groupName) ) {
				return ;
			} 
			
			if (!shouldDisplayStream(streamDescriptor)) {
				// Don't display the stream if it is not in the list.
				return;
			}
			
			if(	streamDescriptor.type == StreamManager.AUDIO_STREAM && 
				_userManager.myUserID != p_evt.streamDescriptor.streamPublisherID &&
				streamDescriptor.finishPublishing){
					if(streamDescriptor.mute){
						_netStreamTable[p_evt.streamDescriptor.id].close();
					}
					else{
						_netStreamTable[p_evt.streamDescriptor.id].play(p_evt.streamDescriptor.id);	
					}
					dispatchEvent(p_evt);	
			}
		}
		
		/**
		 * @private
		 * 
		 * Handles the stream volume change event listening to the stream manager model.
		 */
		protected function onVolumeChanged(p_evt:StreamEvent):void
		{
			var streamDescriptor:StreamDescriptor=p_evt.streamDescriptor;
			
			if ( streamDescriptor==null || (streamDescriptor.groupName && streamDescriptor.groupName != _groupName) ) {
				return ;
			} 
			
			if (!shouldDisplayStream(streamDescriptor)) {
				// Don't display the stream if it is not in the list.
				return;
			} 
			
			if(	streamDescriptor.type==StreamManager.AUDIO_STREAM && 
				_userManager.myUserID!=p_evt.streamDescriptor.streamPublisherID &&
				streamDescriptor.finishPublishing){
				
				_streamDescriptorTable[streamDescriptor.id].volume = streamDescriptor.volume;
				dispatchEvent(p_evt);
			}
		}
		/**
		 * @private
		 */
		protected function onInvalidate(p_evt:Event):void
        {
        	if ( _publishModel != -1 || _accessModel != -1 ) {
				var nodeConf:NodeConfiguration = _streamManager.getNodeConfiguration(StreamManager.AUDIO_STREAM,_groupName);
				
				if ( nodeConf.accessModel != _accessModel && _accessModel != -1 ) {
					nodeConf.accessModel = _accessModel ;
					_accessModel = -1 ;
				}
			
				if ( nodeConf.publishModel != _publishModel && _publishModel != -1 ) {
					nodeConf.publishModel = _publishModel ;
					_publishModel = -1 ;
				}
				
				_streamManager.setNodeConfiguration(nodeConf,StreamManager.AUDIO_STREAM,_groupName);	
						
			}
        }
		
		/**
		 * @private
		 */
		protected function onSynchronizationChange(p_evt:CollectionNodeEvent):void
		{
			if ( _streamManager && _streamManager.isSynchronized ) {
				var sessionManager:SessionManagerBase = _connectSession.sessionInternals.session_internal::sessionManager;
				sessionManager.addEventListener(NetStatusEvent.NET_STATUS,onNetStatus);
			} else {
				for (var id:String in _streamDescriptorTable ) {
					deleteStream(_streamDescriptorTable[id]);
				}
			}
			dispatchEvent(p_evt);	
		}
		
		/**
		 * @private
		 */
		protected function onUserRoleChange(p_evt:CollectionNodeEvent):void
		{
			dispatchEvent(p_evt);	// Bubble it up.
		}

		/**
		 * @private
		 */
		public function onMetaData(info:Object):void
		{
			
		}

		/**
		 * Handler when the connection type changes 
		 * @private
		 */
		protected function onConnectionTypeChange(p_evt:StreamEvent):void
		{
			_connectionTypeChanged = true ;
			playStreams();
			dispatchEvent(p_evt);
		}
		
		/**
		 * @private
		 */
		protected function onPeerTimeout(p_evt:TimerEvent):void
		{
		 	// Peer to peer connection fails , and hence we switch back to the hub and spoke connection...
		 	var userDesc:UserDescriptor = _userManager.getUserDescriptor(_userManager.myUserID) ;
		 	
		 	for (var id:String in _peerTimeoutTable ) {
		 		if ( _peerTimeoutTable[id] == p_evt.currentTarget ) {
		 			_peerTimeoutTable[id].removeEventListener(TimerEvent.TIMER_COMPLETE,onPeerTimeout);
		 			delete _peerTimeoutTable[id] ;
					DebugUtil.debugTrace("Peer to peer connection failed and timed out in Audio for user " + _userManager.getUserDescriptor(_userManager.myUserID).displayName);
					if ( userDesc.isPeer ) {
						_userManager.setPeer(_userManager.myUserID,false);
					}
		 			break ;
		 		}
		 	}
		 	
		 	
		} 
		
		/**
		 * @private
		 */
		protected function onNetStatus(e:NetStatusEvent):void
		{
			// The peer to peer stream connection is successful....
			if (e.info.code == "NetStream.Play.Start" || e.info.code == "NetStream.Play.PublishNotify" || e.info.code == "NetStream.MulticastStream.Reset")
			{
				var stream:NetStream = e.currentTarget as NetStream ;
			 	for (var id:String in _netStreamTable ) {
			 		if ( _netStreamTable[id] == stream && _peerTimeoutTable[id]) {
			 			_peerTimeoutTable[id].stop();
			 			_peerTimeoutTable[id].removeEventListener(TimerEvent.TIMER_COMPLETE,onPeerTimeout);
			 			delete _peerTimeoutTable[id] ;	
			 			break ; 		
			 		}
			 	}
			}
			
			var streamDesc:StreamDescriptor ;
			for ( var streamID:String in _netStreamTable ) {
				if ( _netStreamTable[streamID] == e.currentTarget ) {
					streamDesc = _streamDescriptorTable[streamID] as StreamDescriptor ;
				}
			}
			
			if ( streamDesc )
				dispatchEvent(new StreamStatusEvent(StreamStatusEvent.STREAM_STATUS,e.info.code,streamDesc.streamPublisherID));
			else 
				dispatchEvent(new StreamStatusEvent(StreamStatusEvent.STREAM_STATUS,e.info.code));
			
		}
		
		
		/**
		 * @private
		 */
		protected function createNetStream(p_streamDesc:StreamDescriptor):NetStream
	    {
	    	var stream:NetStream ;
	    	var connection:NetConnection = _connectSession.sessionInternals.session_internal::connection as NetConnection ;
			var sessionManager:SessionManagerBase = _connectSession.sessionInternals.session_internal::sessionManager;
	    	if ( _streamManager.isP2P && !connectSession.archiveManager.isPlayingBack) {
				
					stream = sessionManager.session_internal::getAndPlayAVStream(p_streamDesc.id, p_streamDesc.peerID);
					if ( _peerTimeoutTable[p_streamDesc.id] == null ) {
						// while switching from hub-spoke to p2p , we need to check if the user is behind firewall
						// since when this user might have entered , if it had already switched to hub-spoke, his isPeer might have remained true
						_peerTimeoutTable[p_streamDesc.id] = new Timer(8000,1);
						_peerTimeoutTable[p_streamDesc.id].addEventListener(TimerEvent.TIMER_COMPLETE,onPeerTimeout);
						_peerTimeoutTable[p_streamDesc.id].start();
					}
					
			}else { 
				stream = sessionManager.session_internal::getAndPlayAVStream(p_streamDesc.id);
       		}
       		
       		return stream ;
	    }
	}

}
