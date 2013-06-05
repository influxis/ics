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
package com.adobe.rtc.util
{
	import com.adobe.rtc.authentication.AdobeHSAuthenticator;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.ConnectSessionEvent;
	import com.adobe.rtc.events.SessionEvent;
	import com.adobe.rtc.events.UserEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.UserDescriptor;
	import com.adobe.rtc.sharedModel.CollectionNode;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.external.ExternalInterface;
	import flash.utils.getQualifiedClassName;
	
	/**
	 *A Bridge that enables bidirectional communication between LCCS Components and JavaScript interface using the ExternalInterface
	 * @example
	 *  <code>
	 *	 	_cSession = new ConnectSession();<br />
	 *		var auth:AdobeHSAuthenticator = new AdobeHSAuthenticator();<br />
	 *		auth.requireRTMFP = false;<br />
	 *		auth.protocol = "RTMPS";<br />
	 *		auth.userName = "uName[at]adobe.com";<br />
	 *		auth.password = "passwd";<br />
	 *		_cSession.roomURL = "http://connectnow.acrobat.com/uname/roomName";<br />
	 *		_cSession.authenticator = auth;<br />
	 *		if(!_jsBridge) {<br />
	 *		&nbsp;&nbsp;&nbsp; _jsBridge = new com.adobe.rtc.util.JSBridge();<br />
	 *		}<br />
	 *		_cSession.addEventListener(SessionEvent.SYNCHRONIZATION_CHANGE, onSync);<br />
	 *		_cSession.login();<br />
	 * </code>
	 */
	public class JSBridge extends EventDispatcher implements ISessionSubscriber
	{
		
		/**
		 * @private
		 */
		protected var _connectSession:IConnectSession; 
		/**
		 * @private
		 */
		protected var _collectionsTable:Object = new Object();
		protected var _invalidator:Invalidator = new Invalidator();
		protected var _didSubscribe:Boolean = false;
		
		public function JSBridge(target:IEventDispatcher=null)
		{
			super(target);
			_invalidator.addEventListener("invalidationComplete", onInvalidationComplete);
			_invalidator.invalidate();
		}
		
		/**
		 * The IConnectSession with which this component is associated. Note that this may only be set once before <code>subscribe</code>
		 * is called; re-sessioning of components is not supported. Defaults to the first IConnectSession created in the application.
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
		 * @private
		 */
		public function get sharedID():String
		{
			return null;
		}
		
		/**
		 * @private
		 */
		public function set sharedID(p_id:String):void
		{
			//no op
		}
		
		/**
		 * A variable that indicates whether or not the ConnectSession is fully synchronized with the service.
		 * @return Boolean 
		 */				
		public function get isSynchronized():Boolean
		{
			return _connectSession.isSynchronized;
		}
		
		/**
		 * @private
		 */
		public function close():void
		{
		}
		
		/**
		 * @private
		 */
		public function subscribe():void
		{
			_didSubscribe = true;
			//_connectSession.addEventListener(SessionEvent.SYNCHRONIZATION_CHANGE,onSynch);
			if (ExternalInterface.available) {
				ExternalInterface.addCallback("RTCIncoming", incomingMessage);
				var argObj:Object = new Object();
				argObj.targetType = "ConnectSession";
				argObj.type = "swfReady";
				ExternalInterface.call("sendToJavaScript",argObj);
			} else {
				throw(new Error("External Interface is Not available"));
			}
		}
		
		/**
		 * @private
		 */
		protected function onSynch(p_evt:SessionEvent):void
		{
			if (_connectSession) {
				var argObj:Object = new Object();
				argObj.type = SessionEvent.SYNCHRONIZATION_CHANGE;
				argObj.targetType =  "ConnectSession";
				argObj.isSynchronized = _connectSession.isSynchronized;
				if (_connectSession.isSynchronized) {
					incomingMessage("UserManager", "getUserMgr", null);
				} else {
					ExternalInterface.call("sendToJavaScript",argObj);
				}
			}
		}
		
		/**
		 * @private
		 */
		protected function onInvalidationComplete(p_evt:Event):void
		{
			if (!_didSubscribe) {
				subscribe();
			}
		}
		
		/**
		 * @private
		 */
		protected function incomingMessage(p_class:String, p_msg:String, p_args:Object):void
		{
			// connectSession messages (login, logout)
			if (p_class=="ConnectSession") {
				if (p_msg=="setAuthenticator") {
					if (!_connectSession) {
						_connectSession = new ConnectSession();
					}
					var auth:AdobeHSAuthenticator = new AdobeHSAuthenticator();
					if (p_args.userName) {
						auth.userName = p_args.userName; 
					}
					
					if (p_args.password) {
						auth.password = p_args.password; 
					}
					
					if (p_args.authenticationKey) {
						auth.authenticationKey = p_args.authenticationKey; 
					}
					
					if (p_args.authenticationURL) {
						auth.authenticationURL = p_args.authenticationURL; 
					}
					_connectSession.authenticator = auth;
				}
				
				if (p_msg=="login") {
					if (_connectSession && _connectSession.authenticator) {
						_connectSession.addEventListener(SessionEvent.SYNCHRONIZATION_CHANGE,onSynch);
						_connectSession.login();
					}
				}
				
				if (p_msg=="logout") {
					if (_connectSession) {
						//clean up listeners
						//_connectSession.removeEventListener(SessionEvent.SYNCHRONIZATION_CHANGE,onSynch);
						_connectSession.logout();
					}
				}
				
				if (p_msg=="close") {
					if (_connectSession) {
						_connectSession.close();
					}
				}
				
				if (p_msg =="setRoomURL") {
					if (!_connectSession) {
						_connectSession = new ConnectSession();
					}
					_connectSession.roomURL = p_args.roomURL;
				}
				
			} else if (p_class=="CollectionNode") {
				var collectionName:String = p_args.sharedID;
				var collection:CollectionNode;
				if (!_connectSession) {
					_connectSession	 = ConnectSession.primarySession;			
				}
				if (p_msg=="subscribeCollection") {
					
					collection = _collectionsTable[collectionName] = new CollectionNode();
					collection.sharedID = collectionName;
					collection.subscribe();
					collection.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
					collection.addEventListener(CollectionNodeEvent.NODE_CREATE, onCollectionNodeRecieveEvent);
					collection.addEventListener(CollectionNodeEvent.NODE_DELETE, onCollectionNodeRecieveEvent);
					collection.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onCollectionNodeRecieveEvent);
					collection.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onCollectionNodeRecieveEvent);
					collection.addEventListener(CollectionNodeEvent.MY_ROLE_CHANGE, onCollectionNodeRecieveEvent);
					collection.addEventListener(CollectionNodeEvent.RECONNECT, onCollectionNodeRecieveEvent);
					collection.addEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onCollectionNodeRecieveEvent);
					//Ask nigel about using objectUtils and deserializing all the elements in evt to a object.
				} else if (p_msg=="publishItem") {
					collection = _collectionsTable[collectionName];
					if (collection) {
						collection.publishItem(objToMsgItem(p_args.messageItem));
					}
				} else if (p_msg == "isEmpty"){
					collection = _collectionsTable[collectionName];
					//TODO: consult the boss
				} else if (p_msg == "unsubscribe"){
					collection = _collectionsTable[collectionName];
					if (collection) {
						collection.unsubscribe();
					}
				} else if (p_msg == "createNode"){
					collection = _collectionsTable[collectionName];
					if (collection) {
						collection.createNode(p_args.nodeName, objToNodeConfig(p_args.nodeConfiguration));
					}
				} else if (p_msg == "setNodeConfiguration"){
					collection = _collectionsTable[collectionName];
					if (collection) {
						collection.setNodeConfiguration(p_args.nodeName, objToNodeConfig(p_args.nodeConfiguration));
					}
				} else if (p_msg == "getNodeConfiguration"){
					collection = _collectionsTable[collectionName];
					if (collection) {
						collection.getNodeConfiguration(p_args.nodeName);						
					}
				} else if (p_msg == "removeNode"){
					collection = _collectionsTable[collectionName];
					if (collection) {
						collection.removeNode(p_args.nodeName);
					}
				} else if (p_msg == "setUserRole"){
					collection = _collectionsTable[collectionName];
					if (collection) {
						collection.setUserRole(p_args.userId,p_args.role, p_args.nodeName);
					}
				} else if (p_msg == "getUserRole"){
					collection = _collectionsTable[collectionName];
					if (collection) {
						collection.getUserRole(p_args.userID, p_args.nodeName);
					}
				} else if (p_msg == "retractItem"){
					collection = _collectionsTable[collectionName];
					if (collection) {
						collection.retractItem(p_args.nodeName, p_args.itemID);
					}
				} else {
					//method Not found or yet to be mapped and implemented
				}
				
			}else if(p_class=="UserManager") {
				if (!_connectSession) {
					_connectSession	 = ConnectSession.primarySession;			
				}
				var usrMgr:UserManager = _connectSession.userManager;
				if(p_msg == "getUserMgr") {
					var usrObj:Object = new Object();
					usrObj.anonymousPresence = usrMgr.anonymousPresence;
					usrObj.myBuddyList = usrMgr.myBuddyList;
					usrObj.myUserID = usrMgr.myUserID;
					usrObj.myTicket = usrMgr.myTicket;
					usrObj.myUserAffiliation = usrMgr.myUserAffiliation;
					usrObj.myUserRole = usrMgr.myUserRole;
					if (usrMgr.audienceCollection.length >= 1) {
						usrObj.audienceCollection = arrayCollectionToObject(usrMgr.audienceCollection.source);
					}
					if (usrMgr.hostCollection.length >= 1) {
						usrObj.hostCollection = arrayCollectionToObject(usrMgr.hostCollection.source);
					}
					if (usrMgr.participantCollection.length >= 1) {
						usrObj.participantCollection = arrayCollectionToObject(usrMgr.participantCollection.source);
					}
					usrObj.targetType = "UserManager";
					usrObj.type = "getUserMgr";
					
					usrMgr.addEventListener(UserEvent.ANONYMOUS_PRESENCE_CHANGE,onUserManagerRecieveEvent);
					usrMgr.addEventListener(UserEvent.CUSTOM_FIELD_CHANGE, onUserManagerRecieveEvent);
					usrMgr.addEventListener(UserEvent.CUSTOM_FIELD_DELETE, onUserManagerRecieveEvent);
					usrMgr.addEventListener(UserEvent.CUSTOM_FIELD_REGISTER, onUserManagerRecieveEvent);
					usrMgr.addEventListener(UserEvent.SYNCHRONIZATION_CHANGE, onUserManagerRecieveEvent);
					usrMgr.addEventListener(UserEvent.USER_BOOTED, onUserManagerRecieveEvent);
					usrMgr.addEventListener(UserEvent.USER_CONNECTION_CHANGE, onUserManagerRecieveEvent);
					usrMgr.addEventListener(UserEvent.USER_CREATE, onUserManagerRecieveEvent);
					usrMgr.addEventListener(UserEvent.USER_NAME_CHANGE, onUserManagerRecieveEvent);
					usrMgr.addEventListener(UserEvent.USER_PING_DATA_CHANGE, onUserManagerRecieveEvent);
					usrMgr.addEventListener(UserEvent.USER_REMOVE, onUserManagerRecieveEvent);
					usrMgr.addEventListener(UserEvent.USER_ROLE_CHANGE, onUserManagerRecieveEvent);
					usrMgr.addEventListener(UserEvent.USER_USERICONURL_CHANGE, onUserManagerRecieveEvent);
					ExternalInterface.call("sendToJavaScript", usrObj);
					//swfTrace("Sent usrMgr stuff" + usrObj.hostCollection + usrObj.myUserID);
				}else if(p_msg == "setAnonymousPresence") {
					usrMgr.anonymousPresence = p_args.anonymousPresence;
				}else if(p_msg == "setMyBuddyList") {
					usrMgr.myBuddyList = p_args.buddyList;
				}else if(p_msg == "getUserDescriptor") {
					usrMgr.getUserDescriptor(p_args.userID);
				}else if(p_msg == "setUserRole") {
					usrMgr.setUserRole(p_args.userID, p_args.role);
				}else if(p_msg == "setUserDisplayName") {
					usrMgr.setUserDisplayName(p_args.userID, p_args.name);
				}else if(p_msg == "setPeer") {
					//					usrMgr.setUserDisplayName(p_args.userID, p_args.isPeer);
				}else if(p_msg == "setUserUsericonURL") {
					usrMgr.setUserUsericonURL(p_args.userID, p_args.usericonURL);
				}else if(p_msg == "setPingData") {
					usrMgr.setPingData(p_args.userID, p_args.latency, p_args.drops);
				}else if(p_msg == "registerCustomUserField") {
					usrMgr.registerCustomUserField(p_args.fieldName);
				}else if(p_msg == "setCustomUserField") {
					usrMgr.setCustomUserField(p_args.userID,p_args.fieldName,p_args.value);
				}else if(p_msg == "deleteCustomUserField") {
					usrMgr.deleteCustomUserField(p_args.fieldName);
				}else if(p_msg == "setUserConnection") {
					usrMgr.setUserConnection(p_args.userID, p_args.conn, p_args.forceUpdate);
				}
				
			} else {
				// no op - message we don't recognize
			}
			
			// collectionNode messages (subscribe, publishItem, retractItem, etc)
		}
		
		/**
		 * @private
		 */
		protected function arrayCollectionToObject(p_arr:Array):Object
		{
			var collectionObj:Object = new Object();
			for (var i:int = 0;  i < p_arr.length; i++) {
				var userDesc:UserDescriptor = p_arr[i] as UserDescriptor;
				var userID:String = userDesc.userID;
				collectionObj[i] = userDesc.createValueObject();
			}
			return collectionObj;
		}
		
		/**
		 * @private
		 */
		protected function objToNodeConfig(p_obj:Object):NodeConfiguration
		{
			var nodeConfig:NodeConfiguration = new NodeConfiguration();
			nodeConfig.readValueObject(p_obj);
			return nodeConfig;
		}
		
		/**
		 * @private
		 */
		protected function objToMsgItem(p_obj:Object):MessageItem
		{
			var msgItem:MessageItem = new MessageItem();
			msgItem.readValueObject(p_obj);
			return msgItem;
		}
		
		/**
		 * @private
		 */
		protected function onSyncChange(p_evt:CollectionNodeEvent):void
		{
			var args:Object = new Object();
			var cn:CollectionNode = CollectionNode(p_evt.target);
			args.targetType = "CollectionNode";
			args.type = "synchronizationChange";
			args.targetSharedId = cn.sharedID;
			args.value = cn.isSynchronized;
			if (getNodeRoles(cn)) {
				args.nodeRoles = getNodeRoles(cn);
			}
			args.userRoles = cn.userRoles;
			trace("user Role " + cn.userRoles[cn.connectSession.userManager.myUserID]);
			for (var i:String in cn.userRoles) {
				trace("User Roles " + cn.userRoles[i]);
			}
			trace("CN "+cn.sharedID+" synched "+cn.isSynchronized);
			ExternalInterface.call("sendToJavaScript", args);
		}
		
		/**
		 * @private
		 */
		protected function getNodeRoles(p_collectionNode:CollectionNode):Object
		{
			var nodeNames:Array = p_collectionNode.nodeNames;
			var userRoles:Object = p_collectionNode.userRoles;
			var nodeRoleObject:Object = new Object();
			
			for (var i:int = 0; i < nodeNames.length; i++) {
				nodeRoleObject[nodeNames[i]] = p_collectionNode.getExplicitUserRoles(nodeNames[i]);
			}
			if(nodeNames.length > 0) {
				return nodeRoleObject;
			} else {
				return null;
			}
		}
		
		/**
		 * @private
		 */
		protected function onCollectionNodeRecieveEvent(p_evt:CollectionNodeEvent):void
		{
			ExternalInterface.call("sendToJavaScript", evtToCollectionNodeArgs(p_evt));
		}
		
		/**
		 * @private
		 */
		protected function onUserManagerRecieveEvent(p_evt:UserEvent):void
		{
			ExternalInterface.call("sendToJavaScript", evtToUsrMgrArgs(p_evt));
		}
		
		/**
		 * @private
		 */
		protected function swfTrace(p_traceString:String):void
		{
			ExternalInterface.call("swfTrace", p_traceString);
		}
		
		/**
		 * @private
		 */
		protected function evtToCollectionNodeArgs(p_evt:CollectionNodeEvent):Object
		{
			var args:Object = new Object();
			args.targetType = "CollectionNode";
			args.type = p_evt.type;
			args.targetSharedId = CollectionNode(p_evt.target).sharedID;
			if (p_evt.item) {
				if (p_evt.item.body) {
					//MessageItem.registerBodyClass(Class(flash.utils.getDefinitionByName(flash.utils.getQualifiedClassName(p_evt.item.body))));
					if (p_evt.item.body is Array && p_evt.item.body.length == 0) {
						var body:Array = p_evt.item.body;
						var tmpObject:Object = new Object();
						for (var i:String in body) {
							tmpObject[i] = body[i];
						}
						p_evt.item.body = tmpObject;
					}
				}
				args.item = p_evt.item.createValueObject();
			}
			
			if (p_evt.nodeName) {
				args.nodeName = p_evt.nodeName;
				if ((p_evt.type == CollectionNodeEvent.NODE_CREATE || p_evt.type == CollectionNodeEvent.CONFIGURATION_CHANGE)) {
					if (CollectionNode(p_evt.target).getNodeConfiguration(p_evt.nodeName) != null) {
						args.nodeConfiguration = nodeConfigcreateValueObject(CollectionNode(p_evt.target).getNodeConfiguration(p_evt.nodeName));
					}
				}
			}
			
			if (p_evt.userID) {
				args.userID = p_evt.userID;
			}
			
			if(p_evt.type == CollectionNodeEvent.MY_ROLE_CHANGE || p_evt.type == CollectionNodeEvent.USER_ROLE_CHANGE) {
				if (p_evt.nodeName) {
					args.role = CollectionNode(p_evt.target).getExplicitUserRole(p_evt.userID, p_evt.nodeName);
				} else {
					args.role = CollectionNode(p_evt.target).getUserRole(p_evt.userID);
				}
			}
			return args;
		}
		
		/**
		 * @private
		 */
		protected function nodeConfigcreateValueObject(p_nodeConfig:NodeConfiguration):Object
		{
			var valueObject:Object = new Object();
			valueObject.accessModel = p_nodeConfig.accessModel;
			valueObject.publishModel = p_nodeConfig.publishModel;
			valueObject.persistItems = p_nodeConfig.persistItems;
			valueObject.modifyAnyItem = p_nodeConfig.modifyAnyItem;
			valueObject.userDependentItems = p_nodeConfig.userDependentItems;
			valueObject.sessionDependentItems = p_nodeConfig.sessionDependentItems;
			valueObject.itemStorageScheme = p_nodeConfig.itemStorageScheme;
			valueObject.allowPrivateMessages = p_nodeConfig.allowPrivateMessages;
			valueObject.lazySubscription = p_nodeConfig.lazySubscription;
			valueObject.p2pDataMessaging = p_nodeConfig.p2pDataMessaging;
			return valueObject;
		}
		
		/**
		 * @private
		 */
		protected function evtToUsrMgrArgs(p_evt:UserEvent):Object
		{
			var args:Object = new Object();
			args.targetType = "UserManager";
			args.type = p_evt.type;
			args.targetSharedId = "UserManager";
			var usrMgr:UserManager = p_evt.target as UserManager;
			if (p_evt.type == UserEvent.ANONYMOUS_PRESENCE_CHANGE) {
				args.value = usrMgr.anonymousPresence;
			} else if (p_evt.type == UserEvent.CUSTOM_FIELD_CHANGE) {
				args.customFieldName = p_evt.customFieldName;
				args.value = p_evt.userDescriptor.customFields;
			} else if (p_evt.type == UserEvent.CUSTOM_FIELD_DELETE) {
				args.value = p_evt.customFieldName;
			} else if (p_evt.type == UserEvent.CUSTOM_FIELD_REGISTER) {
				args.value = p_evt.customFieldName;
			} else if (p_evt.type == UserEvent.SYNCHRONIZATION_CHANGE) {
				args.value = usrMgr.isSynchronized;
			} else if (p_evt.type == UserEvent.USER_BOOTED) {
				args.value = p_evt.userDescriptor.createValueObject();
			} else if (p_evt.type == UserEvent.USER_CONNECTION_CHANGE) {
				args.value = p_evt.userDescriptor.createValueObject();
			} else if (p_evt.type == UserEvent.USER_CREATE) {
				args.value = p_evt.userDescriptor.createValueObject();
			} else if (p_evt.type == UserEvent.USER_NAME_CHANGE) {
				args.value = p_evt.userDescriptor.createValueObject();
			} else if (p_evt.type == UserEvent.USER_PING_DATA_CHANGE) {
				args.value = p_evt.userDescriptor.createValueObject();
			} else if (p_evt.type == UserEvent.USER_REMOVE) {
				args.value = p_evt.userDescriptor.createValueObject();
			} else if (p_evt.type == UserEvent.USER_ROLE_CHANGE) {
				args.value = p_evt.userDescriptor.createValueObject();
			} else if (p_evt.type == UserEvent.USER_USERICONURL_CHANGE) {
				args.value = p_evt.userDescriptor.createValueObject();
			}
			return args;
		}
		
	}
}
