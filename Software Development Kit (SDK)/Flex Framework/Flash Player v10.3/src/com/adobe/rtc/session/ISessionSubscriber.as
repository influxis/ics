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

	/**
	 * Dispatched when the component either loses its connection to the session or regains it
	 * and has finished re-synchronizing itself to the rest of the room
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	

	/**
	 * ISessionSubscriber is the interface which real-time collaboration (RTC) components expose in order to:
	 * <ul>
	 * <li>Work in applications with more than one IConnectSession.</li>
	 * <li>Define their logical location on the service.</li>
	 * <li>Synchronize with the service.</li>
	 * <li>Disconnect from the service.</li>
	 * </ul>
	 * This set of functionality is exposed by nearly all RTC components in the framework. Developers building their own
	 * RTC components should implement this interface as well, to support the above.
	 * 
	 * @see com.adobe.rtc.session.IConnectSession
	 * @see com.adobe.rtc.sharedModel.CollectionNode
	 * @see com.adobe.rtc.session.sessionClasses.SessionContainerProxy
	 */
	public interface ISessionSubscriber
	{
		/**
		 * The IConnectSession with which this component is associated. 
		 * Note that this may only be set once before <code>subscribe()</code>
		 * is called; re-sessioning of components is not supported. Defaults 
		 * to the first IConnectSession created in the application.
		 */
		function get connectSession():IConnectSession;
		function set connectSession(p_session:IConnectSession):void;

		/**
		 * Defines the logical location of the component on the service - typically this assigns the sharedID of the collectionNode
		 * used by the component. sharedIDs should be unique within a room (if they're expressing 2 unique locations). Note that
		 * this can only be assigned once (before <code>subscribe()</code> is called). For components with an <code class="property">id</code> property, 
		 * <code class="property">sharedID</code> defaults to that value.
		 */
		function get sharedID():String;
		function set sharedID(p_id:String):void;

		/**
		 * Returns whether or not the component has fully synched up to the service; 
		 * that is, whether it is connected and has all information stored on the service 
		 * regarding it. Generally, such components cannot have their APIs used while 
		 * in a non-synchronized state. <code>synchronizationChange</code> events are 
		 * dispatched to indicate this value changing.
		 */		
		function get isSynchronized():Boolean ;

		/**
		 * Disposes all listeners to the network and framework classes. 
		 * Recommended for proper garbage collection of the component.
		 */
		function close():void ;
		
		/**
		 * Tells the component to begin synchronizing with the service. For UIComponent-based components, this will be called automatically
		 * upon being added to the displayList. For "headless" components, this method must be called explicitly.
		 */
		function subscribe():void;		
	}
}