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
	import com.adobe.rtc.util.ISO9075;
	import com.adobe.rtc.util.Invalidator;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.core.UIComponent;
	import mx.core.UIComponentGlobals;

	 
	 
	/**
	 * Dispatched on upload completion.
	 */
	[Event(name="complete", type="flash.events.Event")]	

	/**
	 * Dispatched on upload progress.
	 */
	[Event(name="progress", type="flash.events.ProgressEvent")]	

	/**
	 * Dispatched on file select for upload.
	 */
	[Event(name="select", type="flash.events.Event")]	
	/**
	 * Dispatched when the component either loses its connection to the session or regains it
	 * and has finished re-synchronizing itself to the rest of the room.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]


	/**
	 * FilePublisher is a foundation component for supporting file uploads 
	 * as well as notification to other users that a file has been uploaded.
	 * It only supports one upload at a time.  Additionally, it optionally plays an animation 
	 * while an upload is in progress. It is normally invisible, but it becomes visible 
	 * when an upload begins; on completion, it disappears again.
	 * <p>
	 * Files are organized logically in LCCS as <i>groups</i> in the FileManager, 
	 * which allows the developer to assign permissions and roles on a group-by-group
	 * basis. FilePublisher acts as an easy to use proxy for the FileManager in creating and 
	 * uploading files to groups. FilePublisher is intended as a low-level component; for a 
	 * higher level component with a user interface which supports uploading, listing, and 
	 * downloading files, see com.adobe.rtc.pods.FileShare.
	 * </p>
	 * <p>
	 * By default, a user must have a role higher than <code>UserRoles.PUBLISHER</code> to 
	 * upload a file, and use <code>UserRoles.VIEWER</code> to receive one.
	 * </p>
	 * @see com.adobe.rtc.sharedManagers.FileManager
	 * @see com.adobe.rtc.sharedManagers.descriptors.FileDescriptor
	 * @see com.adobe.rtc.collaboration.FileSubscriber
	 * @see com.adobe.rtc.pods.FileShare
 	 */
	
   public class  FilePublisher extends UIComponent implements ISessionSubscriber
	{
		/**
		 * The set of invalid characters in a file name.
		 */
		public static const INVALID_FILENAME_CHARS:String = "?\/\\<>*:\",|%";
		
		/**
		 * @private
		 */
		protected var _model:FileManager;
		/**
		 * @private
		 */
		protected var _userManager:UserManager;
		/**
		 * @private
		 */
		protected var _fileManager:FileManager;
		/**
		 * @private
		 */
		protected var _fileReference:FileReference;
		/**
		 * @private
		 */
		protected var _typeFilter:Array;	
		
		/**
		 * @private
		 */
		protected var _background:Sprite;
		//protected var _progressLabel:Label;
		
		/**
		 * @private
		 */
		protected var _progressTimer:Timer;
		/**
		 * @private
		 */
		protected var _progressInterval:Number = 500;
		
		/**
		 * @private
		 */
		protected var _uploadFileDescriptor:FileDescriptor;		// the fileDescriptor of the file currently uploading
		/**
		 * @private
		 */
		protected var _uploadFileID:String;
		
		/**
		 * @private
		 */
		protected var _groupName:String = "defaultFileGroup";						// name of the permission group (node) to upload to
		
		// We can't check on upload progress synchronously.  Instead we must wait for the FileReference to
		//   dispatch the ProgressEvent.PROGRESS event.  Here is where to save the value in between progress
		//   timer pulses.
		/**
		 * @private
		 */
		protected var _lastBytesLoaded:Number;
		
		/**
		 * @private
		 */
		protected const MODE_BROWSE:Boolean = false;
		/**
		 * @private
		 */
		protected const MODE_UPLOAD:Boolean = true;
		
		/**
		 * @private
		 */
		protected var _uploadMode:Boolean = MODE_BROWSE;
		
		/**
		 * @private
		 */
		protected var _baseURL:String;
		
		//protected var _useSSL:Boolean = true;
		
		/**
		 * @private
		 */
		protected var _lm:ILocalizationManager = Localization.impl;
		
		/**
		 * @private
		 */
		private var _fileBrowseOn:Boolean = false;	
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
			
		/**
		 * Constructor.
		 */
		public function FilePublisher():void
		{
			super();
			
			invalidator.addEventListener(Invalidator.INVALIDATION_COMPLETE,onInvalidate);
		}
		
		
		/**
		 * @private
		 */
		override public function initialize():void
		{
			super.initialize();
			
			
			if(!_fileReference) {
				_fileReference = new FileReference();
				_fileReference.addEventListener(Event.SELECT, onSelect);
				_fileReference.addEventListener(Event.COMPLETE, onComplete);
				_fileReference.addEventListener(Event.CANCEL, onCancel);
				_fileReference.addEventListener(ProgressEvent.PROGRESS, onProgress);
				_fileReference.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
				_fileReference.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
								
			}
			
			progressInterval = _progressInterval; // force setter to run
   			_fileBrowseOn = false;
		}
		
		
		[Bindable(event="synchronizationChange")]
		/**
		 * Returns true if the model is synchronized
		 */
		public function get isSynchronized():Boolean
		{
			if ( !_model ) {
				return false ;
			}
			
			return _model.isSynchronized ;
		}
		
		
		/**
		 * Disposes all listeners to the network and framework classes. 
		 * Recommended for proper garbage collection of the component.
		 */
		public function close():void
		{
			if ( _fileReference ) {
				_fileReference.removeEventListener(Event.SELECT, onSelect);
				_fileReference.removeEventListener(Event.COMPLETE, onComplete);
				_fileReference.removeEventListener(Event.CANCEL, onCancel);
				_fileReference.removeEventListener(ProgressEvent.PROGRESS, onProgress);
				_fileReference.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
				_fileReference.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			}
			
			if ( _model ) {
				_model.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
				_model.removeEventListener(FileManagerEvent.READY_FOR_UPLOAD, onReadyForUpload);
			}
		}
		
		/**
		 *  Returns the role of a given user for files, within the group this component is assigned to.
		 * 
		 * @param p_userID The user ID of the user whose role we should get.
		 */
		public function getUserRole(p_userID:String):int
		{
			return _model.getUserRole(p_userID,_groupName);
		}
		
		/**
		 * Sets the role of a given user for publishing and subscribing to this component's group
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
		 * Gets the NodeConfiguration on the file group. 
		 */
		public function getNodeConfiguration():NodeConfiguration
		{	
			return _model.getNodeConfiguration(_groupName).clone();
		}
		
		/**
		 * Sets the NodeConfiguration.
		 * @param p_nodeConfiguration The node Configuration of the file group
		 * 
		 */
		public function setNodeConfiguration(p_nodeConfiguration:NodeConfiguration):void
		{	
			_model.setNodeConfiguration(p_nodeConfiguration,_groupName);
			
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
		 * The role value required for accessing files, for the group this component is assigned to
		 */
		public function get accessModel():int
		{
			return _model.getNodeConfiguration(_groupName).accessModel;
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
		 * Tells the component to begin synchronizing with the service. For UIComponent-based components such as this one,
		 * this is called automatically upon being added to the <code class="property">displayList</code>. 
		 * For "headless" components, this method must be called explicitly.
		 */
		public function subscribe():void
		{
			
			if(!_model){
				_model = _connectSession.fileManager;
				_model.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
				_model.addEventListener(FileManagerEvent.READY_FOR_UPLOAD, onReadyForUpload);
				
				// Move the delete action to server.		
				//_model.addEventListener(FileManagerEvent.CLEARED_FILE_DESCRIPTOR, onClearFileDescriptor);		
			}
			
			if (!_fileManager) {
				_fileManager = _connectSession.fileManager;						
			} 
   			
   			if ( !_userManager ) {
   				_userManager = _connectSession.userManager;
   			}
   			
   			if(!_fileReference) {
				_fileReference = new FileReference();
				_fileReference.addEventListener(Event.SELECT, onSelect);
				_fileReference.addEventListener(Event.COMPLETE, onComplete);
				_fileReference.addEventListener(Event.CANCEL, onCancel);
				_fileReference.addEventListener(ProgressEvent.PROGRESS, onProgress);
				_fileReference.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
				_fileReference.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			}

			_fileBrowseOn = false;
			
			if ( _model ) {
				_model.amIUploadingFile = false;
			}	
			
		}
		
		
		/**
		 * @private
		 */
		override protected function createChildren():void
		{
			
			if ( !_subscribed ) {
				subscribe();
				_subscribed = true ;
			}
			
			
			if(!_background) {
				_background = new Sprite();
				_background.visible = false;
				addChild(_background);
			}
			
			if ( _model ) {
				_model.amIUploadingFile = false;
			}
			
			super.createChildren();
		}
		
					
		/**
		 * @private
		 */
		override protected function measure():void
		{
			super.measure();
			
			if ( UIComponentGlobals.designMode ) {
        		minHeight = 40 ;
        		minWidth = 100 ;
        	}else {
				measuredWidth = measuredMinWidth;
				measuredHeight = measuredMinHeight;
        	}
		}
		
		/**
		 * @private
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			// Scale size of uploadImage to the window.
			var sideLength:Number = Math.min(Math.min(unscaledWidth, unscaledHeight) * 2/3, 100);						
			
			_background.graphics.beginFill(0xEEEEEE);
			_background.graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);					
		}
		
		
		/* Public methods
		//////////////////////////////////////////////////////////////
		*/

		/**
		 * <code>browse()</code> begins the process of preparing for upload by prompting the user to 
		 * select a file. If accepted by the FileManager, it will fire a 
		 * <code>FileManagerEvent.READY_FOR_UPLOAD</code>. The type filter works the
		 * same way as in <code>FileReference.browse()</code>. For more information, see  
		 * <code>browse()</code> in the ActionScript 3.0 documentation: flash.net.filereference.
		 *
		 * @param p_itemID  A unique identifier based on ActionScript's pseudo-random 
		 * number generator and the current time. This ID is used to identify the file that  
		 * will be uploaded to the room.
		 * @param p_typeFilter An array of FileFilter instances used to filter the files that 
		 * are displayed in the dialog box. The default is null and all files are displayed. 
        * 
        * @default null
		 * 
		 * @see FileReference.browse()
		 */
		public function browse(p_itemID:String, p_typeFilter:Array=null):void
		{
			// Don't open this up if the user doesn't  have upload permissions.
			if(!_model.canIUpload(_groupName)) {
				showAlertMessage(_lm.getString("You do not have sufficient permission to perform the upload operation."));
				return;	
			}
			
			if(_fileBrowseOn == true) {
				// This should rarely happen.
				return;
			}
			
			_fileBrowseOn = true;
			
			if(p_typeFilter)
				_typeFilter = p_typeFilter;		

			_uploadMode = MODE_BROWSE;				
		
			// Announce the intention to begin uploading file to the manager, then wait for an okay.
			// A blank file descriptor (except submitterID) signifies this to the FileManager.
			_uploadFileDescriptor = new FileDescriptor();
			_uploadFileDescriptor.id = p_itemID;			
			_uploadFileDescriptor.submitterID = _userManager.myUserID;
			_uploadFileID = p_itemID;
			
			// FP 10 changed security model, so FileReference.browse() can not be called any time.  So this is the solution:
			// if you have FP10, when you click on “paper clip�? icon, it will only bring up the file pod but will not do 
			// browse file, then you click on filepod browse button again to browse.  
			//
			try{
				_fileReference.browse(_typeFilter);
			}catch(e:Error) {
				// Triggered when the "paper clip" icon get clicked. it is a delay timer event instead of mouse event.
				// Clean up our variables. See the http://www.colettas.org/?p=252 article about this new behavior.
				_uploadFileDescriptor = null;
				_fileBrowseOn = false;
			}
		}

		
		/**
		 * Uploads the FileReference passed in. This also submits a notification to the FileManager 
		 * that the user intends to initiate and upload. If the notification is validated, the upload 
		 * begins and others in the room are notified. 
		 * 
		 * @param p_fileReference The file reference to upload.
		 * 
		 */
		public function uploadFileReference(p_fileReference:FileReference,p_uid:String):void
		{
			_fileReference = p_fileReference;
			_fileReference.addEventListener(Event.SELECT, onSelect);
			_fileReference.addEventListener(Event.COMPLETE, onComplete);
			_fileReference.addEventListener(Event.CANCEL, onCancel);
			_fileReference.addEventListener(ProgressEvent.PROGRESS, onProgress);

			_uploadMode = MODE_UPLOAD;

			//  Announce intention to begin uploading file to the Manager, then wait for an okay.
			// A blank file descriptor (except submitterID) signifies this to the FileManager.
			_uploadFileDescriptor = new FileDescriptor();
			_uploadFileID = _uploadFileDescriptor.id = p_uid;
			_uploadFileDescriptor.submitterID = _userManager.myUserID;

			onSelect(new Event(Event.SELECT)); 
		}
						
		 
		/**
		 * Removes the file specified by the <code>fileDescriptor</code>. This will notify room 
		 * participants of the file's removal and delete the file from the service.
		 *
		 * @param p_fileDesc The FileDescriptor representing the file to be deleted.
		 * 
		 */
		public function remove(p_fileDesc:FileDescriptor):void
		{
			//Alert.show("remove file: " + p_fileDesc.name); 
			if(p_fileDesc!=null && _model.getFileDescriptor(p_fileDesc.id) != null)
				_model.clearFileDescriptor(p_fileDesc.id);
		}
		

		/**
		 * Updates the file name of the file specified by the <code>fileDescriptor</code> with a new name.
		 * 
		 * @param p_fileDesc The FileDescriptor representing the file to be deleted.
		 * @param p_newName The new name to use for the file.
		 * 
		 */
		public function updateFilename(p_fileDesc:FileDescriptor, p_newName:String):void
		{			
			if(p_fileDesc ==null || _model.getFileDescriptor(p_fileDesc.id) == null)
				return; 
				
			if(p_fileDesc.name != null && p_newName != null) {		
				
				var groupDescriptors:ArrayCollection = _fileManager.getFileDescriptors(_groupName);
				var len:int = groupDescriptors.length;
				for(var i:int=0; i<len; i++) {
					if(groupDescriptors.getItemAt(i)["name"] ==p_newName) {						
						throw new Error(_lm.getString("Duplicate File Name."));
					}
				}
				
				var newFilename:String = ISO9075.encode(p_newName); // encoded for server
				
				//move actually renaming on the fms server side
				try{
					_model.updateFilename(p_fileDesc.id, p_newName, newFilename);	
				}catch(e:Error) {
					showAlertMessage(_lm.getString(e.message));
				}
				
				dispatchEvent(new Event(Event.COMPLETE));																			
			}
			
		}
						
		/**
		 * @private
		 */
		protected function onRenameIOError(p_event:IOErrorEvent):void
		{
			dispatchEvent(p_event);
		}
		
		/**
		 * @private
		 */
		public function set progressInterval(p_value:Number):void
		{
			if(p_value >= 0)
				_progressInterval = p_value;
			
			_progressTimer = new Timer(_progressInterval);
			_progressTimer.addEventListener(TimerEvent.TIMER, onTimer);
		}
		
		/**
		 * The FilePublisher can send updates to other clients during an upload so that they know how much a user has
		 * uploaded.  By default, these messages are sent every 3000 milliseconds. Set it to 0 if you
		 * don't want to send any updates at all. In that case, the only two announcements will be "The user is going 
		 * to upload a file" and "The file is done uploading."
		 */
		public function get progressInterval():Number
		{
			return _progressInterval;
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
		 * Creates a new group of files within the FileManager with the specified name and optionally configures 
		 * its permissions. It also specifies the <code class="property">groupName</code> to use for any subsequent uploads from 
		 * the publisher. Note that the user must have role of <code>UserRoles.OWNER</code> in order to add a new 
		 * group of files.
		 * 
		 * @param p_groupName The name of the new group.
		 * @param p_nodeConfiguration The configuration for the new group (including <code class="property">
		 * accessModel</code> and <code class="property">publishModel</code>).
		 * 
		 */
		public function createAndUseGroup(p_groupName:String, p_nodeConfiguration:NodeConfiguration = null):void
		{
			_model.createGroup(p_groupName, p_nodeConfiguration);
			groupName = p_groupName;
		}
		
		/**
		 * Cancels any current file upload if one is in progress.
		 */
		public function cancelFileUpload():void
		{
			if(_model.amIUploadingFile == true) {
				// Indicates uploading is in progress.
				_fileReference.cancel();
				remove(_uploadFileDescriptor);			
				
			}			
			
			_fileBrowseOn = false;
			_model.amIUploadingFile = false;
		}
		
		/**
		 * Specifies whether or not the current user is uploading a file.
		 */
		public function amIUploadingFile():Boolean
		{
			if ( !_model ) {
				subscribe();
			}
			
			return _model.amIUploadingFile;			
		}
		
		public function canIUpload():Boolean
		{
			if ( !_model ) {
				subscribe();
			}
			
			return _model.canIUpload(_groupName);
		}
		
		/* Helper functions
		//////////////////////////////////////////////////////////////*/
		
				
		/**
		 * @private
		 */
		protected function onRemoveComplete(p_event:Event):void
		{
			// Alert.show("onRemoveComplete: " + p_event.toString());	
			dispatchEvent(p_event);
		}
		
		/**
		 * @private
		 */
		protected function onCancel(p_event:Event):void
		{
			cancelFileUpload();
			dispatchEvent(p_event);
		}
				
		
		/**
		 * @private
		 * 
		 * When the user selects the file to upload, we immediately upload it. The FilePublisher graphics also becomes visible.
		 */
		protected function onSelect(p_event:Event):void
		{						
			_model.amIUploadingFile = true;
			
			_fileBrowseOn = false;
									
			var size:int = 0;
			
			try{
				size = _fileReference.size;
			}catch(e:Error) {
				showAlertMessage(_lm.formatString("INVALID_FILE_SIZE", size));
				_model.amIUploadingFile = false;
				return;			
			}
						
			announceIntentionPublish(_fileReference.name, size);
					
			dispatchEvent(p_event);	
		}
		
		/**
		 * @private
		 * @param fileName
		 * @param size
		 * 
		 */
		protected function announceIntentionPublish(fileName:String, size:int):void 
		{
			var maxSize:Number = _fileManager.maxFileSize;
			var maxSizeStr:String;
			
			if(size <= 0) {
				maxSizeStr = String(maxSize / 1048576) + " " + _lm.getString("MB");
				showAlertMessage(_lm.formatString("FILE_SIZE_EXCEED_LIMIT", maxSizeStr));	
				_model.amIUploadingFile = false;
				return;
			}
			
			if(size > maxSize) {				
				maxSizeStr = String(maxSize / 1048576) + " " + _lm.getString("MB");
				showAlertMessage(_lm.formatString("FILE_SIZE_EXCEED_LIMIT", maxSizeStr));									
				_model.amIUploadingFile = false;
				return;					
			}
			
			if(!_model.canIUpload(_groupName)) {
				// Throw new Error("FilePublisher.onSelect(): Insufficient permission for upload.");		
				showAlertMessage(_lm.getString("Insufficient permission for upload."));
				_model.amIUploadingFile = false;
				return;					
			}
			
			for(var i:int=0; i<INVALID_FILENAME_CHARS.length; i++) {
				if(fileName.indexOf(INVALID_FILENAME_CHARS.charAt(i)) >=0 ) {	
					showAlertMessage(_lm.formatString("CHARACTER_NOT_PERMITTED_IN_FILENAME", FilePublisher.INVALID_FILENAME_CHARS.charAt(i)));
					_model.amIUploadingFile = false;
					return;
				}
			}
			
			var iso9075FileName:String = ISO9075.encode(fileName);
			
			var groupDescriptors:ArrayCollection = _fileManager.getFileDescriptors(_groupName);	
			for(i = 0; i<groupDescriptors.length; i++) {
				if(groupDescriptors.getItemAt(i)["filename"] == iso9075FileName) {
					showAlertMessage(_lm.getString("A file with same name already exists on the server. Try again."));
					_model.amIUploadingFile = false;
					return;						
				}
			}
			
			// Flex FileReference doesn't allow changing the filename in the request nor accessing the response,
			// so we pass a "server clean" filename on the request (or the server may reject the file).
			_uploadFileDescriptor.filename = iso9075FileName;
			_uploadFileDescriptor.size = size;
			_uploadFileDescriptor.groupName = _groupName ;
			_uploadMode = MODE_UPLOAD;
			
			// It might already be there (we're choosing a new picture).
			if(_model.getFileDescriptor(_uploadFileDescriptor.id)) {
				try{
					_model.updateFileDescriptor( _uploadFileDescriptor.id, null, null, null, null, -1, 0, FileDescriptor.ANNOUNCING_INTENTION_TO_PUBLISH);
				}catch(e:Error){
					showAlertMessage(_lm.getString(e.message));
				}
			}
			else {
				try {
					_model.publishFileDescriptor(_uploadFileDescriptor);
				}catch(e:Error){
					showAlertMessage(_lm.getString(e.message));
				}
			}

		}
				
		/**
		 * @private
		 */
		protected function uploading():void
		{																	
			// Hack to make it easy for the security filter to find the ticket param without 
			// having to parse all of the multipart form data. We really shouldn't have to do
			// this, but it does make processing of the security filter faster/easier.
			var uploadFileUrl:String = _uploadFileDescriptor.url +  "?mst=" + _userManager.myTicket;

			var request:URLRequest = new URLRequest(uploadFileUrl);
			request.method = URLRequestMethod.POST; 			
			request.data = new URLVariables();
			
			// Flex FileReference doesn't allow changing the filename in the request nor accessing the response,
			// so we are passing a "server clean" filename on the request (or the server may reject the file)		
			request.data.filename = _uploadFileDescriptor.filename;
			request.data.response = "status";
			
			try {
				_fileReference.upload(request, "file");
 			}catch(error:Error) {
 				// mx.controls.Alert.show("upload Error: " + error);
 				_model.amIUploadingFile = false;
 				throw error;
 			}
 			 						
			if(progressInterval) {				
				_progressTimer.start();
			}
									
			// mx.controls.Alert.show("onSelect url... " + _uploadFileDescriptor.url);
		}


		/**
		 * @private
		 * When the upload completes, graphics go away.
		 */
		protected function onComplete(p_event:Event):void
		{						
			_model.amIUploadingFile = false;
			
			// In case user cancel the upload. 
			if(_uploadFileDescriptor == null || _model.getFileDescriptor(_uploadFileDescriptor.id) == null)
				return;
				
			if(progressInterval)
				_progressTimer.stop();			// Stop the progress timer.
				
			// stopAnimation();					// Remove graphics.
			_lastBytesLoaded = 0;				// Reset progress counters.
			
			// send out one final message item with uploadProgress = 100
			_uploadFileDescriptor.uploadProgress = 100;
			//_model.updateUploadProgress(_uploadFileDescriptor.id, 100);


			// Update FileDescriptor with information about selected info.
			_uploadFileDescriptor.name = _fileReference.name;
			_uploadFileDescriptor.size = _fileReference.size;
			_uploadFileDescriptor.type = _fileReference.type;
			
			_uploadFileDescriptor.submitterID = _userManager.myUserID;
			
			_uploadFileDescriptor.state = FileDescriptor.PUBLISHING_DESCRIPTOR;
			
			try{
				// Now that the FileDescriptor is complete, share it with FileManager.
				_model.updateFileDescriptor(_uploadFileDescriptor.id, _uploadFileDescriptor.name, _uploadFileDescriptor.filename, _uploadFileDescriptor.url,
						_uploadFileDescriptor.type, _uploadFileDescriptor.size, _uploadFileDescriptor.uploadProgress, _uploadFileDescriptor.state);
			}catch(e:Error) {
				_fileReference.cancel();
				if(_model.canIUpload(_groupName)) {
					remove(_uploadFileDescriptor);	//can't remove if demoted
				}
				this.showAlertMessage(_lm.getString(e.message));
			}
			
			dispatchEvent(p_event);
		}

		/**
		 * @private
		 * We receive progress events from the uploading FileReference. 
		 * When these are received, the percentage display should update.
		 */
		protected function onProgress(p_event:ProgressEvent):void
		{						
			//_progressLabel.text = Math.round(p_event.bytesLoaded / p_event.bytesTotal * 100) + "%";
			_lastBytesLoaded = p_event.bytesLoaded;			
							
			dispatchEvent(p_event);
			
		}
		
		
		/**
		 * @private
		 * Handles FileManagerEvent.READY_FOR_UPLOAD which provides permissions to begin uploading.
		 * It also has an updated FileDescriptor payload describing the file in question; some
		 * attributes were set by the manager that LCCS was previously unaware of, so update the
		 * model here.
		 */
		protected function onReadyForUpload(p_event:FileManagerEvent):void
		{
			if(!_model.canIUpload(_groupName)) {				
				showAlertMessage(_lm.getString("Insufficient permission for upload."));
				_model.clearFileDescriptor(_uploadFileDescriptor.id);
				return;
			}
			
			if(_uploadFileID == p_event.fileDescriptor.id) {
				
				_uploadFileDescriptor = p_event.fileDescriptor;
				
				if (_uploadMode == MODE_BROWSE) {
					_fileReference.browse(_typeFilter);
				} else {
					uploading();
				}
			}
		}
		

		
		/**
		 * @private
		 * If progress has changed since the last tick, update the <code class="property">uploadProgress</code>.
		 */
		protected function onTimer(p_event:TimerEvent):void
		{
			// Verify the file upload is not in the process of canceling.
			if(amIUploadingFile() && _uploadFileDescriptor != null && _model.getFileDescriptor(_uploadFileDescriptor.id) != null)
			{
				var progressPercent:int = Math.round(_lastBytesLoaded / _uploadFileDescriptor.size * 100);
				
				// Bridges the time between upload complete and actually publishing of the file.
				// onComplete will be called when it is finally done.
				if(progressPercent == 100) progressPercent = 99;
				
				if(progressPercent != _uploadFileDescriptor.uploadProgress) {
					_uploadFileDescriptor.uploadProgress = progressPercent;
					try{
						_model.updateUploadProgress(_uploadFileDescriptor.id, progressPercent);
					}catch(e:Error) {
						_fileReference.cancel();
						if(_model.canIUpload(_groupName)) {
							remove(_uploadFileDescriptor);	//can't remove if demoted
						}
						this.showAlertMessage(_lm.getString(e.message));
					}
				}
			}
		}
		
		/**
		 * @private
		 */
		protected function onIOError(p_event:IOErrorEvent):void 
		{
			cancelFileUpload();
			showAlertMessage(p_event.text);
			dispatchEvent(p_event);
		}
		
		/**
		 * @private
		 */
		protected function onHttpStatus(p_event:HTTPStatusEvent):void
		{
			if(p_event.status != 200) {
				cancelFileUpload();									
				if(progressInterval)  _progressTimer.stop();			// Stop the progress timer.													
				showAlertMessage(_lm.formatString("FILE_OPERATION_FAILED", p_event.status));
				remove(_uploadFileDescriptor);
			}
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

		/**
		 * @private
		 * Redispatch received event.
		 */
		protected function onSynchronizationChange(p_event:CollectionNodeEvent):void
		{
			if (!_model.isSynchronized) { //Lost Connection Perform clean UP :(
				if(_fileReference) {
					_fileReference.removeEventListener(Event.COMPLETE, onComplete);
					_fileReference.removeEventListener(ProgressEvent.PROGRESS, onProgress);
					_fileReference.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
				}
			}
			dispatchEvent(p_event);
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
		
	}
}
