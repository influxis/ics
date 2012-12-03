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
	import com.adobe.rtc.events.ArrayCollectionEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	[Event(name="replace", type="ArrayCollectionEvent")]
	[Event(name="add", type="ArrayCollectionEvent")]
	[Event(name="remove", type="ArrayCollectionEvent")]
	[Event(name="removeAll", type="ArrayCollectionEvent")]
	
	/**
	 * The UtilArrayCollection class is a wrapper class that exposes an Array as a collection that can be accessed and manipulated using the methods and properties of the ICollectionView or IList  interfaces
	 * Its primarily used in non-flex environment to replace the mx.collections.ArrayCollection
	 */
   public class  UtilArrayCollection extends Proxy implements IEventDispatcher
	{
		
		protected var _arrayCollection:Array = new Array();
		protected var _dispatcher:EventDispatcher;

		public function UtilArrayCollection()
		{
			_dispatcher = new EventDispatcher(this);
		}
		
		public function get source():Array
		{
			return _arrayCollection;
		}
		
		public function set source(p_arraySource:Array):void
		{
			_arrayCollection = p_arraySource;
		}
		
		public function removeAll():void
		{
			if (_arrayCollection == null)
				_arrayCollection = new Array();
			else
				_arrayCollection.length = 0;
            
			dispatchEvent(new ArrayCollectionEvent(ArrayCollectionEvent.REMOVEALL,-1,null,null));
		}
		
		public function addItem(p_item:Object):void
		{
			_arrayCollection.push(p_item);
			dispatchEvent(new ArrayCollectionEvent(ArrayCollectionEvent.ADD,_arrayCollection.length -1,null,p_item));

		}
		
		public function getItemAt(p_index:int):*
		{
			if (_arrayCollection && _arrayCollection.length >= p_index)
				return _arrayCollection[p_index];
			else
				return null;
		}
		
		public function setItemAt(p_item:Object, p_index:int):void
		{
			var tmp:* = getItemAt(p_index);
			_arrayCollection[p_index] = p_item;
			dispatchEvent(new ArrayCollectionEvent(ArrayCollectionEvent.REPLACE,p_index,tmp,p_item));
		}
		
		public function addItemAt(p_item:Object, p_index:int):void
		{
			_arrayCollection.splice(p_index, 0, p_item);
			dispatchEvent(new ArrayCollectionEvent(ArrayCollectionEvent.ADD,p_index,null,p_item));			
		}
		
		public function removeItemAt(p_index:int):void
		{
			var tmp:* = getItemAt(p_index);
			_arrayCollection.splice(p_index,1);
			dispatchEvent(new ArrayCollectionEvent(ArrayCollectionEvent.REMOVE,p_index,tmp,null));
		}
		
		public function get length():int
		{
			return _arrayCollection.length;
		}
		
		public function getItemIndex(p_item:Object):int
		{
			for ( var i:int = 0; i < _arrayCollection.length ; i++ ) {
				if (_arrayCollection[i] == p_item) {
					return i;
				}
			}
			return -1;
		}
		
		public function contains(p_items:Object):Boolean
		{
			return getItemIndex(p_items) != -1;
		} 
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void{
			_dispatcher.addEventListener(type, listener, useCapture, priority);
		}
		
		public function dispatchEvent(evt:Event):Boolean{
			return _dispatcher.dispatchEvent(evt);
		}
		
		public function hasEventListener(type:String):Boolean{
			return _dispatcher.hasEventListener(type);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void{
			_dispatcher.removeEventListener(type, listener, useCapture);
		}
		
		public function willTrigger(type:String):Boolean {
			return _dispatcher.willTrigger(type);
		}
		
		//--------------------------------------------------------------------------
		//
		// Proxy methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  @private
		 *  Attempts to call getItemAt(), converting the property name into an int.
		 */
		override flash_proxy function getProperty(name:*):*
		{
			if (name is QName)
				name = name.localName;
			
			var index:int = -1;
			try
			{
				// If caller passed in a number such as 5.5, it will be floored.
				var n:Number = parseInt(String(name));
				if (!isNaN(n))
					index = int(n);
			}
			catch(e:Error) // localName was not a number
			{
			}
			
			if (index == -1)
			{
				throw new Error("Item Not Found");
			}
			else
			{
				return getItemAt(index);
			}
		}
		
		/**
		 *  @private
		 *  Attempts to call setItemAt(), converting the property name into an int.
		 */
		override flash_proxy function setProperty(name:*, value:*):void
		{
			if (name is QName)
				name = name.localName;
			
			var index:int = -1;
			try
			{
				// If caller passed in a number such as 5.5, it will be floored.
				var n:Number = parseInt(String(name));
				if (!isNaN(n))
					index = int(n);
			}
			catch(e:Error) // localName was not a number
			{
			}
			
			if (index == -1)
			{
				throw new Error("Item not found");
			}
			else
			{
				setItemAt(value, index);
			}
		}
		
		/**
		 *  @private
		 *  This is an internal function.
		 *  The VM will call this method for code like <code>"foo" in bar</code>
		 *  
		 *  @param name The property name that should be tested for existence.
		 */
		override flash_proxy function hasProperty(name:*):Boolean
		{
			if (name is QName)
				name = name.localName;
			
			var index:int = -1;
			try
			{
				// If caller passed in a number such as 5.5, it will be floored.
				var n:Number = parseInt(String(name));
				if (!isNaN(n))
					index = int(n);
			}
			catch(e:Error) // localName was not a number
			{
			}
			
			if (index == -1)
				return false;
			
			return index >= 0 && index < length;
		}
		
		/**
		 *  @private
		 */
		override flash_proxy function nextNameIndex(index:int):int
		{
			return index < length ? index + 1 : 0;
		}
		
		/**
		 *  @private
		 */
		override flash_proxy function nextName(index:int):String
		{
			return (index - 1).toString();
		}
		
		/**
		 *  @private
		 */
		override flash_proxy function nextValue(index:int):*
		{
			return getItemAt(index - 1);
		}    
		
		/**
		 *  @private
		 *  Any methods that can't be found on this class shouldn't be called,
		 *  so return null
		 */
		override flash_proxy function callProperty(name:*, ... rest):*
		{
			return null;
		}
	}
}
