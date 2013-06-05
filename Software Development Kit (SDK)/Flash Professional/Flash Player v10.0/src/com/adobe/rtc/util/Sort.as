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
	
	import flash.events.EventDispatcher;
	/**
	 * Stripped down version of mx.collections.sort. Only the compareFunction & findItem functionality is available.
	 */ 
	
   public class  Sort extends EventDispatcher
	{
		protected var _compareFunction:Function;
		public static const ANY_INDEX_MODE:String = "any";
		public static const FIRST_INDEX_MODE:String = "first";
		public static const LAST_INDEX_MODE:String = "last";
		
		
		public function Sort()
		{
			
		}
		
		
		/**
		 *  The method used to compare items when sorting.
		 */
		public function set compareFunction(value:Function):void
		{
			_compareFunction = value;
		}
		
		/**
		 *  Finds the specified object within the specified array (or the insertion
		 *  point if asked for), returning the index if found or -1 if not.
		 */ 
		public function findItem(p_items:Array, p_values:Object, p_mode:String, p_returnInsertionIndex:Boolean = false,p_compareFunction:Function = null):int
		{
			var compareForFind:Function;
			var message:String;
			
			if (!p_items) {
				throw new Error("No Items");
			} else if (p_items.length == 0) {
				return p_returnInsertionIndex ? 1 : -1;
			}
			
			if (p_compareFunction != null) {
				compareForFind = p_compareFunction;
			} else {
				compareForFind = _compareFunction;
			}
			
			// let's begin searching
			var found:Boolean = false;
			var objFound:Boolean = false;
			var index:int = 0;
			var lowerBound:int = 0;
			var upperBound:int = p_items.length -1;
			var obj:Object = null;
			var direction:int = 1;
			//it'd be an error to pass a 3rd parameter
			while(!objFound && (lowerBound <= upperBound)) {
				index = Math.round((lowerBound+ upperBound)/2);
				obj = p_items[index];
				direction = compareForFind(p_values, obj);
				
				switch(direction) {
					case -1:
						upperBound = index -1;
						break;
						
					case 0:
						objFound = true;
						switch(p_mode) {
							case ANY_INDEX_MODE:
								found = true;
								break;
								
							case FIRST_INDEX_MODE:
								found = (index == lowerBound);
								// start looking towards bof
								var objIndex:int = index - 1;
								var match:Boolean = true;
								while(match && !found && (objIndex >= lowerBound)) {
									obj = p_items[objIndex];
									var prevCompare:int = compareForFind(p_values, obj);
									match = (prevCompare == 0);
									if (!match || (match && (objIndex == lowerBound))) {
										found= true;
										index = objIndex + (match ? 0 : 1);
									} // if match
									objIndex--;
								} // while
								break;
								
							case LAST_INDEX_MODE:
								// if we where already at the edge case then we already found the last value
								found = (index == upperBound);
								// start looking towards eof
								objIndex = index + 1;
								match = true;
								while(match && !found && (objIndex <= upperBound)) {
									obj = p_items[objIndex];
									var nextCompare:int = compareForFind(p_values, obj);
									match = (nextCompare == 0);
									if (!match || (match && (objIndex == upperBound))) {
										found= true;
										index = objIndex - (match ? 0 : 1);
									} // if match
									objIndex++;
								} // while
								break;
							default:
							{
								throw new Error(message);
							}
						} // switch
						break;
						
					case 1:
						lowerBound = index +1;
						break;
				} // switch
			} // while
			if (!found && !p_returnInsertionIndex) {
				return -1;
			} else {
				return (direction > 0) ? index + 1 : index;
			}
			
		}
	}
}