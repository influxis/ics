// ActionScript file
package 
{
	import mx.states.State;
	
	/**
	 * Describes the user's address.
	 * 
	 */
	 
	  /**********************************************************
	  * ADOBE SYSTEMS INCORPORATED
	  * Copyright [2007-2010] Adobe Systems Incorporated
	  * All Rights Reserved.
	  * NOTICE: Adobe permits you to use, modify, and distribute this file in accordance with the 
	  * terms of the Adobe license agreement accompanying it.If you have received this file from a 
	  * source other than Adobe, then your use, modification, or distribution of it requires the prior 
	  * written permission of Adobe.
	  * *********************************/
	 
	public class Address
	{
		
		/**
		 * The 1st line of address.
		 * 
		 */
		public var addressLine1:String;
		/**
		 * The 2nd line of address.
		 * 
		 */
		public var addressLine2:String;
		/**
		 * The city.
		 * 
		 */
		public var city:String;
		/**
		 * The state.
		 * 
		 */
		public var state:String;
		/**
		 * The zip.
		 * 
		 */
		public var zip:String;
		
		public function Address(p_firstAdd:String=null,p_secondAdd:String=null,p_city:String=null,p_state:String=null,p_zip:String=null):void
		{
			if ( p_firstAdd != null ) {
				addressLine1 = p_firstAdd ;
			}
			
			if ( p_secondAdd != null ) {
				addressLine2 = p_secondAdd ;
			}
			
			if ( p_city != null ) {
				city = p_city ;
			}
			
			if ( p_state != null ) {
				state = p_state ;
			}
			
			if ( p_zip != null ) {
				zip = p_zip ;
			}
		}
		
	}
}