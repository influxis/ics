// ActionScript file
package 
{
	/**
	 * UserProfile describes the user's profile details.
	 * 
	 */
	 
	 /**********************************************************
	  * ADOBE SYSTEMS INCORPORATED
	  * Copyright [2007-2010] Adobe Systems Incorporated
	  * All Rights Reserved.
	  * NOTICE: Adobe permits you to use, modify, and distribute this file in accordance with the 
	  * terms of the Adobe license agreement accompanying it. If you have received this file from a 
	  * source other than Adobe, then your use, modification, or distribution of it requires the prior 
	  * written permission of Adobe.
	  * *********************************/
	public class UserProfile
	{		
		/**
		 * The first name.
		 * 
		 */
		public var firstName:String;
		/**
		 * The last name.
		 * 
		 */
		public var lastName:String;
		
		/**
		 * The User Age
		 */
		public var age:int = 0;
		/**
		 * Current Job
		 */
		 public var currentJob:JobDescription ;
		/**
		 * Address
		 * 
		 */
		public var address:Address ;
		
		
		public function UserProfile(p_firstName:String=null,p_lastName:String=null,p_age:int=0,p_address:Address=null,p_currentJob:JobDescription=null):void
		{
			if ( p_firstName != null ) {
				firstName = p_firstName ;
			}
			
			if ( p_lastName != null ) {
				lastName = p_lastName ;
			}
			
			if ( p_age != 0 ) {
				age = p_age ;
			}
			
			if ( p_address != null ) {
				address = p_address ;
			}
			
			if ( p_currentJob != null ) {
				currentJob = p_currentJob ;
			}
		}
	}
}