// ActionScript file
package com.adobe.rtc.events
{
	import com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor;
	
	import flash.events.Event;

	/**
	 * Event Class dispatched by the StreamManager
	 * @see com.adobe.rtc.sharedManagers.StreamManager
	 */
	public class StreamStatusEvent extends Event
	{
		/**
		 * Dispatched when a room receives a new stream.
		 */
		public static const STREAM_STATUS:String = "streamStatus";	
		
		
		
		/**
		 * A streamDescriptor associated with this event, if applicable.
		 */
		public var streamPublisherID:String;
		public var streamStatusCode:String ;
		
		
		public function StreamStatusEvent(type:String,p_streamStatus:String = null ,p_streamPublisherID:String = null):void {
			super(type);
			
			if ( p_streamPublisherID != null ) {
				streamPublisherID = p_streamPublisherID ;
			}
			
			if ( p_streamStatus != null ) {
				streamStatusCode = p_streamStatus ;
			}
		}

		/**
		 * @private
		 */
		public override function clone():Event
		{
			return new StreamStatusEvent(type, streamStatusCode,streamPublisherID);
		}
	}
}
