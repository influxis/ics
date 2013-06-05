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
	import flash.events.IEventDispatcher;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.events.SessionEvent;
	import com.adobe.rtc.session.managers.SessionManagerAdobeHostedServices;
	import com.adobe.rtc.events.RoomTemplateEvent;

	/**
	 * Dispatched when the room has been successfully saved as a template.
	 */
	[Event(name="templateSave", type="com.adobe.rtc.events.RoomTemplateEvent")]	


	/**
	 * RoomTemplater allows developers to create templates from their existing rooms.
	 * For example, when your create a room with a chat, note, and whiteboard, then that room's
	 * CollectionNodes and settings are stored on the service. Since setting up a room and 
	 * customizing it often represents a substantial amount of work, LCCS allows you to save
	 * your rooms as templates. Templates not only eliminate duplication of effort, but they also
	 * enable creating new rooms on-the-fly without requiring an OWNER to be in the room to recreate them.
	 * In other words, templates allow you to set up a new room with preconfigured CollectionNodes, nodes, 
	 * configurations, items, and room settings without having to be present.
	 *
 	 * <h6>Templating a room with a chat node</h6>
 	 *	<listing>
	 *	&lt;util:RoomTemplater id="templater"/&gt;
	 * &lt;rtc:AdobeHSAuthenticator 
	 * 			// Deployed applications DO NOT hard code username and password here.
	 * 			userName="AdobeIDusername&#64;example.com" 
	 * 			password="AdobeIDpassword" 
	 * 			id="auth"/&gt;	
	 * &lt;session:ConnectSessionContainer 
	 *			roomURL="http://connect.acrobat.com/fakeAccount/fakeRoom" 
	 *			authenticator="{auth}"&gt;
	 * 			&lt;mx:VBox&gt;
	 *					&lt;pods:SimpleChat id="publicChat"/&gt;
	 * 					&lt;mx:Button label="Save" click="templater.saveRoomAsTemplate('myTemplateName');"/&gt;
	 * 			&lt;/mx:VBox&gt;
 	 * &lt;/session:ConnectSessionContainer&gt;</listing>
	 * <blockquote>
	 * <b>Note</b>: You can save rooms as templates programmatically or via the Room Console.
	 * </blockqoute>
	 * <p>
	 * <img src="../../../../devimages/dc_saveastemplate.gif" width="402" height="268" alt="">
	 * 
	 * @see com.adobe.rtc.util.AccountManager 
	 * @see com.adobe.rtc.session.RoomSettings 
	 * 
	 */
   public class  RoomTemplater extends EventDispatcher
	{
		public function RoomTemplater()
		{
		}
		
		/**
		* AdobePatentID="P686"
		*/
		private const Adobe_patent_B1042 = "AdobePatentID=\"B1042\"";		
		
		/**
		 * The IConnectSession with which this component is associated. Defaults to the first IConnectSession
		 * instance created.
		 */
		public var connectSession:IConnectSession = ConnectSession.primarySession;
		
		/**
		 * Saves the room corresponding to the current IConnectSession as a template with the provided name. Templates
		 * may be used for provisioning new rooms that are pre-populated with CollectionNodes. Note that the IConnectSession
		 * must be fully synchronized for this method to work.
		 * 
		 * @param p_name The name of the template to store. Using an existing name overwrites that template.
		 * 
		 */
		public function saveRoomAsTemplate(p_name:String):void
		{
			if ( p_name.length > 15 ) {
				throw new Error("The Template Name can't be more than 15 characters");
				return ;
			}
			
			var sMgr:SessionManagerAdobeHostedServices = connectSession.sessionInternals.session_internal::sessionManager;
			sMgr.addEventListener(SessionEvent.TEMPLATE_SAVE, onTemplateSave);
			sMgr.saveToTemplate(p_name);
		}
		
		/**
		 * @private
		 */
		protected function onTemplateSave(p_evt:SessionEvent):void
		{
			EventDispatcher(p_evt.target).removeEventListener(SessionEvent.TEMPLATE_SAVE, onTemplateSave);
			dispatchEvent(new RoomTemplateEvent(RoomTemplateEvent.TEMPLATE_SAVE, p_evt.templateName));
		}
		
	}
}