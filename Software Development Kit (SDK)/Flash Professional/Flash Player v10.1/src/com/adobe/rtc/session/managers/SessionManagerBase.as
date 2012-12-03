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
	import com.adobe.rtc.authentication.AbstractAuthenticator;
	import com.adobe.rtc.events.SessionEvent;
	import com.adobe.rtc.messaging.manager.MessageManager;
	
	import com.adobe.rtc.session.sessionClasses.GroupCollectionManager;
	
	import com.adobe.rtc.util.DebugUtil;
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.core.messaging_internal;
	
	import flash.events.EventDispatcher;
	import flash.net.NetStream;
	import flash.utils.*;
	import flash.net.NetStream ;

	use namespace session_internal;


	/**
	 * @private
	 * SessionManagerBase is the base implementation of the set of tasks required of SessionManager, a foundation class of any LCCS app. 
	 * See the diagram at : <a href="http://treebeard.macromedia.com/display/Breeze/Components+Needed+for+Cocomo">Components needed for LCCS</a> 
	 * for its place in the scheme of things. 																												<p>
	 * 
	 * The SessionManager is a singleton whose job is to make "physical layer" decisions for the app. That is, it manages : <p>
	 * <ul>
	 * 	<li> The physical connection required of the session (NetConnection, FileSystem, etc)</li>
	 * 	<li> Authentication RPCs for that connection (likely based on session tickets passed in from some source on the client) </li>
	 * 	<li> Connectivity issues (online, disconnecting, reconnecting, failover, offline, seeking)</li>
	 * 	<li> The set of custom RPC passthroughs required by other Manager classes in the LCCS framework. Hopefully very limited.</li> 
	 * </ul> <p>
	 * The intention here is that only the SessionManager makes direct call-responses to any 
	 * server (whether Acorn, LocalConnection, etc), and that only MessageManager, plus potentially UserManager, AVManager, RoomManager, and FileManager will 
	 * have access to its session_internal methods. In this way, the SessionManager (and its helper classes) should constitute a "swappable session layer", with possible 
	 * SessionManagers for Acorn, archive playback, LocalConnection (dev emulation), and others.
	 * 
	 * This Base implementation is just a simple local-loopback, which uses timers to simulate the asynchronous-ness of the RPC call-responses, and fires its own responses.
	 * All session_internal methods are called by other (higher) layers on the application stack, and should be overridden to accomodate new physical decisions smarter than local loopback
	 * (NetConnection or LocalConnection calls, etc). The public methods (which I really wish weren't) are the response methods, called by the server back to the client, which
	 * will route the responses to the appropriate layer in the app stack; these shouldn't need to be overridden.
	 *
	 * @see com.adobe.rtc.messaging.manager.MessageManager MessageManager
	 * @see com.adobe.rtc.session.managers.SessionManagerLocalConnection SessionManagerLocalConnection
	 */
   public class  SessionManagerBase extends EventDispatcher
	{

		/**
		* Set this to false in the constructors of subclasses of this implementation, to avoid local-loopback of events
		*/
		protected var isLocalManager:Boolean = true;
		
		/**
		* @private
		* How long to wait in simulating an async event
		*/
		protected var asynchTimer:int = 100;

		session_internal var messageManager:MessageManager;
		session_internal var connection:*;

		session_internal var authenticator:AbstractAuthenticator;
		session_internal var roomURL:String;
		
		session_internal var groupCollectionManager:GroupCollectionManager;
		
		
		/**
		 * @private
		 */
		protected var _isSynchronized:Boolean = false ;

		public function SessionManagerBase()
		{

		}



		/********************************************************************
		 *			session_internal FUNCTIONS
		 *
		 * 		These functions are called by higher levels of the application stack (such as 
		 * 		MessageManager). SessionManager will take these internal functions and build
		 * 		RPCs from them, and await responses. In the base implementation, we're 
		 * 		emulating service roundtrips through timeouts.
		 * 
		 * 		override these methods to route such calls to an appropriate physical layer
		 * 		(NetConnection, LocalConnection, file systems, etc)
		 * 
		 * *********************************************************************/



		/**
		 * @private
		 * A ConnectSession's internal method for logging into a LCCS session. 
		 * This leads to kicking off discovery of nodes, configurations, roles, and stored items. 
		 * (responses : receiveLogin)
		 */		
		session_internal function login():void
		{
			if (isLocalManager) {
				setTimeout(receiveLogin, asynchTimer, {descriptor:{userID:0, affiliation:100}});
			}
		}

		session_internal function logout():void 
		{
			disconnect();
		}
		session_internal function disconnect():void
		{
			isSynchronized = false;
			dispatchEvent(new SessionEvent(SessionEvent.DISCONNECT));
		}
		
		/**
		 * @private 
		 */
		session_internal function set isSynchronized(p_toggle:Boolean):void
		{
			// no-op, used for playback
			_isSynchronized = p_toggle ;
		}
		
		/**
		 * @private 
		 */
		session_internal function get isSynchronized():Boolean
		{
			return _isSynchronized ;
		}


		/**
		 * @private
		 * The MessageManager's internal method for subscribing to a collectionNode on the server.
		 * This leads to kicking off discovery of nodes, configurations, roles, and stored items. 
		 * (responses : receiveNodes, receiveItems)
		 */		
		session_internal function subscribeCollection(p_collectionName:String=null, p_nodeNames:Array=null):void
		{
			if (isLocalManager) {
				if ( p_collectionName == null ) {
					var data:Object = new Object();
					setTimeout(receiveRootSyncData, asynchTimer, data );
				}
				else 
					setTimeout(receiveAllSynchData, asynchTimer, p_collectionName, p_nodeNames);
				// simulate the asynch-ness of this RPC by using a timer 
				//	for now, tell the collection it's got all nodes/config/roles/items (in this local loopback case, we're not storing items anyhow).
				// In real life, begin the sequence of discovering all viewable nodes, their configs, roles, and items
			}
		}

		/**
		 * @private
		 * The MessageManager's internal method for unsubscribing to a collectionNode on the server.
		 */		
		session_internal function unsubscribeCollection(p_collectionName:String=null):void
		{
			//do nothing, this has no receive equivalent (none needed)
		}

		/**
		 * @private
		 * The MessageManager's internal method for creating a new node on a collectionNode on the server.
		 * (response : receiveNode)
		 */		
		session_internal function createNode(p_collectionName:String, p_nodeName:String, p_nodeConfigurationVO:Object=null):void
		{
			// Reference implementation : echoing the request back to the collection
			if (isLocalManager) {
				setTimeout(receiveNode, asynchTimer, p_collectionName, p_nodeName, p_nodeConfigurationVO);
			}
		}

		/**
		 * @private
		 * The MessageManager's internal method for configuring a node on a collectionNode on the server.
		 * (response : receiveNodeConfiguration)
		 */		
		session_internal function configureNode(p_collectionName:String, p_nodeName:String, p_nodeConfigurationVO:Object):void
		{
			// Reference implementation : echoing the request back to the collection
			if (isLocalManager) {
				setTimeout(receiveNodeConfiguration, asynchTimer, p_collectionName, p_nodeName, p_nodeConfigurationVO);
			}
		}


		/**
		 * @private
		 * The MessageManager's internal method for removing a node on a collectionNode on the server.
		 * (response : receiveNodeDeletion)
		 */		
		session_internal function removeNode(p_collectionName:String, p_nodeName:String=null):void
		{
			// Reference implementation : echoing the request back to the collection
			if (isLocalManager) {
				setTimeout(receiveNodeDeletion, asynchTimer, p_collectionName, p_nodeName);
			}
		}


		/**
		 * @private
		 * The MessageManager's internal method for publishing an item on a node on a collectionNode on the server.
		 * (response : receiveItem)
		 */		
		session_internal function publishItem(p_collectionName:String, p_nodeName:String, p_itemVO:Object, p_overWrite:Boolean=false,p_p2pDataMessaging:Boolean=false):void
		{
			// Reference implementation : echoing the request back to the collection
			if (isLocalManager) {
				var data:Object = new Object();
				data.collectionName = p_collectionName ;
				data.nodeName = p_nodeName ;
				data.item = p_itemVO ;
				setTimeout(receiveItem, asynchTimer, data);
			}			
		}


		/**
		 * @private
		 * The MessageManager's internal method for retracting an item on a node on a collectionNode on the server.
		 * (response : receiveItemRetraction)
		 */		
		session_internal function retractItem(p_collectionName:String, p_nodeName:String, p_itemID:String=null):void
		{
			// Reference implementation : echoing the request back to the collection
			if (isLocalManager) {
				var data:Object = new Object();
				data.collectionName = p_collectionName ;
				data.nodeName = p_nodeName ;
				data.item = p_itemID ;
				setTimeout(receiveItemRetraction, asynchTimer, data);
			}			
		}

		/**
		 * @private
		 * The MessageManager's internal method for fetching items on a node on a collectionNode on the server.
		 * (response : receiveItems)
		 */		
		session_internal function fetchItems(p_collectionName:String, p_nodeName:String, p_itemIDs:Array):void
		{
		}
		
		/**
		 * @private
		 * The MessageManager's internal method for setting a user role on a collectionNode / node on the server.
		 * (response : receiveUserRole)
		 */
		session_internal function setUserRole(p_userID:String, p_role:int, p_collectionName:String=null, p_nodeName:String=null):void
		{
			// Reference implementation : echoing the request back to the collection
			if (isLocalManager) {
				setTimeout(receiveUserRole, asynchTimer, p_userID, p_role, p_collectionName, p_nodeName);
			}
		}
		
		
		/**
		 * @private 
		 * @param p_streamID
		 * @param p_peerID
		 * 
		 */
		session_internal function getAndPlayAVStream(p_streamID:String, p_peerID:String=null):NetStream
		{
			//override it 
			return null ;
		}
		
		/********************************************************************
		 *			RESPONSE FUNCTIONS
		 *
		 * 		These functions are called by the remote service as a result of an RPC
		 * 		(in the base implementation, we're emulating this through timeouts)
		 * 		They're only public because any class which uses the .client property (NetConnection,
		 * 		LocalConnection, etc) require them to be. 
		 * 		Chances are, they don't need to be overridden.
		 * 
		 **********************************************************************/


		/**
		 * The response to the "login" RPC
		 * Notifies the session that authentication has passed
		 * @param p_userDescriptor
		 */
		public function receiveLogin(p_userData:Object):void
		{
			var ticket:String = (p_userData.ticket!=null) ? p_userData.ticket : "";
			var evt:SessionEvent = new SessionEvent(SessionEvent.LOGIN);
			evt.userDescriptor = p_userData.descriptor;
			evt.ticket = ticket;
			dispatchEvent(evt);

		}
		
		/**
		 * The response to the "login" RPC if something went wrong on the server.
		 * Notifies the session that the connectiong has failed
		 * @param p_error  the error message
		 */
		public function receiveError(p_error:Object /*contains .message and .name*/):void
		{
			var error:Error = new Error(p_error.message);
			error.name = p_error.name;
			var errorEvent:SessionEvent = new SessionEvent(SessionEvent.ERROR);
			errorEvent.error = error;
			dispatchEvent(errorEvent);
		}

		/**
		 * @private
		 * Called as the response to the "subscribeCollection" RPC
		 * Notifies the MessageManager that a collection's sync data (nodes, nodeConfigurations,
		 * roles, stored items) has arrived.
		 * 
		 * @param p_collectionName
		 * 
		 */
		public function receiveAllSynchData(p_collectionName:String,p_nodeNames:Array=null):void
		{
			messageManager.messaging_internal::receiveItems(p_collectionName,null,null);
		}

		/**
		 * @private
		 * Called as the response to the "createNode" RPC
		 * Notifies the MessageManager that a node has arrived on some collectionNode (possibly the root collectionNode).
		 */
		public function receiveNode(p_collectionName:String, p_nodeName:String=null, p_nodeConfigurationVO:Object=null,p_peerIDs:Array=null):void
		{
			messageManager.messaging_internal::receiveNode(p_collectionName, p_nodeName, p_nodeConfigurationVO);
		}

		/**
		 * @private
		 * Called as the response to the "configureNode" RPC
		 * Notifies the MessageManager that a node has been configured on some collectionNode (possibly the root collectionNode).
		 */
		public function receiveNodeConfiguration(p_collectionName:String, p_nodeName:String, p_nodeConfigurationVO:Object,p_peerIDs:Array=null):void
		{
			messageManager.messaging_internal::receiveNodeConfiguration(p_collectionName, p_nodeName, p_nodeConfigurationVO);
		}


		/**
		 * @private
		 * Called as the response to the "removeNode" RPC
		 * Notifies the MessageManager that a node has been removed on some collectionNode (possibly the root collectionNode).
		 */
		public function receiveNodeDeletion(p_collectionName:String, p_nodeName:String=null):void
		{
			messageManager.messaging_internal::receiveNodeDeletion(p_collectionName, p_nodeName);
		}


		/**
		 * @private
		 * Called as the response to the "publishItem" RPC
		 * Notifies the MessageManager that a node on some collectionNode has received an item.
		 */
		public function receiveItem(p_itemData:Object):void
		{
			messageManager.messaging_internal::receiveItem(p_itemData.collectionName, p_itemData.nodeName, p_itemData.item);
		}


		/**
		 * @private
		 * Called as the response to the "retractItem" RPC
		 * Notifies the MessageManager that a node on some collectionNode has received an item retraction.
		 */
		public function receiveItemRetraction(p_itemData:Object):void
		{
			messageManager.messaging_internal::receiveItemRetraction(p_itemData.collectionName, p_itemData.nodeName, p_itemData.item);
		}


		/**
		 * @private
		 * Called as the response to the "setUserRole" RPC
		 * Notifies the MessageManager that some node has received a change in user role.
		 */
		public function receiveUserRole(p_userID:String, p_role:int, p_collectionName:String=null, p_nodeName:String=null):void
		{
			messageManager.messaging_internal::receiveUserRole(p_userID, p_role, p_collectionName, p_nodeName);
		}
		
		/**
		 * @private
		 * Called as part of the response to the "subscribeCollection" RPC
		 * Notifies the MessageManager that some collection has received its node sync data.
		 */
		public function receiveNodes(p_data:Object,p_peerIDs:Array=null):void
		{
			DebugUtil.debugTrace("RECEIVENODES " + p_data.collectionName);
			messageManager.messaging_internal::receiveNodes(p_data.collectionName, p_data.nodeConfigurations, p_data.collectionUserRoles, p_data.nodeUserRoles);
		}

		/**
		 * @private
		 * Called as part of the response to the "subscribeCollection" RPC
		 * Notifies the MessageManager that some collection has received its items sync data.
		 */
		public function receiveItems(p_nodeItems:Object):void
		{
			messageManager.messaging_internal::receiveItems(p_nodeItems.collectionName, p_nodeItems.items, p_nodeItems.privateItems, p_nodeItems.alreadySynched);
		}

		/**
		 * @private
		 * Called as the response to the "subscribeCollection" RPC, when sent without a specific collection
		 * Notifies the MessageManager that we've received its sync data for the root.
		 */
		public function receiveRootSyncData(p_data:Object):void
		{
			messageManager.messaging_internal::receiveRootSyncData(p_data.collectionNames, p_data.userRoles);
		}


	}

}
