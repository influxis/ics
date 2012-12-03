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
package com.adobe.rtc.session
{
	import flash.events.EventDispatcher;

	
	/**
	 * RoomSettings declares the initial room settings passed to RoomManager through 
	 * an IConnectSession's <code class="property">initialRoomSettings</code> property. 
	 * Note that this will <b>only take effect the FIRST time</b> the room receives a connection 
	 * from a <code>UserRoles.OWNER</code>. RoomSettings is also a 
	 * class for holding the constant values for various properties within the RoomManager.
 	 * 
	 *
 	 * <h6>Using RoomSettings to auto-promote a viewer to a publisher</h6>
 	 *	<listing>
	 * &lt;rtc:AdobeHSAuthenticator 
	 * // Deployed applications DO NOT hard code username and password here.
     *			userName="AdobeIDusername&#64;example.com" 
     *			password="AdobeIDpassword" 
     *			id="auth"/&gt
	 * &lt;session:RoomSettings autoPromote="true" roomBandwidth="auto" id="roomSettings"/&gt;
 	 * &lt;session:ConnectSessionContainer 
	 * 			roomURL="http://connect.acrobat.com/fakeRoom/" 
	 *			authenticator="{auth}" 
	 *			initialRoomSettings="{roomSettings}"&gt;
	 *			&lt;pods:WebCamera width="100%" height="100%"/&gt;
	 * &lt;/session:ConnectSessionContainer&gt;</listing>
	 * <blockquote>
	 * <b>Note</b>: You can configure room settings programmatically or via the Room Console.
	 * Some settings are owned by the RoomSettings class, and others by the RoomManager class.
	 * Room settings are saved with any templates created from the room.
	 * </blockqoute><p></p>
	 * <img src="../../../../devimages/dc_roomsettings.png" alt="LCCS room settings">
	 *
	 * @see com.adobe.rtc.session.IConnectSession
	 * @see com.adobe.rtc.sharedManagers.RoomManager
	 * @see com.adobe.rtc.util.RoomTemplater
	 */
	
   public class  RoomSettings extends EventDispatcher
	{
		/**
		 * Room connection speed constant for LAN.
		 */
		public static const LAN:String = "LAN";
		
		/**
		 * Room connection speed constant for DSL.
		 */
		public static const DSL:String = "dsl";
		
		/**
		 * Room connection speed constant for MODEM.
		 */
		public static const MODEM:String = "modem";
		
		/**
		 * Room connection speed constant for automatically calculating speed.
		 */
		public static const AUTO:String = "auto";
		
		/**
		 * RoomManager state constant for an open, active room.
		 */
		public static const ROOM_STATE_ACTIVE:String = "active";
		
		/**
		 * RoomManager state constant for a room with no host.
		 */
		public static const ROOM_STATE_HOST_NOT_ARRIVED:String = "hostNotArrived";
		
		/**
		 * RoomManager state constant for a room which has been closed.
		 */
		public static const ROOM_STATE_ENDED:String = "ended";
		
		/**
		 * RoomManager state constant for a room which has been placed on hold.
		 */
		public static const ROOM_STATE_ON_HOLD:String = "onhold";
		
		
		public function RoomSettings()
		{
			_roomBandWidth = AUTO;
			_autoPromote = false;
			_guestsMustKnock = false;
			_roomState = ROOM_STATE_ACTIVE;
		}
		
		//----------------------------------
	    //  roomBandWidth
	    //----------------------------------
	    /**
	     *  @private
	     *  Storage for roomBandWidth property.
	     */
	    private var _roomBandWidth:String = AUTO;
	
	    [Inspectable(category="General", enumeration="LAN,dsl,modem,auto", defaultValue="auto")]
	
	    /**
	     *  Sets the room bandwidth. Valid values include the following: 
		 * <ul>
		 * <li><code>LAN</code></li>
		 * <li><code>dsl</code></li>
	     * <li><code>modem</code></li>
		 * <li><code>auto</code></li>
		 * </ul>
	     *  @default AUTO
	     */
	    public function get roomBandwidth():String
	    {
	        return _roomBandWidth;
	    }
	
	    /**
	     *  @private
	     */
	    public function set roomBandwidth(value:String):void
	    {
	        _roomBandWidth = value;
	    }
		
		//----------------------------------
	    //  autoPromote
	    //----------------------------------
	    /**
	     *  @private
	     *  Storage for autoPromote property.
	     */
	    private var _autoPromote:Boolean = false;
	
	    [Inspectable(category="General", enumeration="true,false", defaultValue="false")]
	
	    /**
	     *  Automatically promotes someone with a viewer role to a publisher role when they enter the room.
         * 
	     *  @default false
	     */
	    public function get autoPromote():Boolean
	    {
	        return _autoPromote;
	    }
	
	    /**
	     *  @private
	     */
	    public function set autoPromote(value:Boolean):void
	    {
	        _autoPromote = value;
	    }
	    
	    //----------------------------------
	    //  roomState
	    //----------------------------------
	    /**
	     *  @private
	     *  Storage for roomState property.
	     */
	    private var _roomState:String = ROOM_STATE_ACTIVE;
	
	    [Inspectable(category="General", enumeration="active,hostNotArrived,ended,onhold", defaultValue="active")]
	
	    /**
	     *  Sets the state of the room. Valid values include the following: 
		 * <ul>
		 * <li>active</li>
		 * <li>hostNotArrived</li>
		 * <li>ended</li>
		 * <li>onhold</li>
		 * </ul> 
	     *
	     *  @default active
	     */
	    public function get roomState():String
	    {
	        return _roomState;
	    }
	
	    /**
	     *  @private
	     */
	    public function set roomState(value:String):void
	    {
	        _roomState = value;
	    }
	    
	    //----------------------------------
	    //  guestsMustKnock
	    //----------------------------------
	    /**
	     *  @private
	     *  Storage for guestsMustKnock property.
	     */
	    private var _guestsMustKnock:Boolean = false;
	
	    [Inspectable(category="General", enumeration="true,false", defaultValue="false")]
	
	    /**
	     *  Requires guests to ask for permission before entering the room.
	     *  
	     *  @default false
	     */
	    public function get guestsMustKnock():Boolean
	    {
	        return _guestsMustKnock;
	    }
	
	    /**
	     *  @private
	     */
	    public function set guestsMustKnock(value:Boolean):void
	    {
	        _guestsMustKnock = value;
	    }

		
	}
}