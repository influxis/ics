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
package com.adobe.rtc.events
{
	import flash.events.Event;
	
    public class  SharedObjectEvent extends Event
	{
		/**
		 * The SharedObjectEvent.PROPERTY_CHANGE constant defines the value of the type property of the event object for an event that is dispatched when a Property in SharedObject has been modified.
		 */ 
		public static const PROPERTY_CHANGE:String = "propertyChange";
		
		/**
  		 * The SharedObjectEvent.PROPERTY_ADD constant defines the value of the type property of the event object for an event that is dispatched when a Property in SharedObject has been added.
		 */ 
		public static const PROPERTY_ADD:String = "propertyAdd";

		/**
		 * The SharedObjectEvent.PROPERTY_REMOVE constant defines the value of the type property of the event object for an event that is dispatched when a Property in SharedObject has been removed.
		 */ 
		public static const PROPERTY_REMOVE:String = "propertyRetracted";

		/**
		 * The key of the property in the sharedObject
		 */ 
		public var propertyName:String;
		
		/**
		 *The value of the property in the sharedObject 
		 */ 
		public var value:Object;
		/**
		 * The Publisher ID of the shared Object
		 */ 
		public var publisherID:String  ;
		
		
		/**
		 * Constructor for the SharedObjectEvent
		 * @param p_type The event type; indicates the action that triggered the event. Its usually SharedObjectEvent.PROPERTY_CHANGE or SharedObjectEvent.PROPERTY_ADD or SharedObjectEvent.PROPERTY_RETRACT
		 * @param p_itemId The p_itemID is the key of the property in the sharedObject
		 * @param p_value The p_value is the value of the property in the sharedObject
		 */ 
		public function SharedObjectEvent(p_type:String, p_itemId:String, p_value:Object, p_publisherID:String=null)
		{
			super(p_type);
			propertyName = p_itemId;
			value = p_value;
			if (p_publisherID) {
				publisherID = p_publisherID;
			}
		}

		/**
		* Duplicates an instance of the SharedEvent class.
		*/
		public override function clone():Event
		{
			return new SharedObjectEvent(type, propertyName, value);
		}		
		
	}
}