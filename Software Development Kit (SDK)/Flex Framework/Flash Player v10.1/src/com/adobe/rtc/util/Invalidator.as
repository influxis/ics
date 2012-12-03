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
package com.adobe.rtc.util
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	
	/**
	 * Dispatched when the synchronization changes for the camera.
	 */
	[Event(name='invalidationComplete', type="flash.events.Event")]
	
	/**
	 *Invalidator is a utility component that helps in invalidating properties together.
	 * It serves as the similar purpose as commitProperties() in any flex's UIComponent.
	 * We need to call Invalidator.invalidate() if we want a particular property to be invalidated.
	 * We use it Collaborative components like AudioPublisher , AudioSubscriber etc.
	 * 
	 * @see com.adobe.rtc.collaboration.AudioPublisher
	 */
   public class  Invalidator extends EventDispatcher
	{
		
		/**
		 * Event fired when the property is invalidated.
		 */
		public static const INVALIDATION_COMPLETE:String = "invalidationComplete";
		/**
		 * @private
		 */
		private static var _invalidationTimer:Timer = new Timer(100,1);
		/**
		 * Constructor
		 */
		public function Invalidator()
		{
			
		}
		
		/**
		 * Invalidates the properties. Calling this function is similar to calling invalidateProperties() in any flex's UIComponent
		 */
		public function invalidate():void
		{
			_invalidationTimer.addEventListener(TimerEvent.TIMER_COMPLETE,onInvalidationComplete);
			
			if ( !_invalidationTimer.running ) {
				_invalidationTimer.start();
			}
			
		}
		
		/**
		 * @private
		 */
		private function onInvalidationComplete(p_evt:TimerEvent):void
		{
			_invalidationTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,onInvalidationComplete);
			dispatchEvent(new Event(INVALIDATION_COMPLETE));
			
		}
		
		
	} 
}