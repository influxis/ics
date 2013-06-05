package
{
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedModel.CollectionNode;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;

	/**
	 * Dispatched when the PollModel has fully connected and synchronized with the service or when it loses that connection.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	
	/**
	 * Dispatched when the current user's role changes with respect to this component.
	 */
	[Event(name="myRoleChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	
	/**
	 * Dispatched when the NoteModel has fully connected and synchronized with the service or when it loses that connection.
	 */
	[Event(name="questionChange", type="flash.events.Event")]	

	/**
	 * SimpleSharedPollModel is meant as a simple example of using a CollectionNode to build a Shared Model.
	 * 
	 * The poll model is intentionally simple: the poll will have a yes or no question, settable only by the OWNER,
	 * and each user with role of UserRoles.VIEWER may submit an answer, but not see the answers of others.
	 * The OWNER will see all answers. 
	 *
	 * The model extends ISessionSubscriber which provides the best way to assign, close, and 
	 * subscribe to connect sessions. Implementing ISessionSubscriber is not mandatory for a shared model; however, 
	 * it is a best practice for having multiple connect sessions, proper cleaning
	 * of listeners, synchronization change events and subscribing at the appropriate place, and so on.
	 */
	 
	 /**********************************************************
	  * ADOBE SYSTEMS INCORPORATED
	  * Copyright [2007-2010] Adobe Systems Incorporated
	  * All Rights Reserved.
	  * NOTICE: Adobe permits you to use, modify, and distribute this file in accordance with the 
	  * terms of the Adobe license agreement accompanying it.If you have received this file from a 
	  * source other than Adobe, then your use, modification, or distribution of it requires the prior 
	  * written permission of Adobe.
	  * *********************************/
	 
	public class SimpleSharedPollModel extends EventDispatcher implements ISessionSubscriber
	{
		/**
		 * The OWNER will keep an list of all the userIDs of users who answered yes.
		 */
		protected var _yesAnswers:ArrayCollection = new ArrayCollection();
		/**
		 * The OWNER will keep an list of all the userIDs of users who answered no.
		 */
		protected var _noAnswers:ArrayCollection = new ArrayCollection();
		/**
		 * The question to ask.
		 */
		protected var _question:String="";
		
		/**
		 * The collectionNode to use.
		 */
		protected var _collectionNode:CollectionNode;
		
		/**
		 * Keep a reference to the userManager handy.
		 */
		protected var _userManager:UserManager;
		
		/**
		 * @private
		 */
		protected var _sharedID:String = "_SimplePollModel";
		
		/**
		 * @private 
		 */		
		protected var _connectSession:IConnectSession = ConnectSession.primarySession;
		
		/**
		 * The shared model will use three nodes. One for the question, one for all the answers, and one for the tally.
		 */
		protected const NODENAME_QUESTION:String = "question";
		protected const NODENAME_ANSWERS:String = "answers";
		protected const NODENAME_TALLY:String = "tally";
				
		/**
		 * Constructors no longer create the collection nodes themselves.
		 */
		function SimpleSharedPollModel()
		{
			
		}
		/**
		*  This ISessionSubscriber method is implemented for subscribing to the collectionNode.
		* Create the collection node here and subscribe to it.
		* 
		*/
		public function subscribe():void
		{
			_userManager = connectSession.userManager;
			if ( _collectionNode == null ) {
				// assume that the room is already in sync once this is instantiated. Build our connection to the service now
				// note we name the collection after our id
				_collectionNode = new CollectionNode();
				_collectionNode.connectSession = connectSession ;
				// this is the shared ID also the collection Name, we have removed the setting of ID's from the constructor
				_collectionNode.sharedID = sharedID ;
				_collectionNode.subscribe();
				// begin listening for the collectionNode to synchronize, and listen for any messages we might get as we do so
				_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
				_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
				// store a local reference to the userManager
			}
		}

		/**
		 * The <code>sharedID</code> is the ID of the class.
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
		 * Assign a connect session to a model once in the beginning; 
		 * if you do not assign anything, it takes the default primary session.
		 * 
		 */
		public function get connectSession():IConnectSession
		{
			return _connectSession;
		}
		
		/**
		 * @private
		 */
		public function set connectSession(p_session:IConnectSession):void
		{
			_connectSession = p_session;
		}
		
		/**
		 * Close method should remove all the event listeners of collection nodes and unsubscribe.
		 */
		public function close():void
		{
			if ( _collectionNode ) {
				_collectionNode.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
				_collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
				_collectionNode.removeEventListener(CollectionNodeEvent.MY_ROLE_CHANGE, onMyRoleChange);
				_collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
				_collectionNode.unsubscribe();
				_collectionNode = null;
			}
		}
		
		
		[Bindable(event="synchronizationChange")]
		/**
		 * Determines whether the collection node is synchronized.
		 */
		public function get isSynchronized():Boolean
		{
			return _collectionNode.isSynchronized;
		}



		[Bindable(event="questionChange")]
		/**
		 * Specifies the question being asked.
		 */
		public function get question():String
		{
			return _question;
		}
		
		public function set question(p_question:String):void
		{
			if (!canISetQuestion) {
				trace("I don't have permission to set the question for this poll");
				return;
			}
			// Send the question on the appropriate node.
			var questionMessage:MessageItem = new MessageItem(NODENAME_QUESTION, p_question);
			_collectionNode.publishItem(questionMessage);
			// Note: the question doesn't really change until onItemReceive.
		}
		
		[Bindable(event="answersChange")]
		public function get yesAnswers():ArrayCollection
		{
			return _yesAnswers;
		}
		
		[Bindable(event="answersChange")]
		public function get noAnswers():ArrayCollection
		{
			return _noAnswers;
		}
		
		[Bindable(event="myRoleChange")]
		public function get canISetQuestion():Boolean
		{
			// CollectionNode makes this easy
			return _collectionNode.canUserPublish(_userManager.myUserID, NODENAME_QUESTION);
		}
		
		public function submitAnswer(p_yesOrNo:Boolean):void
		{
			// Send the answer via the NODENAME_ANSWERS. Note how we're using myUserID as the itemID here, 
			// so that if I change my mind, it replaces the Message already stored under myUserID.
			var answerMessage:MessageItem = new MessageItem(NODENAME_ANSWERS, p_yesOrNo, _userManager.myUserID);
			_collectionNode.publishItem(answerMessage);
		}
		
		protected function onSyncChange(p_evt:CollectionNodeEvent):void
		{
			// There are 2 cases here : 
			//  case 1: I'm a viewer, everything's set up, nothing to do.
			//  case 2: I'm an OWNER, and this is the first time the Model has been run. It hasn't got nodes yet!
			if (_collectionNode.isEmpty && _collectionNode.canUserConfigure(_userManager.myUserID)) {
				// I'm an OWNER, and the CollectionNode needs to be set up. We wait until the CollectionNode 
				// is synchronized, because we know that we've fetched all the nodes it has by now, and it's still empty
				// So, let's set it up!
				var questionNodeConfig:NodeConfiguration = new NodeConfiguration();
				// we only want OWNERs to be able to modify this; all the other default values for the config will work.
				questionNodeConfig.publishModel = UserRoles.OWNER;
				_collectionNode.createNode(NODENAME_QUESTION, questionNodeConfig);
				// the answers node config is definitely different.
				var answersNodeConfig:NodeConfiguration = new NodeConfiguration();
				// first of all, if someone leaves the room, retract their vote
				answersNodeConfig.userDependentItems = true;
				// second of all, we're going to store multiple items. Let's just use the user's ID as the itemID
				// (if you're having a hard time following this, try reading the "LCCS Messaging and Permissions" doc)
				answersNodeConfig.itemStorageScheme = NodeConfiguration.STORAGE_SCHEME_MANUAL;
				// we don't want users to be able to mess with each other's answers!
				answersNodeConfig.modifyAnyItem = false;
				// here's where it really gets nutty. VIEWERS can *publish*, but not *access* The results
				answersNodeConfig.publishModel = UserRoles.VIEWER;
				answersNodeConfig.accessModel = UserRoles.OWNER;
				_collectionNode.createNode(NODENAME_ANSWERS, answersNodeConfig);
				
				// All the needed nodes are now created. This code only runs once for the OWNER on the first time.
				// The nodes are stored on the service until they are explicitly removed.
			}
//			_collectionNode.removeNode(NODENAME_ANSWERS);
//			_collectionNode.removeNode(NODENAME_QUESTION);
//			_collectionNode.removeNode(NODENAME_TALLY);
			// Listen to role changes in case I'm suddenly promoted or demoted.
			_collectionNode.addEventListener(CollectionNodeEvent.MY_ROLE_CHANGE, onMyRoleChange);
			
			// Listen to people's votes being retracted as the leave the room (since userDependentItems is true).
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			dispatchEvent(p_evt);
			
			// Because canISetQuestion is false during synchronization, once sync is finished, 
			// fire a role change to confirm any binding that might depend on it.
			dispatchEvent(new CollectionNodeEvent(CollectionNodeEvent.MY_ROLE_CHANGE));
		}
		
		/**
		 * Response to CollectionNodeEvent.ITEM_RECEIVE.
		 */
		protected function onItemReceive(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName==NODENAME_QUESTION) {
				// Receiving the question, retrieve it from the message.
				_question = p_evt.item.body;
				// Allow binding to work.
				dispatchEvent(new Event("questionChange"));
			}
			else if (p_evt.nodeName==NODENAME_ANSWERS) {
				// Receiving the answers (we must be an OWNER)
				var publisherID:String = p_evt.item.publisherID;
				var i:int;
				if (p_evt.item.body==false) {
					// If the user's answer was in the yes list, clear it.
					for (i=0; i<_yesAnswers.length; i++) {						
						if (_yesAnswers.getItemAt(i)==publisherID) {
							_yesAnswers.removeItemAt(i);
							break;
						}
					}
					// If it's a "no" answer, add this user to the no list.
					_noAnswers.addItem(publisherID);
				} else {
					// If the user's answer was in the no list, clear it.
					for (i=0; i<_noAnswers.length; i++) {						
						if (_noAnswers.getItemAt(i)==publisherID) {
							_noAnswers.removeItemAt(i);
							break;
						}
					}
					// If it's a "yes" answer, add this user to the yes list.
					_yesAnswers.addItem(publisherID);
				}
				dispatchEvent(new Event("answersChange"));
			}
		}

		/**
		 * Response to CollectionNodeEvent.MY_ROLE_CHANGE.
		 */
		protected function onMyRoleChange(p_evt:CollectionNodeEvent):void
		{
			// just bubble it up for the sake of binding "canISetQuestion"
			dispatchEvent(p_evt);
		}
		
		/**
		 * Response to CollectionNodeEvent.ITEM_RETRACT.
		 */
		protected function onItemRetract(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName==NODENAME_ANSWERS) {
				// Someone has retracted their vote because they left the room (since we used userDependentItems),
				// so go through the answer list and clear it. Since the retracted MessageItem is returned to us, 
				// we can figure out which list to look in.
				var publisherID:String = p_evt.item.publisherID;
				var listToCheck:ArrayCollection = (p_evt.item.body==false) ? _noAnswers : _yesAnswers;
				for (var i:int=0; i<listToCheck.length; i++) {
					if (listToCheck.getItemAt(i)==publisherID) {
						listToCheck.removeItemAt(i);
						return;
					}
				}
			}
		}
	}
}