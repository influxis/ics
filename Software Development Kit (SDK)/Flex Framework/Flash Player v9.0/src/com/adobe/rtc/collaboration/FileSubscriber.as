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
package com.adobe.rtc.collaboration
{
	import com.adobe.coreUI.localization.ILocalizationManager;
	import com.adobe.coreUI.localization.Localization;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.FileManagerEvent;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
	import com.adobe.rtc.sharedManagers.FileManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.FileDescriptor;
	import com.adobe.rtc.sharedModel.CollectionNode;
	import com.adobe.rtc.util.Invalidator;
	
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	
	import mx.core.UIComponent;
	import mx.core.UIComponentGlobals;

	
	
	/**
	 * Dispatched on download completion.
	 */
	[Event(name="complete", type="flash.events.Event")]	

	/**
	 * Dispatched on httpStatus.
	 */
	[Event(name="httpStatus", type="flash.events.HTTPStatusEvent")]	

	/**
	 * Dispatched on an IO error.
	 */
	[Event(name="ioError", type="flash.events.IOErrorEvent")]	

	/**
	 * Dispatched on a security error.
	 */
	[Event(name="securityError", type="flash.events.SecurityErrorEvent")]	

	/**
	 * Dispatched as a download progresses.
	 */
	[Event(name="progress", type="flash.events.ProgressEvent")]	
	
	/**
	 * Dispatched when the component either loses its connection to the session or regains it
	 * and has finished re-synchronizing itself to the rest of the room.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]


	/**
	 * FileSubscriber is a simple helper class that enables file download as specified 
	 * by a FileDescriptor. A developer should use the FileManager's events and methods in order to see 
	 * what files are available in a room. For details about a higher level component with a user interface which 
	 * allows for uploading, listing, and downloading files, see com.adobe.rtc.pods.FileShare.
	 * 
	 * @see com.adobe.rtc.sharedManagers.FileManager
	 * @see com.adobe.rtc.sharedManagers.descriptors.FileDescriptor
	 * @see com.adobe.rtc.collaboration.FileSubscriber
	 * @see com.adobe.rtc.pods.FileShare
	 */
	
   public class  FileSubscriber extends UIComponent implements ISessionSubscriber
	{
		/**
		 * @private
		 */
		protected var _model:FileManager;
		
		/**
		 * @private
		 */
		protected var _fileReference:FileReference;
		
		/**
		 * @private
		 */
		protected var _userManager:UserManager;
		
		/**
		 * @private
		 */
		protected var _lm:ILocalizationManager = Localization.impl;
		
		/**
		 * @private
		 */
		protected var _accessModel:int = -1 ;
		
		/**
		 * @private
		 */
		protected var _publishModel:int = -1 ;
		
		/**
		 * @private
		 */
		protected var _groupName:String = "defaultFileGroup";	
		
		/**
		 * @private
		 */
		 protected const invalidator:Invalidator = new Invalidator();
		
		/**
		 * @private
		 */
		 protected var _sharedID:String;
		 
		 /**
		  * @private
		  */
		 protected var _subscribed:Boolean = false ;
		 
		 /**
		  * @private 
		  */		
		 protected var _connectSession:IConnectSession = new SessionContainerProxy(this as UIComponent);
		
		
		public function FileSubscriber():void
		{
			super();
			invalidator.addEventListener(Invalidator.INVALIDATION_COMPLETE,onInvalidate);
		}
		
		// FLeX Begin
		/**
		 * @private
		 */
		override public function initialize():void
		{
			super.initialize();
			
			if ( !_subscribed ) {
				subscribe();
				_subscribed = true ;
			}
		}
		// FLeX End
		
		[Bindable(event="synchronizationChange")]
		/**
		 * Returns true if the model is synchronized.
		 */
		public function get isSynchronized():Boolean
		{
			if ( !_model ) {
				return false ;
			}
			
			return _model.isSynchronized ;
		}
		
		/**
		 * Disposes all listeners to the network and framework classes and 
		 * is recommended for proper garbage collection of the component.
		 */
		public function close():void
		{
			if ( _fileReference ) {
				_fileReference.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
				_fileReference.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
				_fileReference.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				_fileReference.removeEventListener(ProgressEvent.PROGRESS, onProgress);
				_fileReference.removeEventListener(Event.COMPLETE, onComplete);
			}
			if (_model) {
				_model.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE,onSynchronizationChange);
				
			}
		
		}
		
		/**
		 * Defines the logical location of the component on the service; typically this assigns the <code class="property">sharedID</code> of the collectionNode
		 * used by the component. <code class="property">sharedIDs</code> should be unique within a room if they're expressing two 
		 * unique locations. Note that this can only be assigned once before <code>subscribe()</code> is called. For components 
		 * with an <code class="property">id</code> property, <code class="property">sharedID</code> defaults to that value.
		 */
		public function set sharedID(p_id:String):void
		{
			_sharedID = p_id;
		}
		
		/**
		 * @private
		 */
		public function get sharedID():String
		{
			return _sharedID;
		}

		/**
		 * The IConnectSession with which this component is associated; it defaults to the first 
		 * IConnectSession created in the application.  Note that this may only be set once before 
		 * <code>subscribe()</code> is called, and re-sessioning of components is not supported.
		 */
		public function get connectSession():IConnectSession
		{
			return _connectSession;
		}
		
		public function set connectSession(p_session:IConnectSession):void
		{
			_connectSession = p_session;
		}
		
		/**
		 * Subscribes to a particular stream.
		 */
		public function subscribe():void
		{
			
			if ( !_userManager ) {
				_userManager = _connectSession.userManager;
			}
   			
   			if(!_model){
				_model = _connectSession.fileManager;
				_model.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE,onSynchronizationChange);
			}
			
			if (!_fileReference) {
				_fileReference = new FileReference();
				_fileReference.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
				_fileReference.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
				_fileReference.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				_fileReference.addEventListener(ProgressEvent.PROGRESS, onProgress);
				_fileReference.addEventListener(Event.COMPLETE, onComplete);
			}

		}
		
		
		/**
		 * Sets the role of a given user for subscribing to files within this component's group
		 * specified by <code class="property">groupName</code>.
		 * 
		 * @param p_userID The user ID of the user whose role should be set.
		 * @param p_userRole The role value to assign to the user with this user ID.
		 */
		public function setUserRole(p_userID:String ,p_userRole:int):void
		{
			if ( p_userID == null ) 
				return ;
				
			
			if ( (p_userRole < 0 || p_userRole > 100) && p_userRole != CollectionNode.NO_EXPLICIT_ROLE ) 
				return ; 
				
			_model.setUserRole(p_userID,p_userRole,_groupName);
		}
		
		
		/**
		 * Returns the role of a given user for files, within the group this component is assigned to.
		 * 
		 * @param p_userID The user ID of the user whose role we should get.
		 */
		public function getUserRole(p_userID:String):int
		{
			return _model.getUserRole(p_userID,_groupName);
		}
		
		
		/**
		 * Gets the NodeConfiguration on a specific file group. 
		 */
		public function getNodeConfiguration():NodeConfiguration
		{	
			return _model.getNodeConfiguration(_groupName).clone();
		}
		
		/**
		 * Sets the NodeConfiguration.
		 * @param p_nodeConfiguration The node Configuration of the file group.
		 * 
		 */
		public function setNodeConfiguration(p_nodeConfiguration:NodeConfiguration):void
		{	
			_model.setNodeConfiguration(p_nodeConfiguration,_groupName);
			
		}
		
		/**
		 * Downloads the file specified by the supplied FileDescriptor. The User will be prompted to save the file to their
		 * file system.
		 * 
		 * @param p_fileDescriptor A FileDescriptor representing the file to download. For details about
		 * accessing a list of files available in the room, see FileManager's APIs.
		 */
		public function download(p_fileDescriptor:FileDescriptor):void
		{
			var ticket_token:String = "?mst="+ _userManager.myTicket+"&token="+p_fileDescriptor.token;
			
			try {
				_fileReference.download(new URLRequest(p_fileDescriptor.url + p_fileDescriptor.filename + ticket_token), p_fileDescriptor.name);							
			}catch(e:Error) {
				throw e;
			}
		}
		/**
		 * @private
		 */
		public function set publishModel(p_publishModel:int):void
		{	
			
			_publishModel = p_publishModel ;
			invalidator.invalidate();	
		}
		
		/**
		 * The role required for this component to publish to the group specified by <code class="property">groupName</code>.
		 */
		public function get publishModel():int
		{
			return _model.getNodeConfiguration(_groupName).publishModel;
		}
		
		/**
		 * @private
		 */
		public function set accessModel(p_accessModel:int):void
		{	
			_accessModel = p_accessModel ;
			invalidator.invalidate();
		}
		
		/**
		 * The role value required for accessing files associated with this component's group as
		 * specified by <code class="property">groupName</code>.
		 */
		public function get accessModel():int
		{
			return _model.getNodeConfiguration(_groupName).accessModel;
		}
	
		/**
		 * @private
		 */
		protected function onIoError(p_event:IOErrorEvent):void
		{
			if(p_event.text.indexOf("2038") > 0) {				
				showAlertMessage("Error Downloading File");
			}
			else {
				showAlertMessage(p_event.text);
				//dispatchEvent(p_event);
			}
		}
		
		/**
		 * @private
		 */
		protected function onSecurityError(p_event:SecurityErrorEvent):void
		{
			showAlertMessage(p_event.text);
			//dispatchEvent(p_event);
		}
		
		/**
		 * @private
		 */
		protected function onHttpStatus(p_event:HTTPStatusEvent):void
		{
			showAlertMessage(p_event.type);
			//dispatchEvent(p_event);
		}
		
		/**
		 * @private
		 */
		protected function onProgress(p_event:ProgressEvent):void
		{
			dispatchEvent(p_event);
		}
		
		/**
		 * @private
		 */
		protected function onComplete(p_event:Event):void
		{
			dispatchEvent(p_event);
		}

		/**
		 * @private
		 */
		protected function showAlertMessage(message:String):void
		{
			var event:FileManagerEvent = new FileManagerEvent(FileManagerEvent.FILE_ALERT);
			event.alertMessage = _lm.getString(message);
			dispatchEvent(event);											
		}
		
		public function set groupName(p_value:String):void
		{
			_groupName = p_value;
		}
		
		/**
		 * Components (pods) are assigned to a group via <code class="property">groupName</code>; if not specified, 
		 * the component is assigned to the default, public group (the room at large). Groups are like separate 
		 * conversations within the room, but each conversation could employ one or more pods; for example, one 
		 * "conversation" may use a web camera, chat, and whiteboard pod, with each pod using different access 
		 * and publish models. Users are members of and can only see components within the group they are assigned. 
		 * Room hosts can see all the groups and all the members in those groups.
		 */
		public function get groupName():String
		{
			return _groupName;
		}	
		/**
		 * @private
		 */
		protected function onInvalidate(p_evt:Event):void
        {  

			if ( _publishModel != -1 || _accessModel != -1 ) {
				var nodeConf:NodeConfiguration = _model.getNodeConfiguration(_groupName);
				
				if ( nodeConf.accessModel != _accessModel && _accessModel != -1 ) {
					nodeConf.accessModel = _accessModel ;
					_accessModel = -1 ;
				}
			
				if ( nodeConf.publishModel != _publishModel && _publishModel != -1 ) {
					nodeConf.publishModel = _publishModel ;
					_publishModel = -1 ;
				}
				
				_model.setNodeConfiguration(nodeConf,_groupName);	
						
			}
        }
        
        /**
         * @private
         */
        protected function onSynchronizationChange(p_evt:CollectionNodeEvent):void
        {
        	dispatchEvent(p_evt);
        }
        
        
		// FLeX Begin
		/**
		 * @private
		 */
		override protected function measure():void
		{
			super.measure();
			
			if ( UIComponentGlobals.designMode ) {
        		minHeight = 40 ;
        		minWidth = 100 ;
        	}
		}
		// FLeX End

	}
}
