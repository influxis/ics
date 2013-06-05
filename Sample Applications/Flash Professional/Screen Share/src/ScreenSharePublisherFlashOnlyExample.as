package {
	import com.adobe.rtc.authentication.AdobeHSAuthenticator;
	import com.adobe.rtc.collaboration.ScreenSharePublisher;
	import com.adobe.rtc.events.SessionEvent;
	import com.adobe.rtc.session.ConnectSession;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	
	 /**********************************************************
	  * ADOBE SYSTEMS INCORPORATED
	  * Copyright [2007-2010] Adobe Systems Incorporated
	  * All Rights Reserved.
	  * NOTICE: Adobe permits you to use, modify, and distribute this file in accordance with the 
	  * terms of the Adobe license agreement accompanying it.If you have received this file from a 
	  * source other than Adobe, then your use, modification, or distribution of it requires the prior 
	  * written permission of Adobe.
	  * *********************************/

	public class ScreenSharePublisherFlashOnlyExample extends Sprite
	{
		protected var _cSession:ConnectSession =  new ConnectSession();
		protected var _sspublisher:ScreenSharePublisher;
		protected var _flashSSPublisherUI:FlashSSPublisherUI;
		
		protected static const DEFAULT_SS_PERFORMANCE:uint = 70;
		protected static const DEFAULT_SS_KFI:uint = 20;
		protected static const DEFAULT_SS_FPS:uint = 4;
		protected static const DEFAULT_SS_QUALITY:uint = 75;
		protected static const DEFAULT_SS_BANDWIDTH:uint = 125000;
		protected static const DEFAULT_SS_ENABLEHFSS:Boolean = false; 

		public function ScreenSharePublisherFlashOnlyExample()
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
			drawSSUI();
			_sspublisher = new ScreenSharePublisher();
			_sspublisher.connectSession = _cSession;

			//this is optional
/*			var userlist:ArrayCollection = connectSession.userManager.userCollection;
			var recipientIDs:Array = new Array();
			for(var i:int=0; i<userlist.length; i++){
			  recipientIDs.push((userlist.getItemAt(i) as UserDescriptor).userID);
			}
			
			// this is optional, default is everyone in the room can see the screen share
			_sspublisher.recipientIDs = recipientIDs;
*/			
			// see APIs section for the options
			_sspublisher.quality = DEFAULT_SS_QUALITY;  
			_sspublisher.performance = DEFAULT_SS_PERFORMANCE; 
			_sspublisher.keyFrameInterval = DEFAULT_SS_KFI; 
			_sspublisher.fps = DEFAULT_SS_FPS;  
			_sspublisher.enableHFSS = DEFAULT_SS_ENABLEHFSS; 
			_sspublisher.bandwidth = DEFAULT_SS_BANDWIDTH; 
			
			addChild(_sspublisher);			
		}
		
		protected function drawSSUI():void
		{
			_flashSSPublisherUI = new FlashSSPublisherUI(stage.stageWidth/2, stage.stageHeight/2);
			_flashSSPublisherUI.x = 0;// stage.stageWidth/2 - _flashSSPublisherUI.width/2;
			_flashSSPublisherUI.startSharingButton.addEventListener(MouseEvent.CLICK,startSS);
			_flashSSPublisherUI.stopSharingButton.addEventListener(MouseEvent.CLICK,stopSS);
			_flashSSPublisherUI.pauseSharingButton.addEventListener(MouseEvent.CLICK,pauseSS);
			addChild(_flashSSPublisherUI);
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
		
	
		protected function onResize(p_evt:Event=null):void
		{
			width = stage.stageWidth;
			height = stage.stageHeight;

			scaleX = scaleY = 1;
		
		}
		private function startSS(p_evt:MouseEvent):void
		{
			if(_sspublisher != null && !_sspublisher.isPublishing) {
				_sspublisher.publish();
				_flashSSPublisherUI.startSharingButton.enabled = false;
				_flashSSPublisherUI.stopSharingButton.enabled = true;
				_flashSSPublisherUI.pauseSharingButton.enabled = true;
			}
		}
		
		private function stopSS(p_evt:MouseEvent):void
		{
			if(_sspublisher != null) {
				_sspublisher.stop();
				_flashSSPublisherUI.startSharingButton.enabled = true;
				_flashSSPublisherUI.stopSharingButton.enabled = false;
				_flashSSPublisherUI.pauseSharingButton.enabled = false;
			}
		}
		
		private function pauseSS(p_evt:MouseEvent):void
		{
			if(_sspublisher != null && _sspublisher.isPublishing) {
				if(_flashSSPublisherUI.pauseSharingButton.label == "Pause Screen Sharing") {
					_sspublisher.pause(true);
					_flashSSPublisherUI.pauseSharingButton.label = "Resume Screen Sharing";
				}
				else{
					_sspublisher.pause(false);
					_flashSSPublisherUI.pauseSharingButton.label = "Pause Screen Sharing";
				}
			}
		}
		
	}
}
