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
	
	
   public class  ArrayCollectionEvent extends Event
	{
		/**
		 * The ArrayCollectionEvent.REPLACE constant defines the value of the type property of the event object for an event that is dispatched when a value in ArrayCollection has been modified.
		 */ 
	    public static const REPLACE:String = "replace";
		
		/**
  		 * The ArrayCollectionEvent.ADD constant defines the value of the type property of the event object for an event that is dispatched when a value in ArrayCollection has been added.
		 */ 
	    public static const ADD:String = "add";

		/**
		 * The ArrayCollectionEvent.REMOVE constant defines the value of the type property of the event object for an event that is dispatched when a value in ArrayCollection has been removed.
		 */ 
	    public static const REMOVE:String = "remove";
	    public static const REMOVEALL:String = "removeAll";
		
	    public var newItem:*;
	    public var location:int;
	    public var oldItem:*;

		public function ArrayCollectionEvent(p_type:String,p_location:int = -1,
                                    p_oldItem:* = null, p_newItem:* = null)
		{
			super(p_type);
	        location = p_location;
	        oldItem = p_oldItem;
    	    newItem = p_newItem ? p_newItem : null;
		}
		
		override public function clone():Event
		{
			return (new ArrayCollectionEvent(type,location,oldItem,newItem));
		}

	}
}