// ActionScript file
package 
{
	/**
	 * Describes the user's work history and other details
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
	public class JobDescription
	{
		
		/**
		 * The Date of joining
		 * 
		 */
		public var dateJoining:Date;
		
		/**
		 * The Date of leaving(if any)
		 * 
		 */
		public var dateLeaving:Date;

		/**
		 * Job Titles
		 * 
		 */
		public var title:String;
		/**
		 * Company Name
		 */
		 public var companyName:String ;
		 
		 public function JobDescription(p_dateJoining:Date=null,p_dateLeaving:Date=null,p_title:String=null,p_companyName:String=null):void
		{
			if ( p_dateJoining != null ) {
				dateJoining = p_dateJoining ;
			}
			
			if ( p_dateLeaving != null ) {
				dateLeaving = p_dateLeaving ;
			}
			
			if ( p_title != null ) {
				title = p_title ;
			}
			
			if ( p_companyName != null ) {
				companyName = p_companyName ;
			}
		}
	}
}