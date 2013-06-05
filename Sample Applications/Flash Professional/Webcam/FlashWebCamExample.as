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
	 * A Basic example that illustrates how LLCS Flash Only SWC is used. The app illustrates how a WebCam, SharedProperty
	 * is used. The UI is pretty basic to keep the code simple and strictly avoided
	 * using fancy libraries. All the action happens here. Other classes are just UI stuff. I have purposefully restricted the 
	 * LLCS components just to this class.
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
	 
	public class FlashWebCamExample extends Sprite
	{
		protected var _cSession:ConnectSession =  new ConnectSession();
		protected var _webCamSubscriber:WebcamSubscriber;
		protected var _webCamPublisher:WebcamPublisher;
		protected var _audioPublisher:AudioPublisher;
		protected var _audioSubscriber:AudioSubscriber;
		protected var _sharedProperty:SharedProperty;
		protected var _captionTextField:TextField;
		
		
		// The constructor logs us in to the room specified. and the all the UI is built after we are connected to the room
		
		public function FlashWebCamExample()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			setBackGround();
			//Login in to your room.  Please login as room owner the first time you run this app , so that all the nodes are created
			var authenticator:AdobeHSAuthenticator = new AdobeHSAuthenticator();
			authenticator.userName="Your Username";
			//authenticator.password = "YourPassword";
			_cSession.roomURL="Your RoomUrl";
			_cSession.authenticator = authenticator;
			_cSession.login();
			_cSession.addEventListener(SessionEvent.SYNCHRONIZATION_CHANGE, onLogin);
			stage.addEventListener(Event.RESIZE,setBackGround);
		}
		
		
		protected function onLogin(p_evt:SessionEvent):void
		{
			
			// Add the WebCam Subscriber & the WebCam Publisher.
			_webCamSubscriber = new WebcamSubscriber();
			_webCamSubscriber.width = stage.stageWidth/2;
			_webCamSubscriber.height = stage.stageHeight/2;
			_webCamSubscriber.subscribe();			
			// WebCam Publisher
			_webCamPublisher = new WebcamPublisher();
			//_webCamPublisher.publish();
			_webCamSubscriber.webcamPublisher = _webCamPublisher;
			addChild(_webCamSubscriber);
			
			//SharedProperty for a shared Caption
			_sharedProperty = new SharedProperty();
			_sharedProperty.sharedID = "sharedCaption";
			_sharedProperty.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE,onSharedPropSync);
			_sharedProperty.addEventListener(SharedPropertyEvent.CHANGE,onSharedPropChange);
			_sharedProperty.subscribe();
		}
		
		protected function setBackGround(p_evt:Event=null):void
		{
			stage.stageHeight = (stage.stageHeight < 600) ? 600 : stage.stageHeight;
			stage.stageWidth = (stage.stageWidth < 600) ? 600 : stage.stageWidth;
			graphics.clear();
			graphics.beginFill(0x3b3b3b); 
			graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			graphics.endFill();
			
			if (_captionTextField) {
				drawWhiteBG(_captionTextField.x, _captionTextField.y, _captionTextField.width, _captionTextField.height);
			}
		}
		
		protected function addWebCamButton():void
		{
			var webCamButton:CustomSimpleButton = new CustomSimpleButton("Start");
			webCamButton.x = _webCamSubscriber.x + (_webCamSubscriber.width  - webCamButton.width)/2
			webCamButton.y = _webCamSubscriber.height+10;
			webCamButton.addEventListener(MouseEvent.CLICK,onClick);
			addChild(webCamButton);
		}
		
		protected function onClick(p_evt:MouseEvent):void
		{
			if (p_evt.currentTarget.label == "Start") {
				_webCamPublisher.publish();
				p_evt.currentTarget.label = "Stop";
			} else {
				_webCamPublisher.stop();
				p_evt.currentTarget.label = "Start";
			}
		}
		
		//Update the Caption
		protected function onSharedPropChange(p_evt:SharedPropertyEvent):void
		{
			if (_sharedProperty.isSynchronized) {
				_captionTextField.htmlText = p_evt.value as String;
			}
		}
		
		//Add a caption text field and a button to update the caption to the model.
		protected function addCaptionTextField():void
		{
			_captionTextField =  new TextField();
			if (ConnectSession.primarySession.userManager.myUserRole >= UserRoles.PUBLISHER) {
				_captionTextField.type = TextFieldType.INPUT;
			}
			_captionTextField.width = stage.stageWidth/2;
			var format:TextFormat = new TextFormat();
			format.font = "Verdana";
			format.color = 0xFF0000;
			format.size = 14;
			format.align = TextFormatAlign.LEFT;
			_captionTextField.defaultTextFormat = format;
			if (_sharedProperty.value) {
				_captionTextField.htmlText = _sharedProperty.value as String;
			}
			_captionTextField.height = _captionTextField.textHeight + 10;
			
			_captionTextField.x = (stage.stageWidth - _captionTextField.width)/2;
			_captionTextField.y = 5;
			addChild(_captionTextField);
			drawWhiteBG(_captionTextField.x, _captionTextField.y, _captionTextField.width, _captionTextField.height);
			
			_webCamSubscriber.x = (stage.stageWidth - _webCamSubscriber.width)/2;
			_webCamSubscriber.y = _captionTextField.height +15;
			addWebCamButton();
			
			var updateButton:CustomSimpleButton = new CustomSimpleButton("Set");
			updateButton.width = 40;
			updateButton.x = _captionTextField.x + _captionTextField.width + 5;
			updateButton.y = 5
			updateButton.addEventListener(MouseEvent.CLICK,onUpdate);
			addChild(updateButton);
			
		}
		
		protected function onSharedPropSync(p_evt:CollectionNodeEvent):void
		{
			if (_sharedProperty.isSynchronized) {
				addCaptionTextField();
			}
		}
		
		protected function onUpdate(p_evt:MouseEvent):void
		{
			if (_sharedProperty.isSynchronized) {
				_sharedProperty.value = _captionTextField.htmlText;
			}
		}
		
		protected function drawWhiteBG(p_x:uint, p_y:uint, p_width:Number, p_height:Number):void
		{
			graphics.beginFill(0xFFFFFF); 
			graphics.drawRect(p_x, p_y, p_width, p_height);
			graphics.endFill();
		}
		
	}
}