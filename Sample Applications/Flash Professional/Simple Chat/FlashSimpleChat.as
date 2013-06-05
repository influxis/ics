package
{
	import com.adobe.rtc.authentication.AdobeHSAuthenticator;
	import com.adobe.rtc.collaboration.AudioPublisher;
	import com.adobe.rtc.collaboration.AudioSubscriber;
	import com.adobe.rtc.collaboration.WebcamPublisher;
	import com.adobe.rtc.collaboration.WebcamSubscriber;
	import com.adobe.rtc.events.ChatEvent;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.SessionEvent;
	import com.adobe.rtc.events.SharedPropertyEvent;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.sharedModel.SharedProperty;
	import com.adobe.rtc.sharedModel.SimpleChatModel;
	import com.adobe.rtc.sharedModel.descriptors.ChatMessageDescriptor;
	
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.Keyboard;
	
	/**
	 * A Basic example that illustrates how LCCS Flash Only SWC is used. The app illustrates how SimpleChatModel
	 * is used. The UI is pretty basic to keep the code simple (For example there is no scroll bar in chat) and strictly avoided
	 * using fancy libraries. All the action happens here. Other classes are just UI stuff. I have purposefully restricted the 
	 * LCCS components just to this class.
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
	  
	public class FlashSimpleChat extends Sprite
	{
		protected var _cSession:ConnectSession =  new ConnectSession();
		protected var _flashChat:FlashChatUI;
		protected var _chatModel:SimpleChatModel;

		// The constructor logs us in to the room specified. and the all the UI is built after we are connected to the room
		
		public function FlashSimpleChat()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			setBackGround();
			//Login in to your room.  Please login as room owner the first time you run this app , so that all the nodes are created
			var authenticator:AdobeHSAuthenticator = new AdobeHSAuthenticator();
			authenticator.userName="Your Username";
			authenticator.password = "Your password";
			_cSession.roomURL="Your RoomUrl";
			_cSession.authenticator = authenticator;
			_cSession.login();
			_cSession.addEventListener(SessionEvent.SYNCHRONIZATION_CHANGE, onLogin);
			stage.addEventListener(Event.RESIZE,setBackGround);
		}
		
		
		protected function onLogin(p_evt:SessionEvent):void
		{
			
			// Add the chat UI and link the SimpleChatModel to the UI
			addChatUI();
			_chatModel = new SimpleChatModel();
			//Use the sharedId if you are planning to use the same room for various apps. Besides I believe it's a good practice to
			//explicitly assign a sharedId.
			_chatModel.sharedID = "2_SimpleChat";
			_chatModel.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE,linkChatModel);
			_chatModel.subscribe();
			
		}
		
		//Adding the Chat UI.
		protected function addChatUI():void
		{
			_flashChat = new FlashChatUI(stage.stageWidth/2,stage.stageHeight/2);
			_flashChat.x = stage.stageWidth/2 - _flashChat.width/2;
			_flashChat.sendButton.addEventListener(MouseEvent.CLICK,sendChatMsg);
			_flashChat.clearButton.addEventListener(MouseEvent.CLICK,clearChatMsg);
			addChild(_flashChat);
		}
		
		protected function setBackGround(p_evt:Event=null):void
		{
			stage.stageHeight = (stage.stageHeight < 600) ? 600 : stage.stageHeight;
			stage.stageWidth = (stage.stageWidth < 600) ? 600 : stage.stageWidth;
			graphics.clear();
			graphics.beginFill(0x3b3b3b); 
			graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			graphics.endFill();
		}
		
		//Setting history to the textfield
		protected function linkChatModel(p_evt:CollectionNodeEvent):void
		{
			if (_chatModel.isSynchronized) {
				if (_cSession.userManager.myUserRole < UserRoles.OWNER) {
					if (_flashChat.contains(_flashChat.clearButton)) {
						_flashChat.removeChild(_flashChat.clearButton);
					}
				}
				_chatModel.addEventListener(ChatEvent.HISTORY_CHANGE, onChatHistChange);
				_flashChat.histTextArea.htmlText = _chatModel.history;
				_flashChat.inputTextArea.addEventListener(KeyboardEvent.KEY_DOWN,onEnter);
				if (_flashChat.histTextArea.textHeight > _flashChat.histTextArea.height) {
					_flashChat.histTextArea.scrollV = _flashChat.histTextArea.scrollV + (_flashChat.histTextArea.textHeight - _flashChat.histTextArea.height);
				}
			}
		}
		
		//Setting history to the textfield whenever a user types in a message. The optimized method is to append the message received.
		// But I chose the easier approach.
		protected function onChatHistChange(p_evt:ChatEvent):void
		{
			if (p_evt.message) {
				_flashChat.histTextArea.htmlText = "";
				_flashChat.histTextArea.htmlText = _chatModel.history;
				if (_flashChat.histTextArea.textHeight > _flashChat.histTextArea.height) {
					_flashChat.histTextArea.scrollV = _flashChat.histTextArea.scrollV + (_flashChat.histTextArea.textHeight - _flashChat.histTextArea.height);
				}
			}
		}
		
		
		//Send the chat message
		//TODO: Add event listener for the enter key event.
		protected function sendChatMsg(p_evt:MouseEvent=null):void
		{
			if (_chatModel.isSynchronized && _flashChat.inputTextArea.text) {
				var chatMsgDesc:ChatMessageDescriptor = new ChatMessageDescriptor();
				chatMsgDesc.msg = _flashChat.inputTextArea.text;
				_chatModel.sendMessage(chatMsgDesc);
				_flashChat.inputTextArea.text = "";
			}
		}
		
		//Clear the chat history.
		protected function clearChatMsg(p_evt:MouseEvent):void
		{
			if (_chatModel.isSynchronized) {
				_flashChat.histTextArea.htmlText = "";
				_chatModel.clear();
			}	
		}
		
		//Send msg on keyboard enter event
		protected function onEnter(p_evt:KeyboardEvent):void
		{
			if (p_evt.keyCode == Keyboard.ENTER) {
				sendChatMsg();
			}
		}
		
	}
}