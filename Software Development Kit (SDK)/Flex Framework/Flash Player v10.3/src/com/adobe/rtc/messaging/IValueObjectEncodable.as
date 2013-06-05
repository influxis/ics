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
package com.adobe.rtc.messaging
{
	
	/**
	 * IValueObjectEncodable describes a set of functions required to allow class instances to be serialized 
	 * and deserialized as value objects. It is similar to flash.utils.IExternalizable, except that in this case, 
	 * instead of writing directly to binary, IValueObjectEncodable classes can
	 * externalize themselves to simple Value Objects which are suitable for storage in an XML representation. 
	 * <p>
	 * One of the key benefits of IValueObjectEncodable is that it allows a class instance to transmit itself 
	 * minus its default values. As long as the recipient is aware of the same set of default values for 
	 * the class, these need not be sent and could therefore reduce the burden on bandwidth.
	 * 
	 */	
	 
	public interface IValueObjectEncodable
	{

		/**
		 * Takes in a <code>valueObject</code> and structure the current class instance according to the values therein.
		 * 
		 * @param p_valueObject An Object which represents the non-default values for this class instance.
		 */
		function readValueObject(p_valueObject:Object):void;
		
		/**
		 * Creates a ValueObject representation of the current class instance.
		 * 
		 * @return An Object which represents the non-default values for this class instance that is suitable for 
		 * consumption by <code>readValueObject</code>.
		 * 
		 */	
		function createValueObject():Object;
	}
}