package com.ics.events
{
	import flash.events.Event;
	
	public class ExternalAuthTokenEvent extends Event
	{
		static public const EXTERNAL_TOKEN_CREATED:String = "externalTokenCreated";
		
		public var token:String;
		
		public function ExternalAuthTokenEvent(type:String, token:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.token = token;
		}
		
		override public function clone():Event
		{
			return new ExternalAuthTokenEvent(type, token, bubbles, cancelable);
		}
	}
}