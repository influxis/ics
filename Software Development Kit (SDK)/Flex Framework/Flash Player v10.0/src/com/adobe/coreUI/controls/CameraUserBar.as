// ActionScript file
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
package com.adobe.coreUI.controls
{
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.LinkButton;
	
	/**
	 * @private
	 */
   public class  CameraUserBar extends ControllingUserBar
	{
		protected var _userStopBtn:LinkButton;
		protected var _userPauseBtn:LinkButton;
		protected var _pause:Boolean = false ;
		protected var _showStopPauseBtn:Boolean = true ;
		
		[Embed(source="assets/close.png")]
 		private var _icon_close:Class;
 		
 		
 		[Embed(source='assets/campauseplay.swf#webcastVideo_on')]
 		public static var playCam:Class;

 		[Embed(source='assets/campauseplay.swf#webcastVideo_off')]
 		public static var pauseCam:Class;
 		
 		
		/**
		 * Overridding the CreateChildren
		* @private
		*/		
    	override protected function createChildren():void
    	{
    		super.createChildren();
    		createStopBtn();
    		createPauseBtn();

			setStyle("cornerRadius",0);
    	}
    	
    	public function set showStopPauseBtn(p_showStopPauseBtn:Boolean):void
    	{
    		if ( p_showStopPauseBtn == _showStopPauseBtn ) {
    			return ;
    		}
    		
    		_showStopPauseBtn = p_showStopPauseBtn ;
    		
    		if ( !_showStopPauseBtn ) {
    			if ( _userStopBtn ) {
    				removeChild(_userStopBtn);
    				_userStopBtn = null ;
    			}
    		} else {
    			createStopBtn();
    		}
    		
    		if ( !_showStopPauseBtn ) {
    			if ( _userPauseBtn ) {
    				removeChild(_userPauseBtn);
    				_userPauseBtn = null ;
    			}
    		} else {
    			createPauseBtn();
    		}
    		
    		invalidateDisplayList();
    	}
    	
    	
    	protected function createStopBtn():void
    	{
    		if (!_userStopBtn && _showStopPauseBtn) {
    			_userStopBtn = new LinkButton();
    			//_userStopBtn.label = "x";
    			_userStopBtn.width = 22;
    			_userStopBtn.setStyle("icon",_icon_close);
    			_userStopBtn.toolTip = _lm.getString("Stop");
//    			_userStopBtn.alpha = 0.7 ;
    			_userStopBtn.addEventListener(MouseEvent.CLICK,onUserCameraClose);
    			addChild(_userStopBtn);
    		}
    	}
    	
    	override protected function measure():void
    	{
    		measuredHeight = measuredMinHeight = 20; 
    	}
    	
    	protected function createPauseBtn():void
    	{
    		if (!_userPauseBtn && _showStopPauseBtn) {
    			_userPauseBtn = new LinkButton();
    			if ( !_pause ) {
    				//_userPauseBtn.label = "||";
    				_userPauseBtn.setStyle("icon",playCam);
    				_userPauseBtn.toolTip=  _lm.getString("Pause");
    			} else {
    				_userPauseBtn.setStyle("icon",pauseCam);
    				_userPauseBtn.toolTip =  _lm.getString("Play");
    			}
//    			_userPauseBtn.alpha = 0.7 ;
    			_userPauseBtn.addEventListener(MouseEvent.CLICK,onUserCameraPause);
    			addChild(_userPauseBtn);
    		}
    	}
    	
    	
    	public function get pause():Boolean 
    	{
    		return _pause ;
    	}
    	
    	public function set pause(p_pause:Boolean):void
    	{
    		if ( _pause == p_pause )
    			return ;
    			
    		_pause = p_pause ;
    		
    		if ( _userPauseBtn ) {
    			if (!_pause) {
    				_userPauseBtn.setStyle("icon",playCam);
    				_userPauseBtn.toolTip =  _lm.getString("Pause");
    			} else {
    				_userPauseBtn.setStyle("icon",pauseCam);
    				_userPauseBtn.toolTip =  _lm.getString("Play");
    			}
    		}
    		
    	}
    	
    	protected function onUserCameraPause(p_evt:MouseEvent):void
    	{
    		dispatchEvent(new Event(Event.CHANGE));
    	}
    	
    	protected function onUserCameraClose(p_evt:MouseEvent):void
    	{
    		dispatchEvent(new Event(Event.CLOSE));
    	}
    	
    	override protected function updateDisplayList(p_w:Number , p_h:Number):void
    	{
    		super.updateDisplayList(p_w,p_h);
    		
    		if ( !isNaN(p_w) && !isNaN(p_h)) {
	    		var g:Graphics = this.graphics ;
				g.clear();
	    		g.beginFill(0x000000,0.02);
				g.drawRect(0, 0, p_w, p_h);
				g.endFill();
	    		
	    		if (_userStopBtn) {
	    			_userStopBtn.setActualSize(20, _userStopBtn.measuredHeight);
	    			_userStopBtn.move(p_w - 20, (p_h-_userStopBtn.measuredHeight)/2);
	    			_userPauseBtn.setActualSize(25, _userPauseBtn.measuredHeight);
	    			_userPauseBtn.move(p_w - 45, _userStopBtn.y);
	    		}
	    	}
       	} 	
 	}
 	
}
    	
    	
