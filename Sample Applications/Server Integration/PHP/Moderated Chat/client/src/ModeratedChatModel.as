package
{
	import com.adobe.coreUI.util.StringUtils;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.sharedManagers.descriptors.UserDescriptor;
	import com.adobe.rtc.sharedModel.SimpleChatModel;
	import com.adobe.rtc.sharedModel.descriptors.ChatMessageDescriptor;


	public class ModeratedChatModel extends SimpleChatModel
	{
		protected const OUTGOING_MESSAGE_NODE_EVERYONE:String = "outgoing_message_everyone";
		protected const OUTGOING_MESSAGE_NODE_PARTICIPANTS:String = "outgoing_message_participants";
		protected const OUTGOING_MESSAGE_NODE_HOSTS:String = "outgoing_message_hosts";
		
		
		public function ModeratedChatModel(p_isClearAfterSessionRemoved:Boolean=false)
		{
			super();
			this.sharedID = "default_moderatedChat";
		}

		/**
		 * @private
		 */
		override protected function onSynchronizationChange(p_event:CollectionNodeEvent):void
		{
			_myName = (_userManager.getUserDescriptor(_userManager.myUserID) as UserDescriptor).displayName;
			if (_collectionNode.isSynchronized) {
				
				
				//if the node doesn't exist and I'm a host, create it empty so that viewers can publish to it
				if (!_collectionNode.isNodeDefined(HISTORY_NODE_EVERYONE) && _collectionNode.canUserConfigure(_userManager.myUserID)) {
					/*everyone in their respective level can read but only owner can publish*/
					_collectionNode.createNode(HISTORY_NODE_EVERYONE, new NodeConfiguration(UserRoles.VIEWER, UserRoles.OWNER, true, false, false, _isClearAfterSessionRemoved, NodeConfiguration.STORAGE_SCHEME_QUEUE, true));
					_collectionNode.createNode(HISTORY_NODE_PARTICIPANTS, new NodeConfiguration(UserRoles.PUBLISHER, UserRoles.OWNER, true, false, false, _isClearAfterSessionRemoved, NodeConfiguration.STORAGE_SCHEME_QUEUE));
					_collectionNode.createNode(HISTORY_NODE_HOSTS, new NodeConfiguration(UserRoles.OWNER, UserRoles.OWNER, true, false, false, _isClearAfterSessionRemoved, NodeConfiguration.STORAGE_SCHEME_QUEUE));
					
					_collectionNode.createNode(TYPING_NODE_NAME, new NodeConfiguration(UserRoles.VIEWER, UserRoles.VIEWER, true, false, true, _isClearAfterSessionRemoved, NodeConfiguration.STORAGE_SCHEME_MANUAL));
					
					/*everyone can publish but only owner can read*/
					_collectionNode.createNode(OUTGOING_MESSAGE_NODE_EVERYONE, new NodeConfiguration(UserRoles.OWNER, UserRoles.VIEWER, true, false, true, _isClearAfterSessionRemoved, NodeConfiguration.STORAGE_SCHEME_QUEUE, true));
					_collectionNode.createNode(OUTGOING_MESSAGE_NODE_PARTICIPANTS, new NodeConfiguration(UserRoles.OWNER, UserRoles.VIEWER, true, false, false, _isClearAfterSessionRemoved, NodeConfiguration.STORAGE_SCHEME_QUEUE));
					_collectionNode.createNode(OUTGOING_MESSAGE_NODE_HOSTS, new NodeConfiguration(UserRoles.OWNER, UserRoles.VIEWER, true, false, false, _isClearAfterSessionRemoved, NodeConfiguration.STORAGE_SCHEME_QUEUE));
					

					//create by publishing the default
					_collectionNode.publishItem(new MessageItem(TIMEFORMAT_NODE_NAME, TIMEFORMAT_AM_PM));
					//create by publishing the default
					_collectionNode.publishItem(new MessageItem(USE_TIMESTAMPS_NODE_NAME, true));
					_userManager = _connectSession.userManager;
				}
			}
			
			dispatchEvent(p_event);
		}
		
				/**
		 * Sends a message which is specified by the ChatMessageDescriptor.
		 * 
		 * @param p_msgDesc the message to send
		 */
		override public function sendMessage(p_msgDesc:ChatMessageDescriptor):void
		{
			//do this before the returns
			if (_typingTimer.running) {
				_typingTimer.stop();
				onTimerComplete();
			}

			if (!_collectionNode.isSynchronized) {
				return;
			}

			if (StringUtils.isEmpty(p_msgDesc.msg)) {
				return;	//we don't send empty messages
			}
			
			if (p_msgDesc.recipient is String && !_allowPrivateChat) {
				//private messages are not allowed, return
				return;
			}

			p_msgDesc.displayName = _userManager.getUserDescriptor(_userManager.myUserID).displayName;
			
			var nodeName:String;
			if (p_msgDesc.role==UserRoles.VIEWER) {
				nodeName = OUTGOING_MESSAGE_NODE_EVERYONE;
			} else if (p_msgDesc.role==UserRoles.PUBLISHER) {
				nodeName = OUTGOING_MESSAGE_NODE_PARTICIPANTS;
			} else {
				nodeName = OUTGOING_MESSAGE_NODE_HOSTS;
			}
			var msg:MessageItem = new MessageItem(nodeName, p_msgDesc.createValueObject());
			if (p_msgDesc.recipient!=null) {
				msg.recipientID = p_msgDesc.recipient;
			}
			if (p_msgDesc.role>_collectionNode.getUserRole(_userManager.myUserID, nodeName)) {
				// we're sending to people better than us. We won't receive notification, so mirror this locally.
				p_msgDesc.timeStamp = (new Date()).getTime();
				addMsgToHistory(p_msgDesc);
			}
			_collectionNode.publishItem(msg);

		}
		
	

	}
}
