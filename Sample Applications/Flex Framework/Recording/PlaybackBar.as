package
{
	import com.adobe.rtc.archive.ArchiveManager;
	import com.adobe.rtc.events.ArchiveEvent;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.Button;
	import mx.controls.HSlider;
	import mx.core.UIComponent;
	import mx.events.SliderEvent;
	
	/*
	 * ADOBE SYSTEMS INCORPORATED
	 * Copyright 2010 Adobe Systems Incorporated
	 * All Rights Reserved.			 *
	 * NOTICE: Adobe permits you to use, modify, and distribute this file in accordance with the 
	 * terms of the Adobe license agreement accompanying it.If you have received this file from a 
	 * source other than Adobe, then your use, modification, or distribution of it requires the prior 
	 * written permission of Adobe.
	 */

	public class PlaybackBar extends UIComponent implements ISessionSubscriber
	{
		/**
		 * @private
		 */
		protected var _slider:HSlider ;
		/**
		 * @private
		 */
		protected var _startStopBtn:Button;
		/**
		 * @private
		 */
		protected var _playPauseBtn:Button ;
		/**
		  * @private 
		  */		
		 protected var _connectSession:IConnectSession = new SessionContainerProxy(this as UIComponent);
		/**
		 * @private
		 */
		 protected var _archiveManager:ArchiveManager ;
		 /**
		 * @private
		 */
		 protected var _subscribed:Boolean = false ;
		
		public function PlaybackBar()
		{
			super();
		}
		
		/**
		 * The IConnectSession with which this component is associated; it defaults to the first 
		 * IConnectSession created in the application. 
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
			_connectSession = p_session ;
			_archiveManager = _connectSession.archiveManager
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
		}
		
		public function get isSynchronized():Boolean
		{
			return _connectSession.isSynchronized;
		}
		
		public function close():void
		{
			//NO OP
		}
		
		/**
		 * Tells the component to begin synchronizing with the service. For UIComponent-based components such as this one,
		 * this is called automatically upon being added to the <code class="property">displayList</code>. 
		 * For "headless" components, this method must be called explicitly.
		 */
		public function subscribe():void
		{
			if ( !_archiveManager ) {
				_archiveManager = _connectSession.archiveManager ;
				_archiveManager.addEventListener(ArchiveEvent.TOTAL_TIME_CHANGE,onTotalTimeChange);
				_archiveManager.addEventListener(ArchiveEvent.CURRENT_TIME_CHANGE,onCurrentTimeChange);
			}
			
			if ( !_slider) {
				_slider = new HSlider();
				_slider.minimum = 0 ;
				_slider.maximum = _archiveManager.totalTime/1000 ;
				_slider.showDataTip = true ;
				_slider.labels = [_slider.minimum,uint(_slider.maximum/4),uint(_slider.maximum/2),uint(_slider.maximum*3/4),uint(_slider.maximum)];
				_slider.tickInterval = uint(_slider.maximum/4) ;
				_slider.liveDragging = false ;
				_slider.addEventListener(SliderEvent.CHANGE,onChange);
				addChild(_slider);
			}
			
			if ( !_playPauseBtn ) {
				_playPauseBtn = new Button();
				_playPauseBtn.label = "Pause/Stop the Recording" ;
				_playPauseBtn.addEventListener(MouseEvent.CLICK,onPausePlayClick);
				addChild(_playPauseBtn);
			}
			
			_subscribed = true ;
		}
		
		
		/**
		 * @private
		 */
		protected function onPausePlayClick(p_evt:MouseEvent):void
		{
			if ( !_archiveManager ) {
				return ;
			}
			
			if ( (_slider.value*1000) >= _archiveManager.totalTime ){
				return ;
			}
			
			if (_playPauseBtn.label == "Start/Play the Recording" ) {
				_archiveManager.currentTime = _slider.value*1000 ;
				_archiveManager.pause(false);
				_playPauseBtn.label = "Pause/Stop the Recording" ;
			} else if (_playPauseBtn.label == "Pause/Stop the Recording" ) {
				_archiveManager.pause(true);
				_playPauseBtn.label = "Start/Play the Recording" ;
			}
		}
		
		/**
		 * @private
		 */
		override protected function createChildren():void
		{
			super.createChildren();	
			
			if ( !_subscribed ) {
				subscribe();
				_subscribed = true ;
			}
		
		}
		
		/**
		 * @private
		 */
		override protected function measure():void
		{
			super.measure();
			
			if ( measuredWidth < 200 ) {
				measuredWidth = 200 ;
			}
			
			measuredHeight += _slider.height + _playPauseBtn.height + 30 ;
		}
		
		
		/**
		 * @private
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth,unscaledHeight);
			
			var y:Number = 0 ;
			
			if (_slider) {
				_slider.move(10,10);
				_slider.setActualSize(unscaledWidth -20,_slider.getExplicitOrMeasuredHeight()) ;
				y = _slider.y + _slider.height ;
			}
			
			y += 10 ;
			
			if ( _playPauseBtn ) {
				_playPauseBtn.setActualSize(250,30);
				_playPauseBtn.move(unscaledWidth/2 -_playPauseBtn.width/2,y);
			}
			
			y += 10 ;
			
		}
		
		
		/**
		 * @private
		 */
		private function onCurrentTimeChange(p_evt:Event):void
		{
			_slider.value = _archiveManager.currentTime/1000 ;
			
			if ( _archiveManager.currentTime >= _archiveManager.totalTime ) {
				_playPauseBtn.label = "Start/Play the Recording" ;
			}
		}
		
		/**
		 * @private
		 */
		private function onTotalTimeChange(p_evt:Event):void
		{
			_slider.maximum = _archiveManager.totalTime/1000 ;
			_slider.labels = [_slider.minimum,uint(_slider.maximum/4),uint(_slider.maximum/2),uint(_slider.maximum*3/4),uint(_slider.maximum)];
			_slider.tickInterval = uint(_slider.maximum/4);
		}
		
		
		/**
		 * @private
		 */
		public function onMetaData(info:Object):void
		{
			
		}
		
		
		private function onChange(p_evt:Event):void
		{
			_archiveManager.seek(_slider.value*1000);
			
			if ( (_slider.value*1000) < _archiveManager.totalTime ) {
				_playPauseBtn.label = "Pause/Stop the Recording" ;
			}
		}
		
		
	}
}