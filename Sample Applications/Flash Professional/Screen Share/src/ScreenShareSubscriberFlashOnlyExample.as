package
{
	import com.adobe.rtc.authentication.AdobeHSAuthenticator;
	import com.adobe.rtc.collaboration.ScreenShareSubscriber;
	import com.adobe.rtc.events.SessionEvent;
	import com.adobe.rtc.session.ConnectSession;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	
	 /**********************************************************
	  * ADOBE SYSTEMS INCORPORATED
	  * Copyright [2007-2010] Adobe Systems Incorporated
	  * All Rights Reserved.
	  * NOTICE: Adobe permits you to use, modify, and distribute this file in accordance with the 
	  * terms of the Adobe license agreement accompanying it.If you have received this file from a 
	  * source other than Adobe, then your use, modification, or distribution of it requires the prior 
	  * written permission of Adobe.
	  * *********************************/

	public class ScreenShareSubscriberFlashOnlyExample extends Sprite
	{
		protected var _cSession:ConnectSession =  new ConnectSession();
		protected var _ssSubscriber:ScreenShareSubscriber;

		public function ScreenShareSubscriberFlashOnlyExample()
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
			_ssSubscriber = new ScreenShareSubscriber();	
			_ssSubscriber.connectSession = _cSession;
			_ssSubscriber.graphics.drawRect(0, 0, stage.width, stage.height);
			addChild(_ssSubscriber);			
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
		
	}
}