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
	import com.adobe.rtc.util.URLParser;
	
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.net.LocalConnection;
	import flash.utils.Timer;
	
	use namespace session_internal;
		
	/**
	 * @private
	 * SessionManagerLocalConnection is an extended SessionManagerBase, whose job it is to route messaging calls to a LocalConnection. 
	 * LocalConnectionMessageManager listens to this same LocalConnection, and acts as a server in this case, to allow multiple clients 
	 * (on the same machine) to pass messages. <p>
	 * 
	 * Note that SessionManagerLocalConnection needs only override the session_internal functions of SessionManagerBase. These
	 * are the set of supported RPC requests being made from layers above the SessionManager, such as MessageManager. 
	 * In this class, used for Development Emulation, the SessionManager routes these requests to an instance of 
	 * LocalConnectionMessageManager, operating in another swf. SessionManagerLocalConnection will establish the approriate Connections,
	 * including a rudimentary handshake authentication. <p>
	 * 
	 * Most public functions of SessionManagerBase won't need overriding, and are called by the "server", straight from the incoming LocalConnection. 
	 * 
	 * @see com.adobe.rtc.session.managers.SessionManagerBase SessionManagerBase
	 * @see com.adobe.rtc.messaging.serveremulation.ServerManager ServerManager
	 * @see com.adobe.rtc.messaging.manager.MessageManager MessageManager
	 * 
	 */
	public class SessionManagerLocalConnection 
		extends SessionManagerBase
	{
		/**
		 * The connection name clients temporarily use to listen for a private connection
		 */		
		public static const CLIENT_HANDSHAKE_CONNECTION_NAME:String = "_ClientHandShake";
		/**
		 * The connection name clients use to request any other server call be made
		 */		
		public static const SERVER_REQUEST_CONNECTION_NAME:String = "_ServerRequest";
		/**
		 * The prefix for the connection name the server uses to contact an individual client
		 */		
		public static const PRIVATE_CONNECTION_NAME:String = "_Private";
		
		/**
		 * @private
		 * Each client starts by listening to this "public" channel through which the "server" assigns private channels to each client.
		 */
		protected var _handShakeIncoming:LocalConnection;
		
		/**
		 * @private
		 * Each client uses an outgoingConnection to the server through which to send requests. (This is equivalent to "incomingConnection" on 
		 * LocalConnectionMessageManager.)
		 */
		protected var _outgoingConnection:LocalConnection;
		
		/**
		 * @private
		 * Each client is assigned its own (private) LocalCollection through which the server will send information. 
		 */
		protected var _privateIncoming:LocalConnection;
		
		/**
		 * @private
		 * Making sure a connection is established before accepting any CollectionNode subscriptions. We queue these up until ready. 
		 */
		protected var subscriptionQueue:Array;
		/**
		 * This Timer keeps pinging to the server once in a while and if the ping is no longer there then the server closes the connection.
		 * @private
		 */
		protected var beepTimer:Timer ;
		/**
		 * The User ID of this User
		 * @private
		 */
		protected var userID:String ;
		/**
		 * The room name 
		 * @private
		 */
		protected var roomName:String ;		
		
		
		public function SessionManagerLocalConnection()
		{
			super();
			isLocalManager = false;
			subscriptionQueue = new Array();		
		}
		
		/**
		 * When the LocalConnectionMessageManager has a userID and roles for the current client, it accepts the client by calling this function.
		 * (I still think this sort of thing might be covered in another module?)
		 * 
		 * @param p_userID
		 * @param p_role
		 * @param collectionNames
		 * 
		 */		
		override public function receiveLogin(p_userData:Object):void
		{
			userID = p_userData.descriptor.userID ;
			var privateConn:String = PRIVATE_CONNECTION_NAME + p_userData.descriptor.userID ;
			_handShakeIncoming.close();
			isSynchronized = true;
			_privateIncoming = new LocalConnection();
			_privateIncoming.allowDomain('*');
			try {
				_privateIncoming.connect(privateConn);
			}catch(e:Error) {
				trace("This connection seems to be existing");	
			}
			
			_privateIncoming.client = this;
			
			beepTimer = new Timer(2000,1);
			beepTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimer);
			beepTimer.start();
			
			session_internal::connection = _outgoingConnection;
			
			super.receiveLogin(p_userData);
		}
				
		protected function onTimer(event:TimerEvent):void
		{
			_outgoingConnection.send(SERVER_REQUEST_CONNECTION_NAME, "pingServer", roomName, userID);
			beepTimer.start();
		}				
		
		override session_internal function login():void
		{
			// do we have a roomURL to parse?  previous versions of LocalConnectionServer
			// did not support roomURL or multiple rooms.
			if (session_internal::roomURL == null
				|| session_internal::roomURL == "")
			{
				// return error
				trace("login() request does not include roomURL.");
				var error:Object = new Object();
				error.name = "INVALID_INSTANCE";
				error.message = "The roomURL is not set";
				receiveError(error);
				return;
			}
			
			// go ahead, parse out the room name
			var path:String = URLParser.parseURL(session_internal::roomURL).path;
			// path should be /account/room(/); room name should be the 3rd part
			roomName = path.split('/')[2]; 			 
			
			// listen to the public channel, wait to receive "receiveLogin" from the server	
			_handShakeIncoming = new LocalConnection();
			_handShakeIncoming.allowDomain("*");
			
			try 
			{
				_handShakeIncoming.connect(CLIENT_HANDSHAKE_CONNECTION_NAME);
			}
			catch(e:Error) 
			{
				trace("This connection seems to be existing");	
			}
			_handShakeIncoming.client = this;
			
			_outgoingConnection = new LocalConnection();
			_outgoingConnection.addEventListener(StatusEvent.STATUS,onStatus);

			if ( authenticator.authenticationKey != null ) 
			{
				// external authentication
				_outgoingConnection.send(SERVER_REQUEST_CONNECTION_NAME, "acceptClient", {token:authenticator.authenticationKey});
			}
			else if ( roomName != null ) 
			{
				_outgoingConnection.send(SERVER_REQUEST_CONNECTION_NAME, "acceptClient", {room:roomName, role:100, userName:authenticator.userName});
			}
			else
			{
				trace("Something went wrong; not sure what to send LocalConnectionServer.");	
			}			
			
			//_outgoingConnection.send(SERVER_REQUEST_CONNECTION_NAME, "subscribeCollection", "1");			
		}
		
		private function onStatus(event:StatusEvent):void
		{
			
		}
		
		
		override session_internal function logout():void
		{
			try {
				_handShakeIncoming.close();
				_outgoingConnection.close();
			} catch (e:Error) {
				//throw e;
			}
		}
		
		/**
		 * @private
		 * CollectionNodes' internal method for registering itself to the Manager, and 
		 * kicking off discovery of nodes, configurations, roles, and stored items.
		 */
		
		override session_internal function subscribeCollection(p_collectionName:String=null, p_nodeNames:Array=null):void
		{
			var userID:String = messageManager.connectSession.userManager.myUserID ;
			if (isSynchronized) {
				session_internal::connection.send(SERVER_REQUEST_CONNECTION_NAME, 
					"subscribeCollection", roomName, userID, p_collectionName, p_nodeNames);
			} else {
				// we haven't finished the handshake with the server, store this request for when we're done
				subscriptionQueue.push({nodeCollectionName:p_collectionName, nodeNames:p_nodeNames});
			}
		}
		
		/**
		 * @private
		 * CollectionNodes' internal method for unregistering itself from the Manager.
		 */
		
		override session_internal function unsubscribeCollection(p_collectionName:String=null):void
		{
			connection.send(SERVER_REQUEST_CONNECTION_NAME, 
				"unsubscribeCollection", roomName, messageManager.connectSession.userManager.myUserID, p_collectionName);
		}
		
		/**
		 * @private
		 * CollectionNodes' internal method for submitting this request
		 */
		
		override session_internal function createNode(p_collectionName:String, p_nodeName:String, p_nodeConfigurationVO:Object=null):void
		{
			_outgoingConnection.send(SERVER_REQUEST_CONNECTION_NAME, 
				"createNode", roomName, messageManager.connectSession.userManager.myUserID, p_collectionName, p_nodeName, p_nodeConfigurationVO);
		}
		
		/**
		 * @private
		 * CollectionNodes' internal method for submitting this request
		 */
		
		override session_internal function configureNode(p_collectionName:String, p_nodeName:String, p_nodeConfigurationVO:Object):void
		{
			_outgoingConnection.send(SERVER_REQUEST_CONNECTION_NAME, 
				"configureNode", roomName, messageManager.connectSession.userManager.myUserID, p_collectionName, p_nodeName, p_nodeConfigurationVO);
		}
		
		/**
		 * @private
		 * CollectionNodes' internal method for submitting this request
		 */
		
		override session_internal function removeNode(p_collectionName:String, p_nodeName:String=null):void
		{
			_outgoingConnection.send(SERVER_REQUEST_CONNECTION_NAME, 
				"removeNode", roomName, messageManager.connectSession.userManager.myUserID, p_collectionName, p_nodeName);
		}
				
		/**
		 * @private
		 * CollectionNodes' internal method for submitting this request
		 */
		
		override session_internal function publishItem(p_collectionName:String, p_nodeName:String, p_itemVO:Object, p_overWrite:Boolean=false,p_p2pDataMessaging:Boolean=false):void
		{
			session_internal::connection.send(SERVER_REQUEST_CONNECTION_NAME, 
				"publishItem", roomName, messageManager.connectSession.userManager.myUserID, p_collectionName, p_nodeName, p_itemVO);
		}
		
		/**
		 * @private
		 * CollectionNodes' internal method for submitting this request
		 */
		override session_internal function retractItem(p_collectionName:String, p_nodeName:String, p_itemID:String=null):void
		{
			_outgoingConnection.send(SERVER_REQUEST_CONNECTION_NAME, 
				"retractItem", roomName, messageManager.connectSession.userManager.myUserID, p_collectionName, p_nodeName, p_itemID);
		}
				
		/**
		 * @private
		 * CollectionNodes' internal method for submitting this request
		 */
		override session_internal function setUserRole(p_userID:String, p_role:int, p_collectionName:String=null, p_nodeName:String=null):void
		{
			_outgoingConnection.send(SERVER_REQUEST_CONNECTION_NAME, 
				"setUserRole", roomName, messageManager.connectSession.userManager.myUserID, p_userID, p_role, p_collectionName, p_nodeName);
		}		
		
	}
}