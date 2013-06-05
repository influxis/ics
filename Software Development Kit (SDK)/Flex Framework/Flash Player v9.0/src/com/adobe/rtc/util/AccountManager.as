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
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import com.adobe.rtc.authentication.AbstractAuthenticator;
	import com.adobe.rtc.session.sessionClasses.MeetingInfoService;
	import com.adobe.rtc.events.MeetingInfoEvent;
	import com.adobe.rtc.events.AuthenticationEvent;
	import com.adobe.rtc.events.AccountManagerEvent;

	/**
	 * Dispatched when a call to <code>requestTemplateList</code> has returned.
	 */
	[Event(name="templateListReceive", type="com.adobe.rtc.events.AccountManagerEvent")]
	/**
	 * Dispatched when a call to <code>requestRoomList</code> has returned.
	 */
	[Event(name="roomListReceive", type="com.adobe.rtc.events.AccountManagerEvent")]
	/**
	 * Dispatched when a call to <code>requestArchiveList</code> has returned.
	 */
	[Event(name="archiveListReceive", type="com.adobe.rtc.events.AccountManagerEvent")]	
	/**
	 * Dispatched when a call to <code>createRoom</code> has returned.
	 */
	[Event(name="roomCreate", type="com.adobe.rtc.events.AccountManagerEvent")]
	/**
	 * Dispatched when a call to <code>deleteRoom</code> has returned.
	 */
	[Event(name="roomDelete", type="com.adobe.rtc.events.AccountManagerEvent")]
	/**
	 * Dispatched when a call to <code>createTemplate</code> has returned.
	 */
	[Event(name="templateClone", type="com.adobe.rtc.events.AccountManagerEvent")]
	/**
	 * Dispatched when a call to <code>deleteTemplate</code> has returned.
	 */
	[Event(name="templateDelete", type="com.adobe.rtc.events.AccountManagerEvent")]
	/**
	 * Dispatched when a call to <code>login</code> to the service has succeeded.
	 */
	[Event(name="loginSuccess", type="com.adobe.rtc.events.AccountManagerEvent")]
	/**
	 * Dispatched when a call to <code>login</code> to the service has failed.
	 */
	[Event(name="loginFailure", type="com.adobe.rtc.events.AccountManagerEvent")]
	/**
	 * Dispatched when a request fails
	 */
	[Event(name="accessError", type="com.adobe.rtc.events.AccountManagerEvent")]

	/**
	 * The AccountManager class enables the developer to build Flex applications which dynamically create rooms, 
	 * list templates and rooms, and delete templates and rooms. It makes use of an upcoming REST-based API for the service 
	 * which allows server-to-server calls to provide this functionality. The REST API is still being refined; 
	 * for the time being this component allows developers to prototype dynamic room creation and management with an 
	 * interface that will remain constant. 
	 * 
	 * Note: As the REST API changes underneath it, this class will be updated.
	 * 
	 * @see com.adobe.rtc.util.RoomTemplater
	 */
   public class  AccountManager extends EventDispatcher
	{
		/**
		 * @private
		 */
		protected var _meetingInfo:MeetingInfoService;
		/**
		 * @private
		 */
		protected var _templateReqPending:Boolean = false;
		/**
		 * @private
		 */
		protected var _templateDeletePendingName:String;
		/**
		 * @private
		 */
		protected var _templateClonePendingName:String;
		/**
		 * @private
		 */
		protected var _roomDeletePendingName:String;
		/**
		 * @private
		 */
		protected var _roomCreatePendingName:String;
		/**
		 * @private
		 */
		protected var _roomCreateTemplateName:String;
		/**
		 * @private
		 */
		protected var _roomListPending:Boolean = false;
		/**
		 * @private
		 */
		protected var _archiveListPending:Boolean = false;
		
		public function AccountManager()
		{
			
		}
		
		/**
		 * The developer's account URL. This is typically the URL of a room with the last branch of the path removed. 
		 * For example, if roomURL="https://connectnow.acrobat.com/fakeaccount/fakeroom", then 
		 * accountURL="https://connectnow.acrobat.com/fakeaccount".
		 */
		public var accountURL:String;
		
		/**
		 * An authenticator (AdobeHSAuthenticator) as used with an IConnectSession.
		 */
		public var authenticator:AbstractAuthenticator;
		[Bindable(event="loginSuccess")]
		
		/**
		 * (Read-Only) Specifies whether or not the AccountManager has completed authentication and logging in. 
		 * Login is necessary before any other calls can be executed. 
		 */
		public var isAuthenticated:Boolean = false;
            
        /**
         * (Read-Only) Specifies whether or not the account is an SDK account
         */
        public var isSDKAccount:Boolean = false;
		
		/**
		 * Logs into the service. Note that an <code>accountURL</code> and <code>authenticator</code> are required before 
		 * this method may be called. Also note that the account manager must be logged in for any subsequent calls to work.
		 */
		public function login():void
		{
			_meetingInfo = new MeetingInfoService(accountURL, authenticator);
			authenticator.addEventListener(AuthenticationEvent.AUTHENTICATION_SUCCESS, onAuthEvent);
			authenticator.addEventListener(AuthenticationEvent.AUTHENTICATION_FAILURE, onAuthEvent);
			_meetingInfo.addEventListener(MeetingInfoEvent.INFO_RECEIVE, onInfoReceive);
			_meetingInfo.addEventListener(MeetingInfoEvent.ITEMS_RECEIVE, onItemsReceive);
			_meetingInfo.addEventListener("error", onError);
			_meetingInfo.requestAccountInfo();
		}
		
		/**
		 * Creates a new room on the service under the current account. 
		 * 
		 * @param p_roomName The name of the new room.
		 * @param p_templateName The name of the template to use in creating the room. If null, the default template is used.
		 */
		public function createRoom(p_roomName:String, p_templateName:String=null):void
		{
			if (!isAuthenticated) {
				throw new Error("You must be authenticated to create a room.");
				return;
			}
			_roomCreatePendingName = p_roomName;
			_roomCreateTemplateName = p_templateName;
			_meetingInfo.createRoom(p_roomName, p_templateName);
		}
		
		/**
		 * Deletes a specified room from the service.
		 *  
		 * @param p_roomName The name of the room to delete (room name only--not the entire path).
		 * @param p_templateName Optional. The name of the template from which the room came. 
		 * Including the template name causes the ROOM_DELETE
		 * event to include the <code>templateName</code>; ommitting <code>roomName</code> has no effect.
 		 */
		public function deleteRoom(p_roomName:String, p_templateName:String=null):void
		{
			if (!isAuthenticated) {
				throw new Error("You must be authenticated to delete the room.");
				return;
			}
			_roomDeletePendingName = p_roomName;
			_templateDeletePendingName = p_templateName;
			_meetingInfo.deleteItem(p_roomName, MeetingInfoService.ROOM_ITEMS);
		}

		/**
		 * Requests a list of all archives under the current account. An <code>AccountManagerEvent.ARCHIVE_LIST_RECEIVE</code>
		 * event is dispatched with the result.
		 */
		public function requestArchiveList():void
		{
			if (!isAuthenticated) {
				throw new Error("You must be authenticated to access the archive list.");
				return;
			}
			_archiveListPending = true;
			_meetingInfo.requestItems(MeetingInfoService.ARCHIVE_ITEMS);
		}
		
		/**
		 * Requests a list of all rooms under the current account. An <code>AccountManagerEvent.ROOM_LIST_RECEIVE</code>
		 * event is dispatched with the result.
		 */
		public function requestRoomList():void
		{
			if (!isAuthenticated) {
				throw new Error("You must be authenticated to access the room list.");
				return;
			}
			_roomListPending = true;
			_meetingInfo.requestItems(MeetingInfoService.ROOM_ITEMS);
		}
		
		/**
		 * Requests a list of all templates under the current account. An <code>AccountManagerEvent.TEMPLATE_LIST_RECEIVE</code>
		 * event is dispatched with the result.
		 */
		public function requestTemplateList():void
		{
			if (!isAuthenticated) {
				throw new Error("You must be authenticated to access the templates.");
				return;
			}
			_templateReqPending = true;
			_meetingInfo.requestItems(MeetingInfoService.TEMPLATE_ITEMS);
		}
		
		/**
		 * Creates a new template on the service under the current account. 
		 * 
		 * @param p_templateName The name of the new template
		 */
		public function cloneDefaultTemplate(p_templateName:String):void
		{
			if (!isAuthenticated) {
				throw new Error("You must be authenticated to create a template.");
				return;
			}
			_templateClonePendingName = p_templateName;
			_meetingInfo.cloneDefaultTemplate(p_templateName);
		}
		
		/**
		 * Deletes the specified template. Deleting a template results in all the rooms based on that
		 * template begin moved to the default template. However the room's configuration does not change.
		 */
		public function deleteTemplate(p_templateName:String):void
		{
			if (!isAuthenticated) {
				throw new Error("You must be authenticated to delete templates.");
				return;
			}
			_templateDeletePendingName = p_templateName;
			_meetingInfo.deleteItem(p_templateName, MeetingInfoService.TEMPLATE_ITEMS);
		}
        
		/**
		 * @private
		 */
		protected function onAuthEvent(p_evt:AuthenticationEvent):void
		{
			authenticator.removeEventListener(p_evt.type, onAuthEvent);
            
            if (p_evt.type == AuthenticationEvent.AUTHENTICATION_SUCCESS)
                _meetingInfo.requestAccountInfo();
            else
				dispatchEvent(new AccountManagerEvent(AccountManagerEvent.LOGIN_FAILURE));
		}
		
		/**
		 * @private
		 */
		protected function onInfoReceive(p_evt:MeetingInfoEvent):void
		{
			if (!isAuthenticated) {
				isAuthenticated = true;
                
                var room:String = _meetingInfo.roomName;
                isSDKAccount = (room != null && room.slice(-10) != "/mymeeting");
				dispatchEvent(new AccountManagerEvent(AccountManagerEvent.LOGIN_SUCCESS));
				return;
			}
			var e:AccountManagerEvent = new AccountManagerEvent(AccountManagerEvent.ROOM_CREATE);
			e.roomName = _roomCreatePendingName;
			e.templateName = _roomCreateTemplateName;
			dispatchEvent(e);
		}
		
		/**
		 * @private
		 */
		protected function onItemsReceive(p_evt:MeetingInfoEvent):void
		{
			var e:AccountManagerEvent;
			if (_roomDeletePendingName) {
				e = new AccountManagerEvent(AccountManagerEvent.ROOM_DELETE);
				e.roomName = _roomDeletePendingName;
				e.templateName = _templateDeletePendingName;
				dispatchEvent(e);
				_roomDeletePendingName = null;
			} else if (_templateClonePendingName) {
				e = new AccountManagerEvent(AccountManagerEvent.TEMPLATE_CLONE);
				e.roomName = null;
				e.templateName = _templateClonePendingName;
				dispatchEvent(e);
				_templateClonePendingName = null;
			} else if (_templateDeletePendingName) {
				e = new AccountManagerEvent(AccountManagerEvent.TEMPLATE_DELETE);
				e.templateName = _templateDeletePendingName;
				dispatchEvent(e);
				_templateDeletePendingName = null;
			} else if (_roomListPending) {
				e = new AccountManagerEvent(AccountManagerEvent.ROOM_LIST_RECEIVE);
				e.list = p_evt.items;
				dispatchEvent(e);
				_roomListPending = false;
			} else if (_archiveListPending) {
				e = new AccountManagerEvent(AccountManagerEvent.ARCHIVE_LIST_RECEIVE);
				e.list = p_evt.items;
				dispatchEvent(e);
				_archiveListPending = false;				
			} else if (_templateReqPending) {
				e = new AccountManagerEvent(AccountManagerEvent.TEMPLATE_LIST_RECEIVE);
				e.list = p_evt.items;
				dispatchEvent(e);
				_templateReqPending = false;
			}
		}
        
        protected function onError(p_evt:Event):void
        {
            			// notify our clients someting went wrong
			if (hasEventListener(AccountManagerEvent.ACCESS_ERROR))
				dispatchEvent(new AccountManagerEvent(AccountManagerEvent.ACCESS_ERROR));
			else 
				throw new Error(p_evt);
        }
	}
}
