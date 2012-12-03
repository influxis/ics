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
	import com.adobe.rtc.clientManagers.MicrophoneManager;
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.events.AudioConfigurationEvent;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.ConnectSessionEvent;
	import com.adobe.rtc.events.StreamEvent;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
	import com.adobe.rtc.sharedManagers.StreamManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.constants.UserVoiceStatuses;
	import com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor;
	import com.adobe.rtc.sharedModel.CollectionNode;
	import com.adobe.rtc.util.Invalidator;
	
	import flash.events.ActivityEvent;
	import flash.events.Event;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.media.Microphone;
	import flash.media.SoundCodec;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.NetStreamInfo;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.utils.Timer;
	
	import mx.core.UIComponent;
	import mx.core.UIComponentGlobals;
	
	
	/**
	 * Dispatched when the component either loses its connection to the session or regains it
	 * and has finished re-synchronizing itself to the rest of the room.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	

	/**
	 * Dispatched when the user's role with respect to the component changes.
	 */
	[Event(name="userRoleChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	
	
	/**
	 * Dispatched when the current user's audio stream is about to be published by the component.
	 */
	[Event(name="streamReceive", type="com.adobe.rtc.events.StreamEvent")]
	
	/**
	 * Dispatched when the current user's audio stream stops publishing.
	 */
	[Event(name="streamDelete", type="com.adobe.rtc.events.StreamEvent")]	

	/**
	 * Dispatched when the current user's audio stream is paused.
	 */
	[Event(name="streamPause", type="com.adobe.rtc.events.StreamEvent")]
	
	/**
	 * Dispatched when the current user is publishing or stops publishing.
	 */
	[Event(name="streamPublishing", type="com.adobe.rtc.events.StreamEvent")]	
	
	/**
	 * Dispatched when the current user's gain is changed.
	 */
	[Event(name="gainChanged", type="com.adobe.rtc.events.AudioConfigurationEvent")]
	
	/**
	 * Dispatched when the current user's silence level is changed.
	 */
	[Event(name="silenceLevelChanged", type="com.adobe.rtc.events.AudioConfigurationEvent")]	

	/**
	 * Dispatched when the current user's echo suppression is changed.
	 */
	[Event(name="echoSuppressionChanged", type="com.adobe.rtc.events.AudioConfigurationEvent")]
	
	/**
	* Dispatched when a user changes whether they are publishing audio or not.
	*/
	[Event(name="isAudioPublishing", type="flash.events.Event")]

	/**
	 * AudioPublisher is the collaboration component responsible for publishing VOIP audio to others 
	 * in the room. It acts as an intermediary between the Microphone/NetStream and StreamManager and 
	 * is responsible for publishing audio StreamDescriptors to the StreamManager so that AudioSubscribers 
	 * in the room are aware a new stream has been initiated. 
	 * <p>
	 * In order to improve workflow, it provides an API through which to request other users to begin publishing their audio 
	 * (<code class="property">publish</code> with an optional parameter). It also listens for remote requests 
	 * for the user to begin publishing and prompts the user to begin when needed. The AudioPublisher 
	 * has no user interface of its own, but it does provide a basic API through which any commands 
	 * concerning publishing VOIP audio should be routed.
	 * 
	 * <p> Like all stream components, AudioPublisher has an API for setting and getting a <code class="property">groupName</code>. 
	 * This property can be used to create multiple VOIP groups, each being separate and having different access/publish models, 
	 * allowing for multiple private conversations. For a subscriber to listen to a particular VOIP stream from a publisher, 
	 * both should have the same assigned <code class="property">groupName</code>.
	 * If no <code class="property">groupName</code> is assigned, the publisher defaults to publishing into the public group.
	 * </p>
	 * 
	 * <p>
	 * By default, only users with the role <code>UserRoles.PUBLISHER</code> or greater may publish audio, 
	 * and all users with role of greater than <code>UserRoles.VIEWER</code> are able to subscribe to these streams.
 	 * <p>
 	 * <h6>Starting and stopping VOIP audio in a room</h6>
 	 *	<listing>
	 *  &lt;session:ConnectSessionContainer 
	 * 			roomURL="http://connect.acrobat.com/exampleAccount/exampleRoom" 
	 * 			authenticator="{auth}"&gt;
	 * 			&lt;mx:VBox&gt;
	 *	&nbsp;&nbsp;&nbsp;			&lt;collaboration:AudioPublisher id="audioPub"/&gt;
	 *	&nbsp;&nbsp;&nbsp;			&lt;collaboration:AudioSubscriber/&gt;
	 * 	&nbsp;&nbsp;&nbsp;			&lt;mx:Button label="Audio" toggle="true" id="audioButt" 
	 *			click="(audioButt.selected) ? audioPub.publish() : audioPub.stop()"/&gt;
	 * 			&lt;/mx:VBox&gt;
 	 *	&lt;/session:ConnectSessionContainer&gt;
	 * </listing>
	 * </p>
	 * 
	 * @see com.adobe.rtc.collaboration.AudioSubscriber
	 * @see com.adobe.rtc.sharedManagers.StreamManager
	 * @see com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor
	 */
	
   public class  AudioPublisher extends UIComponent implements ISessionSubscriber
	{
		/**
		 * @private
		 */
		 protected var _streamManager:StreamManager;
		 
		/**
		 * @private
		 */
		 public var microphoneManager:MicrophoneManager;
		 
		 /**
		 * @private
		 */
		protected var _mic:Microphone;
		
		 /**
		 * @private
		 * Muted variable
		 */
		protected var _isMuted:Boolean = false;
				
		/**
		 * @private
		 * Netstream variable
		 */
		protected var _stream:NetStream;
		
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
		protected var _uniqueStreamID:String = null ;
		
		/**
		* @private
		*/		
		protected var _associatedUserID:String = null;
		
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
		 protected var _silenceTimeout:int = 2000 ;
		
		 /**
		 * @private
		 */
		 protected var _silenceTimeoutChanged:Boolean = false ; 
		
		 /**
		 * @private
		 */
		protected var _gain:Number =  50;
		
		/**
		 * @private
		 */
		 protected var _gainChanged:Boolean = true ;
		
		 /**
		 * @private
		 */
		 protected var _useEchoSuppression:Boolean = false ;
		 
		 /**
		 * @private
		 */
		 protected var _useEchoSuppressionChanged:Boolean = false ;
		 
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
		  * @private 
		  */		
		 protected var _connectSession:IConnectSession = new SessionContainerProxy(this as UIComponent);
		  /**
		 * @private
		 */
		 protected var _recipientIDs:Array ;
		
		 /**
		 * @private
		 */
		protected var _peerTimeout:Timer = new Timer(7000,1);	
		/**
		 * @private
		 */
		protected var activityTimer:Timer = new Timer(700,1);
		/**
		 * @private
		 */
		protected var _cameraDenied:Boolean = false ;
		 /**
		 * @private
		 */
		 protected var _startRollingWindow:Boolean = false ;
		 /**
		 * @private
		 */
		 protected var _volActivityCount:Number = 0 ;
		 /**
		 * @private
		 */
		 protected static const TOTAL_POLLING_TIME:Number = 7500 ;
		 /**
		 * @private
		 */
		 protected static const INTERVAL_DURATION:Number = 500 ;
		 /**
		 * @private
		 */
		 protected var _pollIntervalTimer:Timer = new Timer(INTERVAL_DURATION,1);
		 /**
		 * @private
		 */
		 protected var _activityArray:Array = new Array(15);
		 /**
		 * @private
		 */
		 protected var _gainControl:Boolean = false ;
		 /**
		 * @private
		 */
		 protected var _multicastWindowDuration:Number = 4 ;
		
		/**
		 * Constructor
		 */
		public function AudioPublisher()
		{
			super();
			
			invalidator.addEventListener(Invalidator.INVALIDATION_COMPLETE,onInvalidate);
		}

		
		/**
		 * @private
		 */
				 
		override protected function createChildren():void
		{
			super.createChildren();
			
			if ( !_subscribed ) {
				subscribe();
				_subscribed = true ;
			}
		}
		 
		
		[Bindable(event="isAudioPublishing")]
		/**
		 * Returns true if my audio is publishing; false if not.
		 */
		public function get isPublishing():Boolean
		{
			return (_audioStreamID!=null);
		}
		
		
		[Bindable(event="streamPause")]
		/**
		 * Returns true if my audio is paused; false if not or audio is not there.
		 */
		public function get isPaused():Boolean
		{
			return _isMuted;
		}
		
		/**
		 * Returns the Microphone object associated with this publisher.
		 */
		public function get microphone():Microphone
		{
			return _mic;
		}
		
			[Bindable]
		/**
		 * Sets the silence level of the microphone associated with this publisher.
		 *
		 * @param p_silenceLevel
		 */
		public function set silenceLevel(p_silenceLevel:Number):void
		{
			// no op
		}
		
		/**
		 * @private
		 */
		public function get silenceLevel():Number
		{
			if ( _mic ) {
				return _mic.silenceLevel ; 
			}
			
			return 10 ;
		}
		
		
		
		/**
		 * Sets the silence timeout of the publisher's microphone.
		 *
		 * @param p_silenceLevel
		 */
		public function set multicastWindowDuration(p_multicastWindowDuration:int):void
		{
			if ( p_multicastWindowDuration == _multicastWindowDuration ) 
				return ;
				
			_multicastWindowDuration = p_multicastWindowDuration ;
			
			if ( _stream ) {
				_stream.multicastWindowDuration = _multicastWindowDuration ;
			}
		}
		
		/**
		 * @private
		 */
		public function get multicastWindowDuration():int
		{
			return _multicastWindowDuration ;
		}
		
		
		
		/**
		 * Sets the silence timeout of the publisher's microphone.
		 *
		 * @param p_silenceLevel
		 */
		public function set silenceTimeout(p_silenceTimeout:int):void
		{
			if ( _silenceTimeout == p_silenceTimeout ) 
				return ;
				
			_silenceTimeout = p_silenceTimeout ;
			
			_silenceTimeoutChanged = true ;
			invalidator.invalidate();
		}
		
		/**
		 * @private
		 */
		public function get silenceTimeout():int
		{
			return _silenceTimeout ;
		}
		
		[Bindable]
		/**
		 * The microphone gain that is the amount by which the microphone should multiply the signal before transmitting it.
		 *
		 * @param p_gain a number between 1 and 100.
		 */
		public function set gain(p_gain:Number):void
		{
			if ( _gain == p_gain ) 
				return ;
			
			_gain = p_gain ;
			_gainChanged = true ;
			invalidator.invalidate();
		}
		
		
		/**
		 * @private
		 */
		public function get gain():Number
		{
			microphoneManager = MicrophoneManager.getInstance();
			if (!_gainChanged) {
				_gain = microphoneManager.gain ;
			}
			return _gain;
		}
		
		
		
		[Bindable]
		/**
		 * The microphone gain control defaults to false
		 *
		 * @param p_gainControl true or false.
		 */
		public function set gainControl(p_gainControl:Boolean):void
		{
			if ( _gainControl == p_gainControl ) 
				return ;
			
			_gainControl = p_gainControl ;
			

			if ( _audioStreamID && _gainControl) {
				_pollIntervalTimer.addEventListener(TimerEvent.TIMER_COMPLETE,onMaxVolPollTimerComplete);
				_pollIntervalTimer.start();	
			}else if ( !_gainControl ) {
				_pollIntervalTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,onMaxVolPollTimerComplete);
				_pollIntervalTimer.stop();	
			}
		}
		
		
		/**
		 * @private
		 */
		public function get gainControl():Boolean
		{
			return _gainControl ;
		}
		
		[Bindable]
		[Inspectable(enumeration="false,true", defaultValue="false")]
		/**
		 * true if echo suppression is enabled; false otherwise.
		 *
		 * @param p_echoSuppression
		 */
		public function set useEchoSuppression(p_useEchoSuppression:Boolean):void
		{
			if ( _useEchoSuppression == p_useEchoSuppression ) 
				return ;
			
			_useEchoSuppression = p_useEchoSuppression;
			_useEchoSuppressionChanged = true ;
			invalidator.invalidate();
		}
		
		
		/**
		 * @private
		 */
		public function get useEchoSuppression():Boolean
		{
			return _useEchoSuppression ;
		}
		
		[Bindable(event="synchronizationChange")]
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
				if ( _streamManager == null ) {
					_groupName = p_groupName ;
					return ;
				}
				
				// If I am publishing and I am placed in a different group, then stop my stream.
				if ( isPublishing ) {
					stop();
				}
				// Assign the new groupName.
				_groupName = p_groupName ;
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
		 * Returns the NetStreamInfo for the audio stream published by the publisher
         */
		 public function get netStreamInfo():NetStreamInfo
         {
			if ( _stream ) {
				return _stream.info ;
			}
			return null ;
		}
		
		/**
		 * Array of Recipient UserIDs for audio streams published by this user.
		 * Throws an error while setting this property if Private Streaming is not allowed i.e. allowPrivateStreams property is false in StreamManager.
		 * Throws an error while setting this property if the Audio Stream for this user is currently published. Stop the stream and then set this property.
		 * Set this property to null if you want to broadcast your audio stream to everyone. This is also the default case.
		 * 
		 * @default null
		 */
		public function get recipientIDs():Array
		{
			return _recipientIDs ;	
		}
		/**
		 * @private
		 */
		public function set recipientIDs(p_recipientIDs:Array):void
		{
			if ( isPublishing ) {
				throw new Error("The audio stream is currently publishing. Stop the stream and then set RecipientIDs.");
				return ;
			}
			
			if ( p_recipientIDs == null ) {
				_recipientIDs = null ;
				return ;
			}
			
			if ( !_streamManager.allowPrivateStreams ) {
				throw new Error("Private Streaming is not allowed inside the room.");
				return ;
			}
			
			_recipientIDs = p_recipientIDs ;
		}
		
		
		/**
		 * Gets the NodeConfiguration that defines message permissions and storage policies for the current stream group.
		 */
		public function getNodeConfiguration():NodeConfiguration
		{	
			return _streamManager.getNodeConfiguration(StreamManager.AUDIO_STREAM,_groupName).clone();
		}
		
		/**
		 * Sets the NodeConfiguration that defines message permissions and storage policies for the current stream group.
		 * 
		 * @param p_nodeConfiguration The current stream groups node configuration.
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
		 * The role value required for access to audio streams for this component's group.
		 */
		public function get accessModel():int
		{
			return _streamManager.getNodeConfiguration(StreamManager.AUDIO_STREAM,_groupName).accessModel;
		}
		
		/**
		 *  Returns the given stream publisher or subscriber's user role within the stream's group.
		 * 
		 * @param p_userID The user ID of the user whose role we should get.
		 */
		public function getUserRole(p_userID:String):int
		{
			return _streamManager.getUserRole(p_userID,StreamManager.AUDIO_STREAM,_groupName);
		}
		
		/**
		 * Sets the user role that enables publishing to the component's group specified by the <code class="property">groupName</code>. 
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
		 * The IConnectSession with which this component is associated; it defaults to the first 
		 * IConnectSession created in the application.  Note that this may only be set once before 
		 * <code>subscribe()</code> is called, and re-sessioning of components is not supported.
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
		 * Tells the component to begin synchronizing with the service. For UIComponent-based components such as this one,
		 * this is called automatically upon being added to the <code class="property">displayList</code>. 
		 * For "headless" components, this method must be called explicitly.
		 */
		public function subscribe():void
		{
			if ( !_streamManager) {
				_streamManager = _connectSession.streamManager;
				//adding the event listeners 
				_connectSession.addEventListener(ConnectSessionEvent.CLOSE, onSessionClose);
				_streamManager.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
				_streamManager.addEventListener(StreamEvent.STREAM_RECEIVE, onStreamReceive);
				_streamManager.addEventListener(StreamEvent.STREAM_DELETE,onStreamDelete);
				_streamManager.addEventListener(StreamEvent.STREAM_PAUSE,onStreamMuted);
				_streamManager.addEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onUserRoleChange);
				_streamManager.addEventListener(StreamEvent.CONNECTION_TYPE_CHANGE,onConnectionTypeChange);
				_streamManager.addEventListener(StreamEvent.CODEC_CHANGE,onCodecChange);
			}
						
			if ( !_userManager ) {
				_userManager = _connectSession.userManager;
			}
			
			
			
			invalidator.invalidate();
		}
		
		
		/**
		 * Begins publishing the stream for the user identified by <code class="property">p_publisherID</code> after prompting the user. 
		 * If the user declines to publish on the first prompt, subsequent attempts to publish invoke a dialog 
		 * that allows the user to change their publish settings. If the user accepts, it notifies other users through the StreamManager
		 * of the new audio stream and begins streaming to the room for consumption by participating subscribers. 
		 * It may also be optionally used for requesting a remote user of a particular <code class="property">p_publisherID</code>.
		 * 
		 * @param p_publisherID Defaults to null and therefore the current user. If non-null, the parameter requests 
		 * the specified user to begin. Note that only a user with role of owner may request others to publish.
		 * 
		 * @see com.adobe.rtc.sharedManagers.StreamManager
		 */		
		public function publish(p_publisherID:String = null):void
		{
			// If null, the StreamManager will turn it into userID+type
			// since the audio publisher doesn't have any children and we 
			// publish immediately after creating, then we need to validate 
			// the properties first to get the stream manager.
			if ( connection == null ) {
				return ; // if there is no netconnection, just return.
			}
			
			if ( !_subscribed ) {
				subscribe();
				_subscribed = true ;
			}

			_associatedUserID = p_publisherID;
			
			if ( _groupName != null && !_streamManager.isGroupDefined(_groupName)) {
				// For users creating a group and immediately publishing to it.
				if( _mic ==null ){
					createStream(p_publisherID);
				}else{
					if ( !_mic.muted ) {
						_streamManager.publishStream(StreamManager.AUDIO_STREAM,p_publisherID,_groupName,_recipientIDs);
					}else {
						Security.showSettings();
					}
				}
			}else {
				var nodeConfiguration:NodeConfiguration = _streamManager.getNodeConfiguration(StreamManager.AUDIO_STREAM,_groupName);
				if ( nodeConfiguration != null ) {
					if (_streamManager.getUserRole(_userManager.myUserID,StreamManager.AUDIO_STREAM,_groupName) >= nodeConfiguration.publishModel ){
						if( _mic ==null ){
							createStream(p_publisherID);
						}else{
							if ( !_mic.muted ) {
								_streamManager.publishStream(StreamManager.AUDIO_STREAM,p_publisherID,_groupName,_recipientIDs);
							}
						}	
					} else {
						throw new Error("AudioPublisher: The stream cannot be published because user does not have permission.");
					}
				}
			}
		}
		
		/**
		 * Pauses or unpauses the stream specified by p_publisherID; defaults to the current user's stream.
		 * Dispatches a notification event that can be used to notify room members that the streams state has changed.
		 * 
		 * @param p_pause True to pause; false to play.
		 * @param p_publisherID An optional user ID of the user whose stream pause state should change; otherwise, if null,
		 * the current user's stream.
		 * 
		 */
		public function pause(p_mute:Boolean = false , p_publisherID:String = null ):void
		{
			if ( _streamManager.getUserRole(_userManager.myUserID,StreamManager.AUDIO_STREAM,_groupName) >= _streamManager.getNodeConfiguration(StreamManager.AUDIO_STREAM).publishModel ){
				if ( p_publisherID ) {
					_streamManager.muteStream(StreamManager.AUDIO_STREAM, p_mute, p_publisherID,_groupName,_recipientIDs);
				} else {
					_streamManager.muteStream(StreamManager.AUDIO_STREAM, p_mute ,_userManager.myUserID,_groupName,_recipientIDs);
				}
			} else {
				throw new Error("AudioPublisher: The stream's pause state cannot be changed because the user does not have permission.");
			} 
		}
		
		/**
		 * Stops publishing the stream published by the user identified by p_publisherID; if the ID is null, it defaults to the current user's stream.
		 * 
		 * @param p_publisherID The user ID of the user whose stream should be stopped. Defaults to the 
		 * current user. Only a room owner can stop a remote user's stream.
		 */		
		public function stop(p_publisherID:String = null ):void
		{			
			if (_streamManager.getUserRole(_userManager.myUserID,StreamManager.AUDIO_STREAM,_groupName) >= _streamManager.getNodeConfiguration(StreamManager.AUDIO_STREAM).publishModel ){
				if ( p_publisherID ) {
					_streamManager.deleteStream(StreamManager.AUDIO_STREAM, p_publisherID,_groupName);
				} else {
					_streamManager.deleteStream(StreamManager.AUDIO_STREAM,_userManager.myUserID , _groupName);
				}
			} else {
				throw new Error("AudioPublisher: The stream cannot be deleted because user does not have permission.");
			} 
		}
	
		
		/**
		 * @private
		 * 
		 * Returns the Netconnection.
		 */
		protected function get connection():NetConnection
		{
			return _connectSession.sessionInternals.session_internal::connection as NetConnection;
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
			// Handles when stream is received	
			
			microphoneManager = MicrophoneManager.getInstance();		
			streamDescriptor=_streamManager.getStreamDescriptor(p_evt.streamDescriptor.type,p_evt.streamDescriptor.streamPublisherID,p_evt.streamDescriptor.groupName);	
			
			if ( streamDescriptor.groupName && streamDescriptor.groupName != _groupName ) {
				return ;
			} 
			
			if( streamDescriptor!=null &&
				_userManager.myUserID==p_evt.streamDescriptor.streamPublisherID &&
				 streamDescriptor.type==StreamManager.AUDIO_STREAM	){
					if(_mic==null){
						_mic = microphoneManager.selectedMic; 
						if ( _mic != null ) {
							_stream = createNetStream();
                			_stream.attachAudio(_mic);                			
							_mic.addEventListener(StatusEvent.STATUS,statusHandler);
							if ( !_mic.muted ) {
								// publishes on the stream again
                    			_streamManager.publishStream(streamDescriptor.type,streamDescriptor.streamPublisherID,streamDescriptor.groupName,_recipientIDs);		
							}else {
								if ( _streamManager.camAudioPermissionDenied ) {
									Security.showSettings(SecurityPanel.PRIVACY);
								}
							}
						} else {							
							_streamManager.deleteStream(StreamManager.AUDIO_STREAM, streamDescriptor.id,_groupName);
							return ;
						}
					} 
					
					if( _mic!=null && !_mic.muted && p_evt.streamDescriptor.finishPublishing){
						
            			if( _stream == null ){
            				_stream = createNetStream();
                			_stream.attachAudio(_mic);                			
            			}
            			_audioStreamID=p_evt.streamDescriptor.id;
            			dispatchEvent(new Event("isAudioPublishing"));
                    	_stream.attachAudio(_mic);
                    	_stream.publish(_audioStreamID);
                    	
						dispatchEvent(p_evt);
						// Additionally, set our user voice status in our UserDescriptor so that
						// people will know if we're talking.
						_userManager.setUserVoiceStatus(_userManager.myUserID, UserVoiceStatuses.ON_SILENT);

						if ( _mic.codec.toLowerCase() == SoundCodec.SPEEX.toLowerCase() ) {
							MicrophoneManager.getInstance().selectedMic.setSilenceLevel(0)  ;
							MicrophoneManager.getInstance().framesPerPacket = 1  ;
							activityTimer.addEventListener(TimerEvent.TIMER_COMPLETE,onActivityTimerComplete);
							activityTimer.start();
						}else if ( _mic.codec.toLowerCase() == SoundCodec.NELLYMOSER.toLowerCase() ) {
							MicrophoneManager.getInstance().selectedMic.setSilenceLevel(10) ;
							_mic.addEventListener(ActivityEvent.ACTIVITY, onActivity);	
						}
						
						if ( gainControl ) {
							_pollIntervalTimer.addEventListener(TimerEvent.TIMER_COMPLETE,onMaxVolPollTimerComplete);
							_pollIntervalTimer.start();
						}					
   				  }
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
			
			// If there is a group, then it will only listen to the streams of that group.
			if ( streamDescriptor.groupName && streamDescriptor.groupName != _groupName ) {
				return ;
			} 
			
			
			if( streamDescriptor.type == StreamManager.AUDIO_STREAM && _userManager.myUserID==p_evt.streamDescriptor.streamPublisherID){				
				// If the stream exists and not made null my the role change. 
				if ( _stream ) {
					_stream.attachAudio(null);
					_stream.close();
			   		_stream = null;
				}
				
				if (_mic) {
					if ( _mic.codec.toLowerCase() == SoundCodec.NELLYMOSER.toLowerCase() ) {
						MicrophoneManager.getInstance().selectedMic.setSilenceLevel(10) ;
						_mic.removeEventListener(ActivityEvent.ACTIVITY, onActivity);
					}else if ( _mic.codec.toLowerCase() == SoundCodec.SPEEX.toLowerCase()) {
						activityTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,onActivityTimerComplete);
						activityTimer.stop();
					}
					// Clear the listener so when the user unmutes the microphone via the settings panel, 
					// it will not try to magically start the audio stream.	
					_mic = null; 			
				}
                
                _audioStreamID = null ;
			   	dispatchEvent(new Event("isAudioPublishing"));
				invalidator.invalidate() ;
				
				if ( gainControl ) {
					_pollIntervalTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,onMaxVolPollTimerComplete);
					_pollIntervalTimer.stop();
				}
				
				dispatchEvent(p_evt);
				
				// Update user descriptor's voice status.
				_userManager.setUserVoiceStatus(p_evt.streamDescriptor.streamPublisherID, UserVoiceStatuses.OFF);
				
            } 
		}
 
 		/**
		 * @private
		 * Handles the stream muted event listening to the stream manager model.
		 */
		protected function onStreamMuted(p_evt:StreamEvent):void
		{
			var streamDescriptor:StreamDescriptor=p_evt.streamDescriptor;
			// Checks if its audio stream and I am the one who published it.
			
			if ( streamDescriptor.groupName && streamDescriptor.groupName != _groupName ) {
				return ;
			} 
			
			if(streamDescriptor.type==StreamManager.AUDIO_STREAM && _userManager.myUserID==p_evt.streamDescriptor.streamPublisherID){
				 
				_isMuted = p_evt.streamDescriptor.mute ;
				dispatchEvent(p_evt);		
			}
			invalidator.invalidate() ;
		}
		
		
		/**
		 * Disposes all listeners to the network and framework classes and assures proper garbage collection of the component.
		 */
		public function close():void
		{
			_connectSession.removeEventListener(ConnectSessionEvent.CLOSE, onSessionClose);
			_streamManager.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			_streamManager.removeEventListener(StreamEvent.STREAM_RECEIVE, onStreamReceive);
			_streamManager.removeEventListener(StreamEvent.STREAM_DELETE,onStreamDelete);
			_streamManager.removeEventListener(StreamEvent.STREAM_PAUSE,onStreamMuted);
			_streamManager.removeEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onUserRoleChange);
			_streamManager.removeEventListener(StreamEvent.CONNECTION_TYPE_CHANGE,onConnectionTypeChange);
			
		}
		
		
		/**
		 * 
		 * @private
		 * Verify the camera gets turned off if the session closes.
		 */
		protected function onSessionClose(p_evt:ConnectSessionEvent):void
		{
			
			if ( isPublishing ) {
				stop();
			}
		}
 		
		/**
		 * @private
		 * 
		 * Handles the synchronization change event
		 */
		protected function onSynchronizationChange(p_evt:CollectionNodeEvent):void
		{
			if ( isPublishing && _stream && !_streamManager.isSynchronized) {
				_stream.attachAudio(null);
				_mic = null;					
				_stream.close();
				_stream=null;
				_audioStreamID = null ;
			}
			
			dispatchEvent(p_evt);	
		}
		
		/**
		 * @private
		 *
		 * Handles the onuser role change event.
		 */
		protected function onUserRoleChange(p_evt:CollectionNodeEvent):void
		{
			if ( !_subscribed ) {
				return ;
			}
			// the UI changes are only if its you ..
			if ( p_evt.userID == _userManager.myUserID && _streamManager.getNodeConfiguration(StreamManager.AUDIO_STREAM,_groupName) != null ) {
				if (_streamManager.getUserRole(_userManager.myUserID,StreamManager.AUDIO_STREAM,_groupName) >= _streamManager.getNodeConfiguration(StreamManager.AUDIO_STREAM,_groupName).publishModel ){
					// Role is more than needed for audio.
					
				}
				else{
					// Role is less than needed for audio and audio has not started yet.
					if (_stream !=null ) {
						delete _streamManager.getStreamDescriptor(StreamManager.AUDIO_STREAM,_associatedUserID,_groupName);					
						_stream.attachAudio(null);
						_mic = null;					
				   		_stream.close();
				   		_stream=null;
					}
					
				}
			}
			
			invalidator.invalidate() ;
			dispatchEvent(p_evt);	// Bubble it up.
		}
		
		/**
		 * @private
		 *
		 * Handles the onuser role change event.
		 */
        private function statusHandler(event:StatusEvent):void 
        {
            if( _mic != null){
            	if(event.code == "Microphone.Unmuted"){
            		_streamManager.publishStream(StreamManager.AUDIO_STREAM, _associatedUserID, _groupName,_recipientIDs);
            		_streamManager.camAudioPermissionDenied = false ;
            		
            	} else {
            		_streamManager.deleteStream(StreamManager.AUDIO_STREAM,_associatedUserID,_groupName );
            		_streamManager.camAudioPermissionDenied = true ;
            	}
            	
        	}
        }
        
        
		/**
		 * @private
		 * This fires when the mic goes from no activity to some activity, or vice versa.
		 * It doesn't tell us how much activity is happening which is fine for our purposes.
		 */
		public function onActivity(p_event:ActivityEvent=null):void
		{
			if(MicrophoneManager.getInstance().selectedMic.activityLevel >= 11) {
				if(_userManager.getUserDescriptor(_userManager.myUserID).voiceStatus != UserVoiceStatuses.ON_SPEAKING)
					_userManager.setUserVoiceStatus(_userManager.myUserID, UserVoiceStatuses.ON_SPEAKING);
			}
			else {
				if(_userManager.getUserDescriptor(_userManager.myUserID).voiceStatus != UserVoiceStatuses.ON_SILENT)
					_userManager.setUserVoiceStatus(_userManager.myUserID, UserVoiceStatuses.ON_SILENT);
			}
			
		}
		
		/**
		 * @private
		 *
		 * Creates the Stream Descriptor and publishes the stream.
		 * 
		 */
		protected function createStream(p_streamPublisherID:String=null):void
		{
			var streamDescriptor:StreamDescriptor = new StreamDescriptor();
			
			if ( p_streamPublisherID )
				streamDescriptor.streamPublisherID = p_streamPublisherID ;
			else {
				streamDescriptor.streamPublisherID = _userManager.myUserID ;
				_associatedUserID = streamDescriptor.streamPublisherID ;
			}
			
			// streamDescriptor.id = StreamManager.AUDIO_STREAM  + streamDescriptor.streamPublisherID ;
			streamDescriptor.type = StreamManager.AUDIO_STREAM ;
			streamDescriptor.groupName = _groupName ;
			streamDescriptor.recipientIDs = _recipientIDs ;
			 
			_streamManager.createStream(streamDescriptor);
			
		}  
		
		
		/**
		 * @private
		 */
		protected function onInvalidate(p_evt:Event):void
        {
        	
			microphoneManager = MicrophoneManager.getInstance();
			
			if ( _silenceTimeoutChanged ) {
				microphoneManager.silenceTimeout = _silenceTimeout ;
				_silenceTimeoutChanged = false ;
				dispatchEvent(new AudioConfigurationEvent(AudioConfigurationEvent.SILENCE_TIMEOUT_CHANGED));
			}
			
			if ( _gainChanged ) {
				microphoneManager.gain = _gain ;
				_gainChanged = false ;
				dispatchEvent(new AudioConfigurationEvent(AudioConfigurationEvent.GAIN_CHANGED));
			}
			
			
			if ( _useEchoSuppressionChanged ) {
				_useEchoSuppressionChanged = false ;
				microphoneManager.echoSuppression = _useEchoSuppression ;
				dispatchEvent(new AudioConfigurationEvent(AudioConfigurationEvent.ECHO_SUPPRESSION_CHANGED));
			}
        	
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
       	
        override protected function measure():void
        {
        	super.measure();
        	if ( UIComponentGlobals.designMode ) {
        		minHeight = 40 ;
        		minWidth = 100 ;
        	}else {
        		minHeight = 0 ;
        		minWidth = 0 ;
        	}
        } 
		 
        
        /**
        * @private
        */
        protected function onConnectionTypeChange(p_evt:StreamEvent):void
		{
			if ( _streamManager.getStreamDescriptor(StreamManager.AUDIO_STREAM,_userManager.myUserID,_groupName)== null ) {
				return ;
			}
			
			if ( _stream == null ) {
				return ;
			}
		
			_stream.attachAudio(null);
			_stream.close();
			_stream = createNetStream();
            _stream.attachAudio(_mic);
           	_stream.publish(_audioStreamID);
           
			
		} 
		
		/**
		 * @private
		 */
		protected function onCodecChange(p_evt:StreamEvent):void
		{
	    	var lastCodec:String = MicrophoneManager.getInstance().selectedMic.codec.toLowerCase() ;
	    	
	    	if ( _stream ) {
	    		MicrophoneManager.getInstance().selectedMic = null ;
	    		_mic = MicrophoneManager.getInstance().selectedMic ;
				if ( lastCodec == SoundCodec.NELLYMOSER.toLowerCase() ) {
					MicrophoneManager.getInstance().selectedMic.setSilenceLevel(0) ;
					MicrophoneManager.getInstance().framesPerPacket = 1  ;
					activityTimer.addEventListener(TimerEvent.TIMER_COMPLETE,onActivityTimerComplete);
					_mic.removeEventListener(ActivityEvent.ACTIVITY,onActivity);
					activityTimer.start();
					_mic.codec = SoundCodec.SPEEX ;	    		
				}else { 
					MicrophoneManager.getInstance().selectedMic.setSilenceLevel(10) ;
					activityTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,onActivityTimerComplete);
					activityTimer.stop();
					_mic.addEventListener(ActivityEvent.ACTIVITY,onActivity);
					_mic.codec = SoundCodec.NELLYMOSER ;
						
				}
	    	}else {
				MicrophoneManager.getInstance().selectedMic = null ;
				var mic:Microphone = MicrophoneManager.getInstance().selectedMic ;
				
				if ( lastCodec == SoundCodec.NELLYMOSER.toLowerCase() ) {
					MicrophoneManager.getInstance().selectedMic.setSilenceLevel(0) ;
					MicrophoneManager.getInstance().framesPerPacket = 1  ;
					mic.codec = SoundCodec.SPEEX ;	    		
				}else {
					MicrophoneManager.getInstance().selectedMic.setSilenceLevel(10) ;
					mic.codec = SoundCodec.NELLYMOSER ;
				}
	    	}
					
	    }
	    
	    public function set codec(p_codecType:String ):void {
	    
	    	if ( p_codecType.toLowerCase() != MicrophoneManager.getInstance().selectedMic.codec.toLowerCase() ) {
	    		MicrophoneManager.getInstance().selectedMic = null ;
	    		if ( _mic ) {
	    			_stream.attachAudio(null);
					_stream.close();
	    			_mic = MicrophoneManager.getInstance().selectedMic ;
	    			_mic.codec = p_codecType ;
	    			_stream.attachAudio(_mic);
					_stream.publish(_audioStreamID);
	    		}else {
	    			var mic:Microphone = MicrophoneManager.getInstance().selectedMic ;
	    			mic.codec = p_codecType ;
	    		}
	    		
	    		if ( _stream ) {
	    			if ( p_codecType.toLowerCase() == SoundCodec.SPEEX.toLowerCase()) {
	    				MicrophoneManager.getInstance().selectedMic.setSilenceLevel(0) ;
						MicrophoneManager.getInstance().framesPerPacket = 1  ;
						activityTimer.addEventListener(TimerEvent.TIMER_COMPLETE,onActivityTimerComplete);
						_mic.removeEventListener(ActivityEvent.ACTIVITY,onActivity);
						activityTimer.start();
	    			} else if (  p_codecType.toLowerCase() == SoundCodec.NELLYMOSER.toLowerCase()) {
	    				MicrophoneManager.getInstance().selectedMic.setSilenceLevel(10) ;
	    				activityTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,onActivityTimerComplete);
						activityTimer.stop();
						_mic.addEventListener(ActivityEvent.ACTIVITY,onActivity);
	    			}
	    		}
	    		
	    	}
	    }
	    
	    private function onActivityTimerComplete(p_evt:TimerEvent):void
		{
			onActivity();
			activityTimer.start();

		}
			
	    private function onMaxVolPollTimerComplete(p_evt:TimerEvent):void
	    {
	    	// if the max volume is more than 20% of the time ,then auto decrease the gain and reset the timer 
	    	_activityArray[_volActivityCount] =  MicrophoneManager.getInstance().selectedMic.activityLevel;
	    	_volActivityCount += 1 ;
	    	
	    	var numInterval:Number = (TOTAL_POLLING_TIME/INTERVAL_DURATION);
	    	if ( _volActivityCount == numInterval ) {
	    		_volActivityCount = 0 ;
	    		_startRollingWindow = true ;
	    	}	
			
			if ( _startRollingWindow ) {
	    		var maxCount:Number = 0 ;
	    		for ( var i:int = 0 ; i < numInterval ; i++ ) {
	    			if ( _activityArray[i] == 100 ) {
	    				maxCount += 1;
	    			}
	    		}	
	    		if ( maxCount > 0.4*numInterval && gain > 20) {
	    			var gainDecrease:uint = uint(gain/10) ;
	    			gain -= gainDecrease ;
	    		}		
		    }
		    
		    _pollIntervalTimer.start();
	    }
	    
	    
	    /**
	    * @private
	    */
	    protected function createNetStream():NetStream
	    {
	    	if ( _streamManager.isP2P ) {
				
				if ( _streamManager.isArgo() && _streamManager.streamMulticast ) {
					if ( _groupName == null ) {
						_stream= new NetStream(connection,_streamManager.getMulticastGroupSpec(StreamManager.DEFAULT_MULTICAST_STREAM_GROUP).toString());
						_stream.multicastWindowDuration = multicastWindowDuration ;
					}else {
						_stream= new NetStream(connection,_streamManager.getMulticastGroupSpec(_groupName).toString());
					}
				}else {
				
					_stream= new NetStream(connection,NetStream.DIRECT_CONNECTIONS);
				
				}
				
			}else { 
				_stream= new NetStream(connection,NetStream.CONNECT_TO_FMS);
       		}
       		
       		return _stream ;
	    }
	}

}
