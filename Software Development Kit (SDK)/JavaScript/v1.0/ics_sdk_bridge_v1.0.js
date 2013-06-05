/**
 * @File Overview
 * @name ics_sdk_bridge_v1.0.js
 * @description A JavaScript Bridge for the LCCS SDK 
 * @author http://forums.adobe.com/community/livecycle/lccs
 */

/*************************************************************************
 *
 * ADOBE CONFIDENTIAL
 * ___________________
 *
 * Copyright 2007-2010 Adobe Systems Incorporated
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
 **************************************************************************/

/**
 *@private
 */
function myTrace(msg)
{
	alert(msg);
	//window.dump(msg);
}

/**
 *@private
 */
function sendToJavaScript()
{
	//myTrace("arguments length" + arguments.length + arguments[0]);
	var args = arguments[0];
	if (args.targetType =="CollectionNode") {
		//	myTrace("Recieved something from AS side");
		ConnectSession.primarySession.collections[args.targetSharedId].receiveEvent(args);
	} else if (args.targetType =="UserManager") {
		var usrMgr = ConnectSession.primarySession.userManager;
		if (args.type == "getUserMgr") {
			//myTrace("Initializing User Manager");
			usrMgr.initialize(args);
			var evt = new Object();
			evt.target = evt.currentTarget = ConnectSession.primarySession;
			evt.type = "synchronizationChange";
			evt.value = true;
			this.LCCSReady = true;
			ConnectSession.primarySession.dispatchEvent(evt);
			//myTrace(usrMgr.myUserID);
		} else {
			usrMgr.receiveEvent(args);
		}
	} else if (args.targetType =="ConnectSession") {
			if (args.type == "swfReady") {
				var evt = new Object();
				evt.target = evt.currentTarget = ConnectSession.primarySession;
				evt.type = "swfReady";
				ConnectSession.primarySession.dispatchEvent(evt);
			} else {
				var evt = new Object();
				evt.target = evt.currentTarget = ConnectSession.primarySession;
				evt.type = "synchronizationChange";
				this.LCCSReady = args.value;
				evt.value = args.value;
				ConnectSession.primarySession.dispatchEvent(evt);
			}
	}
}

/**
 *@private
 */
function swfTrace()
{
	alert("SWF TRACE Commn from the swf:" + arguments[0]);
}


//TODO: Come on - Prolly its a good idea to dispatch a event :)
/**
 *@private
 */
function swfLoaded()
{
	//This function should be called only by the swf to notify that ConnectSession.PrimarySession is synchronized
	//alert("LCCS is Ready");
	this.LCCSReady = true;
}

/**
 *@private
 * Its a standard solution that is cited on many websites to address scope issues
 */
function bindUsingClosure(func, obj) {
    return function() {
        	func.apply(obj, arguments);
    };
}

/**
 * @class The EventDispatcher class is the helper class for all classes that dispatch events.
 * <p>The event model is similar to,but not the same as ActionScript's event model.
 * Components generate and dispatch events and consume (listen to) other events. An object that requires information
 * about another object's events registers a listener with that object. When an event occurs, the object dispatches
 * the event to all registered listeners by calling a function that was requested during registration. To receive multiple
 * events from the same object, you must register your listener for each event.</p>
 *
 * <p>Components have built-in events that you can handle in your JavaScript applications. You can also take advantage of the
 * model to define your own event listeners outside of your applications, and define which methods of your custom listeners
 * will listen to certain events. You can register listeners with the target object so that when the target object dispatches
 * an event, the listeners get called.</p>
 *
 * @example
 *      // Simple EventListener snippet that you would use for components that
 *      //would dispatch events
 *
 *      //In the example below SimpleChatModel class would dispatch "historyChange"
 *      //event whenever the chat history changes
 *      //1) Add an event Listener
 *      chatModel.addEventListener("historyChange", this);
 *      ....
 *      //2)Define your listener. Its function name should match the event type
 *      //that it is listening to. So the reaction or actions to the event
 *      // "historyChange" would be defined inside the function
 *      function historyChange(evt) {
 *      	document.form1.histArea.value = evt.target.history; 
 *      }
 *
 * @example
 *      //Defining your own CustomEvents.
 *      //1) Register your class with the event listener.
 *      EventDispatcher.initialize(YourClass);
 *
 *      //2) Create your custom event with all the necessay information that you
 *      //would dispatch and that others would expect.
 *      var evt = new Object();
 *      evt.type = "EventType";
 *      evt.target=evt.currentTarget = this;
 *
 *      //3) Dispatch Events as you need them using the dispatchEvent method.
 *      //The scope of the dispatchEvent method is local.So you would have
 *      //to add the "this."
 *	this.dispatchEvent(evt);
 * @constructor
 */
EventDispatcher = function() {
}


EventDispatcher._removeEventListener = function(queue, event, handler)
{
	if (queue != undefined)
	{
		var l = queue.length;
		var i;
		for (i = 0; i < l; i++)
		{
			var o = queue[i];
			if (o == handler) {
				queue.splice(i, 1);
				return;
			}
		}
	}
}


/**
 * Register your class that would need to dispatch events to notify other components
 * @static
 * @function
 * @param object the object to receive the methods
 * @example EventDispatcher.initialize(YourClass);
 */
EventDispatcher.initialize = function(object)
{
	object.addEventListener = _fEventDispatcher.addEventListener;
	object.removeEventListener = _fEventDispatcher.removeEventListener;
	object.dispatchEvent = _fEventDispatcher.dispatchEvent;
	object.dispatchQueue = _fEventDispatcher.dispatchQueue;
	//myTrace("Dispatcher initialized " + object + " "+ object.dispatchEvent);
}

// internal function for dispatching events
EventDispatcher.prototype.dispatchQueue = function(queueObj, eventObj)
{
	var queueName = "__q_" + eventObj.type;
	var queue = queueObj[queueName];
	if (queue != undefined)
	{
		var i;
		// loop it as an object so it resists people removing listeners during dispatching
		for (i in queue)
		{
			var o = queue[i];
			var oType = typeof(o);
			
			// a handler can be a function, object, or movieclip
			if (oType == "object" || oType == "movieclip")
			{
				// this is a backdoor implementation that
				// is not compliant with the standard
				if (o.handleEvent == undefined)
				{
					if (o[eventObj.type] != undefined)
						o[eventObj.type](eventObj);
				}
				else // this is the DOM3 way
				{
					o.handleEvent(eventObj);
				}
			}
			else // it is a function
			{
				o.apply(queueObj, [eventObj]);
			}
		}
	}
}

/**
 * Dispatches an event into the event flow.
 * @function
 * @param eventObj an Event or one of its subclasses describing the event
 * @example
 *      var evt = new Object();
 *      evt.type = "EventType";
 *      evt.target=evt.currentTarget = this;
 *      this.dispatchEvent(evt);
 */
EventDispatcher.prototype.dispatchEvent = function(eventObj)
{
	if (eventObj.target == undefined)
		eventObj.target = this;
	
	if (this[eventObj.type + "Handler"] != undefined)
		this[eventObj.type + "Handler"](eventObj);
	
	// Dispatch to objects that are registered as listeners for
	// this object.
	this.dispatchQueue(this, eventObj);
}

/**
 * Registers an event listener object with an EventDispatcher model so that the listener receives notification of an event.
 * @function
 * @param event the name of the event ("click", "change", etc)
 * @param the function or object that should be called
 * @example chatModel.addEventListener("historyChange", this);
 */
EventDispatcher.prototype.addEventListener = function(event, handler)
{
	var queueName = "__q_" + event;
	if (this[queueName] == undefined)
	{
		this[queueName] = new Array();
	}
	//Not supported in asc, it shouldn't matter. _global.ASSetPropFlags(this, queueName,1);
	
	EventDispatcher._removeEventListener(this[queueName], event, handler);
	this[queueName].push(handler);
}

/**
 * Remove a listener for a particular event
 * @function
 * @param event the name of the event ("click", "change", etc)
 * @param the function or object that should be called
 * @example chatModel.removeEventListener("historyChange", this);
 */
EventDispatcher.prototype.removeEventListener = function(event, handler)
{
	var queueName = "__q_" + event;
	EventDispatcher._removeEventListener(this[queueName], event, handler);
}

_fEventDispatcher = new EventDispatcher();





/**
 * @class ConnectSession is responsible to establish a session with LCCS.
 * Its the Room's primary session that is passed from the invisible swf. It is responsible for the operation
 * of the UserManager class and maintains the UserManager property to access them.
 * <table><tr><th><b>Event</b></th><th><b>Summary</b></th></tr>
 * <tr><td valign="top"><code>SynchronizationChange</code></td> <td>This event is dispatched when the <code>ConnectSession</code> establishes or loses its connection to the service</td></tr></table>
 * @param p_bridgeSWF {string} The invisble swf's name that is responsible for the communication with the LCCS
 *
 * @example
 * var cs = new ConnectSession("JSBridge"); //For WebKit based browsers
 * @constructor
 */
function ConnectSession(p_bridgeSWF)
{
	if (typeof(p_bridgeSWF)== "string") {
		if (navigator.appName.indexOf("Microsoft") != -1) {
		    p_bridgeSWF = window[p_bridgeSWF];
		} else {
		    p_bridgeSWF = document[p_bridgeSWF];
		}
	}
	this.bridgeSWF = p_bridgeSWF;
	ConnectSession.primarySession = this;
	this.userManager = new UserManager();
	this.addEventListener("swfReady",this);
}
EventDispatcher.initialize(ConnectSession.prototype);
/**
 *The userManager of the room's Primary Connect Session
 *@field userManager
 */
ConnectSession.prototype.userManager = undefined;
/**
 * (Required) The authenticator through which login information is passed.
 * The authenticator object could have any of the following values.
 * <ul>
 * <li>userName - When <code>authenticationKey</code> is not used, <code>
 * userName</code> is required upon room entry; when a someone enters as a guest, the name 
 * becomes the user's display name.
 * <p>
 * Two cases are supported: 
 * <ul>
 * <li><strong>userName is supplied with no password</strong>: The user is logged in as 
 * viewer and <code>UserDescriptor.displayName</code> is set to the value in 
 * <code>userName</code>.
 * 
 * <li><strong>A username and password are supplied</strong>: <code>password</code>
 * is only provided when members login with Adobe IDs which is an uncommon case. See below.
 * </ul></li>
 * <li>password - <code>password</code> is only required when Adobe IDs
 * are used; therefore, it is likely that only developers would need this parameter except
 * during development. If used, it is supplied in addition to 
 * <code>userName</code> and permits admitting users as other than a guest. 
 * Note that while it is possible for registered Adobe service users to use their Adobe ID, 
 * applications will likely leverage LCCS's external authentication capabilities so that 
 * <code>authenticationKey</code> would be used in lieu of a username and
 * password.  </li>
 * <li>authenticationURL - Allows a developer to specify the URL of a LCCS-compatible authentication service; 
 * it is <strong>not needed</strong> for many applications.</li>
 * </ul>
 * Code example
 * <code>
 * 	connectSession.roomURL = "http://connectnow.acrobat.com/accountName/roomName";
 * 	var auth = new Object();
 * 	auth.userName = "username@xyz.com";
 * 	auth.password = "password";
 * 	connectSession.authenticator = auth;
 * </code>
 *@field userManager
 */
ConnectSession.prototype.authenticator = undefined;
/**
 * (Required) The URL of the room to which to connect.
 *@field roomURL
 */
ConnectSession.prototype.roomURL = undefined;
/**
 *@private
 */
ConnectSession.prototype.swfLoaded = false;

/**
 *@private
 */
ConnectSession.prototype.loginFlag = false;

/**
 *@private
 */
ConnectSession.prototype.subscribeCollection = function(p_collection)
{
	if (this.collections == null) {
		this.collections = new Object();
		this.collections[p_collection.sharedID] = p_collection;
	} else {
		this.collections[p_collection.sharedID] = p_collection;
	}
	//this.bridgeSWF.RTCIncoming("CollectionNode", "subscribeCollection", p_collection.sharedID)
	var args = new Object();
	args.sharedID = p_collection.sharedID;
	this.callLCCSMethod("CollectionNode", "subscribeCollection", args);
}

/**
 *@private
 */
ConnectSession.prototype.publishItem = function(p_collection, p_messageItem)
{
	//this.bridgeSWF.RTCIncoming("CollectionNode", "publishItem", p_collection.sharedID, p_messageItem)
	var args = new Object();
	args.sharedID = p_collection.sharedID;
	args.messageItem = p_messageItem;
	this.callLCCSMethod("CollectionNode", "publishItem", args);
}

/**
 *@private
 */
ConnectSession.prototype.swfReady = function(p_evt)
{
	this.swfLoaded = true;
	if (this.loginFlag) {
		this.loginFlag = false;
		this.login();
	}
}

/**
* Logs into the RTC service. Calling login is required for using ConnectSession, as compared with ConnectSessionContainer,
* Which does so automatically.
* @function
*/
ConnectSession.prototype.login = function() {
	if (this.authenticator && this.roomURL) {
		if (this.swfLoaded) {
			var roomURL = new Object();
			roomURL.roomURL = this.roomURL;
			this.callLCCSMethod("ConnectSession", "setRoomURL", roomURL);
			this.callLCCSMethod("ConnectSession", "setAuthenticator", this.authenticator);
			this.callLCCSMethod("ConnectSession", "login", null);
		} else {
			this.loginFlag = true;
		}
	}
}

/**
 * Logs out and disconnects from the session.
 * @function
 */
ConnectSession.prototype.logout = function() {
	this.callLCCSMethod("ConnectSession", "logout", null);
}

/**
 * Disposes all listeners to the network and framework classes.
 * @function
 */
ConnectSession.prototype.close = function() {
	this.callLCCSMethod("ConnectSession", "close", null);
}

/**
 * A function that indicates whether or not the ConnectSession is fully synchronized with the service.
 * @function
 */
ConnectSession.prototype.isSynchronized = function() {
	return this.LCCSReady;
}

/**
 *@private
 */
ConnectSession.prototype.callLCCSMethod = function(p_className,p_methodName, p_methodArgs)
{
	this.bridgeSWF.RTCIncoming(p_className, p_methodName, p_methodArgs);
}

/**
 *@private
 */
function UserDescriptor()
{
	
}
/**
 *@private
 */
UserDescriptor.prototype.userID = "";
/**
 *@private
 */
UserDescriptor.prototype.displayName = "";
/**
 *@private
 */
UserDescriptor.prototype.role = 0;
/**
 *@private
 */
UserDescriptor.prototype.affiliation = 0;
/**
 *@private
 */
UserDescriptor.prototype.connection = "";
/**
 *@private
 */
UserDescriptor.prototype.usericonURL = "";
/**
 *@private
 */
UserDescriptor.prototype.playerVersion = "";
/**
 *@private
 */
UserDescriptor.prototype.isPeer = false;
/**
 *@private
 */
UserDescriptor.prototype.isRTMFP = false;

/**
 *@private
 */
UserDescriptor.prototype.setValues = function(usrDescObj)
{
	for (var i in usrDescObj) {
		if (i != undefined && UserDescriptor.prototype.hasOwnProperty(i)) {
			this[i] = usrDescObj[i];
		}
	}
}

function MessageItem()
{
	
}
//MessageItem.prototype.SINGLE_ITEM_ID = "item";
MessageItem.prototype.nodeName;
MessageItem.prototype.itemID;
MessageItem.prototype.body;
MessageItem.prototype.publisherID;
MessageItem.prototype.associatedUserID;
MessageItem.prototype.recipientID;
MessageItem.prototype.recipientIDs;
MessageItem.prototype.timeStamp;
MessageItem.prototype.collectionName;

function NodeConfiguration()
{
	
}

NodeConfiguration.prototype.accessModel=10;
NodeConfiguration.prototype.publishModel=50;
NodeConfiguration.prototype.persistItems=true;
NodeConfiguration.prototype.modifyAnyItem=true;
NodeConfiguration.prototype.userDependentItems=false;
NodeConfiguration.prototype.sessionDependentItems=false;
NodeConfiguration.prototype.itemStorageScheme=0;
NodeConfiguration.prototype.allowPrivateMessages=false;
NodeConfiguration.prototype.lazySubscription=false;
NodeConfiguration.prototype.p2pDataMessaging=false;

/**
 * @class UserManager is one of the "four pillars" of a room and is tasked with maintaining a list of the set of users in the room, along with their descriptors.
 * It is also the primary class through which one publishes changes to a user role or other user information.
 * <table><tr><th><b>Event</b></th><th><b>Summary</b></th></tr>
 * <tr><td valign="top"><code>anonymousPresenceChange </code></td> <td>	 Dispatched when anonymousPresence is set in the UserManager  </td></tr>
 * <tr><td valign="top"><code>customFieldChange</code></td> <td> Dispatched when a custom field value for a user has changed. </td></tr>
 * <tr><td valign="top"><code>customFieldDelete</code></td> <td> Dispatched when a custom field for a user is deleted. </td></tr>
 * <tr><td valign="top"><code>customFieldRegister</code></td> <td> Dispatched when a custom field for a user is registered. </td></tr>
 * <tr><td valign="top"><code>synchronizationChange</code></td> <td> Dispatched when the UserManager has received everything up to the current state of the room or has lost the connection. </td></tr>
 * <tr><td valign="top"><code>userBooted</code></td> <td> Dispatched when a user is forcibly ejected from the room.  </td></tr>
 * <tr><td valign="top"><code>userConnectionChange</code></td> <td> Dispatched when a user's connection speed has changed. </td></tr>
 * <tr><td valign="top"><code>userCreate</code></td> <td> Dispatched when a new user joins the room. </td></tr>
 * <tr><td valign="top"><code>userNameChange</code></td> <td> Dispatched when the user's displayName has changed. </td></tr>
 * <tr><td valign="top"><code>userPingDataChange</code></td> <td> Dispatched when a user's ping data has changed. </td></tr>
 * <tr><td valign="top"><code>userRemove</code></td> <td> Dispatched when a user leaves the room. </td></tr>
 * <tr><td valign="top"><code>userRoleChange</code></td> <td> Dispatched when the user's role has changed. </td></tr>
 * <tr><td valign="top"><code>userUsericonURLChange</code></td> <td> Dispatched when a user's icon URL has changed. </td></tr>
 * </table>
 * @constructor
 */
function UserManager()
{
	//Mention the fact that UserManager is not exactly a symmetrical copy of SDK's UserManager
	//While setting some properties, there is a possibility of a user not able to set some properties
	//So should set properties only if you are the room Owner
	
	//Flexible rights can be future upgrade. This would require some SDK changes as well
}

EventDispatcher.initialize(UserManager.prototype);

/**
 *Determines whether all the others users in the room be revealed. Upon setting this property to true, users aren't revealed until explicitly called for.
 *UserManager.userCollection and getUserDescriptor won't have any entry for any user (other than one's self) unless there's a specific request for that user.
 *Any call to the getUserDescriptor will cause the UserManager to fetch that particular UserDescriptor and cache it, dispatching the usual userCreate event. 
 *@field
 */
UserManager.prototype.anonymousPresence = false;
/**
 *An array of userIDs, which represents the set of users which might be listening for the current user's updates
 *Note, this isn't the set of users the current user is listening for, but rather the inverse.
 *The current user would notify users in the Array about all his activities. In other words the users in the Array users are listening to the current user even if he is not listening to them. 
 *@field
 */
UserManager.prototype.myBuddyList = new Array();
/**
 *The current user's userID. 
 *@field
 */
UserManager.prototype.myUserID = "";
/**
 *THe current user's userTicket
 *@private 
 *@field
 */
UserManager.prototype.myTicket = "";
/**
 *Specifies the current user's affiliation. 
 *@field
 */
UserManager.prototype.myUserAffiliation = 0;
/**
 *Specifies the current user's role
 *@field
 */
UserManager.prototype.myUserRole = 0;
/**
 *This field is set if anyone has peer to peer disabled. i.e. behind firewall or something...
 *@field
 */
UserManager.prototype.isPeerEnable = false;
/**
 *Returns a sorted collection of user descriptors with root user roles of UserRoles.VIEWER (10).
 *@field
 */
UserManager.prototype.audienceCollection = new Object();
/**
 *Returns a sorted collection of user descriptors with root user roles of UserRoles.OWNER (100).
 *@field
 */
UserManager.prototype.hostCollection = new Object();
/**
 *Returns a sorted collection of user descriptors with root user roles of UserRoles.PUBLISHER (50).
 *@field
 */
UserManager.prototype.participantCollection = new Object();
/**
 *internal storage for the entire set of users (hashed by userID)
 *@private
 *@field
 */
UserManager.prototype.userDescriptorTable= new Object();
/**
 *Specifies whether or not the UserManager has connected and has synchronized all of the user information from the service.
 *The userManager of the room's Primary Connect Session
 *@field
 */
UserManager.prototype.isSynchronized=false;
/**
 *Returns the list of all the custom fields created.
 *@field
 */
UserManager.prototype.customFieldNames = new Object();
/**
 *Used to recreate the UserManager once the ConnectSession.primarySession's userManager is synchronized
 *@function
 *@private
 */
UserManager.prototype.initialize = function(usrObj)
{
	for (var i in usrObj) {
		if (i != undefined && UserManager.prototype.hasOwnProperty(i)) {
			if(i == "audienceCollection" || i == "hostCollection" || i == "participantCollection") {
				//Might have to translate the values in the collection to UserDescriptor.
				this[i] = this.objectValuesToUserDescriptorUtility(usrObj[i]);
			} else {
				this[i] = usrObj[i];
			}
		}
	}
	this.isSynchronized = true;
	//myTrace("Just stopping to examine");
}

/**
 *@private
 */
UserManager.prototype.objectValuesToUserDescriptorUtility = function(usrCollection,keyString)
{
	var usrObj = new Object();
	for (var i in usrCollection) {
		var usrDesc = new UserDescriptor();
		usrDesc.setValues(usrCollection[i]);
		var usrID = usrDesc.userID;
		//usrCollection[usrID] = usrDesc;
		usrObj[usrID] = usrDesc;
		this.userDescriptorTable[usrID] = usrDesc;
	}
	return usrObj;
	//this[keyString] = usrObj;
}

/**
 *Set whether other users in the room should be revealed or not.
 *@param p_anonymousPresence {boolean}
 *@function
 */
UserManager.prototype.setAnonymousPresence = function(p_anonymousPresence)
{
	//Set the local value of the anonymousPresence once it is set on the server
	if (this.anonymousPresence != p_anonymousPresence && this.myUserRole >= 50 && this.isSynchronized) {
		var args = new Object();
		args.anonymousPresence = p_anonymousPresence;
		this.connectSession.callLCCSMethod("UserManager", "setAnonymousPresence", args);
	}
}

/**
 *An array of userIDs, which represents the set of users which might be listening for the current user's updates Note, this isn't the set of users the current user is listening for, but rather the inverse.
 *@param p_buddyList {array} List of buddies with their userId's
 *@function
 */
UserManager.prototype.setMyBuddyList = function(p_buddyList)
{
	//Set the local value of the anonymousPresence once it is set on the server
	if (this.myUserRole >= 50 && this.isSynchronized) {
		var args = new Object();
		args.buddyList = p_buddyList;
		this.connectSession.callLCCSMethod("UserManager", "setMyBuddyList", args);
	}
}



/**
 * Fetches all available details about the specified user. If <code>anonymousPresence</code> is set to true,
 * the method migth return a null if <code>UserDescriptor</code> was never fetched. In such a situation we must
 * listen to <code>UserEvent.USER_CREATE</code> event and update the User's  <code>UserDescriptor</code> we wanted.
 * 
 * Note: If the <code>UserManager.anonymousPresence</code> is set to true, then this method might fail if the
 * user's userDescriptor has not been fetched. So it is adviced to call this method after the required userDescriptor's
 * are fetched.In other words listen to <code>UserEvent.USER_CREATE</code> event and call this method after the required
 * userDescriptor's are fetched.
 * @function
 * @param p_userID The unique ID of the user being queried.
 * @return The UserDescriptor of the specified user if <code>anonymousPresence</code> were false.
 */
UserManager.prototype.getUserDescriptor = function(p_userID)
{
	if (this.userDescriptorTable[p_userID]) {
		return this.userDescriptorTable[p_userID];
	} else {
		if (this.anonymousPresence) {
			//fetchUserDescriptor(p_userID);
			var args = new Object();
			args.userID = p_userID;
			this.connectSession.callLCCSMethod("UserManager", "getUserDescriptor", args);
			return null;
		} else {
			return null;		
		}
	}
}

/**
 * Promotes or demotes the specified user at the "root level". This is the primary 
 * way to change a user's role (although it's also possible to change a user's role relative 
 * to a specific CollectionNode within the application). Note that only users with an owner 
 * role  at the root level may call this method.
 * 
 * @param p_userID The unique ID of the user to affect
 * @param p_role The new role for the user
 * @function
 */
UserManager.prototype.setUserRole = function(p_userID, p_userRole)
{
	//Set the local value of the userRole once it is set on the server
	//Talk to nigel abt dual or conflicting userRoles ie a guy who can
	//configure usrMgr alone but his general role is less than the owner or
	//publisher
	if (this.myUserRole >= 50 || (this.myUserAffiliation==100 && p_userID==this.myUserID)) {
		var args = new Object();
		args.userID = p_userID;
		args.role = p_userRole;
		this.connectSession.callLCCSMethod("UserManager", "setUserRole", args);
	}
}

/**
 * Gets the role of the specified user for a particular node. 
 * 
 * @param p_userID The specified user's <code>userID</code>.
 * @return int which is the user role value
 * @function
 */
UserManager.prototype.getUserRole = function(p_userID)
{
	if (this.userDescriptorTable[p_userID] &&  this.isSynchronized) {
		return this.userDescriptorTable[p_userID].role;
	}
}


/**
 * Modifies the displayName of a given user. Note that only OWNERs and the user in question are able to 
 * change the user's displayName.
 * 
 * Note: If the <code>UserManager.anonymousPresence</code> is set to true, then this method might fail if the
 * user's userDescriptor has not been fetched. So it is adviced to call this method after the required userDescriptor's
 * are fetched.In other words listen to <code>UserEvent.USER_CREATE</code> event and call this method after the required
 * userDescriptor's are fetched.
 * 
 * @param p_userID The userID of the specified user
 * @param p_name The new displayName to assign to that user
 * @function
 */
UserManager.prototype.setUserDisplayName = function(p_userID,p_name)
{
	//Ensure u have the right priviliges.
	
	//Set the local value of the userRole once it is set on the server
	//Talk to nigel abt dual or conflicting userRoles ie a guy who can
	//configure usrMgr alone but his general role is less than the owner or
	//publisher
	if (this.myUserRole >= 50 &&  this.isSynchronized) {
		var args = new Object();
		args.userID = p_userID;
		args.name = p_name;
		this.connectSession.callLCCSMethod("UserManager", "setUserDisplayName", args);
	}
}

/**
 * Modifies the isPeer property of a given user. Note that only OWNERs and the user in question are able to 
 * change the user's displayName. This shows whether an user can do p2p streaming.
 * @param p_userID The userID of the specified user
 * @param p_name The new displayName to assign to that user
 * @function
 */
UserManager.prototype.setPeer = function(p_userID,p_isPeer)
{
	//Ensure u have the right priviliges.
	
	//Set the local value of the userRole once it is set on the server
	//Talk to nigel abt dual or conflicting userRoles ie a guy who can
	//configure usrMgr alone but his general role is less than the owner or
	//publisher	
	if (this.myUserRole >= 50 &&  this.isSynchronized) {
		var args = new Object();
		args.userID = p_userID;
		args.isPeer = p_isPeer;
		this.connectSession.callLCCSMethod("UserManager", "setPeer", args);
	}
}


/**
 * Sets the URL for the user's avatar icon.
 * 
 * Note: If the <code>UserManager.anonymousPresence</code> is set to true, then this method might fail if the
 * user's userDescriptor has not been fetched. So it is adviced to call this method after the required userDescriptor's
 * are fetched.In other words listen to <code>UserEvent.USER_CREATE</code> event and call this method after the required
 * userDescriptor's are fetched.
 * 
 * @param p_userID The userID of the user specified.
 * @param p_usericonURL the URL of the icon desired.
 * @function
 */
UserManager.prototype.setUserUsericonURL = function(p_userID,p_usericonURL)
{
	if (this.myUserRole >= 50 &&  this.isSynchronized) {
		var args = new Object();
		args.userID = p_userID;
		args.usericonURL = p_usericonURL;
		this.connectSession.callLCCSMethod("UserManager", "setUserUsericonURL", args);
	}
}


/**
 * Publishes a ping data update.
 * @param p_userID The userID of the user to update.
 * @param p_latency The new latency statistic.
 * @param p_drops The new drops statistic.
 * @function
 */
UserManager.prototype.setPingData = function(p_userID,p_latency, p_drops)
{
	if (this.myUserRole >= 50 &&  this.isSynchronized) {
		var args = new Object();
		args.userID = p_userID;
		args.latency = p_latency;
		args.drops = p_drops;
		this.connectSession.callLCCSMethod("UserManager", "setPingData", args);
	}
}


/**
 * Registers a custom field for use in the userDescriptor (will appear in the CustomField Object).
 * Only hosts are allowed to create regisfields, but users can publish them once
 * @param p_fieldName The name of the new custom field
 * @function
 */
UserManager.prototype.registerCustomUserField = function(p_fieldName)
{
	if (this.myUserRole >= 50 &&  this.isSynchronized) {
		var args = new Object();
		args.fieldName = p_fieldName;
		this.connectSession.callLCCSMethod("UserManager", "registerCustomUserField", args);
	}
}

/**
 * Tests whether a custom field is already registered with the UserManager
 * @param p_fieldName the custom field in question
 * @return true if defined, false if not
 * @private
 */
UserManager.prototype.isCustomFieldDefined = function(p_fieldName)
{
	if (this.customFieldNames[p_fieldName]) {
		return true;
	} else {
		return false;
	}
}

/**
 * Custom User Fields are used to store extended info about a particular user (for example, phone status, "I have a question", etc).
 * A custom field must be registered before it can be modified. Custom fields are modifiable by the given user or a host.
 * @param p_userID The user to be modified
 * @param p_fieldName The name of the custom field to modify
 * @param p_value The new value for the custom field (null to delete)
 * @function
 */
UserManager.prototype.setCustomUserField = function(p_userID,p_fieldName,p_value)
{
	if (this.myUserRole >= 50 &&  this.isSynchronized) {
		var args = new Object();
		args.fieldName = p_fieldName;
		args.userID = p_userID;
		args.value = p_value;
		this.connectSession.callLCCSMethod("UserManager", "setCustomUserField", args);
	}
}

/**
 * Deletes a custom field for used in the customField Object).
 * Only hosts are allowed to create deleteFields.
 * @param p_fieldName The name of the custom field to be deleted
 * 
 */
UserManager.prototype.deleteCustomUserField = function(p_fieldName)
{
	if (this.myUserRole >= 50 &&  this.isSynchronized) {
		var args = new Object();
		args.fieldName = p_fieldName;
		this.connectSession.callLCCSMethod("UserManager", "deleteCustomUserField", args);
	}
}

/**
 * Sets the user's connection to one of the following: 
 * <ul>
 * <li>RoomSettings.MODEM</li>
 * <li>RoomSettings.DSL</li>
 * <li>RoomSettings.LAN</li>
 * </ul> 
 * 
 * Note: If the <code>UserManager.anonymousPresence</code> is set to true, then this method might fail if the
 * user's userDescriptor has not been fetched. So it is adviced to call this method after the required userDescriptor's
 * are fetched.In other words listen to <code>UserEvent.USER_CREATE</code> event and call this method after the required
 * userDescriptor's are fetched.
 * 
 * @param p_userID The userID of the user the change.
 * @param p_conn The new connection speed value which is one of the RoomSetting constants.
 * @param p_forceUpdate Whether or not the update should be forced; the default is false. 
 */
UserManager.prototype.setUserConnection = function(p_userID, p_conn, p_forceUpdate)
{
	if (this.myUserRole >= 50 &&  this.isSynchronized) {
		var args = new Object();
		args.userID = p_userID;
		args.conn = p_conn;
		args.forceUpdate = p_forceUpdate;
		this.connectSession.callLCCSMethod("UserManager", "setUserConnection", args);
	}
}

/**
 * This function checks if anyone has peer to peer disabled. i.e. behind firewall or something...
 * @returns {boolean} returns if the p2p is disabled.
 * @function
 */
UserManager.prototype.getIsPeerEnable = function()
{
	for (var i in this.userDescriptorTable) {
		if (!this.userDescriptorTable[i].isPeer) {
			return false;
		}
	}
	return true;
}

/*
*@private
*/
UserManager.prototype.updateUserTables = function(args)
{
	this.userDescriptorTable[args.value.userID] = args.value;
	if (args.value.role == 100) {
		this.hostCollection[args.value.userID] = args.value;
	} else if (args.value.role == 50) {
		this.participantCollection[args.value.userID] = args.value;
	} else if(args.value.role <= 10){
		this.audienceCollection[args.value.userID] = args.value;
	}
}

/*
* Internal helper method to dispatchEvents and morph arguments to objects and set the target & currentTarget
*@private
*/
UserManager.prototype.receiveEvent = function(args)
{
	var evt = new Object();
	evt.type = args.type;
	evt.currentTarget = evt.target = this;
	if (evt.type == "anonymousPresenceChange") {
		this.anonymousPresence  = args.value;
	} else if (evt.type == "customFieldChange") {
		if(this.isCustomFieldDefined(args.customFieldName)) {
			this.customFieldNames[args.customFieldName] = args.value;
		}
	} else if (evt.type == "customFieldDelete") {
		if(this.isCustomFieldDefined(args.value)) {
			delete 	this.customFieldNames[args.value]
		}
	} else if (evt.type == "customFieldRegister") {
		this.customFieldNames[args.value] = new Object();
	} else if (evt.type == "synchronizationChange") {
		this.isSynchronized = evt.value;
	} else if (evt.type == "userBooted") {
		if (this.userDescriptorTable[args.value.userID]) {
			delete this.userDescriptorTable[args.value.userID];
		}
		if (args.value.role == 100 && this.hostCollection[args.value.userID]) {
			delete this.hostCollection[args.value.userID];
		} else if (args.value.role == 50 && this.participantCollection[args.value.userID]) {
			delete this.participantCollection[args.value.userID];
		} else if(args.value.role <= 10 && this.audienceCollection[args.value.userID]){
			delete this.audienceCollection[args.value.userID];
		}
		evt.userID = args.value.userID;
	} else if (evt.type == "userConnectionChange") {
		this.updateUserTables(args);
		evt.userID = args.value.userID;
	} else if (evt.type == "userCreate") {
		this.updateUserTables(args);
		evt.userID = args.value.userID;
	} else if (evt.type == "userNameChange") {
		this.updateUserTables(args);
		evt.userID = args.value.userID;
	} else if (evt.type == "userPingDataChange") {
		this.updateUserTables(args);
		evt.userID = args.value.userID;
	} else if (evt.type == "userRemove") {
		delete this.userDescriptorTable[args.value.userID];
		if (args.value.role == 100 && this.hostCollection[args.value.userID]) {
			delete this.hostCollection[args.value.userID];
		} else if (args.value.role == 50 && this.participantCollection[args.value.userID]) {
			delete this.participantCollection[args.value.userID];
		} else if(args.value.role <= 10 && this.audienceCollection[args.value.userID]){
			delete this.audienceCollection[args.value.userID];
		}
		evt.userID = args.value.userID;
	} else if (evt.type == "userRoleChange") {
		this.userDescriptorTable[args.value.userID] = args.value;
		if (args.value.role == 100) {
			this.hostCollection[args.value.userID] = args.value;
			if(this.participantCollection[args.value.userID] ) {
				delete this.participantCollection[args.value.userID];
			}
			if(this.audienceCollection[args.value.userID] ) {
				delete this.audienceCollection[args.value.userID];
			}			
		} else if (args.value.role == 50) {
			this.participantCollection[args.value.userID] = args.value;
			if(this.hostCollection[args.value.userID] ) {
				delete this.hostCollection[args.value.userID];
			}
			if(this.audienceCollection[args.value.userID] ) {
				delete this.audienceCollection[args.value.userID];
			}
			
			
		} else if(args.value.role <= 10){
			this.audienceCollection[args.value.userID] = args.value;
			if(this.participantCollection[args.value.userID] ) {
				delete this.participantCollection[args.value.userID];
			}
			if(this.hostCollection[args.value.userID] ) {
				delete this.hostCollection[args.value.userID];
			}
		}
		evt.userID = args.value.userID;
	} else if (evt.type == "userUsericonURLChange") {
		this.updateUserTables(args);
		evt.userID = args.value.userID;
	}
	this.dispatchEvent(evt);
}



/**
 * @class CollectionNode is the foundation class for building shared models requiring publish
 * and subscribe messaging. All shared classes including the sharedModel, sharedManager, 
 * and many pods use CollectionNodes in order to manage  messages, permissions, and roles.
 * <p>
 * At its core, a room can be logically seen as a group of CollectionNodes. For example, 
 * one CollectionNode is used in a chat pod, one within UserManager, and so on. CollectionNodes, 
 * in turn, are made up of nodes which can be thought of as permission-managed channels 
 * through which MessageItems are sent and received. Each node has its own NodeConfiguration 
 * which determines the permissions and storage policies sent through it.
 * </p>
 * <p>
 * CollectionNode is the main component class developers will create and interact with in order
 * accomplish the following: 
 * <ul>
 *  <li>Create message nodes.</li>
 *  <li>Publish MessageItems to those nodes.</li>
 *  <li>Subscribe to nodes.</li>
 *  <li>Configure nodes.</li>
 *  <li>Manage collection and node user roles.</li>
 * </ul>
 * Only users with a role of <code>UserRoles.OWNER</code> may create and configure collectionNodes. 
 * Users of <code>UserRoles.PUBLISHER</code> can typically publish MessageItems, and 
 * <code>UserRoles.VIEWER</code> may subscribe and receive messages. As such, it's typically 
 * the case that an owner set up the required CollectionNodes in a room before publishers may 
 * publish or viewers may receive MessageItems.
 * <p>
 * CollectionNodes do not store the items which pass through them even if they are stored on 
 * the services. Developers are advised to listen to the <code>ITEM_RECEIVE</code> event and 
 * store details as needed in their own models.
 * <table><tr><th><b>Event</b></th><th><b>Summary</b></th></tr>
 * <tr><td valign="top"><code>configurationChange </code></td> <td> Dispatched when a node within the collection has a change in its configuration (typically, its access-model).</td></tr>
 * <tr><td valign="top"><code>itemReceive</code></td> <td> Dispatched when a node within the collection receives an item.</td></tr>
 * <tr><td valign="top"><code>itemRetract</code></td> <td> Dispatched when a node within the collection retracts an item.</td></tr>
 * <tr><td valign="top"><code>myRoleChange</code></td> <td> Dispatched when the current user's role changes for the  collectionNode as a whole and not nodes within it.</td></tr>
 * <tr><td valign="top"><code>nodeCreate</code></td> <td> Dispatched when a node is created within the collection.</td></tr>
 * <tr><td valign="top"><code>nodeDelete</code></td> <td> Dispatched when a node is deleted within the collection.</td></tr>
 * <tr><td valign="top"><code>reconnect</code></td> <td> Dispatched when the collection has been disconnected from the server and is in the process of reconnecting and re-subscribing.</td></tr>
 * <tr><td valign="top"><code>synchronizationChange</code></td> <td> Dispatched when the collection has fully received all nodes and items stored up until the present time thereby becoming synchronized as well as when the collection becomes disconnected from (and thus "out of sync" with) the room's messaging bus.</td></tr>
 * <tr><td valign="top"><code>userRoleChange</code></td> <td> Dispatched when the collection or a node within the collection, has a change in roles for any user.</td></tr>
 * </table>
 *
 * @constructor
 */	
function CollectionNode()
{
	this.connectSession = ConnectSession.primarySession;
}
EventDispatcher.initialize(CollectionNode.prototype);

/**
 * The <code>sharedID</code> is the logical address of this collection 
 * within the room and must therefore be unique from all other CollectionNode names.
 * @field
 */
CollectionNode.prototype.sharedID = "";
/**
 * The ConnectSession with which this component is associated. Note that this may only be set once before <code>subscribe</code>
 * is called; re-sessioning of components is not supported.
 * @field
 */
CollectionNode.prototype.connectSession = undefined;
/**
 * Determines whether or not the collection is "up to state" with all previously 
 * stored items in its nodes. Once a CollectionNode has successfully connected 
 * to the service and retrieved all its nodes and messageItems, it is considered 
 * synchronized. If the connection is lost, it becomes unsynchronized until it 
 * fully reconnects and re-retrieves its state.
 * @field
 */
CollectionNode.prototype.isSynchronized = false;
/**
 *@private
 *@field
 */
CollectionNode.prototype.messageNodes;
/**
 * @private
 * @field
 */
CollectionNode.prototype.nodeUserRoles;
/**
 * The complete set of roles for this collection described as {userID:role} pairs.
 * @field
 */
CollectionNode.prototype.userRoles = undefined;

/**
 * <code>subscribe()</code> causes the CollectionNode to subscribe to the logical 
 * destination provided by <code>collectionName</code>. If there is no such 
 * destination on the service and the current user has an owner role, a new 
 * CollectionNode is created and stored on the service with the given <code>
 * collectionName</code>.
 * When subscription is successful or a new CollectionNode is created, the collection:
 * <ul>
 * <li>Discovers all the accessible nodes for this collection along with 
 * their configurations and roles.</li>
 * <li>Subscribes to all nodes allowed within the collection.</li>																</li>
 * <li>Retrievs all stored items for all nodes within it and broadcasts <code>
 * ITEM_RECEIVE</code> events for each.</li>
 * <li>Fires a <code>COLLECTION_SYNCHRONIZE</code> event once the collection 
 * has retrieved the data above.</li>
 * </ul>
 * @function
 */		
CollectionNode.prototype.subscribe = function()
{
	this.connectSession.subscribeCollection(this);
}

/**
 * Determines whether or not the collection is empty, that is, having no nodes
 * @return Boolean
 * @function
 */
CollectionNode.prototype.isEmpty = function()
{
	for (var i in this.messageNodes)
	{
		return true;
	}
	return false;
}

/**
 * Disconnects this CollectionNode from the server. Typically used for garbage collection. 
 * If a node is subscribed but a network or services glitch causes it to disconnect, 
 * the CollectionNode will attempt to reconnect automatically.
 * @function
 */
CollectionNode.prototype.unsubscribe = function()
{
	args.sharedID = this.sharedID;
	this.connectSession.callLCCSMethod("CollectionNode", "unsubscribe");
}

/**
 * Creates a new node in this collection; they are either optionally configured when 
 * created or accept the default configuration. Note that only users with and owner role 
 * may create or configure nodes on a CollectionNode.
 * 
 * @param p_nodeName The name for the new node which must be unique within the CollectionNode.
 * @param p_nodeConfiguration Optionally, the configuration for this node. If none is supplied, 
 * <code>NodeConfiguration.defaultConfiguration</code> is used.
 * @function
 */
CollectionNode.prototype.createNode = function(p_nodeName,p_nodeConfiguration)
{
	var args = new Object();
	args.nodeName = p_nodeName;
	args.sharedID = this.sharedID;
	args.nodeConfiguration = p_nodeConfiguration;
	this.connectSession.callLCCSMethod("CollectionNode", "createNode", args);
}

/**
 * Configures a node in this collection and replaces the existing NodeConfiguration. 
 * Only users with an owner role may change a node's configuration.
 * 
 * @param p_nodeName The name of the node to configure.
 * @param p_nodeConfiguration The new NodeConfiguration for the node.
 * @function
 */

CollectionNode.prototype.setNodeConfiguration = function(p_nodeName,p_nodeConfiguration)
{
	var args = new Object();
	args.nodeName = p_nodeName;
	args.sharedID = this.sharedID;
	args.nodeConfiguration = p_nodeConfiguration;
	this.connectSession.callLCCSMethod("CollectionNode", "setNodeConfiguration", args);
	
}

/**
 * Returns the NodeConfiguration options for a given node in this CollectionNode.
 * 
 * @param p_nodeName The name of the desired node.
 * @function
 */

CollectionNode.prototype.getNodeConfiguration = function(p_nodeName)
{
	return this.messageNodes[p_nodeName];
}

/**
 * Removes the given node from this collection. Only users with an owner role may
 * change a node's configuration.
 * 
 * @param p_nodeName
 * @function
 */		
CollectionNode.prototype.removeNode = function(p_nodeName)
{
	var args = new Object();
	args.nodeName = p_nodeName;
	args.sharedID = this.sharedID;
	this.connectSession.callLCCSMethod("CollectionNode", "removeNode", args);
}

/**
 * Gives a specific user a specific role level for this entire collection or optionally 
 * a specified node within it. Roles cascade down from the root level of the room to 
 * the CollectionNode level and then to the node level. The following override rules apply: 
 * <ul>
 * <li>Setting a role on a collection node overrides the role at the root for that collection node.
 * <li>Setting a role on a node overrides both the role at the root and the collection node for that node.
 * </ul>
 * 
 * @param p_userID The desired user's <code>userID</code>.
 * @param p_role The users new role.
 * @param p_nodeName [Optional, defaults to null] The UserRole for the entire CollectionNode
 * @function
 */
CollectionNode.prototype.setUserRole = function(p_userID, p_role, p_nodeName)
{
	var args = new Object();
	args.userID = p_userID;
	args.role = p_role;
	args.nodeName = p_nodeName;
	args.sharedID = this.sharedID;
	this.connectSession.callLCCSMethod("CollectionNode", "setUserRole", args);
}

/**
 * Gets the role of a given user for this collection or a node within it. Note that this 
 * function discovers the implicit or cascading role of the user at this location; that is, 
 * if no explicit role is specified for a node, the user's role on the parent collection's 
 * is queried. If the user's role isn't explicitly defined on the collection, the root role 
 * is queried.
 * 
 * @param p_userID The user whose role is being queried.
 * @param p_nodeName [Optional, defaults to null]. The name of the node to check for roles. 
 * If null, check the entire CollectionNode.
 * 
 * @return the level of role of the specified user
 *
 * @function
 * 
 */
CollectionNode.prototype.getUserRole = function(p_userID,p_nodeName)
{
	if (this.isNodeDefined(p_nodeName)) {
		if (this.getExplicitUserRole(p_userID, p_nodeName) != -999) {
			return this.getExplicitUserRole(p_userID, p_nodeName);
		} else {
			return this.getRootUserRole(p_userID);
		}
	} else {
		return this.getRootUserRole(p_userID);
	}
}

/**
 * Finds the room-level userRole for a user
 * @private
 */
CollectionNode.prototype.getRootUserRole = function(p_userID)
{
	if (this.userRoles && this.userRoles[p_userID]) {
		return this.userRoles[p_userID];
	} else {
		var usrRole = this.connectSession.userManager.getUserRole(p_userID);
		if (usrRole) {
			return usrRole;
		} else {
			//something wrong
			return null;
		}
	}
}

/**
 * Gets the roles explicitly set for a node within this collection. This only returns the 
 * explicit roles set on the particular node and doesn't look up the cascading roles from
 * the root as <code>getUserRole()</code> does.
 * 
 * @param p_userID The user whose role is being queried.
 * @param p_nodeName The name of the node to whose roles are desired. If null, returns the 
 * set of user roles at the collection node level.
 * 
 * @return An object table of <code>{userID:role}</code> tuples.
 * @function
 */
CollectionNode.prototype.getExplicitUserRoles = function(p_nodeName)
{
	if (this.isNodeDefined(p_nodeName)) {
		return this.nodeUserRoles[p_nodeName];
	}else {
		return this.userRoles;
	}
}

/**
 * Gets the role of a given user for a node within this collection or the 
 * collection itself. This only returns the explicit roles set on the 
 * particular node and doesn't look up the cascading roles from the root 
 * as <code>getUserRole()</code> does.
 * 
 * @param p_userID The user whose role is being queried.
 * @param p_nodeName The name of the node to whose roles are desired. 
 * Null for the collection itself.
 * 
 * @return The requested role. If the role for the user isn't explicitly 
 * set, it returns <code>NO_EXPLICIT_ROLE</code>.
 * @function
 */

CollectionNode.prototype.getExplicitUserRole = function(p_userID,p_nodeName)
{
	if (this.isNodeDefined(p_nodeName)) {
		var tmpObject = this.nodeUserRoles[p_nodeName];
		if (tmpObject) {
			return tmpObject[p_userID];
		}
	} else {
		if (this.userRoles && this.userRoles[p_userID]) {
			return this.userRoles[p_userID];
		}
	}
	return -999;
}

/**
 * Determines whether a given user is allowed to subscribe to this entire collection 
 * or a node within it.
 * 
 * @param p_userID The ID of the user whose role is being queried.
 * @param p_nodeName [Optional, null if empty]. The node to check. If null, it 
 * checks the entire CollectionNode.
 * @function
 */
CollectionNode.prototype.canUserSubscribe = function(p_userID,p_nodeName)
{
	if (p_nodeName==null) {
		return (this.getUserRole(p_userID)>=10);
	} else {
		var roleNeededToSubscribe = this.getNodeConfiguration(p_nodeName).accessModel;
		return (getUserRole(p_userID, p_nodeName)>=roleNeededToSubscribe);
	}
}

/**
 * Determines whether a given user is allowed to publish to a given node in 
 * this collection.
 * 
 * @param p_userID The ID of the user whose role (and therefore permissions) is being queried.
 * @param p_nodeName The name of the desired node. 
 * 
 * @return 
 * @function
 */		
CollectionNode.prototype.canUserPublish = function(p_userID,p_nodeName)
{
	if (!this.isNodeDefined(p_nodeName)) {
		return (this.getUserRole(p_userID, p_nodeName)>=100);
	}
	var roleNeededToPublish = this.getNodeConfiguration(p_nodeName).publishModel;
	if (roleNeededToPublish) {
		return (this.getUserRole(p_userID, p_nodeName)>=roleNeededToPublish);
	} else {
		return (this.getUserRole(p_userID, p_nodeName)>=100);
	}
}

/**
 * Determines whether a given user is allowed to configue this collection. 
 * 
 * @param p_userID The ID of the user whose role (and therefore permissions) is being queried.
 * @param p_nodeName Optionally, the name of the requested node. Defaults to the collection.
 *
 * @return 
 * @function
 */		
CollectionNode.prototype.canUserConfigure = function(p_userID,p_nodeName)
{
	if (p_nodeName==null) {
		return (this.getUserRole(p_userID)>=100);
	} else {
		return (this.canUserPublish(p_userID, p_nodeName) && this.getUserRole(p_userID, p_nodeName)>=100);
	}
}

/**
 * Retracts the indicated item. This removes the item from storage on the server and 
 * sends an <code>itemRetract</code> event to all users.
 * 
 * @param p_nodeName The <code>nodeName</code> of the <code>messageItem</code> to retract.
 * @param p_itemID The <code>itemID</code> of the <code>messageItem</code> (stored on the server) 
 * to retract.
 * @function
 */
CollectionNode.prototype.retractItem = function(p_nodeName,p_itemID)
{
	var args = new Object();
	args.itemID = p_itemID;
	args.nodeName = p_nodeName;
	args.sharedID = this.sharedID;
	this.connectSession.callLCCSMethod("CollectionNode", "retractItem", args);
}

/**
 * Fetches the set of items specified by itemIDs from a given node. This will result in one <code>ITEM_RECEIVE</code> event
 * per item retrieved, for the current user. Attempts to fetch items which don't exist fails silently.
 * @param p_nodeName The name of the node from which to fetch the items.
 * @param p_itemIDs An array of <code>itemID<code>s (Strings) to fetch from the service.
 * @function
 */
CollectionNode.prototype.fetchItems = function(p_nodeName,p_itemIDs)
{
	var args = new Object();
	args.itemIDs = p_itemIDs;
	args.nodeName = p_nodeName;
	args.sharedID = this.sharedID;
	this.connectSession.callLCCSMethod("CollectionNode", "fetchItems", args);
}

/**
 * Whether the given node exists in this CollectionNode.
 * 
 * @param p_nodeName the name of desired node 
 * @return 
 * @function
 */
CollectionNode.prototype.isNodeDefined = function(p_nodeName)
{
	if (this.messageNodes && this.messageNodes[p_nodeName]) {
		return true;
	} else {
		return false;
	}
}







/**
 * Publishes a MessageItem. The MessageItem itself will have a <code>nodeName</code> declared.
 * <p>
 * <code>p_overWrite</code> provides users with control over whether edits take 
 * precedence over delete actions. It is essentially a lock that assures an item can
 * only be published if it exists. The general rule of thumb is that if you 
 * want to add a new item, use the <code>p_overWrite</code> default flag of false. 
 * If you're editing an item that may be retracted, then set the flag according to 
 * your preference. 
 * <p>
 * 
 * @param p_messageItem The MessageItem to publish.
 * @param p_overWrite True if this call is overwriting an existing item. False (the default) 
 * if it is not.
 * @function
 */

CollectionNode.prototype.publishItem = function(p_messageItem)
{
	// check, am I synchronized?
	this.connectSession.publishItem(this, p_messageItem);
}

/*
* Internal Method to dispatchEvents and morph arguments to objects and set the target & currentTarget
*@private
*/
CollectionNode.prototype.receiveEvent = function(args)
{
	args.currentTarget = args.target = this;
	//myTrace("Recieved Event - " + args.type);
	if (args.type == "synchronizationChange" && args.value) {
		this.isSynchronized = args.value;
		this.nodeUserRoles = args.nodeRoles;
		this.userRoles = args.userRoles;
		//this.messageNodes = new Object();
		//this.messageNodes = args.nodes;
	}
	if (args.type == "itemReceive" && !this.isSynchronized) {
		//return;
	}
	
	if (args.type == "nodeCreate" || args.type == "configurationChange") {
		if (!this.messageNodes) {
			this.messageNodes = new Object();
		}
		this.messageNodes[args.nodeName] = args.nodeConfiguration;
	}
	
	if (args.type == "nodeDelete") {
		delete this.messageNodes[args.nodeName];
	}
	
	if (args.type == "myRoleChange" || args.type == "userRoleChange") {
		if (args.nodeName) {
			var nodeObject = this.nodeUserRoles[args.nodeName];
			nodeObject[args.userID] = args.role;
		}else {
			this.userRoles[args.userID] = args.role;
		}
	}
	this.dispatchEvent(args);
}


/**
 * @class SharedObject is used to store data in an unordered hash (key-value) across the AFCS services; elements can only be accessed using its key.
 * A SharedObject can be used in situations where you need to access a property using its key value as opposed to
 * index. Similar to SharedCollection and SharedProperty,this component supports "piggybacking" on existing CollectionNodes,
 * through its <code>collectionNode</code> property and its subscribe method. Developers can avoid CollectionNode
 * proliferation in their applications by pre-supplying a CollectionNode (to the <code>collectionNode</code> property)
 * and a nodeName (in the subscribe method) for the SharedObject to use. If none is supplied, the SharedObject will create its own 
 * collectionNode (named for the uniqueID supplied in subscribe()) for sending and receiving messages.
 * <table><tr><th><b>Event</b></th><th><b>Summary</b></th></tr>
 * <tr><td valign="top"><code>propertyAdd </code></td> <td> Dispatched when an item to SharedObject is added.</td></tr>
 * <tr><td valign="top"><code>propertyChange</code></td> <td> Dispatched when the SharedObject has been updated in some way.</td></tr>
 * <tr><td valign="top"><code>propertyRetracted</code></td> <td> Dispatched when an item from SharedObject is removed.</td></tr>
 * <tr><td valign="top"><code>reconnect</code></td> <td> The type of event emitted when the CollectionNode is about to reconnect to the server.</td></tr>
 * <tr><td valign="top"><code>synchronizationChange</code></td> <td> Dispatched when the SharedObject goes in and out of sync with the service.</td></tr>
 * </table>
 * @constructor
 */
function SharedObject()
{
	this.connectSession = ConnectSession.primarySession;
}
EventDispatcher.initialize(SharedObject.prototype);

/**
 * Defines the logical location of the component on the service - typically this assigns the sharedID of the collectionNode
 * used by the component. sharedIDs should be unique within a room (if they're expressing 2 unique locations). Note that
 * this can only be assigned once (before <code>subscribe()</code> is called). For components with an <code>id</code> property, 
 * sharedID defaults to that value.
 * @field
 */
SharedObject.prototype.sharedID = "_SharedObject";
/**
 * Specifies an existing collectionNode to use in case a developer wishes to supply their own, and avoid having the 
 * sharedObject create a new one.
 * @field
 */
SharedObject.prototype.collectionNode = undefined;
/**
 * The ConnectSession with which this component is associated. Note that this may only be set once before <code>subscribe</code>
 * is called; re-sessioning of components is not supported.
 * @field
 */
SharedObject.prototype.connectSession = undefined;
/**
 * Sets the Node Configuration on a already defined node that holds the sharedObject
 * @field
 */
SharedObject.prototype.nodeConfiguration = undefined;
/**
 * Sets the Node name for the node being created
 * @field
 */
SharedObject.prototype.nodeName = "sharedObjectNode";
/**
 *@private
 */
SharedObject.prototype.myUserID;
/**
 *@private
 */
SharedObject.prototype.sharedObject = new Object(); 

/**
 * Returns whether or not the SharedObject has retrieved any information previously stored on the service, and 
 * is currently connected to the service.
 * @returns {boolean}
 * @function
 */
SharedObject.prototype.isSynchronized = function()
{
	if (this.collectionNode) {
		return this.collectionNode.isSynchronized;
	} else {
		return false;
	}
}

/**
 * Sets the Node Configuration on a already defined node that holds the sharedObject
 * @param p_nodeConfig The Node Configuration
 * @function
 */
SharedObject.prototype.setNodeConfiguration = function(p_nodeConfig)
{
	this.nodeConfiguration = p_nodeConfig ;
	if ( this.collectionNode.isSynchronized ) {
		this.collectionNode.setNodeConfiguration(this.nodeName,this.nodeConfiguration);
	}
}


/**
 *  Sets the role of a given user for the SharedObject.
 * 
 * @param p_userRole The role value to set on the specified user.
 * @param p_userID The ID of the user whose role should be set.
 * @function
 */
SharedObject.prototype.setUserRole = function(p_userID ,p_userRole)
{
	if ( p_userID == null ) {
		return ;
	}
	this.collectionNode.setUserRole(p_userID,p_userRole);
}


/**
 *  Returns the role of a given user for the SharedObject.
 * 
 * @param p_userID The user ID for the user being queried.
 * @function
 */
SharedObject.prototype.getUserRole = function(p_userID)
{
	if ( p_userID == null ) {
		return null;
	}
	return this.collectionNode.getUserRole(p_userID);
}



/**
 * Tells the component to begin synchronizing with the service.  
 * For "headless" components such as this one, this method must be called explicitly.
 * @function
 */
SharedObject.prototype.subscribe = function()
{
	if ( !this.nodeConfiguration) {
		this.nodeConfiguration = new NodeConfiguration();
	}
	
	//this.nodeConfiguration.itemStorageScheme = NodeConfiguration.STORAGE_SCHEME_MANUAL;
	this.nodeConfiguration.itemStorageScheme = 2;
	if (!this.collectionNode) {
		this.collectionNode = new CollectionNode();
		this.collectionNode.sharedID = this.sharedID ;
		this.collectionNode.connectSession = this.connectSession;
		this.collectionNode.addEventListener("synchronizationChange", this);
		this.collectionNode.addEventListener("itemReceive", this);
		this.collectionNode.addEventListener("itemRetract", this);
		this.collectionNode.subscribe();
	}
}

/**
 * Disposes all listeners to the network and framework classes. 
 * Recommended for proper garbage collection of the component.
 * @function
 */
SharedObject.prototype.close = function()
{
	this.collectionNode.removeEventListener("synchronizationChange", this);
	this.collectionNode.removeEventListener("itemReceive", this);
	this.collectionNode.removeEventListener("itemRetract", this);
	this.collectionNode.removeEventListener("reconnect", this);
	this.collectionNode.unsubscribe();
	this.collectionNode = null;
}

/**
 * @private
 */
SharedObject.prototype.synchronizationChange = function(p_evt)
{
	if ( this.collectionNode.isSynchronized ) {
		this.myUserID = this.connectSession.userManager.myUserID;
		if (!this.collectionNode.isNodeDefined(this.nodeName) && this.collectionNode.canUserConfigure(this.myUserID, this.nodeName)) {
			// this collectionNode has never been built, and I can add it...
			this.collectionNode.createNode(this.nodeName, this.nodeConfig);
		}
	}
	p_evt.target = p_evt.currentTarget = this;
	p_evt.value = p_evt.isSynchronized = true;
	this.dispatchEvent(p_evt);
}

/**
 * @private
 */
SharedObject.prototype.reconnect = function(p_evt)
{
	this.sharedObject = new Object();
	p_evt.target = p_evt.currentTarget = this;
	this.dispatchEvent(p_evt);
}

/**
 * @private
 */
SharedObject.prototype.itemReceive = function(p_evt)
{
	//update the Object
	if (p_evt.nodeName!=this.nodeName) {
		return;
	}
	var newItemToAdd = p_evt.item;
	
	var eventType = (this.sharedObject[newItemToAdd.itemID]) ? "propertyChange" : "propertyAdd";
	p_evt.type = eventType;
	p_evt.itemID = newItemToAdd.itemID;
	p_evt.value = newItemToAdd.body;
	p_evt.target = p_evt.currentTarget = this;
	this.sharedObject[newItemToAdd.itemID] = newItemToAdd.body;
	this.dispatchEvent(p_evt);
}

/**
 * @private
 */
SharedObject.prototype.itemRetract = function(p_evt)
{
	if (p_evt.nodeName!=this.nodeName) {
		return;
	}
	var retractedItem = p_evt.item;
	delete this.sharedObject[retractedItem.itemID];
	p_evt.type = "propertyRetracted";
	p_evt.itemID = retractedItem.itemID;
	p_evt.value = retractedItem.body;
	p_evt.target = p_evt.currentTarget = this;
	this.dispatchEvent(p_evt);
}

/**
 * Add or Update the value of a given property name in a shared object
 * @param p_propertyName The key of the Property being added
 * @param p_value The value of the property, defaults to null
 * @function
 */ 
SharedObject.prototype.setProperty = function(p_propertyName, p_value)
{
	var msg = new MessageItem();
	msg.nodeName = this.nodeName;
	msg.body = p_value;
	msg.itemID = p_propertyName;
	this.collectionNode.publishItem(msg);
}

/**
 * Returns the value of the given property name
 * @param p_propertyName The key of the Property whose value is requested.
 * @function
 */ 
SharedObject.prototype.getProperty =  function(p_propertyName)
{
	return this.sharedObject[p_propertyName];
}

/**
 * Returns whether the given property exists or not in the shared object
 * @param p_propertyName The key of the Property whose presence is verified
 * @function
 */ 
SharedObject.prototype.hasProperty = function(p_propertyName)
{
	if (this.sharedObject[p_propertyName]) {
		return true;
	} else {
		return false;
	}
}

/**
 * Remove the property from the shared object
 * @param p_propertyName The key of the Property that needs to be retracted from the sharedObject
 * @function
 */ 
SharedObject.prototype.removeProperty = function(p_propertyName)
{
	this.collectionNode.retractItem(this.nodeName, p_propertyName);
}

/**
 * Return all the items in the shared object as one big hashMap (Object)
 * @function
 */ 
SharedObject.prototype.getValues= function()
{
	return this.sharedObject;
}

/**
 * Remove all the items in the shared object.
 * @function
 */ 
SharedObject.prototype.removeAll = function()
{
	for (var propertyName in this.sharedObject) {
		this.removeProperty(propertyName);
	}
}

/**
 * Check if the shared object is empty
 * @function
 */ 
SharedObject.prototype.isEmpty = function()
{
	for (var propertyName in this.sharedObject) {
		return false;
	}
	return true;
}

/**
 * @class <code>SharedProperty</code> is a model that manages a 
 * variable of any type and which is shared amongst all users connected to the room.
 * <p>
 * Note that this component supports "piggybacking" on existing CollectionNodes 
 * through its constructor. Developers can avoid CollectionNode proliferation in 
 * their applications by pre-supplying a CollectionNode and a <code>nodeName</code> 
 * for the <code>SharedProperty</code> to use. If none is supplied, the SharedProperty 
 * will create its own <code>collectionNode</code> for sending and receiving messages.
 * <table><tr><th><b>Event</b></th><th><b>Summary</b></th></tr>
 * <tr><td valign="top"><code>change </code></td> <td> Dispatched when the value of the property is changed: it is subject to round tripping to the service.</td></tr>
 * <tr><td valign="top"><code>myRoleChange</code></td> <td> Dispatched when the user's role with respect to this SharedProperty  changes.</td></tr>
 * <tr><td valign="top"><code>synchronizationChange</code></td> <td> Dispatched when the SharedProperty goes in and out of sync.</td></tr>
 * </table>
 * @constructor
 */
function SharedProperty ()
{
	this.connectSession = ConnectSession.primarySession;
}
/**
 * The Collection Node to which the shared property subscribes/publishes
 * @field
 */ 
SharedProperty.prototype.collectionNode = undefined;
/**
 * The ConnectSession with which this component is associated. Note that this may only be set once before <code>subscribe</code>
 * is called; re-sessioning of components is not supported.
 * @field
 */
SharedProperty.prototype.connectSession = undefined;
/**
 * The value of the SharedProperty which users can only set if <code>canUserEdit
 * </code> is true.
 * @field
 */
SharedProperty.prototype.value = undefined;
/**
 * Defines the logical location of the component on the service - typically this assigns the sharedID of the collectionNode
 * used by the component. sharedIDs should be unique within a room (if they're expressing 2 unique locations). Note that
 * this can only be assigned once (before <code>subscribe()</code> is called). For components with an <code>id</code> property, 
 * sharedID defaults to that value.
 * @field
 */
SharedProperty.prototype.sharedID = "sharedProperty";
/**
 * The Node Name to which the value is published
 * @field
 */
SharedProperty.prototype.nodeName = "value";
/**
 * @private
 */
SharedProperty.prototype.itemReceived;
/**
 * @private
 */
SharedProperty.prototype.isClearAfterSessionRemoved = false;
/**
 * Role value which is required for access the property
 * @field
 */
SharedProperty.prototype.accessModel = -1 ;
/**
 * @private
 */
SharedProperty.prototype.tempAccessModel = -1 ;
/**
 * Role Value required to publish on the property
 * @field
 */
SharedProperty.prototype.publishModel = -1 ;
/**
 * @private
 */
SharedProperty.prototype.tempPublishModel = -1 ;
/**
 * @private
 */
SharedProperty.prototype.updateInterval = 0 ;
/**
 * @private
 */
SharedProperty.prototype.userManager = 0 ;
/**
 * @private
 */
SharedProperty.prototype.cachedValueForSync;
/**
 * @private
 */
SharedProperty.prototype.cachedValueForSending;
/**
 * @private
 */
SharedProperty.prototype.sendDataTimer;

EventDispatcher.initialize(SharedProperty.prototype);
/**
 * Cleans up all networking and event handling; it is recommended for garbage collection.
 * @function
 */
SharedProperty.prototype.close = function()
{
	this.collectionNode.removeEventListener("synchronizationChange", this);	
	this.collectionNode.removeEventListener("itemReceive", this);
	this.collectionNode.removeEventListener("myRoleChange", this);			
	this.collectionNode.unsubscribe();
	this.collectionNode = null;
	if (this.sendDataTimer) {
		clearTimeout(this.sendDataTimer);
		this.sendDataTimer = null;
	}
}

/**
 * Tells the component to begin synchronizing with the service.  
 * For "headless" components such as this one, this method must be called explicitly.
 * @function
 */
SharedProperty.prototype.subscribe = function()
{
	this.userManager = this.connectSession.userManager;
	
	if (this.collectionNode == null) {			
		this.collectionNode = new CollectionNode();
		this.collectionNode.connectSession = this.connectSession ;
		this.collectionNode.sharedID =  this.sharedID  ;
		this.collectionNode.subscribe();
	} else {
		if (this.collectionNode.isSynchronized) {
			this.synchronizationChange("synchronizationChange");
		}
	}
	this.collectionNode.addEventListener("synchronizationChange", this);	
	this.collectionNode.addEventListener("itemReceive", this);
	this.collectionNode.addEventListener("myRoleChange", this);
}

/**
 * The value of the SharedProperty which users can only set if <code>canUserEdit
 * </code> is true. 
 * @param p_value
 * @function
 */
SharedProperty.prototype.setValue = function(p_value)
{
	if (p_value != this.value && this.collectionNode.isSynchronized) {
		if (this.updateInterval != 0) {
			this.cachedValueForSending = p_value;
			if (this.sendDataTimer) {
				clearTimeout(this.sendDataTimer);
			}
			this.sendDataTimer = setTimeout( bindUsingClosure(this.onTimerComplete,this), (this.updateInterval + 300));
		} else {
			var msg = new MessageItem();
			msg.nodeName = this.nodeName;
			msg.body = p_value;
			this.collectionNode.publishItem(msg);
		}
	} else if (p_value != this.value) {
		this.cachedValueForSync = p_value;
	}
}

/**
 * Determines whether the SharedProperty is connected and fully synchronized with the service.
 * @function
 */
SharedProperty.prototype.isSynchronized = function()
{
	return this.collectionNode.isSynchronized;
}

/**
 * Determines whether the current user can edit the property.
 * @function
 */
SharedProperty.prototype.canIEdit = function()
{
	return this.canUserEdit(this.userManager.myUserID);
}

/**
 * Determines whether the specified user can edit the property.
 * 
 * @param p_userID The user to query regarding whether they can edit.
 * @function
 */
SharedProperty.prototype.canUserEdit = function(p_userID)
{
	return (this.collectionNode.canUserPublish(p_userID,this.nodeName));
}

/**
 * Allows the current user with an owner role to grant the specified user 
 * the ability to edit the property. 
 * 
 * @param p_userID The userID of the user being granted editing privileges.
 * @function
 * 
 */
SharedProperty.prototype.allowUserToEdit = function(p_userID)
{
	// If I can't configure, cancel.
	if(this.collectionNode.canUserConfigure(this.userManager.myUserID,this.nodeName)){
		this.collectionNode.setUserRole(p_userID, 50, this.nodeName);
	}
	
}

/**
 * Gets the NodeConfiguration of the SharedProperty Node.
 * @function
 */
SharedProperty.prototype.getNodeConfiguration = function()
{	
	return this.collectionNode.getNodeConfiguration(this.nodeName);
}

/**
 * Sets the NodeConfiguration on the SharedProperty node.
 * @param p_nodeConfiguration The node Configuration of the shared property node to be set.
 * @function
 * 
 */
SharedProperty.prototype.setNodeConfiguration = function(p_nodeConfiguration)
{	
	this.collectionNode.setNodeConfiguration(this.nodeName,p_nodeConfiguration);
}

/**
 * Set the role Value required to publish on the property
 * @function
 */
SharedProperty.prototype.setPublishModel = function(p_publishModel)
{	
	if ( p_publishModel > 0 && p_publishModel <= 100 )
	{
		if ( this.collectionNode.isSynchronized ) {
			this.publishModel = p_publishModel ;
			this.commitProperties();
		} else {
			this.tempPublishModel = p_publishModel ;
		}
	}
	
}

/**
 * Role Value required to publish on the property
 * @function
 */
SharedProperty.prototype.getPublishModel = function()
{
	if ( this.collectionNode.isNodeDefined(this.nodeName) ) {
		return this.collectionNode.getNodeConfiguration(this.nodeName).publishModel;
	}
	
	return -1 ;
}

/**
 * Set the role value which is required for access the property
 * @function
 */
SharedProperty.prototype.setAccessModel = function(p_accessModel)
{	
	if ( p_accessModel > 0 && p_accessModel <= 100 ) 
	{
		if ( this.collectionNode.isSynchronized ) {
			this.accessModel = p_accessModel ;
			this.commitProperties();
		} else {
			this.tempAccessModel = p_accessModel ;
		}
	}
	
}

/**
 * Role value which is required for access the property
 * @function
 */
SharedProperty.prototype.getAccessModel = function()
{
	if ( this.collectionNode.isNodeDefined(this.nodeName) ) {
		return this.collectionNode.getNodeConfiguration(this.nodeName).accessModel;
	}
	
	return -1 ;
}

/**
 *  Returns the role of a given user for the property.
 * 
 * @param p_userID UserID of the user in question
 * @function
 */
SharedProperty.prototype.getUserRole = function(p_userID)
{
	return this.collectionNode.getUserRole(p_userID);
}

/**
 *  Sets the role of a given user for the property.
 * 
 * @param p_userID UserID of the user whose role we are setting
 * @param p_userRole Role value we are setting
 * @function
 */
SharedProperty.prototype.setUserRole = function(p_userID ,p_userRole)
{
	this.collectionNode.setUserRole(p_userID,p_userRole);
}

/**
 * @private
 */
SharedProperty.prototype.synchronizationChange = function(p_evt)
{
	
	if (this.collectionNode.isSynchronized) {
		if (!this.collectionNode.isNodeDefined(this.nodeName)) {	//we're the first ones there
			var nodeConf = new NodeConfiguration();
			nodeConf.accessModel = 10;
			nodeConf.publishModel = 50;
			nodeConf.sessionDependentItems = this.isClearAfterSessionRemoved;
			nodeConf.modifyAnyItem = true;
			this.collectionNode.createNode(this.nodeName, nodeConf);
			
			if (this.cachedValueForSync) {
				if (this.value == null) {					
					this.setValue(this.cachedValueForSync);
					this.cachedValueForSync = null;
				}
			} else {
				if (this.value != null && this.itemReceived) {	//this happens on disconnect
					//this is if you never got an item, you still want to say "I'm ready!"
					this.value = null;
					dispatchEvent("change");
				}
			}
			
		}
		
		if ( this.tempAccessModel != -1 || this.tempPublishModel != -1) {
			if ( this.tempAccessModel != -1 ) {
				this.accessModel = this.tempAccessModel ;
				this.tempAccessModel = -1 ;
			}
			
			if ( this.tempPublishModel != -1 ) {
				this.publishModel = this.tempPublishModel ;
				this.tempPublishModel = -1 ;
			}
			
			this.commitProperties
		}
		
	} else {
		this.cachedValueForSync = null;
		this.cachedValueForSending = null;
		this.itemReceived = false;
		clearTimeout(this.sendDataTimer)
	}
	p_evt.target = p_evt.currentTarget = this;
	this.dispatchEvent(p_evt);
}

/**
 * @private
 */
SharedProperty.prototype.itemReceive = function(p_evt)
{
	if (p_evt.item.nodeName == this.nodeName) {
		this.value = p_evt.item.body;
		this.itemReceived = true;
		this.cachedValueForSync = null;
		
		var evt = new Object();
		evt.type = "change";
		evt.value = this.value ;
		p_evt.target = p_evt.currentTarget = this;
		this.dispatchEvent(evt);
	}
}

/**
 * @private
 */
SharedProperty.prototype.myRoleChange = function(p_evt)
{
	//TODO: Peldi clean up my model if I have to?
	p_evt.target = p_evt.currentTarget = this;
	this.dispatchEvent(p_evt);
}

/**
 * @private
 */
SharedProperty.prototype.commitProperties = function(p_evt)
{	
	var nodeConf;
	if ( this.publishModel != -1 && this.collectionNode.getNodeConfiguration(this.nodeName).publishModel != this.publishModel ){
		nodeConf = this.collectionNode.getNodeConfiguration(this.nodeName) ;
		nodeConf.publishModel = this.publishModel ;
		this.collectionNode.setNodeConfiguration(this.nodeName,nodeConf );
	}
	
	if ( this.accessModel != -1 && this.collectionNode.getNodeConfiguration(this.nodeName).accessModel != _accessModel ){
		nodeConf = this.collectionNode.getNodeConfiguration(this.nodeName) ;
		nodeConf.accessModel = this.accessModel ;
		this.collectionNode.setNodeConfiguration(this.nodeName, nodeConf ) ;
	}
}

/**
 *@private
 */
SharedProperty.prototype.onTimerComplete = function(args)
{
	var msg = new MessageItem();
	msg.nodeName = args.nodeName;
	msg.body = args.cachedValueForSending;
	args.collectionNode.publishItem(msg);
}

/**
 * @class Baton is a model class which provides a workflow between users. Essentially, it tracks the "holder" of a given resource and provides APIs for grabbing, putting down, and giving control to others. Users with an owner role always have the power to grab the baton, put it down, or give it to others regardless of who has the baton. Users with a publisher role must wait according to the grabbable property:
 *
 *    * If the baton is set to grabbable, they may grab the baton as soon as it is available (since it will then have no controller).
 *    * If the baton is not grabbable, the owner must explicitly pass the baton to someone else. 
 *
 * Note that users with an owner role may adjust the roles of other users relative to the baton using allowUserToGrab (which makes that user a publisher) and allowUserToAdminister (which makes that user an owner).
 *
 * This component also supports "piggybacking" on existing CollectionNodes through its constructor. Developers can avoid CollectionNode proliferation in their applications by pre-supplying a CollectionNode and a nodeName for the baton to use. If none is supplied, the baton will create its own collection node for sending and receiving messages.
 * <table><tr><th><b>Event</b></th><th><b>Summary</b></th></tr>
 * <tr><td valign="top"><code>batonHolderChange </code></td> <td> Dispatched when the baton is given to someone or put down.</td></tr>
 * <tr><td valign="top"><code>synchronizationChange</code></td> <td> Dispatched when the component has fully connected and synchronized with the service or when it loses the connection.</td></tr>
 * </table> 
 * @constructor
 */
function Baton() {
	this.connectSession = ConnectSession.primarySession;
}

/**
 * The the Node Name to which the value is published
 * @field
 */

Baton.prototype.nodeName = "holderID";
/**
 * The Collection Node to which the shared property subscribes/publishes
 * @field
 */

Baton.prototype.collectionNode = undefined;
/**
 * Specifies the <code>userID</code> of the person controlling the baton. Returns null if 
 * noone has the baton. For example, this function might be used to create a "controlled 
 * by XXX" tooltip for your component.
 * @field
 */
Baton.prototype.holderID = undefined;
/**
 * Defines the logical location of the component on the service - typically this assigns the sharedID of the collectionNode
 * used by the component. sharedIDs should be unique within a room (if they're expressing 2 unique locations). Note that
 * this can only be assigned once (before <code>subscribe()</code> is called). For components with an <code>id</code> property, 
 * sharedID defaults to that value.
 * @field
 */
Baton.prototype.sharedID = "Baton";
/**
 * @private
 */
Baton.prototype.pubModelForControlling = 50;
/**
 * @private
 */
Baton.prototype.pubModelForYanking = 100;
/**
 * @private
 */
Baton.prototype.cachedBatonHolderID;
/**
 * @private
 */
Baton.prototype.userManager;
/**
 * @private
 */
Baton.prototype.inSync = false;		
/**
 * @private
 */
Baton.prototype.yankable = true;
/**
 * @private
 */
Baton.prototype.grabbable = true;
/**
 * Role value which is required for seeing the baton
 * @field
 */
Baton.prototype.accessModel = -1 ;
/**
 * Role value which is required for publishing to the baton
 * @field
 */
Baton.prototype.publishModel = -1 ;
/**
 * The ConnectSession with which this component is associated. Note that this may only be set once before <code>subscribe</code>
 * is called; re-sessioning of components is not supported.
 * @field
 */
Baton.prototype.connectSession = undefined;
/**
 * Number of seconds after which the baton times out
 * @field
 */ 
Baton.prototype.timeOut = undefined;
/**
 * @private
 */
Baton.prototype.autoPutDownTimer;

EventDispatcher.initialize(Baton.prototype);

/**
 * Tells the component to begin synchronizing with the service.  
 * This method must be called explicitly.
 * @function
 */
Baton.prototype.subscribe = function()
{
	this.userManager = this.connectSession.userManager;
	//this.autoPutDownTimer=setTimeout(this.onTimerComplete,this.timeOut*1000,this);
	if (!this.collectionNode) {			
		this.collectionNode = new CollectionNode();
		this.collectionNode.sharedID = this.sharedID  ;
		this.collectionNode.connectSession = this.connectSession ;
		this.collectionNode.subscribe();
	} else {
		if (this.collectionNode.isSynchronized) {
			this.synchronizationChange("synchronizationChange");
		}
	}
	this.collectionNode.addEventListener("synchronizationChange", this);				
	this.collectionNode.addEventListener("itemReceive", this);
	this.collectionNode.addEventListener("itemRetract", this);
}


/**
 * Gets the NodeConfiguration of the Baton Node.
 * @function
 */
Baton.prototype.getNodeConfiguration = function()
{	
	return this.collectionNode.getNodeConfiguration(this.nodeName);
}

/**
 * Sets the NodeConfiguration on the baton node.
 * @param p_nodeConfiguration The node Configuration of the baton node to be set.
 * @function
 * 
 */
Baton.prototype.setNodeConfiguration = function(p_nodeConfiguration)
{	
	this.collectionNode.setNodeConfiguration(this.nodeName,p_nodeConfiguration);
}

/**
 * Set the Role Value required to publish the baton
 * @function
 */
Baton.prototype.setPublishModel = function(p_publishModel)
{	
	if ( p_publishModel > 0 && p_publishModel <= 100 ) 
	{
		this.publishModel = p_publishModel ;
		this.commitProperties();
	}
}

/**
 * Role Value required to publish the baton
 * @function
 */
Baton.prototype.getPublishModel = function()
{
	return this.collectionNode.getNodeConfiguration(this.nodeName).publishModel;
}

/**
 * Set the role value which is required for seeing the baton
 * @function
 */
Baton.prototype.setAccessModel= function(p_accessModel)
{	
	if ( p_accessModel > 0 && p_accessModel <= 100 ) 
	{
		if ( this.collectionNode.isSynchronized ) {
			this.accessModel = p_accessModel ;
			this.commitProperties();
		}
	}
}
/**
 * Role value which is required for seeing the baton
 * @function
 */
Baton.prototype.getAccessModel = function()
{
	return this.collectionNode.getNodeConfiguration(this.nodeName).accessModel;
}


/**
 *  Returns the role of a given user for the baton.
 * 
 * @param p_userID UserID of the user in question
 * @function
 */
Baton.prototype.getUserRole = function(p_userID)
{
	return this.collectionNode.getUserRole(p_userID,this.nodeName);
}

/**
 * Determines whether the component has connected to the server and has fully synchronized.
 * @function
 */
Baton.prototype.isSynchronized = function()
{
	return this.collectionNode.isSynchronized;
}

/**
 * Determines whether the current user has permission to administer the baton 
 * by taking it from someone or forcing them to put it down.
 * @function
 */
Baton.prototype.canIAdminister = function()
{
	return this.canUserAdminister(this.userManager.myUserID);
}

/**
 * Determines whether a specified user can administer the baton from others. 
 * 
 * @param p_userID The <code>userID</code> of the user to check if they have 
 * adminstrator rights.
 * @function
 */		
Baton.prototype.canUserAdminister = function(p_userID)
{
	return (this.yankable && this.collectionNode.getUserRole(p_userID, this.nodeName) >= this.pubModelForYanking);
}

/**
 * Determines whether the current user has permission to grab the baton 
 * when available.
 * @function
 */
Baton.prototype.canIGrab = function()
{
	return this.canUserGrab(this.userManager.myUserID);
}

/**
 * Determines whether a specified user can grab the baton if it's available.
 * 
 * @param p_userID  The <code>userID</code> of the user to check if they 
 * can grab the baton.
 * @function
 */
Baton.prototype.canUserGrab = function(p_userID)
{
	return (this.grabbable && this.collectionNode.getUserRole(p_userID, this.nodeName) >= this.pubModelForControlling);
}

/**
 * When called by an owner, <code>setUserRole()</code> sets the role of the specified 
 * user with respect to this baton. The following rules apply: 
 * <ul>
 * <li>Setting the role to <code>UserRoles.PUBLISHER</code> allows the user to grab the baton. </li>
 * <li>Setting the role to <code>UserRoles.OWNER</code> allows the user to administer the baton.</li> 
 * <li>Setting to <code>UserRoles.VIEWER</code> will allow neither.</li>
 * </ul>
 * 
 * @param p_userID The <code>userID</code> of the user to set the role for. 
 * @param p_role The new role for that user.
 * @function
 */
Baton.prototype.setUserRole = function(p_userID, p_role)
{
	if ( p_userID != null )
	{
		if ( (p_role > 0 && p_role <= 100) && p_role != -999 )
		{
			this.collectionNode.setUserRole(p_userID, p_role, this.nodeName);
		}
	}
}


/**
 * Determines whether the current user is holding the baton.
 * @function
 */
Baton.prototype.amIHolding = function()
{
	return (this.holderID == this.userManager.myUserID);
}

/**
 * Determines whether the baton is up for grabs because it has no current holder.
 * @function
 */
Baton.prototype.available = function()
{
	return ((this.holderID == null) && this.grabbable);
}

/**
 * Cleans up all networking and event handling; recommended for garbage collection.
 * @function
 */
Baton.prototype.close = function()
{
	this.collectionNode.unsubscribe();
	this.collectionNode = null;
}

/**
 * If grabbable, users with a publisher role can grab the control if it's available 
 * by using this method. Users with an owner role may grab the baton at any time.
 * @function
 */
Baton.prototype.grab = function()
{
	if (!this.canIAdminister()) {
		// if I can Yank, don't worry about other
		if ( !this.available() || !this.canIGrab()) {
			return;
		}
	}
	
	if ( this.amIHolding() ) {
		return;
	}
	
	if ( this.isSynchronized() ) {
		var msgItem = new MessageItem();
		msgItem.nodeName =  this.nodeName;
		msgItem.body = this.userManager.myUserID;
		this.collectionNode.publishItem(msgItem);
	} else {
		this.cachedBatonHolderID = this.userManager.myUserID;
	}
}

/**
 * Users with an publisher role in control can use this method to 
 * release their control. Users with an owner role  can use this method 
 * to remove the baton from a user who has it.
 * @function
 */
Baton.prototype.putDown = function()
{
	if ( this.available() ) {
		return;
	}
	
	if (!this.canIAdminister() && !this.amIHolding()) {
		return;
	}			
	if ( this.isSynchronized() ) {				
		this.collectionNode.retractItem(this.nodeName);
	}
}

/**
 * If the baton is grabbable, the holding user can hand the baton to a specified user. 
 * A user with an owner role can give a baton to anyone with the required permissions 
 * at any time.
 * 
 * @param p_userID  The <code>userID</code> of the user to allow to grab the baton.
 * @function
 */
Baton.prototype.giveTo = function(p_userID)
{
	if (!this.canIAdminister() && (!this.grabbable || !this.amIHolding())) {
		return;
	}
	
	if ( this.isSynchronized() ) {
		var msgItem = new MessageItem();
		msgItem.nodeName =  this.nodeName;
		msgItem.body = p_userID;
		this.collectionNode.publishItem(msgItem);
	} else {
		this.cachedBatonHolderID = p_userID;
	}
}

/**
 *@private
 */
Baton.prototype.synchronizationChange = function(p_evt)
{						
	if (this.isSynchronized()) {
		if (!this.collectionNode.isNodeDefined(this.nodeName)) {	//we're the first ones here
			var nodeConf = new NodeConfiguration();
			nodeConf.accessModel = 10;
			nodeConf.publishModel = this.pubModelForControlling;
			nodeConf.modifyAnyItem = true;
			nodeConf.userDependentItems = true;
			this.collectionNode.createNode(this.nodeName, nodeConf);
		}
		
		if (this.holderID == null && this.cachedBatonHolderID != null) {	//this will work but I don't like it...we might want to use this.holderIDSetFromNetwork
			if ( this.getUserRole(this.userManager.myUserID) >= this.pubModelForYanking ) {
				this.giveTo(this.cachedBatonHolderID);
			} else if ( this.canIGrab() && this.cachedBatonHolderID == this.userManager.myUserID ) {
				this.grab();
			}
			this.cachedBatonHolderID = null;
		}
	} else {
		clearTimeout(this.autoPutDownTimer);
		this.cachedBatonHolderID = null;
		this.holderID = null;
	}
	p_evt.currentTarget = p_evt.target = this;
	this.dispatchEvent(p_evt);	//bubble it
}

/**
 *@private
 */
Baton.prototype.itemReceive = function(p_evt)
{
	var theItem = p_evt.item;
	
	if (theItem.nodeName == this.nodeName) {
		this.holderID = theItem.body;	
		this.cachedBatonHolderID = null;
		if (this.amIHolding() && this.timeOut>0) {
			this.autoPutDownTimer = setTimeout( bindUsingClosure(this.onTimerComplete,this), (this.timeOut*1000));
		}
		p_evt.currentTarget = p_evt.target = this;
		p_evt.type = "batonHolderChange";
		this.dispatchEvent(p_evt);
	}			
}

/**
 *@private
 */
Baton.prototype.itemRetract = function(p_evt)
{
	if (p_evt.nodeName == this.nodeName) {			//no need to check the itemID, I only have one
		this.holderID = null;
		this.cachedBatonHolderID = null;
		p_evt.currentTarget = p_evt.target = this;
		p_evt.type = "batonHolderChange";
		clearTimeout(this.autoPutDownTimer);
		this.dispatchEvent(p_evt);
	}
}


/**
 *@private
 */
Baton.prototype.commitProperties = function(p_evt)
{	
	var nodeConf;
	if ( this.publishModel != -1 && this.collectionNode.getNodeConfiguration(this.nodeName).publishModel != this.publishModel ){
		nodeConf = this.collectionNode.getNodeConfiguration(this.nodeName) ;
		nodeConf.publishModel = this.publishModel ;
		this.collectionNode.setNodeConfiguration(this.nodeName,nodeConf );
	}
	
	if ( this.accessModel != -1 && this.collectionNode.getNodeConfiguration(this.nodeName).accessModel != this.accessModel ){
		nodeConf = this.collectionNode.getNodeConfiguration(this.nodeName) ;
		nodeConf.accessModel = this.accessModel ;
		this.collectionNode.setNodeConfiguration(this.nodeName, nodeConf ) ;
	}
	
}

/**
 *@private
 */
Baton.prototype.onTimerComplete = function(args)
{
	args.collectionNode.retractItem(args.nodeName);
}

/**
 * Extends the timeout if the baton has one. 
 */
Baton.prototype.extendTimer = function()
{
	if (this.autoPutDownTimer) {
		clearTimeout(this.autoPutDownTimer);
		this.autoPutDownTimer = null;
		this.autoPutDownTimer = setTimeout( bindUsingClosure(this.onTimerComplete,this), (this.timeOut*1000));
	}
}

/**
 * @class BatonProperty is a model component which manages a property of any type that 
 * only one user can edit at a time. It exposes a standard Baton component to 
 * manage this workflow.
 * <p>
 * This component supports "piggybacking" on existing CollectionNodes through its 
 * constructor. Developers can avoid CollectionNode proliferation in their applications
 * by pre-supplying a CollectionNode and a <code>nodeName</code> for the <code>
 * BatonProperty</code> to use. If none is supplied, the <code>BatonProperty</code> will 
 * create its own CollectionNode for sending and receiving messages.
 * <table><tr><th><b>Event</b></th><th><b>Summary</b></th></tr>
 * <tr><td valign="top"><code>batonHolderChange </code></td> <td> Dispatched when the baton holder for the string is assigned or when the string becomes available.</td></tr>
 * <tr><td valign="top"><code>change </code></td> <td> Dispatched when the value of the property is changed: it is subject to round tripping to the service.</td></tr>
 * <tr><td valign="top"><code>myRoleChange</code></td> <td> Dispatched when the user's role with respect to this SharedProperty  changes.</td></tr>
 * <tr><td valign="top"><code>synchronizationChange</code></td> <td> Dispatched when the SharedProperty goes in and out of sync.</td></tr>
 * </table> 
 * @constructor
 */
function BatonProperty() {
	this.baton = new Baton();
	this.connectSession = ConnectSession.primarySession;
}

/**
 *@private
 */
BatonProperty.prototype = new SharedProperty();
BatonProperty.prototype.constructor = BatonProperty;
/**
 *@private
 */
BatonProperty.prototype.baton;
/**
 *@private
 */
BatonProperty.prototype.cachedValueForToggle;
/**
 *@private
 */
BatonProperty.prototype.nodeNameResource = "cID";
/**
 * Defines the logical location of the component on the service - typically this assigns the sharedID of the collectionNode
 * used by the component. If this is used to "piggyback" on an existing collectionNode, sharedID specifies the nodeName
 * to use for the property itself. sharedIDs should be unique within a room (if they're expressing 2 unique locations). Note that
 * this can only be assigned once (before <code>subscribe()</code> is called). For components with an <code>id</code> property, 
 * sharedID defaults to that value.
 * @field
 */
BatonProperty.prototype.sharedID = "batonProperty";
EventDispatcher.initialize(BatonProperty.prototype);

/**
 * Sets the CollectionNode to be used in setting up the property and baton nodes, when used in "piggybacking"
 * @function
 */
BatonProperty.prototype.setCollectionNode = function(p_collectionNode)
{
	SharedProperty.prototype.collectionNode = this.baton.collectionNode = p_collectionNode ;	
}

/**
 * Node Name for the baton
 * @function
 */
BatonProperty.prototype.setNodeNameBaton = function(p_nodeNameBaton)
{
	this.nodeNameResource = p_nodeNameBaton;
	this.baton.nodeName = this.nodeNameResource ;	
}

/**
 * When used with "piggybacking" on an existing CollectionNode, specifies the node name for the baton
 * @function
 */
BatonProperty.prototype.getNodeNameBaton = function()
{
	return this.baton.nodeName ;
}


/**
 * Tells the component to begin synchronizing with the service.  
 * For "headless" components such as this one, this method must be called explicitly.
 * @function
 */
BatonProperty.prototype.subscribe = function()
{
	SharedProperty.prototype.subscribe.call(this) ;
	this.baton.sharedID = this.sharedID ;
	this.baton.collectionNode = this.collectionNode ;
	this.baton.nodeName = this.nodeNameResource ;
	this.baton.connectSession = this.connectSession;
	this.baton.addEventListener("batonHolderChange", this);
	this.baton.subscribe();
}

/**
 * Cleans up all listeners and network connections: recommended for garbage collection.
 * @function
 */
BatonProperty.prototype.close = function()
{
	SharedProperty.prototype.close.call(this) ;
	this.baton.removeEventListener("batonHolderChange", this);
	this.baton.close();
	this.cachedValueForToggle = null;
}

/**
 * The value of the BatonProperty which a user can only set it if the user is in 
 * control of it.
 * <p>
 * If the BatonProperty is not yet synchrnonized, the value will be cached and 
 * sent when the BatonProperty is back in sync.
 * <p>
 * If the BatonProperty is available, setting the value will also try to grab 
 * control of the BatonProperty before setting the text.
 * @function
 */
BatonProperty.prototype.setValue = function(p_value)
{
	if (p_value == this.value) {	//no need to set it again
		return;
	}
	
	if (this.collectionNode.isSynchronized) {
		if (this.baton.amIHolding()) {
			this.cachedValueForSending = p_value;
			this.sendDataTimer = setTimeout( bindUsingClosure(this.onTimerComplete,this), (this.updateInterval + 300));
			this.baton.extendTimer();
		} else if (this.baton.available()) {
			if (!this.cachedValueForToggle) {	//only toggle the first time
				this.baton.grab();
			}
			this.cachedValueForToggle = p_value;	//overwrite the value that will eventually be published
		}
	} else {
		this.cachedValueForSync = p_value;
	}
}

/**
 * @private
 */
BatonProperty.prototype.batonHolderChange = function(p_evt)
{
	if (this.baton.amIHolding() && this.cachedValueForToggle) {
		this.setValue(this.cachedValueForToggle);
		this.cachedValueForToggle = null;
	}
	p_evt.currentTarget = p_evt.target = this;
	this.dispatchEvent(p_evt);
}

/**
 * @private
 */
BatonProperty.prototype.synchronizationChange = function(p_evt)
{
	if (this.collectionNode.isSynchronized) {
	} else {
		//clear model
		this.cachedValueForToggle = null;
	}
	var args = new Array();
	args.push(p_evt);
	SharedProperty.prototype.synchronizationChange.apply(this,args);
}


/**
 * Determines whether the specified user can edit the property.
 * 
 * @param p_userID The user to query regarding whether they can edit.
 * @function
 */
BatonProperty.prototype.canUserEdit = function(p_userID)
{
	return (SharedProperty.prototype.canUserEdit.call(this) && this.baton.canUserGrab(p_userID));
	
}

/**
 * Allows the current user with an owner role to grant the specified user 
 * the ability to edit the property. 
 * 
 * @param p_userID The userID of the user being granted editing privileges.
 * @function
 */
BatonProperty.prototype.allowUserToEdit = function(p_userID)
{
	// Let the user grab the baton.
	this.baton.setUserRole(p_userID, UserRoles.PUBLISHER);
	
	// Let the user edit the text.
	var superArgs = new Object();
	superArgs.userID = p_userID;
	var args = new Array();
	args.push(superArgs);
	SharedProperty.prototype.allowUserToEdit.apply(this,args);
}


/**
 * Set the role Value required to publish on the property
 * @function
 */
BatonProperty.prototype.setPublishModel = function(p_publishModel)
{	
	this.baton.publishModel = p_publishModel ;
	this.accessModel = p_publishModel;
}

/**
 * Role Value required to publish on the property
 * @function
 */
BatonProperty.prototype.getPublishModel = function()
{
	return this.baton.publishModel ;
}

/**
 * Set the Role value which is required for accessing the property value
 * @function
 */
BatonProperty.prototype.setAccessModel = function(p_accessModel)
{	
	this.baton.accessModel = p_accessModel ;
	this.accessModel = p_accessModel;
}

/**
 * Role value which is required for accessing the property value
 * @function
 */
BatonProperty.prototype.getAccessModel = function()
{
	return this.baton.accessModel ;
}

/**
 *  Returns the role of a given user for the property.
 * 
 * @param p_userID UserID of the user in question
 * @function
 */
BatonProperty.prototype.getUserRole = function(p_userID)
{
	return this.baton.getUserRole(p_userID);
}

/**
 *  Sets the role of a given user for the property.
 * 
 * @param p_userID UserID of the user whose role we are setting
 * @param p_userRole Role value we are setting
 * @function
 */
BatonProperty.prototype.setUserRole = function(p_userID ,p_userRole)
{
	this.baton.setUserRole(p_userID,p_userRole);
	var superArgs = new Object();
	superArgs.userID = p_userID;
	superArgs.userRole = p_userRole;
	var args = new Array();
	args.push(superArgs);
	SharedProperty.prototype.setUserRole.apply(this,args);
}

/**
 *@private
 */
BatonProperty.prototype.onTimerComplete = function(args)
{
	var argsArray = new Array();
	argsArray.push(args);
	SharedProperty.prototype.onTimerComplete.apply(this,argsArray);
}

/**
 * @class BatonObject is a model class which provides a workflow between users for muliple resources. Essentially, it 
 * tracks the "holder" of a given resource and provides APIs for grabbing, putting down, 
 * and giving control to others. Users with an owner role always have the power to 
 * grab the BatonObject, put it down, or give it to others regardless of who has the BatonObject. 
 * Users with a publisher role must wait according to the <code>grabbable</code> property:
 * <p>
 * <ul>
 * <li>If the BatonObject is set to <code>grabbable</code>, they may grab the resources in the BatonObject as soon 
 * as it is available (since it will then have no controller).</li>
 * <li>If the BatonObject is not <code>grabbable</code>, the owner must explicitly pass the resources in the BatonObject
 * to someone else. 
 * </ul>
 * By default, a BatonObject will timeout in five seconds and be released. This timeout can be 
 * adjusted in the constructor and extended during use of the resource in question using 
 * <code>extendTimer</code>.
 * <p>
 * Note that users with an owner role may adjust the roles of other users relative to the 
 * BatonObject using <code>allowUserToGrab</code> (which makes that user a publisher) and <code>
 * allowUserToAdminister</code> (which makes that user an owner).
 * </p>
 * <p>
 * This component also supports "piggybacking" on existing CollectionNodes through its constructor. 
 * Developers can avoid CollectionNode proliferation in their applications by pre-supplying a 
 * CollectionNode and a <code>nodeName</code> for the BatonObject to use. If none is supplied, the 
 * BatonObject will create its own collection node for sending and receiving messages.

 * <table><tr><th><b>Event</b></th><th><b>Summary</b></th></tr>
 * <tr><td valign="top"><code>batonHolderChange </code></td> <td> Dispatched when the one of the batonObjects property is assigned,grabbed or when its available.</td></tr>
 * <tr><td valign="top"><code>synchronizationChange</code></td> <td> Dispatched when the SharedProperty goes in and out of sync.</td></tr>
 * </table> 
 * @constructor
 */
function BatonObject() {
	this.holderID = new Object();
	this.cachedBatonHolderID = new Object();
	this.autoReleaseTimers = new Object();
	this.sharedID = SharedObject.prototype.sharedID = "_BatonObject";
	this.cachedValueForSetProp = new Object();
	this.cachedValueForDeleteProp = new Object();
	this.connectSession = ConnectSession.primarySession;
}

/**
 * @private
 */
BatonObject.prototype = new SharedObject();
BatonObject.prototype.constructor = BatonObject;

/**
 * @field
 */
BatonObject.prototype.batonNodeName = "holderIDs";
/**
 * @private
 */
BatonObject.prototype.holderID;

/**
 * @private
 */
BatonObject.prototype.pubModelForControlling=50;
/**
 * @private
 */
BatonObject.prototype.pubModelForYanking=100;
/**
 * @private
 */
BatonObject.prototype.autoReleaseTimers;
/**
 * @private
 */
BatonObject.prototype.timeOut = 0;	//in seconds
/**
 * @private
 */
BatonObject.prototype.cachedBatonHolderID;
/**
 * @private
 */
BatonObject.prototype.userManager;
/**
 * @private
 */
BatonObject.prototype.yankable = true;
/**
 * Whether or not to allow users with a publisher role to grab an available resource in BatonObject.
 * When false, the resources in BatonObject can only be handed off by users with an owner role.
 * @field
 */
BatonObject.prototype.grabbable = true;
/**
 * @private
 */
BatonObject.prototype.accessModel = -1 ;
/**
 * @private
 */
BatonObject.prototype.publishModel = -1 ;
/**
 * @private
 */
BatonObject.prototype.cachedValueForSetProp;
/**
 * @private
 */
BatonObject.prototype.cachedValueForDeleteProp;

EventDispatcher.initialize(BatonObject.prototype);

/**
 * Number of seconds after which the BatonObject times out
 * If 0, no timeout is used. 
 * @param p_timeOut Number of seconds until the resources in the BatonObject is released
 * @param p_propertyName The id of the property, If null would set the p_timeOut value to all the properties
 * @function
 */
BatonObject.prototype.setTimeOut = function(p_timeOut,p_propertyName)
{
	if (p_propertyName) {
		//this.createTimer(p_propertyName);
		if (this.autoReleaseTimers[p_propertyName]) {
			this.autoReleaseTimers[p_propertyName].delay =  p_timeOut*1000;
		} else {
			this.autoReleaseTimers[p_propertyName] = new Object();
			this.autoReleaseTimers[p_propertyName].delay =  p_timeOut*1000;
		}
	} else {
		if (this.autoReleaseTimers) {
			for (var property in this.autoReleaseTimers) {
				this.autoReleaseTimers[p_propertyName].delay =  p_timeOut*1000;
			}
		}
		this.timeOut = p_timeOut;
	}
}

/**
 * Number of seconds after which the BatonObject times out
 * @param p_propertyName The id of the property. If null would return the defualt timeout value
 * @function
 */
BatonObject.prototype.getTimeOut = function(p_propertyName)
{
	if (p_propertyName && this.autoReleaseTimers[p_propertyName].delay) {
		return this.autoReleaseTimers[p_propertyName].delay;
	} else {
		return this.timeOut;
	}
}

/**
 * Set the role Value required to grab the BatonObject
 * @function
 */
BatonObject.prototype.setPublishModel = function(p_publishModel) 
{ 
	if ( p_publishModel < 0 || p_publishModel > 100 ) 
		return ; 
	
	this.publishModel = p_publishModel ;
	commitProperties();
}

/**
 * Get the role Value required to grab the BatonObject
 * @function
 */
BatonObject.prototype.getPublishModel = function() 
{ 
	return this.collectionNode.getNodeConfiguration(this.batonNodeName).publishModel;
}

/**
 * Set the role value which is required for seeing the BatonObject
 * @function
 */
BatonObject.prototype.setAccessModel = function(p_accessModel) 
{ 
	if ( p_accessModel < 0 || p_accessModel > 100 ) 
		return ; 
	
	this.accessModel = p_accessModel ;
	commitProperties();
}

/**
 * Get the role value which is required for seeing the BatonObject
 * @function
 */
BatonObject.prototype.getAccessModel = function() 
{ 
	return this.collectionNode.getNodeConfiguration(this.batonNodeName).accessModel;
}

/**
 * Get the role of a given user for the BatonObject.
 * @function
 */
BatonObject.prototype.getUserRole = function(p_userID) 
{ 
	return this.collectionNode.getUserRole(p_userID,this.batonNodeName);
}

/**
 * Specifies the <code>userID</code> of the person controlling the the resource in the BatonObject. Returns null if 
 * no one has the BatonObject. For example, this function might be used to create a "controlled 
 * by XXX" tooltip for your component.
 * @param p_propertyName The id of the property
 * @function
 */
BatonObject.prototype.getHolderID = function(p_propertyName) 
{ 
	return this.holderID[p_propertyName];
}

/**
 * Determines whether the current user has permission to administer the BatonObject 
 * by taking it from someone or forcing them to put it down.
 * @function
 */
BatonObject.prototype.canIAdminister = function() 
{ 
	return this.canUserAdminister(this.userManager.myUserID);
}

/**
 * Determines whether a specified user can administer the BatonObject from others. 
 * @param p_userID The <code>userID</code> of the user to check if they have
 * @function
 */
BatonObject.prototype.canUserAdminister = function(p_userID) 
{ 
	return (this.yankable && this.collectionNode.getUserRole(p_userID, this.batonNodeName) >= this.pubModelForYanking);
}

/**
 * Determines whether the current user has permission to grab the BatonObject 
 * when available. It just determines if you are allowed to grab any property inside the BatonObject.
 * @function
 */
BatonObject.prototype.canIGrab = function() 
{ 
	return this.canUserGrab(this.userManager.myUserID);
}

/**
 * Determines whether a specified user can grab the BatonObject if it's available.
 * @param p_userID  The <code>userID</code> of the user to check if they 
 * can grab the BatonObject. 
 * @function
 */
BatonObject.prototype.canUserGrab = function(p_userID) 
{
	return (this.grabbable && this.collectionNode.getUserRole(p_userID, this.batonNodeName) >= this.pubModelForControlling);
}

/**
 * When called by an owner, <code>setUserRole()</code> sets the role of the specified 
 * user with respect to this BatonObject. The following rules apply: 
 * <ul>
 * <li>Setting the role to <code>UserRoles.PUBLISHER</code> allows the user to grab the resources in the BatonObject. </li>
 * <li>Setting the role to <code>UserRoles.OWNER</code> allows the user to administer the resources in the BatonObject.</li> 
 * <li>Setting to <code>UserRoles.VIEWER</code> will allow neither.</li>
 * </ul>
 * 
 * @param p_userID The <code>userID</code> of the user to set the role for. 
 * @param p_role The new role for that user.
 * @function
 */
BatonObject.prototype.setUserRole = function(p_userID ,p_userRole) 
{ 
	if ( p_userID == null ) 
		return ;
	
	
	if ( (p_userRole < 0 || p_userRole > 100) && p_userRole != -999 ) 
		return ; 
	
	this.collectionNode.setUserRole(p_userID, p_userRole, this.batonNodeName);
	var args = new Array();
	args.push(p_userID);
	args.push(p_userRole);
	SharedObject.prototype.setUserRole.apply(this,args) ;
}

/**
 * Determines whether the current user is holding a resource in the BatonObject.
 * @param p_propertyName The id of the property
 * @function
 */
BatonObject.prototype.amIHolding = function(p_propertyName) 
{ 
	return (this.holderID[p_propertyName] == this.userManager.myUserID);
}

/**
 * Determines whether the resource in the BatonObject is up for grabs because it has no current holder.
 * @param p_propertyName The id of the property 
 * @function
 */
BatonObject.prototype.isAvailable = function(p_propertyName) 
{ 
	return (this.holderID[p_propertyName] == null) && this.grabbable;
}

/**
 * Cleans up all networking and event handling; recommended for garbage collection.
 * @function
 */
BatonObject.prototype.close = function() 
{ 
	this.collectionNode.unsubscribe();
	this.collectionNode = null;
	this.stopAllTimers();//REVISIT
	this.userManager = null;
	SharedObject.prototype.close.call(this) ;
}

/**
 * If grabbable, users with a publisher role can grab the control if it's available 
 * by using this method. Users with an owner role may grab a resource in the BatonObject at any time.
 * @param p_propertyName The id of the property
 * @function
 */
BatonObject.prototype.grab = function(p_propertyName) 
{ 
	if (!this.canIAdminister()) {
		// if I can Yank, don't worry about other
		if ( !this.isAvailable(p_propertyName) || !this.canIGrab()) {
			return;
		}
	}
	
	if ( this.amIHolding(p_propertyName) ) {
		return;
	}
	
	//this.createTimer(p_propertyName);
	if ( this.isSynchronized ) {
		//grab it
		var msg = new MessageItem();
		msg.nodeName = this.batonNodeName;
		msg.body = this.userManager.myUserID;
		msg.itemID = p_propertyName;

		this.collectionNode.publishItem(msg);
	} else {
		this.cachedBatonHolderID[p_propertyName] = this.userManager.myUserID;
	}
}

/**
 * Users with an publisher role in control can use this method to 
 * release their control. Users with an owner role  can use this method 
 * to remove the BatonObject resource from a user who has it.
 * @param p_propertyName The id of the property
 * @function
 */
BatonObject.prototype.putDown = function(p_propertyName) 
{
	//REVISIT
	if ( this.isAvailable(p_propertyName) ) {
		return;
	}
	
	if (!this.canIAdminister() && !this.amIHolding(p_propertyName)) {
		return;
	}			
	if ( this.isSynchronized ) {				
		//release it
		this.collectionNode.retractItem(this.batonNodeName,p_propertyName);
	} // else not in sync, doing nothing
}

/**
 * If the BatonObject is grabbable, the holding user can hand the BatonObject's resource to a specified user. 
 * A user with an owner role can give a BatonObject resource to anyone with the required permissions 
 * at any time.
 * 
 * @param p_userID  The <code>userID</code> of the user to allow to grab the BatonObject.
 * @param p_propertyName The id of the property   
 * @function
 */
BatonObject.prototype.giveTo = function(p_userID,p_propertyName) 
{ 
	if (!this.canIAdminister() && (!this.grabbable || !this.amIHolding(p_propertyName))) {
		return;
	}
	
	if ( this.isSynchronized ) {
		//give it to someone
		var msg = new MessageItem();
		msg.nodeName = this.batonNodeName;
		msg.body = p_userID;
		msg.itemID = p_propertyName;
		this.collectionNode.publishItem(msg);
	} else {
		this.cachedBatonHolderID[p_propertyName] = p_userID;
	}
}

/**
 * Extends the timeout if the BatonObject has one.
 * @param p_propertyName The id of the property  
 * @function
 */
BatonObject.prototype.extendTimer = function(p_propertyName) 
{ 
	if (this.autoReleaseTimers[p_propertyName]) {
		if (this.autoReleaseTimers[p_propertyName].timer) {
			clearTimeout(this.autoReleaseTimers[p_propertyName].timer);
		}
		this.autoReleaseTimers[p_propertyName].timer = null;
		if (this.autoReleaseTimers[p_propertyName].delay) {
			var delay =  this.autoReleaseTimers[p_propertyName].delay;
			this.autoReleaseTimers[p_propertyName].timer = setTimeout( bindUsingClosure(this.onTimerComplete,this), delay, p_propertyName);
		} else {
			this.autoReleaseTimers[p_propertyName].timer = setTimeout( bindUsingClosure(this.onTimerComplete,this), (this.timeOut*1000), p_propertyName);
		}
	}
}

/**
 * The value of the BatonObjects property which a user can only set it if the user is in 
 * control of it.
 * <p>
 * If the BatonObject is not yet synchrnonized, the value will be cached and 
 * sent when the BatonProperty is back in sync.
 * <p>
 * If the BatonObjects property is available, setting the value will also try to grab 
 * control of the property before setting the value.
 * @param p_propertyName The key of the Property being added
 * @param p_value The value of the property, defaults to null
 * @function
 */
BatonObject.prototype.setProperty = function(p_propertyName, p_value) 
{
	if (this.isSynchronized) {
		if (this.isAvailable(p_propertyName)) {
			if (!this.cachedValueForSetProp[p_propertyName]) {	//only toggle the first time
				this.grab(p_propertyName);
			}
			this.cachedValueForSetProp[p_propertyName] = p_value; //overwrite the value that will eventually be published
		} else if (this.amIHolding(p_propertyName)){
			var args = new Array();
			args.push(p_propertyName);
			args.push(p_value);
			SharedObject.prototype.setProperty.apply(this,args) ;
			delete this.cachedValueForSetProp[p_propertyName];
		}
	}
}

/**
 * The value of the BatonObjects property which a user can only delete it if the user is in 
 * control of it.
 * <p>
 * If the BatonObject is not yet synchrnonized, the value will be cached and 
 * deleted when the BatonProperty is back in sync.
 * <p>
 * If the BatonObjects property is available, deleting the value will also try to grab 
 * control of the property before deleting the value and then release the control as well.
 * @param p_propertyName The key of the Property that needs to be retracted from the BatonObject.
 * @function
 */
BatonObject.prototype.removeProperty = function(p_propertyName) 
{
	if (this.isAvailable(p_propertyName)) {
		if (!this.cachedValueForDeleteProp[p_propertyName]) {	//only toggle the first time
			this.grab(p_propertyName);
		}
		this.cachedValueForDeleteProp[p_propertyName] = "someRandomValue"; //overwrite the value that will eventually be published
	} else if (this.amIHolding(p_propertyName)){
		//putDown(p_propertyName);
		var args = new Array();
		args.push(p_propertyName);
		SharedObject.prototype.removeProperty.apply(this,args) ;
		//delete _cachedValueForDeleteProp [p_propertyName];
	}
}

/**
 * Calls the <code>removeProperty</code> for all the properties in the BatonObject. It would delete all the properties that are
 * avialable or properties that you are holding.
 * @function
 */
BatonObject.prototype.removeAll = function() 
{ 
	for (var propertyName in this.sharedObject) {
		this.removeProperty(propertyName);
	}
}

/**
 * @private
 */
BatonObject.prototype.onTimerComplete = function(args) 
{ 
	for (var i in this.autoReleaseTimers) {
		if (this.autoReleaseTimers[i].timer &&  args && i == args) {
			this.collectionNode.retractItem(this.batonNodeName,i);
			clearTimeout(this.autoReleaseTimers[i].timer);
			this.autoReleaseTimers[i].timer = undefined;
			break;
		}
	}
}

/**
 * @private
 */
BatonObject.prototype.synchronizationChange = function(p_evt) 
{ 
	if (!this.userManager && this.connectSession) {
		this.userManager = this.connectSession.userManager;
	}

	var args = new Array();
	args.push(p_evt);
	SharedObject.prototype.synchronizationChange.apply(this,args) ;

	if (this.isSynchronized) {
		if (!this.collectionNode.isNodeDefined(this.batonNodeName)) {	//we're the first ones here
			var nodeConf = new Object();
			nodeConf.accessModel = 10;
			nodeConf.publishModel = this.pubModelForControlling;
			nodeConf.modifyAnyItem = false;
			nodeConf.userDependentItems = true;
			this.collectionNode.createNode(this.batonNodeName, nodeConf);
		}
		
		if (this.holderID && this.cachedBatonHolderID) {	//this will work but I don't like it...we might want to use _holderIDSetFromNetwork:Boolean
			for (var i in this.cachedBatonHolderID) {
				if ( this.getUserRole(this.userManager.myUserID) >= this.pubModelForYanking ) {
					//giveTo(_cachedBatonHolderID);
					this.giveTo(this.cachedBatonHolderID[i],i);
				} else if ( this.canIGrab && this.cachedBatonHolderID[i] == this.userManager.myUserID ) {
					this.grab(this.cachedBatonHolderID[i]);
				}
				delete this.cachedBatonHolderID[i];
			}
		}
	} else {
		//clean up model!
		this.stopAllTimers();
		this.cachedBatonHolderID = null;
		this.holderID = null;
	}
	
}

/**
 * @private
 */
BatonObject.prototype.itemReceive = function(p_evt) 
{ 
	var theItem = p_evt.item;
	if (!this.userManager && this.connectSession) {
		this.userManager = this.connectSession.userManager;
	}
	
	if (theItem.nodeName == this.batonNodeName) {
		this.holderID[theItem.itemID] = theItem.body;	
		if (this.cachedBatonHolderID[theItem.itemID]) {
			delete this.cachedBatonHolderID[theItem.itemID];
		}
		if (this.amIHolding(theItem.itemID)) {
			if ((this.autoReleaseTimers[theItem.itemID] && this.autoReleaseTimers[theItem.itemID].delay>0) || this.timeOut > 0) {
				this.createTimer(theItem.itemID);
			}
		}
		var evt = new Object();
		evt.type = "batonHolderChange";
		evt.PROPERTY_ID = theItem.itemID;
		evt.currentTarget = evt.target = this;
		if (this.cachedValueForSetProp[theItem.itemID]) {
			if (this.isSynchronized && this.amIHolding(theItem.itemID)) {
				var args = new Array();
				args.push(theItem.itemID);
				args.push(this.cachedValueForSetProp[theItem.itemID]);
				SharedObject.prototype.setProperty.apply(this,args);
				delete this.cachedValueForSetProp[theItem.itemID];
			}
		} else if (this.cachedValueForDeleteProp[theItem.itemID]) {
			if (this.isSynchronized && this.amIHolding(theItem.itemID)) {
				this.removeProperty(theItem.itemID);
				delete this.cachedValueForDeleteProp[theItem.itemID];
			}
		}
		this.dispatchEvent(evt);
	} else {
		var args = new Array();
		args.push(p_evt);
		SharedObject.prototype.itemReceive.apply(this,args) ;
	}
}

/**
 * @private
 */
BatonObject.prototype.itemRetract = function(p_evt) 
{
	var theItem = p_evt.item;
	if (p_evt.nodeName == this.batonNodeName) {			//no need to check the itemID, I only have one
		delete this.holderID[theItem.itemID];
		delete this.cachedBatonHolderID[theItem.itemID];
		if (this.autoReleaseTimers[theItem.itemID] && this.autoReleaseTimers[theItem.itemID].timer) {
			clearTimeout(this.autoReleaseTimers[theItem.itemID].timer);
			this.autoReleaseTimers[theItem.itemID].timer = undefined;
		}
		//super.removeProperty(theItem.itemID);
		var evt = new Object();
		evt.type = "batonHolderChange";
		evt.PROPERTY_ID = theItem.itemID;
		evt.currentTarget = evt.target = this;
		this.dispatchEvent(evt);
	}else {
		//super.onItemRetract(p_evt);
		var args = new Array();
		args.push(p_evt);
		SharedObject.prototype.itemRetract.apply(this,args);
		delete this.cachedValueForDeleteProp[theItem.itemID];
		if (this.amIHolding(theItem.itemID)) {
			this.putDown(theItem.itemID);
		}
	}
}

/**
 * @private
 */
BatonObject.prototype.commitProperties = function() 
{ 
	var nodeConf ;

	if ( this.publishModel != -1 && this.collectionNode.getNodeConfiguration(this.batonNodeName).publishModel != this.publishModel ){
		nodeConf = this.collectionNode.getNodeConfiguration(this.batonNodeName) ;
		nodeConf.publishModel = this.publishModel ;
		this.collectionNode.setNodeConfiguration(this.batonNodeName,nodeConf );
	}
	
	if ( this.accessModel != -1 && this.collectionNode.getNodeConfiguration(this.batonNodeName).accessModel != this.accessModel ){
		nodeConf = this.collectionNode.getNodeConfiguration(this.batonNodeName) ;
		nodeConf.accessModel = this.accessModel ;
		this.collectionNode.setNodeConfiguration(this.batonNodeName, nodeConf ) ;
	}
}

/**
 * @private
 */
BatonObject.prototype.createTimer = function(p_timerID) 
{ 
	if (!this.autoReleaseTimers[p_timerID] || (this.autoReleaseTimers[p_timerID] && !this.autoReleaseTimers[p_timerID].timer)) {
		if (this.autoReleaseTimers[p_timerID] && this.autoReleaseTimers[p_timerID].delay) {
			var delay =  this.autoReleaseTimers[p_timerID].delay;
			this.autoReleaseTimers[p_timerID].timer = setTimeout( bindUsingClosure(this.onTimerComplete,this), delay, p_timerID);
		} else {
			if (!this.autoReleaseTimers[p_timerID]) {
				this.autoReleaseTimers[p_timerID] = new Object();
			}
			this.autoReleaseTimers[p_timerID].timer = setTimeout( bindUsingClosure(this.onTimerComplete,this), (this.timeOut*1000), p_timerID);
		}
	}
}

/**
 * @private
 */
BatonObject.prototype.stopAllTimers = function() 
{ 
	for (var i in this.autoReleaseTimers) {
		if (i.timer) {
			clearTimeOut(i.timer);
		}
		delete this.autoReleaseTimers[i];
	}
}

/**
 * @class SharedCollection is a simple ArrayCollection which is shared across the LCCS services. Useful for sharing the contents
 * of a List or Datagrid (or any other component with a dataProvider), it supports the general addItem, setItemAt, removeItemAt,
 * and removeAll methods for updating the collection. Any changes through these APIs are shared with other users subscribed to 
 * the collection. Note, however, that changing a collection's object properties without calling setItemAt to update them results
 * in those properties not being shared.
 * <p>
 * The collection does not share sort order: Any sorting desired should be performed on each respective client. As such,
 * addItemAt isn't supported, although addItem is. The collection makes update decisions on items based on a unique ID.
 * Items added to the collection should either implement the IUID interface or provide a field which is guaranteed to be unique 
 * for this collection. The SharedCollection exposes an <code>idField</code> property to specify which 
 * field to use as unique ID; in the case the items do not implement IUID.
 * <p>
 * The SharedCollection exposes the ability to set NodeConfiguration options for the node upon which the items are sent. In this way
 * the collection can have its access and publish rights assigned as well as the other settings allowed by NodeConfiguration.
 * Note that this component supports "piggybacking" on existing CollectionNodes through its <code>collectionNode</code> property
 * and its subscribe method. Developers can avoid CollectionNode proliferation in their applications by pre-supplying a CollectionNode 
 * to the <code>collectionNode</code> property and a <code>nodeName</code> (in the subscribe method) 
 * for the SharedCollection to use. If none is supplied, the SharedCollection will create its own collectionNode named for the 
 * <code>uniqueID</code> supplied in subscribe()for sending and receiving messages.
 * <table><tr><th><b>Event</b></th><th><b>Summary</b></th></tr>
 * <tr><td valign="top"><code>collectionChange </code></td> <td> Dispatched when the Collection has been updated in some way.</td></tr>
 * <tr><td valign="top"><code>reconnect</code></td> <td> The type of event emitted when the CollectionNode is about to reconnect to the server.</td></tr>
 * <tr><td valign="top"><code>synchronizationChange</code></td> <td> Dispatched when the SharedCollection goes in and out of sync with the service.</td></tr>
 * </table>
 * 
 */
function SharedCollection() {
	this.connectSession = ConnectSession.primarySession;
	this.sharedArray = new Array();
	this.source = this.sharedArray;
}
EventDispatcher.initialize(SharedCollection.prototype);

/**
 * Defines the logical location of the component on the service. Typically this assigns the <code>sharedID</code> of the collectionNode
 * used by the component. <code>sharedIDs</code> should be unique within a room if they're expressing 2 unique locations. Note that
 * this can only be assigned once before <code>subscribe()</code> is called. For components with an <code>id</code> property, 
 * <code>sharedID</code> defaults to that value.
 */
SharedCollection.prototype.sharedID;
/**
 * The ConnectSession with which this component is associated. Note that this may only be set once before <code>subscribe</code>
 * is called; re-sessioning of components is not supported.
 */
SharedCollection.prototype.connectSession = undefined;
/**
 * Specifies an existing collectionNode to use in case a developer wishes to supply their own, and avoid having the 
 * sharedCollection create a new one.
 */
SharedCollection.prototype.collectionNode;

/**
 * @private
 */
SharedCollection.prototype.ITEM_NODE = "itemNode";
/**
 * @private
 */
SharedCollection.prototype.nodeConfig;
/**
 * @private
 */
SharedCollection.prototype.nodeName = "itemNode";
/**
 * @private
 */
SharedCollection.prototype.myUserID;

/**
 * If each item doesn't implement IUID, specifies a field within the item to use as a unique ID.
 */
SharedCollection.prototype.idField;
/**
 * If each item doesn't implement IUID, specifies a field within the item to use as a unique ID.
 */
SharedCollection.prototype.sharedArray = undefined;

SharedCollection.prototype.source = undefined;


/**
 * Returns whether or not the sharedCollection has retrieved any information previously stored on the service, and 
 * is currently connected to the service. 
 */
SharedCollection.prototype.isSynchronized = function()
{
	if (this.collectionNode) {
		return this.collectionNode.isSynchronized;
	} else {
		return false;
	}
}
/**
 * Sets the node configuration.
 * @param p_nodeConfig The node configuration..
 */
SharedCollection.prototype.setNodeConfiguration = function(p_nodeConfig)
{
	this.nodeConfig = p_nodeConfig ;
	if ( isSynchronized ) {
		this.collectionNode.setNodeConfiguration(this.nodeName,this.nodeConfig);
	}
}

/**
 * Disposes all listeners to the network and framework classes. 
 * Recommended for proper garbage collection of the component.
 */
SharedCollection.prototype.close = function()
{	
	this.collectionNode.removeEventListener("synchronizationChange", this);
	this.collectionNode.removeEventListener("itemReceive", this);
	this.collectionNode.removeEventListener("itemRetract", this);
	this.collectionNode.removeEventListener("reconnect", this);
	this.collectionNode.unsubscribe();
	this.collectionNode = null;
}

/**
 * Tells the component to begin synchronizing with the service.  
 * For "headless" components such as this one, this method must be called explicitly.
 */
SharedCollection.prototype.subscribe = function()
{
	if ( this.nodeConfig == null ) {
		this.nodeConfig = new NodeConfiguration();
	}
	
	this.nodeConfig.itemStorageScheme = 2;
	
	if (!this.collectionNode) {
		this.collectionNode = new CollectionNode();
		this.collectionNode.sharedID = this.sharedID ;
		this.collectionNode.connectSession = this.connectSession ;
		this.collectionNode.subscribe();
	}
	this.collectionNode.addEventListener("synchronizationChange", this);
	this.collectionNode.addEventListener("itemReceive", this);
	this.collectionNode.addEventListener("itemRetract", this);
	this.collectionNode.addEventListener("reconnect", this);
}

/**
 * Replaces the item at the specified index.
 * @param The new item to set.
 * @param The index of the item to replace. Note that this index is local-only; on remote collections, it's the unique ID
 * of the item which is used to locate and replace the item. 
 * @return The item previously at this location.
 */
SharedCollection.prototype.setItemAt = function(p_item, p_index)
{
	var oldItem = this.getItemAt(p_index);
	var msg = new MessageItem();
	msg.nodeName = this.nodeName;
	msg.body = p_item;
	msg.itemID = this.getItemID(oldItem);
	
	this.collectionNode.publishItem(msg, true);
	return oldItem;
}

/**
 * Adds the specified item to the end of the list. 
 * @param p_item The item to add.
 */
SharedCollection.prototype.addItem = function(p_item)
{
	var msg = new MessageItem();
	msg.nodeName = this.nodeName;
	msg.body = p_item;
	msg.itemID = this.getItemID(p_item);
	this.collectionNode.publishItem(msg);
}

/**
 * Removes the item at the specified index.
 * @param p_index The index of the item to remove. Note that this index is local-only; on remote collections, it's the 
 * unique ID of the item which is used to locate and remove the item.
 * @return The item preivously at this location.
 * 
 */		
SharedCollection.prototype.removeItemAt = function(p_index)
{
	var oldItem = this.getItemAt(p_index);
	this.collectionNode.retractItem(this.nodeName, this.getItemID(oldItem));
	return oldItem;
}

/**
 * Removes all items in the collection.
 */		
SharedCollection.prototype.removeAll = function()
{
	for (var i=this.sharedArray.length-1; i>=0; i--) {
		this.removeItemAt(i);
	}
}

/**
 * @private
 */
SharedCollection.prototype.synchronizationChange = function(p_evt)
{
	if ( this.collectionNode.isSynchronized ) {
		this.myUserID = this.connectSession.userManager.myUserID;
		if (!this.collectionNode.isNodeDefined(this.nodeName) && this.collectionNode.canUserConfigure(this.myUserID, this.nodeName)) {
			// this collectionNode has never been built, and I can add it...
			this.collectionNode.createNode(this.nodeName, this.nodeConfig);
		}
	}
	p_evt.target = p_evt.currentTarget = this;
	this.dispatchEvent(p_evt);
}

/**
 * @private
 */
SharedCollection.prototype.reconnect = function(p_evt)
{
	this.removeAll(this.sharedArray) ; //expand it
	p_evt.target = p_evt.currentTarget = this;
	this.dispatchEvent(p_evt);
}

/**
 * @private
 */
SharedCollection.prototype.itemReceive = function(p_evt)
{
	if (p_evt.nodeName!=this.nodeName) {
		return;
	}
	var newItem = p_evt.item.body;
	var itemID = (this.idField) ? newItem[this.idField] : newItem.uid;
	var oldItem;
	var i;
	// yes, this is ugly. Improve later
	var l = this.sharedArray.length;
	for (var idx=0; idx<l; idx++) {
		if (itemID==this.getItemID(this.getItemAt(idx))) {
			oldItem = this.getItemAt(idx);
			break;
		}
	}
	if (oldItem) {
		// it's an item update
		for (i in newItem) {
			if (newItem[i]!=oldItem[i]) {
				var tmpOldValue = oldItem[i];
				oldItem[i] = newItem[i];
				this.itemUpdated(oldItem, i, tmpOldValue, oldItem[i]); //expand
			}
		}
		this.setLocalItemAt(this.sharedArray, oldItem, idx);
	} else {
		this.addLocalItem(this.sharedArray,newItem);
	}
}

/**
 * @private
 */
SharedCollection.prototype.itemRetract = function(p_evt)
{
	if (p_evt.nodeName!=this.nodeName) {
		return;
	}
	var newItem = p_evt.item.body;
	var itemID = (this.idField) ? newItem[this.idField] : newItem.uid;
	
	var oldItem;
	// yes, this is ugly. Improve later
	var l = this.sharedArray.length;
	for (var idx=0; idx<l; idx++) {
		if (itemID==this.getItemID(this.getItemAt(idx))) {
			oldItem = this.getItemAt(idx);
			break;
		}
	}
	if (oldItem) {
		this.removeLocalItemAt(this.sharedArray,idx);
	}
}

/**
 * @private
 */
SharedCollection.prototype.getItemID = function(p_item)
{
	var testID = (p_item.uid) ? p_item.uid : p_item[this.idField];
	if (!testID) {
		throw new Error("Each item in a sharedCollection requires a unique ID. Please have your items either implement mx.core.IUID, or " + 
			"specify 'sharedCollection.idField' so that the collection knows which field of your item is unique."); 
	} else {
		return testID;
	}
}

/**
 * @private
 */
SharedCollection.prototype.getItemAt = function(p_index)
{
	if (p_index < 0 || p_index >= this.sharedArray.length)  {
		throw new Error("Out of Bound Error");
	}
	return this.sharedArray[p_index];
	
}

/**
 * @private
 */
SharedCollection.prototype.removeLocalItemAt = function(p_array,p_index)
{
	var event = new Object();
	event.type = "collectionChange";
	event.kind = "remove";
	event.location = p_index;
	event.oldItem = p_array[p_index];
	event.newItem = null;
	p_array.splice(p_index, 1);
	event.target = event.currentTarget = this;
	this.dispatchEvent(event);
	
}

/**
 * @private
 */
SharedCollection.prototype.itemUpdated = function(item, property,oldValue,newValue)
{
	//dispatch an event
	var event = new Object();
	event.type = "collectionChange";
	event.item = item;
	event.property = property;
	event.oldValue = oldValue
	event.newValue = newValue;
	event.target = event.currentTarget = this;
	event.kind = "replace";
	this.dispatchEvent(event);
}
/**
 * @private
 */
SharedCollection.prototype.setLocalItemAt = function(p_array,p_item,p_index)
{
	if (p_index < 0 || p_index >= this.sharedArray.length)  {
		throw new Error("Out of Bound Error");
	}
	var tmp = this.getItemAt(p_index);
	this.sharedArray[p_index] = p_item;
	var event = new Object;
	event.type = "collectionChange";
	event.kind = "replace";
	event.location = p_index;
	event.oldItem = tmp;
	event.newItem = p_item;
	event.target = event.currentTarget = this;
	//this.dispatchEvent(event);
}
/**
 * @private
 */
SharedCollection.prototype.addLocalItem = function(p_array,p_item)
{
	this.sharedArray[this.sharedArray.length] = p_item;
	var event = new Object;
	event.target = event.currentTarget = this;
	event.type = "collectionChange";
	event.kind = "add";
	event.location = this.sharedArray.length -1;
	event.oldItem = null;
	event.newItem = p_item;
	this.dispatchEvent(event);
}
/**
 * @private
 */
SharedCollection.prototype.getItemIndex = function(p_item)
{
	for ( var i = 0; i < this.sharedArray.length ; i++ ) {
		if (this.sharedArray[i] == p_item) {
			return i;
		}
	}
	return -1;
}

SharedCollection.prototype.contains = function(p_item)
{
	return this.getItemIndex(p_item) != -1;
}

SharedCollection.prototype.length = function()
{
	return this.sharedArray.length;
} 



/**
 * @class SimpleChatModel is a model component which drives the SimpleChat pod. 
 * Its job is to keep the shared state of the chat pod synchronized across
 * multiple users using an internal CollectionNode. It exposes methods for 
 * manipulating that shared model as well as events indicating when that 
 * model changes. In general, user with the viewer role and higher can both 
 * add new messages and view those messages.
 * <table><tr><th><b>Event</b></th><th><b>Summary</b></th></tr>
 * <tr><td valign="top"><code>allowPrivateChatChange </code></td> <td> Dispatched when private chat is turned on or off.</td></tr>
 * <tr><td valign="top"><code>historyChange</code></td> <td> Dispatched when the message history changes; for example, when there is a new message or the messages are cleared.</td></tr>
 * <tr><td valign="top"><code>synchronizationChange</code></td> <td> Dispatched when the SimpleChatModel has fully connected and synchronized with the service or when it loses that connection.</td></tr>
 * <tr><td valign="top"><code>timeFormatChange</code></td> <td> Dispatched when the timestamp time format changes.</td></tr>
 * <tr><td valign="top"><code>typingListUpdate</code></td> <td> Dispatched when the list of currently typing users is updated.</td></tr>
 * <tr><td valign="top"><code>useTimeStampsChange</code></td> <td> Dispatched when timestamps are turned on or off.</td></tr>
 * </table>
 * @constructor
 */
function SimpleChatModel() {
	this.connectSession = ConnectSession.primarySession;
}
EventDispatcher.initialize(SimpleChatModel.prototype);

/**
 * Constant for setting the time format of timestamps to AM/PM mode.
 * @field
 */
SimpleChatModel.prototype.TIMEFORMAT_AM_PM = "ampm";
/**
 * Constant for setting the time format of timestamps to 24 hour mode.
 * @field
 */
SimpleChatModel.prototype.TIMEFORMAT_24H = "24h";

/**
 * @private
 */
SimpleChatModel.prototype.HISTORY_NODE_EVERYONE = "history";
/**
 * @private
 */
SimpleChatModel.prototype.HISTORY_NODE_PARTICIPANTS = "history_participants";
/**
 * @private
 */
SimpleChatModel.prototype.HISTORY_NODE_HOSTS = "history_hosts";
/**
 * @private
 */
SimpleChatModel.prototype.TYPING_NODE_NAME = "typing";
/**
 * @private
 */
SimpleChatModel.prototype.TIMEFORMAT_NODE_NAME = "timeformat";
/**
 * @private
 */
SimpleChatModel.prototype.USE_TIMESTAMPS_NODE_NAME = "useTimeStamps";
/**
 * @private
 */
SimpleChatModel.prototype.TOO_MANY_TYPING_THRESHOLD = 5;
/**
 * @private
 */
SimpleChatModel.prototype.COLOR_PRIVATE = "990000";
/**
 * @private
 */
SimpleChatModel.prototype.COLOR_HOSTS = "0099FF";

/**
 * @private
 */
SimpleChatModel.prototype.collectionNode;
/**
 * @private
 */
SimpleChatModel.prototype.userManager;
/**
 * Returns the current history of chat messages as a string.
 * @field
 */		
SimpleChatModel.prototype.history = "";
/**
 * @private
 */
SimpleChatModel.prototype.myName;
/**
 * Returns a list of currently typing users as a string.
 * @field
 */
SimpleChatModel.prototype.usersTyping = undefined;
/**
 * @private
 */
SimpleChatModel.prototype.userWithoutUserDescriptorTyping;
/**
 * @private
 */
SimpleChatModel.prototype.typingTimer;
/**
 * @private
 */
SimpleChatModel.prototype.timeFormat;
/**
 * Specifies whether or not to display timestamps next to each message. 
 * Only users with a publisher role or higher can configure this setting.
 * @field
 */
SimpleChatModel.prototype.useTimeStamps = true;
/**
 * Specifies whether private chat is allowed. Note that only users with the
 * owner role can configure this setting.
 * @field
 */
SimpleChatModel.prototype.allowPrivateChat = undefined;
/**
 * @private
 */
SimpleChatModel.prototype.chatCleared = false;
/**
 * @private
 */
SimpleChatModel.prototype.isClearAfterSessionRemoved =false;
/**
 * @private
 */
SimpleChatModel.prototype.messagesSeen = new Object();
/**
 * The role value set for accessing the chat history
 * @field
 */
SimpleChatModel.prototype.accessModel = undefined ;
/**
 * The role value set to publish to the chat history
 * @field
 */
SimpleChatModel.prototype.publishModel = undefined ;
/**
 * The ConnectSession with which this component is associated. Note that this may only be set once before <code>subscribe</code>
 * is called.
 * @field
 */
SimpleChatModel.prototype.connectSession = undefined;
/**
 * Defines the logical location of the component on the service - typically the sharedID of the collectionNode
 * used by the component.
 * @field
 */
SimpleChatModel.prototype.sharedID = "defaultSimpleChat";
/**
 * The default color used in formatting messages for the user's name
 * @field
 */
SimpleChatModel.prototype.nameColor = "0x000000";
/**
 * The default color used in formatting messages for the timestamp
 * @field
 */
SimpleChatModel.prototype.timeStampColor = "0x999999";

/**
 * Tells the component to begin synchronizing with the service.  
 * This method must be called explicitly.
 * @function
 */
SimpleChatModel.prototype.subscribe= function()
{
	this.collectionNode = new CollectionNode();
	this.collectionNode.sharedID = this.sharedID ;
	this.collectionNode.connectSession = this.connectSession ;
	this.collectionNode.addEventListener("synchronizationChange", this);
	this.collectionNode.addEventListener("userRoleChange", this);
	this.collectionNode.addEventListener("itemReceive", this);
	this.collectionNode.addEventListener("itemRetract", this);
	this.collectionNode.addEventListener("nodeDelete", this);
	this.collectionNode.addEventListener("nodeCreate", this);
	this.collectionNode.addEventListener("configurationChange", this);
	this.collectionNode.addEventListener("reconnect", this);
	this.collectionNode.subscribe();
	
	this.userManager = this.connectSession.userManager;
	this.userManager.addEventListener("userCreate",this);
	
	this.usersTyping = new Array();
	this.userWithoutUserDescriptorTyping = new Array();
	
	//this.typingTimer = new Timer(2000, 1);			
	//this.typingTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);
	//this.typingTimer = setTimeout(this.onTimerComplete,2000);
}


/**
 * Disposes all listeners to the network and framework classes. Recommended for 
 * proper garbage collection of the component.
 * @function
 */
SimpleChatModel.prototype.close= function()
{
	this.collectionNode.removeEventListener("synchronizationChange", synchronizationChange);
	this.collectionNode.removeEventListener("synchronizationChange", this);
	this.collectionNode.removeEventListener("userRoleChange", this);
	this.collectionNode.removeEventListener("itemReceive", this);
	this.collectionNode.removeEventListener("itemRetract", this);
	this.collectionNode.removeEventListener("nodeDelete", this);
	this.collectionNode.removeEventListener("nodeCreate", this);
	this.collectionNode.removeEventListener("configurationChange", this);
	this.userManager.removeEventListener("userCreate",this);
	
	this.collectionNode.unsubscribe();
	clearTimeout(this.typingTimer);
}

/**
 * Determines whether the Model is connected and fully synchronized with the service.
 * @function
 */
SimpleChatModel.prototype.isSynchronized = function()
{
	return this.collectionNode.isSynchronized;
}		

/**
 * Sends a message which is specified by the ChatMessageDescriptor.
 * 
 * @param p_msgDesc the message to send
 * @function
 */
SimpleChatModel.prototype.sendMessage = function(p_msgDesc)
{
	//do this before the returns
	//if (this.typingTimer.running) {
	//      this.typingTimer.stop();
	//    onTimerComplete();
	//}
	if(this.typingTimer) {
		clearTimeout(this.typingTimer);
		this.onTimerComplete();
	}
	
	if (!this.collectionNode.isSynchronized) {
		return;
	}
	
	if (p_msgDesc.msg && p_msgDesc.msg.length < 0) {
		return;	//we don't send empty messages
	}
	
	if (p_msgDesc.recipient && !this.allowPrivateChat) {
		//private messages are not allowed, return
		return;
	}
	
	p_msgDesc.displayName = this.userManager.getUserDescriptor(this.userManager.myUserID).displayName;
	
	var nodeName;
	if (p_msgDesc.role) {
		if (p_msgDesc.role==10) {
			nodeName = this.HISTORY_NODE_EVERYONE;
		} else if (p_msgDesc.role==50) {
			nodeName = this.HISTORY_NODE_PARTICIPANTS;
		} else {
			nodeName = this.HISTORY_NODE_HOSTS;
		}
	} else {
		nodeName = this.HISTORY_NODE_EVERYONE;
	}
	var msg = new Object();
	msg.body = p_msgDesc;
	msg.nodeName = nodeName;
	if (p_msgDesc.recipient!=null) {
		msg.recipientID = p_msgDesc.recipient;
	}
	if (p_msgDesc.role>this.collectionNode.getUserRole(this.userManager.myUserID, nodeName)) {
		p_msgDesc.timeStamp = (new Date()).getTime();
		this.addMsgToHistory(p_msgDesc);
	}
	this.collectionNode.publishItem(msg);
}

/**
 * Gets the NodeConfiguration on a specific node in the ChatModel. If the node is not defined, it will return null
 * @param p_nodeName The name of the node.
 * @function
 */
SimpleChatModel.prototype.getNodeConfiguration = function(p_nodeName)
{	
	if ( this.collectionNode.isNodeDefined(p_nodeName)) {
		return this.collectionNode.getNodeConfiguration(p_nodeName);
	}
	return null ;
}

/**
 * Sets the NodeConfiguration on a already defined node in chatModel. If the node is not defined, it will not do anything.
 * @param p_nodeConfiguration The node Configuration on a node in the NodeConfiguration.
 * @param p_nodeName The name of the node.
 * @function
 */
SimpleChatModel.prototype.setNodeConfiguration = function(p_nodeName,p_nodeConfiguration)
{	
	if ( this.collectionNode.isNodeDefined(p_nodeName)) {
		this.collectionNode.setNodeConfiguration(p_nodeName,p_nodeConfiguration) ;
	}
	
}

/**
 * Set the role value required for publishing to the chat
 * @function
 */
SimpleChatModel.prototype.setPublishModel = function(p_publishModel)
{	
	if ( p_publishModel < 0 || p_publishModel > 100 ) 
		return ; 
	
	var nodeConf ;
	
	if ( this.collectionNode.getNodeConfiguration(this.HISTORY_NODE_EVERYONE).publishModel != p_publishModel ){
		nodeConf = this.collectionNode.getNodeConfiguration(this.HISTORY_NODE_EVERYONE) ;
		nodeConf.publishModel = p_publishModel ;
		this.collectionNode.setNodeConfiguration(this.HISTORY_NODE_EVERYONE, nodeConf ) ;
	}
	
	if ( this.collectionNode.getNodeConfiguration(this.HISTORY_NODE_HOSTS).publishModel != p_publishModel ){
		nodeConf = this.collectionNode.getNodeConfiguration(this.HISTORY_NODE_HOSTS) ;
		nodeConf.publishModel = p_publishModel ;
		this.collectionNode.setNodeConfiguration(this.HISTORY_NODE_HOSTS, nodeConf ) ;
	}
	
	if ( this.collectionNode.getNodeConfiguration(this.HISTORY_NODE_PARTICIPANTS).publishModel != p_publishModel ){
		nodeConf = this.collectionNode.getNodeConfiguration(this.HISTORY_NODE_PARTICIPANTS) ;
		nodeConf.publishModel = p_publishModel ;
		this.collectionNode.setNodeConfiguration(this.HISTORY_NODE_PARTICIPANTS, nodeConf ) ;
	}
	
	if ( this.collectionNode.getNodeConfiguration(TYPING_NODE_NAME).publishModel != p_publishModel ){
		nodeConf = this.collectionNode.getNodeConfiguration(TYPING_NODE_NAME) ;
		nodeConf.publishModel = p_publishModel ;
		this.collectionNode.setNodeConfiguration(TYPING_NODE_NAME, nodeConf ) ;
	}
}

/**
 * The role value required for publishing to the chat
 * @function
 */
SimpleChatModel.prototype.getPublishModel = function()
{
	return this.collectionNode.getNodeConfiguration(this.HISTORY_NODE_EVERYONE).publishModel;
}

/**
 * Set The role value required for accessing the chat history
 * @function
 */
SimpleChatModel.prototype.setAccessModel = function(p_accessModel)
{	
	if ( p_accessModel < 0 || p_accessModel > 100 ) 
		return ; 
	
	var nodeConf ;
	
	if ( this.collectionNode.getNodeConfiguration(this.HISTORY_NODE_EVERYONE).accessModel != p_accessModel ){
		nodeConf = this.collectionNode.getNodeConfiguration(this.HISTORY_NODE_EVERYONE) ;
		nodeConf.accessModel = p_accessModel ;
		this.collectionNode.setNodeConfiguration(this.HISTORY_NODE_EVERYONE, nodeConf ) ;
	}
	
	if ( this.collectionNode.getNodeConfiguration(this.TYPING_NODE_NAME).accessModel != p_accessModel ){
		nodeConf = this.collectionNode.getNodeConfiguration(this.TYPING_NODE_NAME) ;
		nodeConf.accessModel = p_accessModel ;
		this.collectionNode.setNodeConfiguration(this.TYPING_NODE_NAME, nodeConf ) ;
	}	
	
}

/**
 * The role value required for accessing the chat history
 * @function
 */
SimpleChatModel.prototype.getAccessModel = function()
{
	return this.collectionNode.getNodeConfiguration(this.HISTORY_NODE_EVERYONE).accessModel;
}

/**
 *  Returns the role of a given user for the chat.
 * 
 * @param p_userID UserID of the user in question
 * @function
 */
SimpleChatModel.prototype.getUserRole = function(p_userID)
{
	return (this.collectionNode.isSynchronized) ? this.collectionNode.getUserRole(p_userID) : 5;
}

/**
 *  Sets the role of a given user for the chat.
 * 
 * @param p_userID UserID of the user whose role we are setting
 * @param p_userRole Role value we are setting
 * @function
 */
SimpleChatModel.prototype.setUserRole = function(p_userID ,p_userRole,p_nodeName)
{
	if ( p_userID == null ) 
		return ;
	
	
	if ( (p_userRole < 0 || p_userRole > 100) && p_userRole != -999 ) 
		return ; 
	
	if (p_nodeName) {
		if ( this.collectionNode.isNodeDefined(p_nodeName)) {
			this.collectionNode.setUserRole(p_userID,p_userRole,p_nodeName);
		}
	}else {
		this.collectionNode.setUserRole(p_userID,p_userRole);
	}
}

/**
 * Clears all chat history. Note that only a user with role UserRoles.OWNER may clear the chat
 * @function
 */
SimpleChatModel.prototype.clear= function()
{
	if (this.collectionNode.isSynchronized && this.collectionNode.canUserConfigure(this.userManager.myUserID)) {
		this.collectionNode.removeNode(this.HISTORY_NODE_EVERYONE);
		var nodeConfig = new Object();
		nodeConfig.accessModel=10;
		nodeConfig.publishModel=10;
		nodeConfig.persistItems=true;
		nodeConfig.modifyAnyItem=true;
		nodeConfig.userDependentItems=false;
		nodeConfig.sessionDependentItems=this.isClearAfterSessionRemoved;
		nodeConfig.itemStorageScheme=1;
		nodeConfig.allowPrivateMessages=false;
		nodeConfig.lazySubscription=false;
		nodeConfig.p2pDataMessaging=false;
		this.collectionNode.createNode(this.HISTORY_NODE_EVERYONE, nodeConfig);
		this.collectionNode.removeNode(this.HISTORY_NODE_PARTICIPANTS);
		var partNodeConfig = new Object();
		partNodeConfig.accessModel=50;
		partNodeConfig.publishModel=10;
		partNodeConfig.persistItems=true;
		partNodeConfig.modifyAnyItem=false;
		partNodeConfig.userDependentItems=false;
		partNodeConfig.sessionDependentItems=this.isClearAfterSessionRemoved;
		partNodeConfig.itemStorageScheme=1;
		partNodeConfig.allowPrivateMessages=false;
		partNodeConfig.lazySubscription=false;
		partNodeConfig.p2pDataMessaging=false;
		this.collectionNode.createNode(this.HISTORY_NODE_PARTICIPANTS,nodeConfig);
		this.collectionNode.removeNode(this.HISTORY_NODE_HOSTS);
		var hostNodeConfig = new Object();
		hostNodeConfig.accessModel=100;
		hostNodeConfig.publishModel=10;
		hostNodeConfig.persistItems=true;
		hostNodeConfig.modifyAnyItem=false;
		hostNodeConfig.userDependentItems=false;
		hostNodeConfig.sessionDependentItems=this.isClearAfterSessionRemoved;
		hostNodeConfig.itemStorageScheme=1;
		hostNodeConfig.allowPrivateMessages=false;
		hostNodeConfig.lazySubscription=false;
		hostNodeConfig.p2pDataMessaging=false;
		this.collectionNode.createNode(this.HISTORY_NODE_HOSTS, nodeConfig);
		this.messagesSeen = new Object();
	}
}

/**
 * The format of timestamps.
 * @function
 */
SimpleChatModel.prototype.getTimeFormat = function()
{
	return this.timeFormat;
}

/**
 * Specifies the format of timestamps (see the constants on this class). 
 * Note that only a user with a publisher role or higher can change this setting.
 * @function
 */
SimpleChatModel.prototype.setTimeFormat = function(p_timeFormat)
{
	switch (p_timeFormat) {
		case this.TIMEFORMAT_24H:
		case this.TIMEFORMAT_AM_PM:
			break;
		default:
			return;
	}
	
	if (this.timeFormat == p_timeFormat) {
		return;
	}
	
	if (this.collectionNode.canUserPublish(this.userManager.myUserID, this.TIMEFORMAT_NODE_NAME)) {
		var msgItem = new Object();
		msgItem.nodeName = this.TIMEFORMAT_NODE_NAME;
		msgItem.body = p_timeFormat;
		this.collectionNode.publishItem(msgItem);
	}
}

/**
 * Specifies whether or not to display timestamps next to each message.
 * @function
 */
SimpleChatModel.prototype.getUseTimeStamps = function()
{
	return this.useTimeStamps;
}

/**
 * Specifies whether or not to display timestamps next to each message. 
 * Only users with a publisher role or higher can configure this setting.
 * @function
 */
SimpleChatModel.prototype.setUseTimeStamps = function(p_useThem)
{
	if (this.useTimeStamps == p_useThem) {
		return;
	}
	
	if (this.collectionNode.canUserPublish(this.userManager.myUserID, this.USE_TIMESTAMPS_NODE_NAME)) {
		var msgItem = new Object();
		msgItem.nodeName = this.USE_TIMESTAMPS_NODE_NAME;
		msgItem.body = p_useThem;
		this.collectionNode.publishItem(msgItem);
	}
}

/**
 * Specifies whether private chat is allowed.
 * @function
 */
SimpleChatModel.prototype.getAllowPrivateChat = function()
{
	return this.allowPrivateChat;
}

/**
 * Specifies whether private chat is allowed. Note that only users with the
 * owner role can configure this setting.
 * @function
 */
SimpleChatModel.prototype.setAllowPrivateChat = function(p_allowIt)
{
	if (this.allowPrivateChat == p_allowIt) {
		return;
	}
	
	if (this.collectionNode.canUserConfigure(this.userManager.myUserID, this.HISTORY_NODE_EVERYONE)) {
		var oldConfig = this.collectionNode.getNodeConfiguration(this.HISTORY_NODE_EVERYONE);
		var newConfig = new NodeConfiguration();
		newConfig = oldConfig;
		newConfig.allowPrivateMessages = p_allowIt;
		this.collectionNode.setNodeConfiguration(HISTORY_NODE_EVERYONE, newConfig);
	}
}

/**
 * Returns a list of currently typing users as a string.
 * @function
 */
SimpleChatModel.prototype.getUsersTyping = function()
{
	var res = "";
	for (var i=0; i<this.usersTyping.length; i++) {
		var userID = this.usersTyping[i];
		var desc = this.userManager.getUserDescriptor(userID);
		if (desc != null && userID!=this.userManager.myUserID) {
			res+=((res=="") ? "" : ", ")+desc.displayName;
		}
	}
	return res;
}

/**
 * Updates the model to notify others that the current user is typing. This is automatically withdrawn after 2 seconds, unless this method is called again
 * during that time, at which point the 2 second timeout is reset. Typically, chaining this call to a TextInput's CHANGE event is effective - iAmTyping will 
 * avoid re-broadcasting the notification if not needed.
 * @function
 */
SimpleChatModel.prototype.iAmTyping= function()
{			
	if (!this.collectionNode.isSynchronized) {
		return;
	}
	
	if (!this.contains(this.usersTyping,this.userManager.myUserID)
		&& this.usersTyping.length < this.TOO_MANY_TYPING_THRESHOLD
	) {
		//I'm not typing yet and we're below the threshold, publish my item
		this.collectionNode.publishItem(new MessageItem(TYPING_NODE_NAME, this.userManager.myUserID, this.userManager.myUserID));
		
		//the receiveItem will start the timer
	}				
	
	//Extend the timer if it's running (and it's only running if we received our own typing item)
	this.typingTimer = setTimeout( bindUsingClosure(this.onTimerComplete,this), 2000);
}

/**
 *@private
 */
SimpleChatModel.prototype.onTimerComplete = function(args)
{
	if (args && this.contains(args.usersTyping, args.userManager.myUserID)) {
		args.collectionNode.retractItem(TYPING_NODE_NAME, args.userManager.myUserID);
	}
}

/**
 *@private
 */
SimpleChatModel.prototype.reconnect = function(p_evt)
{
	this.history = "";
	this.messagesSeen = new Object();
	this.chatCleared = true;
	p_evt.currentTarget = p_evt.target = this;
	p_evt.type = "historyChange"
	this.dispatchEvent(p_evt);
}

/**
 *@private
 */
SimpleChatModel.prototype.synchronizationChange = function(p_event)
{
	this.myName = (this.userManager.getUserDescriptor(this.userManager.myUserID)).displayName;
	if (this.collectionNode.isSynchronized) {
		//if the node doesn't exist and I'm a host, create it empty so that viewers can publish to it
		if (!this.collectionNode.isNodeDefined(this.HISTORY_NODE_EVERYONE) && this.collectionNode.canUserConfigure(this.userManager.myUserID)) {
			var nodeConfig = new Object();
			nodeConfig.accessModel=10;
			nodeConfig.publishModel=10;
			nodeConfig.persistItems=true;
			nodeConfig.modifyAnyItem=false;
			nodeConfig.userDependentItems=false;
			nodeConfig.sessionDependentItems=this.isClearAfterSessionRemoved;
			nodeConfig.itemStorageScheme=1;
			nodeConfig.allowPrivateMessages=true;
			nodeConfig.lazySubscription=false;
			nodeConfig.p2pDataMessaging=false;
			this.collectionNode.createNode(this.HISTORY_NODE_EVERYONE, nodeConfig);
			
			var partNodeConfig = new Object();
			partNodeConfig.accessModel=50;
			partNodeConfig.publishModel=10;
			partNodeConfig.persistItems=true;
			partNodeConfig.modifyAnyItem=false;
			partNodeConfig.userDependentItems=false;
			partNodeConfig.sessionDependentItems=this.isClearAfterSessionRemoved;
			partNodeConfig.itemStorageScheme=1;
			partNodeConfig.allowPrivateMessages=false;
			partNodeConfig.lazySubscription=false;
			partNodeConfig.p2pDataMessaging=false;
			this.collectionNode.createNode(this.HISTORY_NODE_PARTICIPANTS, partNodeConfig);
			
			var hostNodeConfig = new Object();
			hostNodeConfig.accessModel=100;
			hostNodeConfig.publishModel=10;
			hostNodeConfig.persistItems=true;
			hostNodeConfig.modifyAnyItem=false;
			hostNodeConfig.userDependentItems=false;
			hostNodeConfig.sessionDependentItems=this.isClearAfterSessionRemoved;
			hostNodeConfig.itemStorageScheme=1;
			hostNodeConfig.allowPrivateMessages=false;
			hostNodeConfig.lazySubscription=false;
			hostNodeConfig.p2pDataMessaging=false;
			this.collectionNode.createNode(this.HISTORY_NODE_HOSTS, hostNodeConfig);
			
			var nodeConfig1 = new Object();
			nodeConfig1.accessModel=10;
			nodeConfig1.publishModel=10;
			nodeConfig1.persistItems=true;
			nodeConfig1.modifyAnyItem=false;
			nodeConfig1.userDependentItems=true;
			nodeConfig1.sessionDependentItems=this.isClearAfterSessionRemoved;
			nodeConfig1.itemStorageScheme=1;
			nodeConfig1.allowPrivateMessages=true;
			nodeConfig1.lazySubscription=false;
			nodeConfig1.p2pDataMessaging=false;
			this.collectionNode.createNode(this.TYPING_NODE_NAME, nodeConfig1);
			//create by publishing the default
			
			var msgItem = new Object();
			msgItem.nodeName = this.TIMEFORMAT_NODE_NAME;
			msgItem.body = this.TIMEFORMAT_AM_PM;
			this.collectionNode.publishItem(msgItem);
			
			//create by publishing the default
			var msgItem1 = new Object();
			msgItem1.nodeName = this.USE_TIMESTAMPS_NODE_NAME;
			msgItem1.body = true;
			this.collectionNode.publishItem(msgItem1);
			this.userManager = this.connectSession.userManager;
		}
	}
	p_event.currentTarget = p_event.target = this;
	this.dispatchEvent(p_event);
}

/**
 *@private
 */
SimpleChatModel.prototype.itemReceive = function(p_event)
{
	var item = p_event.item;
	if (this.userManager) {
		var tmpUsrDesc;
		if (item.publisherID) {
			tmpUsrDesc = this.userManager.getUserDescriptor(item.publisherID);
		} else {
			tmpUsrDesc = this.userManager.getUserDescriptor(item.itemID);
		}
	}
	
	switch (item.nodeName)
	{
		case this.HISTORY_NODE_PARTICIPANTS:
		case this.HISTORY_NODE_HOSTS:
		case this.HISTORY_NODE_EVERYONE:
			//add it to the history
			
			
			var msgDesc = new Object();
			msgDesc = item.body;
			if (this.messagesSeen[item.itemID]) {
				return;
			}
			this.messagesSeen[item.itemID] = true;
			if (item.recipientID!=null) {
				msgDesc.recipient = item.recipientID;
			}
			if (item.nodeName==this.HISTORY_NODE_HOSTS) {
				msgDesc.role = 100;
			} else if (item.nodeName==this.HISTORY_NODE_PARTICIPANTS) {
				msgDesc.role = 50;
			}
			msgDesc.timeStamp = item.timeStamp;
			msgDesc.publisherID = item.publisherID;
			this.addMsgToHistory(msgDesc);				
			break;
		case this.TYPING_NODE_NAME:
			if (!this.contains(this.addMsgToHistory, item.itemID)) {
				if (item.itemID == this.userManager.myUserID) {
					this.usersTyping.push(item.itemID);
					//we got our own item back, start the timer
					if(this.typingTimer) {
						clearTimeout(this.typingTimer);
						this.typingTimer = setTimeout( bindUsingClosure(this.onTimerComplete,this), 2000);
					}
					p_evt.currentTarget = p_evt.target = this;
					p_evt.type = "typingListUpdate";
					this.dispatchEvent(p_evt);
				} else if (this.userManager.getUserDescriptor(item.itemID)) {
					this.usersTyping.push(item.itemID);
					p_evt.currentTarget = p_evt.target = this;
					p_evt.type = "typingListUpdate";
					this.dispatchEvent(p_evt);
				} else {
					this.userWithoutUserDescriptorTyping.push(item.itemID);
				}
				
			}
			break;
		case this.TIMEFORMAT_NODE_NAME:
			this.timeFormat = item.body;
			p_evt.currentTarget = p_evt.target = this;
			p_evt.type = "timeFormatChange";
			this.dispatchEvent(p_evt);
			break;
		case this.USE_TIMESTAMPS_NODE_NAME:
			this.useTimeStamps = item.body;
			p_evt.currentTarget = p_evt.target = this;
			p_evt.type = "useTimeStampsChange";
			this.dispatchEvent(new ChatEvent(ChatEvent.USE_TIME_STAMPS_CHANGE));
			break;
	}
}

/**
 *@private
 */
SimpleChatModel.prototype.userCreate = function(p_evt)
{
	if (this.contains(this.userWithoutUserDescriptorTyping,p_evt.userDescriptor.userID)) {
		this.usersTyping.push(p_evt.userDescriptor.userID);
		p_evt.currentTarget = p_evt.target = this;
		p_evt.type = "typingListUpdate";
		this.dispatchEvent(p_evt);
		this.removeItem(this.userWithoutUserDescriptorTyping,p_evt.userDescriptor.userID);
	}
}

/**
 *@private
 */
SimpleChatModel.prototype.getNameColor = function(p_msgDesc)
{
	if (p_msgDesc.recipient!=null) {
		// it was a message I sent privately to another
		return this.COLOR_PRIVATE;
	} else if (p_msgDesc.role>UserRoles.VIEWER)	{
		// it was a message sent to a role group, and I can see it (either because I sent it or am in the group)
		return this.COLOR_HOSTS;
	} else {
		return this.nameColor+"";
	}
}

/**
 *@private
 */
SimpleChatModel.prototype.getMsgColor = function(p_msgDesc)
{
	if (p_msgDesc.recipient!=null) {
		// it was a message I sent privately to another
		return this.COLOR_PRIVATE;
	} else if (p_msgDesc.role>10)	{
		// it was a message sent to a role group, and I can see it (either because I sent it or am in the group)
		return this.COLOR_HOSTS;
	} else {
		if (p_msgDesc.color) {
			return p_msgDesc.color;
		}
	}
	return this.COLOR_HOSTS;
}

/**
 *@private
 */
SimpleChatModel.prototype.getHistoryFontSize = function()
{
	return this.historyFontSize;
}

/**
 *@private
 */
SimpleChatModel.prototype.setHistoryFontSize = function(p_size)
{
	if ( this.historyFontSize != p_size ) {
		this.historyFontSize = p_size;
		//EXPENSIVE!
		this.history = this.history.replace(/size=\".*?\"/g, "size=\""+this.historyFontSize+"\"");
		p_evt.currentTarget = p_evt.target = this;
		p_evt.type = "historyChange";
		this.dispatchEvent(p_evt);
	}
}

/**
 *@private
 */
SimpleChatModel.prototype.getTimeStampColor = function(p_msgDesc)
{
	if (p_msgDesc.recipient!=null) {
		// it was a message I sent privately to another
		return this.COLOR_PRIVATE;
	} else if (p_msgDesc.role>UserRoles.VIEWER)	{
		// it was a message sent to a role group, and I can see it (either because I sent it or am in the group)
		return this.COLOR_HOSTS;
	} else {
		return this.timeStampColor+"";
	}
}

/**
 * Formats a given MessageDescriptor into a readable string
 * @param p_msgDesc the desired ChatMessageDescriptor to format
 * @function
 */
SimpleChatModel.prototype.formatMessageDescriptor = function(p_msgDesc)
{
	var timeStampStr = "";
	
	var nameColor = this.getNameColor(p_msgDesc);
	var msgColor = this.getMsgColor(p_msgDesc);
	var tStampColor = this.getTimeStampColor(p_msgDesc);			
	
	var privateModifier = "";
	
	if (p_msgDesc.publisherID == this.userManager.myUserID && p_msgDesc.recipient!=null) {
		// it was a message I sent privately to another
		privateModifier = " (to"+" "+p_msgDesc.recipientDisplayName+")";
	} else if (p_msgDesc.role>UserRoles.VIEWER)	{
		// it was a message sent to a role group, and I can see it (either because I sent it or am in the group)
		privateModifier = " (to"+" "+((p_msgDesc.role == UserRoles.OWNER)? "hosts" : "participants")+")";
	} else if (p_msgDesc.recipient!=null) {
		// it was a message sent privately to me
		privateModifier = " ("+"privately"+")";
	}
	
	if (this.useTimeStamps && !isNaN(p_msgDesc.timeStamp)) {
		var d = new Date(p_msgDesc.timeStamp);
		var hourMinutes = new Array();
		hourMinutes.push = d.getHours();
		hourMinutes.push = d.getMinutes();
		if (hourMinutes[1] < 10) {	//pad minutes if needed
			hourMinutes[1] = "0"+hourMinutes[1];
		}
		if (this.timeFormat == this.TIMEFORMAT_AM_PM) {
			var timeTemplate = "%12%:%M% %D%";
			timeTemplate = timeTemplate.replace("%M%", hourMinutes[1]);
			var h = hourMinutes[0];
			if (h >= 12) {
				h -= 12;
				timeTemplate = timeTemplate.replace("%D%", "pm");
			} else {
				timeTemplate = timeTemplate.replace("%D%", "am");
			}
			if (h == 0) {
				timeStampStr = timeTemplate.replace("%12%", "12");
			} else {
				timeStampStr = timeTemplate.replace("%12%", h);
			}
		} else {
			timeStampStr = hourMinutes[0]+":"+hourMinutes[1];
		}
		timeStampStr = "<font color=\"#"+tStampColor+"\">["+timeStampStr+"]</font> ";
	}
	
	var msg = p_msgDesc.msg;
	msg = msg.replace(/</g, "&lt;");
	msg = msg.replace(/>/g, "&gt;");
	
	//TODO: make these colors come from a style!
	var toAdd;
	toAdd = "<font size=\""+this.historyFontSize+"\">"
		+timeStampStr
		+"<font color=\"#"+nameColor+"\"><b>"+p_msgDesc.displayName+privateModifier+"</b>: </font>"
		+"<font color=\"#"+msgColor+"\">"+msg+"</font>"
		+"</font><br/>";
	
	return toAdd;
}


/**
 *@private
 */
SimpleChatModel.prototype.addMsgToHistory = function(p_msgDesc)
{
	//var toAdd = this.formatMessageDescriptor(p_msgDesc);
	var toAdd;
	if (p_msgDesc instanceof Array) {
		//toAdd = p_msgDesc[1]+":"+p_msgDesc[2]+"\n";
		for (var i in p_msgDesc)
		{
			if (toAdd) {
				toAdd = toAdd + p_msgDesc[i];
			} else {
				toAdd = p_msgDesc[i];
			}
		}
		toAdd = toAdd + "\n";
	} else if (p_msgDesc instanceof Object) {
		toAdd = p_msgDesc.displayName+":"+p_msgDesc.msg+"\n";
		//toAdd = p_msgDesc["displayName"]+":"+p_msgDesc["msg"]+"\n";
	}
	//var toAdd = p_msgDesc;
	var p_evt = new Object();
	if (this.chatCleared) {
		this.history=toAdd;
		this.chatCleared = false;
		p_evt.currentTarget = p_evt.target = this;
		p_evt.message = p_msgDesc;
		p_evt.type = "historyChange";
		this.dispatchEvent(p_evt);
	} else {
		this.history+=toAdd;
		p_evt.currentTarget = p_evt.target = this;
		p_evt.message = p_msgDesc;
		p_evt.type = "historyChange";
		this.dispatchEvent(p_evt);
	}
	
}

/**
 *@private
 */
SimpleChatModel.prototype.itemRetract = function(p_evt)
{
	var item = p_evt.item;
	
	if (item.nodeName == this.TYPING_NODE_NAME)
	{
		if (this.contains(this.addMsgToHistory,item.itemID)) {
			this.removeItem(this.usersTyping,item.itemID);
			p_evt.currentTarget = p_evt.target = this;
			p_evt.type = "typingListUpdate";
			this.dispatchEvent(p_evt);
		}
		
		if (this.contains(this.userWithoutUserDescriptorTyping,item.itemID)) {
			this.removeItem(this.userWithoutUserDescriptorTyping,item.itemID);	
		}
	}
}

/**
 *@private
 */
SimpleChatModel.prototype.nodeDelete = function(p_evt)
{
	if (p_evt.nodeName == this.HISTORY_NODE_EVERYONE) {
		this.chatCleared = true;
		this.history = "<font size=\""+this.historyFontSize+"\" color=\"#666666\"><i>"+"The chat history has been cleared."+'\n'+"</i></font>";
		p_evt.currentTarget = p_evt.target = this;
		p_evt.type = "historyChange";
		this.dispatchEvent(p_evt);
	}
}

/**
 *@private
 */
SimpleChatModel.prototype.nodeCreate = function(p_evt)
{
	if (p_evt.nodeName==this.HISTORY_NODE_EVERYONE) {
		var tmpAllow = this.collectionNode.getNodeConfiguration(this.HISTORY_NODE_EVERYONE).allowPrivateMessages;
		if (tmpAllow!=this.allowPrivateChat) {
			this.allowPrivateChat = tmpAllow;
			p_evt.currentTarget = p_evt.target = this;
			p_evt.type = "allowPrivateChatChange";
			this.dispatchEvent(p_evt);
		}
	}
}

/**
 *@private
 */
SimpleChatModel.prototype.userRoleChange = function(p_evt)
{
	p_evt.currentTarget = p_evt.target = this;
	this.dispatchEvent(p_evt);
}

/**
 *@private
 *Contains code snippet copied from StackOverflow
 *http://stackoverflow.com/questions/237104/javascript-array-containsobj
 */
SimpleChatModel.prototype.contains = function(p_array, obj) {
	var i = p_array.length;
	while (i--) {
		if (p_array[i] === obj) {
			return true;
		}
	}
	return false;
}

/**
 *@private
 */
SimpleChatModel.prototype.removeItem = function(p_array, itemToRemove) {
	var j = 0;
	while (j < p_array.length) {
		if (p_array[j] == itemToRemove) {
			p_array.splice(j, 1);
		} else {
			j++;
		}
	}
}



/**
 * @class SharedCursor tracks the cursor positions of any user with role of UserRoles.PUBLISHER or higher within it and reports that position to other users.
 * It is also responsible for rendering the remote cursors corresponding to these positions.
 * <table><tr><th><b>Event</b></th><th><b>Summary</b></th></tr>
 * <tr><td valign="top"><code>synchronizationChange</code></td> <td> Dispatched when the SimpleChatModel has fully connected and synchronized with the service or when it loses that connection.</td></tr>
 * </table>
 * @constructor
 */
function SharedCursorPane() {
	this.connectSession = ConnectSession.primarySession;
	this.initialize();
}
EventDispatcher.initialize(SharedCursorPane.prototype);

SharedCursorPane.prototype.document;
/**
 * The field of UserDescriptor you want to show as label with your cursor. You can also show custom fields
 * @field
 */

SharedCursorPane.prototype.label = undefined;
/**
 * @private
 * @field
 */
SharedCursorPane.prototype.divElement = undefined;

/**
 * The time in milliseconds of the polling interval for cursor positions. 
 * Note that setting this to a higher number reduces 
 * network message traffic but also reduces responsiveness. Setting it to a lower 
 * number uses more bandwidth.
 */
SharedCursorPane.prototype.pollInterval = 500;
/**
 *@private
 */
SharedCursorPane.prototype.inactivityInterval = 2000;
/**
 *@private
 */
SharedCursorPane.prototype.shareCursorPosition;
/**
 * Defines the logical location of the component on the service; typically this assigns the <code>sharedID</code> of the collectionNode
 * used by the component. <code>sharedIDs</code> should be unique within a room if they're expressing two 
 * unique locations. Note that this can only be assigned once before <code>subscribe()</code> is called. For components 
 * with an <code>id</code> property, <code>sharedID</code> defaults to that value.
 */
SharedCursorPane.prototype.sharedID = "SharedCursorsCollection";
/**
 * The ConnectSession with which this component is associated; it defaults to the first 
 * IConnectSession created in the application.  Note that this may only be set once before 
 * <code>subscribe()</code> is called, and re-sessioning of components is not supported.
 */
SharedCursorPane.prototype.connectSession = undefined;
/**
 * When specifying an existing CollectionNode, <code>nodeName</code> specifies a 
 * <code>nodeName</code>  to use within that collectionNode for
 * all message traffic. Defaults to "Shared_Cursors".
 */
SharedCursorPane.prototype.nodeName = "Shared_Cursors";
/**
 *@private
 */
SharedCursorPane.prototype.wasPublisher = false;
/**
 * Property for sharing mode. There are two modes of sharing, <b>absolute</b> and  <b>relative</b>.
 * In <b>absolute</b> mode you get the exact position of the cursor of the sharing user.
 * In <b>relative</b> you get the relative position with respect to the size of your own cursor pane.
 * Default mode is <b>absolute</b>.
 */
SharedCursorPane.prototype.sizingMode = "absolute";
/**
 *@private
 */
SharedCursorPane.prototype.cursorsByID;
/**
 *@private
 */
SharedCursorPane.prototype.inactivityTimer;
/**
 *@private
 */
SharedCursorPane.prototype.lastMouseX = 0;
/**
 *@private
 */
SharedCursorPane.prototype.lastMouseY = 0;
/**
 *@private
 */
SharedCursorPane.prototype.pointTimer;
/**
 *@private
 */
SharedCursorPane.prototype.hasRetracted = false;
/**
 *@private
 */
SharedCursorPane.prototype.mouseX = 0;
/**
 *@private
 */
SharedCursorPane.prototype.mouseY = 0;
/**
 *Number that specifies the component's horizontal position, in pixels, within its parent container.
 *@field
 */
SharedCursorPane.prototype.x = 0;
/**
 *Number that specifies the component's vertical position, in pixels, within its parent container.
 *@field
 */
SharedCursorPane.prototype.y = 0;
/**
 *Number that specifies the width of the component, in pixels, in the parent's coordinates.
 *@field
 */
SharedCursorPane.prototype.width = undefined;
/**
 *Number that specifies the height of the component, in pixels, in the parent's coordinates.
 *@field
 */
SharedCursorPane.prototype.height = undefined;
/**
 *Specify your custom image src for the cursor
 *@field
 */
SharedCursorPane.prototype.cursorImgSrc = 'cursor.png';
/**
 *Specify your custom css class for the cursors font
 *@field
 */
SharedCursorPane.prototype.cursorClass;

/**
 *Initialized the shared Cursor by passing the document. The document model is used to manipulate the mouse positions.
 * @function
 */
SharedCursorPane.prototype.initialize = function()
{
	document.body.cursorTarget = this;
	if (!this.width) {
		this.width = document.documentElement.clientWidth;
	}
	if (!this.height) {
		this.height = document.documentElement.clientHeight;
	}
}

/**
 * Tells the component to begin synchronizing with the service. 
 * @function
 */
SharedCursorPane.prototype.subscribe = function()
{
	if (!this.collectionNode) {
		this.collectionNode = new CollectionNode();
		this.collectionNode.sharedID = this.sharedID ;
		this.collectionNode.connectSession = this.connectSession ;
		this.collectionNode.addEventListener("synchronizationChange", this);
		this.collectionNode.subscribe();
	}
	
	this.userManager = this.connectSession.userManager;
}

/**
 * @private
 */
SharedCursorPane.prototype.synchronizationChange = function(p_evt)
{
	if (this.collectionNode.isSynchronized) {
		this.collectionNode.addEventListener("myRoleChange", this);
		this.collectionNode.addEventListener("itemReceive", this);
		this.collectionNode.addEventListener("itemRetract", this);
		if (!this.collectionNode.isNodeDefined(this.nodeName) && this.collectionNode.canUserConfigure(this.userManager.myUserID)) {
			var nodeConfig = new Object();
			nodeConfig.userDependentItems = true;
			nodeConfig.modifyAnyItem = false;
			nodeConfig.itemStorageScheme = 2;
			nodeConfig.accessModel = 10;
			nodeConfig.publishModel = 50;
			this.collectionNode.addEventListener("nodeCreate", this);
			this.collectionNode.createNode(this.nodeName, nodeConfig);
		} else {
			if (!this.collectionNode.isNodeDefined(this.nodeName)) {
				this.collectionNode.addEventListener("nodeCreate", this);
			} else if (this.collectionNode.canUserPublish(this.userManager.myUserID, this.nodeName)) {
				this.wasPublisher = true;
				if (!document.body.onmousemove) {
					document.body.onmousemove = this.onMouseMove;
				}
			}
		}
		if (this.userMgr) {
			this.userMgr.addEventListener("userCreate",this);
		}
	} else {
		this.removeMyEventListeners();
	}
	this.dispatchEvent(p_evt);
}

/**
 * @private
 */
SharedCursorPane.prototype.myRoleChange = function(p_evt)
{
	// disable / enable 
	if (this.wasPublisher && !this.collectionNode.canUserPublish(this.userManager.myUserID, this.nodeName)) {
		this.removeMyEventListeners();
		this.wasPublisher = false;
	} else if (!this.wasPublisher && this.collectionNode.canUserPublish(this.userManager.myUserID, this.nodeName)) {
		this.pointTimer = setTimeout(bindUsingClosure(this.sendMyCursor,this), this.pollInterval);
		if(!document.body.onmousemove) {
			document.body.onmousemove = this.onMouseMove;
		}
		this.wasPublisher = true;
	}
}

/**
 * @private
 */
SharedCursorPane.prototype.itemReceive = function(p_evt)
{
	if (p_evt.nodeName== this.nodeName) {
		if (p_evt.item.publisherID!= this.userManager.myUserID) {
			// we ignore our own cursor
			var body = p_evt.item.body;
			var screenX;
			var screenY;
			
			var locWidth;
			var locHeight;
			//console.log(document.documentElement.clientWidth + " " + document.documentElement.clientHeight);
			
			if( typeof( window.innerWidth ) == 'number' ) {
			    //Non-IE
				locWidth = window.innerWidth;
				locHeight = window.innerHeight;
			} else if( document.documentElement && ( document.documentElement.clientWidth || document.documentElement.clientHeight ) ) {
			    //IE 6+ in 'standards compliant mode'
				  locWidth = document.documentElement.clientWidth;
				  locHeight = document.documentElement.clientHeight;
			} else if( document.body && ( document.body.clientWidth || document.body.clientHeight ) ) {
			    //IE 4 compatible
				  locWidth = document.body.clientWidth;
				  locHeight = document.body.clientHeight;
			}
			
			if ( this.sizingMode == "relative") {
				screenX = body.x*(locWidth);
				screenY = body.y*(locHeight);
			}else if ( this.sizingMode == "absolute" ) {
				screenX = body.x;
				screenY = body.y;
			}
			//			this.document.body.ownerDocument.getElementById("msgArea").value = " " + screenX + " " + screenY;
			//console.log("set w innerwidth " + body.x*(locWidth));
			//console.log("set w docEle.clientwidth " + body.x*(document.documentElement.clientWidth));
			//console.log("set w body.clientwidht " + body.x*(document.body.clientWidth));
			if (this.cursorsByID && this.cursorsByID[p_evt.item.publisherID]!=null) {
				//var tmp = document;
				//console.log("Recieved " +  body.x + " " + body.y +" setting " + screenX + " " +  screenY + " w&h " + locWidth + " " + locHeight);
				this.moveCursorTo(p_evt.item.publisherID, screenX, screenY);
			} else {
				this.addNewCursor(p_evt.item.publisherID, screenX, screenY);
			}
		} else {
			this.cursorsByID[p_evt.item.publisherID] = true;
		}
	}	
}

/**
 * @private
 */
SharedCursorPane.prototype.itemRetract = function(p_evt)
{
	if (p_evt.nodeName==this.nodeName) {
		this.removeCursor(p_evt.item.publisherID);
	}
}

/**
 * @private
 */
SharedCursorPane.prototype.sendMyCursor = function()
{
	this.sendCursorWrapper();
}

/**
 * @private
 */
SharedCursorPane.prototype.sendCursorWrapper = function()
{
	if (this && this.mouseX==this.lastMouseX && this.mouseY==this.lastMouseY) {
		this.inactivityTimer = setTimeout(bindUsingClosure(this.onInactivity,this), this.inactivityInterval);
		if(!document.body.onmousemove) {
			document.body.onmousemove = this.onMouseMove;
		}
		clearTimeout(this.pointTimer);
		this.pointTimer = null;
		
	} else {
		var item = new Object() ;
		if ( this.sizingMode == "relative" ) {
			var locWidth;
			var locHeight;
			//console.log(document.documentElement.clientWidth + " " + document.documentElement.clientHeight);
			
			if( typeof( window.innerWidth ) == 'number' ) {
			    //Non-IE
				locWidth = window.innerWidth;
				locHeight = window.innerHeight;
			  } else if( document.documentElement && ( document.documentElement.clientWidth || document.documentElement.clientHeight ) ) {
			    //IE 6+ in 'standards compliant mode'
				  locWidth = document.documentElement.clientWidth;
				  locHeight = document.documentElement.clientHeight;
			  } else if( document.body && ( document.body.clientWidth || document.body.clientHeight ) ) {
			    //IE 4 compatible
				  locWidth = document.body.clientWidth;
				  locHeight = document.body.clientHeight;
			  }

			
			var relativeX = this.mouseX/locWidth;
			var relativeY = this.mouseY/locHeight;
			item.nodeName = this.nodeName;
			var bodyObject = new Object();
			bodyObject.x = relativeX;
			bodyObject.y = relativeY;
			item.body = bodyObject;
			item.itemID = this.userManager.myUserID;
			var tmp = document;
			//console.log("Sending x & y as " + relativeX +" " +relativeY +" and the actual x & y " +this.mouseX + " " + this.mouseY + " w&h " + locWidth + " " + locHeight);
		} else if ( this.sizingMode == "absolute" ) {
			item.nodeName = this.nodeName;
			var bodyObject = new Object();
			bodyObject.x = this.mouseX;
			bodyObject.y = this.mouseY;
			item.body = bodyObject;
			item.itemID = this.userManager.myUserID;
			//console.log("Sending x & y as " +this.mouseX + " " + this.mouseY + " w&h " + locWidth + " " + locHeight);

		}
		
		if (this.collectionNode.isSynchronized) {
			// safety check.
			this.hasRetracted = false;
			this.collectionNode.publishItem(item);
		}
		
		this.lastMouseX = this.mouseX;	
		this.lastMouseY = this.mouseY;
		clearTimeout(this.pointTimer);
		this.pointTimer = null;
		this.pointTimer = setTimeout( bindUsingClosure(this.sendMyCursor,this), this.pollInterval);
	}
	
}

/**
 * @private
 */
SharedCursorPane.prototype.nodeCreate = function(p_evt)
{
	if (p_evt.nodeName && this.collectionNode.canUserPublish(this.userManager.myUserID, this.nodeName)) {
		this.wasPublisher = true;
		if(!document.body.onmousemove) {
			document.body.onmousemove = this.onMouseMove;
		}
	}
}

/**
 * @private
 */
SharedCursorPane.prototype.removeMyEventListeners = function()
{
	clearTimeout(this.pointTimer);
	this.pointTimer = null;
	document.body.onmousemove = null;
	this.userMgr.removeEventListener("userCreate",this);
}

/**
 * @private
 */
SharedCursorPane.prototype.moveCursorTo = function(p_userID, p_x, p_y)
{
	if (this.containsPoint(p_x,p_y)) {
		var divElement = document.getElementById(p_userID);
		divElement.style.position = "absolute";
		var tweenX = new Tween(divElement, parseFloat(divElement.style.left) , p_x, 400);
		var tweenY = new Tween(divElement, parseFloat(divElement.style.top) , p_y, 400);
		tweenX.onTweenUpdate = this.onTweenUpdateX;
		tweenY.onTweenUpdate = this.onTweenUpdateY;
		//console.log("x " + divElement.style.left+" y " + divElement.style.top);
		
		if (p_x >= 0 && p_x <= document.body.clientWidth && p_y >= 0 && p_y <= document.body.clientHeight) {
			this.setOpacity(divElement,1.0);
		} else {
			this.setOpacity(divElement,0.1);
		}
	}
}

/**
 * @private
 */
SharedCursorPane.prototype.containsPoint = function(p_x,p_y)
{
	if(p_x >= this.x && p_x <= (this.x + document.body.clientWidth) && p_y >= this.y && p_y <= (this.y + document.body.clientHeight)) {
		return true;
	} else {
		return false;
	}
}

/**
 * @private
 */
SharedCursorPane.prototype.setOpacity = function(p_divElement, p_opacity)
{
	var opacity = p_opacity;
	p_divElement.style.opacity = p_opacity;
	p_divElement.style.filter = 'alpha(opacity = ' + (p_opacity * 100) + ')';
}


/**
 * @private
 */
SharedCursorPane.prototype.onTweenUpdateX = function(curVal)
{
	var divElement = this.listener;
	divElement.style.left = parseInt(curVal)+"px";
}

/**
 * @private
 */
SharedCursorPane.prototype.onTweenUpdateY = function(curVal)
{
	var divElement = this.listener;
	divElement.style.top = parseInt(curVal)+"px";
}

/**
 * @private
 */
SharedCursorPane.prototype.addNewCursor = function(p_userID,  p_x, p_y)
{
	var divElement = document.createElement('div');
	var htmlString = "<p><img src="+ this.cursorImgSrc +" width='8' height='14' align='middle' style='padding-top: 0px; padding-right: 0px; padding-bottom: 0px; padding-left: 0px; border-top-width: 0px; border-right-width: 0px; border-bottom-width: 0px; border-left-width: 0px; border-style: initial; border-color: initial; margin-top: 0px; margin-right: 0px; margin-bottom: 0px; margin-left: 0px; position: absolute; left: 0px; top: 0px;'/>";
	divElement.innerHTML= htmlString + this.userManager.getUserDescriptor(p_userID).displayName + "</p>";
	divElement.id = p_userID;
	//set some style
	divElement.style.position = "absolute";
	divElement.style.padding = "0px";
	divElement.style.border = "0px";
	divElement.style.margin = "0px";
	divElement.style.left = p_x+"px";
	divElement.style.top = p_y+"px";
	if (this.cursorClass) {
		divElement.className = this.cursorClass;
	}
	
	if (!this.cursorsByID) {
		this.cursorsByID =  new Object();
	}
	this.cursorsByID[p_userID] = divElement;
	document.body.appendChild(divElement);
	
}

/**
 * @private
 */
SharedCursorPane.prototype.userCreate = function()
{
	
}

/**
 * @private
 */
SharedCursorPane.prototype.removeCursor = function(p_userID)
{
	if (this.cursorsByID[p_userID]) {
		var divElement = document.getElementById(p_userID);
		if (divElement	) {
			document.body.removeChild(divElement);
		}
		delete this.cursorsByID[p_userID];
	}
}

/**
 * @function
 */
SharedCursorPane.prototype.removeMyCursor = function()
{
	if (this.collectionNode.isSynchronized && !this.hasRetracted) {
		this.hasRetracted = true;
		this.collectionNode.retractItem(this.nodeName, this.userManager.myUserID);
	}
	//Remove mouse listener
	if(!document.body.onmousemove) {
		document.body.onmousemove = this.onMouseMove;
	}
	
	if(this.pointTimer) {
		clearTimeout(this.pointTimer);
		this.pointTimer = null;
	}
}

/**
 * @private
 */
SharedCursorPane.prototype.onMouseMove = function(p_evt)
{
	//reset the timer
	clearTimeout ( this.cursorTarget.inactivityTimer );
	if(p_evt == undefined) {
		//this.cursorTarget.mouseX = window.event.clientX + this.scrollLeft - this.clientLeft;
		//this.cursorTarget.mouseY = window.event.clientY + this.scrollTop - this.clientTop;
		var doc = document.documentElement;
		var body = document.body;
		this.cursorTarget.mouseX = window.event.clientX + (doc && doc.scrollLeft || body && body.scrollLeft || 0) - (doc && doc.clientLeft || body && body.clientLeft || 0);
		this.cursorTarget.mouseY = window.event.clientY + (doc && doc.scrollTop  || body && body.scrollTop  || 0) - (doc && doc.clientTop  || body && body.clientTop  || 0);
	} else {
		this.cursorTarget.mouseX = p_evt.pageX;
		this.cursorTarget.mouseY = p_evt.pageY;
	}
	
	if (!this.cursorTarget.pointTimer) {
		this.cursorTarget.sendMyCursor();
	}
}

/**
 * @private
 */
SharedCursorPane.prototype.onInactivity = function()
{
	this.removeMyCursor();
	this.lastMouseX = this.lastMouseY = -1;
}

/**
 * Closes any event listeners and network operations. Using this function 
 * is recommended for garbage collection.
 * @function
 */
SharedCursorPane.prototype.close = function()
{
	this.removeMyEventListeners();
}



/**
 * @private
 * @ignore
 * @class Helper - Internal method to manage tweens
 * @constructor
 */
function Tweener()
{
	
}

/**
 * @private
 * @ignore
 */
Tweener.prototype.ActiveTweens = new Object();
/**
 * @private
 */
Tweener.prototype.Interval = 10;
/**
 * @private
 * @ignore
 */
Tweener.prototype.IntervalToken;
/**
 * @private
 * @ignore
 */
Tweener.prototype.TweenCount = 0;

/**
 * @private
 * @ignore
 */
Tweener.prototype.AddTween = function(tween)
{
	this.ActiveTweens[tween.ID] = tween;
	if (this.IntervalToken==undefined) {
		//this.Dispatcher.DispatchTweens = this.DispatchTweens;
		this.IntervalToken = setInterval(bindUsingClosure(this.DispatchTweens,this) , this.Interval);
	}
}

/**
 * @private
 * @ignore
 */
Tweener.prototype.RemoveTween = function(tween)
{
	delete this.ActiveTweens[tween.ID];
	var tweensLeft = false;
	
	for (var i in this.ActiveTweens) {
		tweensLeft = true;
		break;
	}
	
	
	if (!tweensLeft) {
		clearInterval(this.IntervalToken);
		delete this.IntervalToken;
	}
}

/**
 * @private
 * @ignore
 */
Tweener.prototype.DispatchTweens = function()
{
	var aT = this.ActiveTweens;
	for (var i in aT) {
		aT[i].doInterval();
	}
}

/**
 * @private
 * @ignore
 */
Tweener.initialize = function(object) {
	object.tweener = _tweener;
}
/**
 * @private
 * @ignore
 */
var _tweener = new Tweener();

/**
 * @class The Tween class defines a tween, a property animation performed
 *  on a target object over a period of time.
 *  
 *  When the constructor is called, the animation automatically starts playing.
 *
 *  @param listener Object that is notified at each interval of the animation. You typically pass the <code>this</code> 
 *  keyword as the value.  The <code>listenerObj</code> must define the <code>onTweenUpdate()</code> method and optionally the  
 *  <code>onTweenEnd()</code> method. The former method is invoked for each interval of the animation,  and the latter is invoked just after the animation finishes.
 *  @param init Initial value(s) of the animation. Either a number or an array of numbers. If a number is passed, the Tween interpolates
 *  between this number and the number passed in the <code>endValue</code> parameter. If an array of numbers is passed, 
 *  each number in the array is interpolated.
 *  @param end Final value(s) of the animation. The type of this argument must match the <code>startValue</code>  parameter.
 *  @param dur Duration of the animation, expressed in milliseconds.
 *  @constructor
 */  
function Tween(listenerObj, init, end, dur)
{
	if ( listenerObj==undefined ){
		return;
	}
	
	this.arrayMode = false;
	
	this.listener = listenerObj;
	this.initVal = init;
	this.endVal = end;
	
	Tweener.initialize(this);
	
	if (dur!=undefined) {
		this.duration = dur;
	}
	this.ID = this.tweener.TweenCount++;
	this.startTime = new Date().getTime();
	
	if (this.Interval) {
		this.tweener.Interval = this.Interval;
	}
	
	if (this.IntervalToken) {
		this.tweener.IntervalToken = this.IntervalToken;
	}
	
	if (this.TweenCount) {
		this.tweener.TweenCount = this.TweenCount;
	}
	
	if ( this.duration==0 ) {
		this.doInterval()
	} else {
		this.tweener.AddTween(this);
	}
}

//EventDispatcher.initialize(Tween.prototype);

/**
 * Object that is notified at each interval of the animation.
 * @field
 */ 
Tween.prototype.listener = undefined;
/**
 * @private
 */
Tween.prototype.tweener = undefined;
/**
 * Duration of the animation, in millisecond's.
 *  @field
 */  
Tween.prototype.duration = 3000;

/**
 *  Initial value(s) of the animation. Either a number or an array of numbers. If a number is passed, the Tween interpolates
 *  between this number and the number passed in the <code>endValue</code> parameter. If an array of numbers is passed, 
 *  each number in the array is interpolated.
 *  @field
 */ 
Tween.prototype.initVal = undefined; // relaxed type to accommodate numbers or arrays
/**
 *  Final value of the animation.The type of this argument must match the startValue parameter.
 *  @field
 */  
Tween.prototype.endVal = undefined;
/**
 *  @private
 */
Tween.prototype.arrayMode;
/**
 *  @private
 */
Tween.prototype.startTime;
/**
 *  @private
 */
Tween.prototype.updateFunc;
/**
 *  @private
 */
Tween.prototype.endFunc;
/**
 *  @private
 */
Tween.prototype.ID;

/**
 * @private
 */
Tween.prototype.doInterval = function()
{
	var curTime = new Date().getTime() -this.startTime;
	var curVal= this.getCurVal(curTime);
	
	if (curTime >= this.duration) {
		this.endTween();
	} else {
		if (this.updateFunc!=undefined) {
			this.listener[updateFunc](curVal);
		} else {
			this.onTweenUpdate(curVal);
		}
	}
}


/**
 * @private
 */
Tween.prototype.getCurVal = function(curTime)
{
	if (this.arrayMode) {
		var returnArray = new Array();
		for (var i=0; i<initVal.length; i++) {
			returnArray[i] = this.easingEquation(curTime, this.initVal[i], this.endVal[i]-this.initVal[i], this.duration);
		}
		return returnArray;
	}
	else {
		return this.easingEquation(curTime, this.initVal, this.endVal-this.initVal, this.duration);
	}
}

/**
 *  Interrupt the tween, jump immediately to the end of the tween, 
 *  and invoke the <code>onTweenEnd()</code> callback function.
 *  @function
 */  
Tween.prototype.endTween = function()
{
	if (this.endFunc!=undefined) {
		this.listener[endFunc](endVal);
	} else {
		//this.listener.onTweenEnd(endVal);
	}
	this.tweener.RemoveTween(this);
}

/**
 *  Stops the tween, ending it without dispatching an event or calling
 *  the Tween's endFunction or <code>onTweenEnd()</code>.
 *  @function
 */  
Tween.prototype.stopTween = function()
{
	this.tweener.RemoveTween(this);
}

/**
 * @private
 */
Tween.prototype.setTweenHandlers = function(update, end)
{
	this.updateFunc = update;
	this.endFunc = end;
}

/**
 * @private
 */
Tween.prototype.easingEquation = function (t,b,c,d)
{
	return c/2 * ( Math.sin( Math.PI * (t/d-0.5) ) + 1 ) + b;
}