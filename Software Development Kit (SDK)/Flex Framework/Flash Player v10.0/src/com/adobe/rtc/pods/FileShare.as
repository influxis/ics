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
package com.adobe.rtc.pods
{
	import com.adobe.coreUI.localization.ILocalizationManager;
	import com.adobe.coreUI.localization.Localization;
	import com.adobe.coreUI.util.StringUtils;
	import com.adobe.rtc.clientManagers.PlayerCapabilities;
	import com.adobe.rtc.collaboration.FilePublisher;
	import com.adobe.rtc.collaboration.FileSubscriber;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.FileManagerEvent;
	import com.adobe.rtc.events.RoomManagerEvent;
	import com.adobe.rtc.events.UserEvent;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.pods.fileSharePodClasses.FileSharePodConfirmation;
	import com.adobe.rtc.pods.fileSharePodClasses.IFileShareDialog;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.RoomSettings;
	import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
	import com.adobe.rtc.sharedManagers.FileManager;
	import com.adobe.rtc.sharedManagers.RoomManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.FileDescriptor;
	import com.adobe.rtc.sharedManagers.descriptors.UserDescriptor;
	import com.adobe.rtc.util.ISO9075;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.DataGrid;
	import mx.controls.TextInput;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.core.Application;
	import mx.core.IFlexDisplayObject;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.DataGridEvent;
	import mx.events.DataGridEventReason;
	import mx.events.FlexEvent;
	import mx.events.ListEvent;
	import mx.events.ToolTipEvent;
	import mx.managers.PopUpManager;
	import mx.managers.ToolTipManager;
	import mx.utils.UIDUtil;

	/**
	 * @private
	 */
	[Event(name="DataCollectionUpdate", type="flash.events.Event")]	
	/**
	 * Dispatched when the component either loses its connection to the session or regains it
	 * and has finished re-synchronizing itself to the rest of the room.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	
	
	/**
	 * this is workaround for flashplayer doesn't support right click
	 */
	[Event(name="uploadBtnVisibleStateChange", type="flash.events.Event")]	 
	
	/**
	 * FileShare is a high level pod component which offers a full mini-application for 
	 * uploading files, viewing lists of files, and downloading files. It uses FileManager 
	 * groups as its basic model for display and FilePublisher and FileSubscriber to actually
	 * upload and download files. 
	 * <p>
	 * Users with  a viewer role or greater are able to download, and only users with a 
	 * publisher role or greater may upload a file.
	 * 
	 * @see com.adobe.rtc.collaboration.FilePublisher
	 * @see com.adobe.rtc.collaboration.FileSubscriber
	 * @see com.adobe.rtc.sharedManagers.FileManager
 	 */
   public class  FileShare extends UIComponent implements ISessionSubscriber
	{
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
		protected var _groupid:String;
		/**
		 * @private
		 */
		protected var _publisher:FilePublisher;
		/**
		 * @private
		 */
		protected var _subscriber:FileSubscriber;		
		/**
		 * @private
		 */
		protected var _fileReference:FileReference;	
		/**
		 * @private
		 */
		private var _isDisabledUntilGroupSet:Boolean = false;
		
		// assets
		[Embed (source = 'fileSharePodAssets/paperclip.png')]
		/**
		 * @private
		 */
		protected var AddFileIconClass:Class;

		[Embed (source = 'fileSharePodAssets/download.png')]
		/**
		 * @private
		 */
		protected var SaveFileIconClass:Class;

		[Embed (source = 'fileSharePodAssets/download_disabled.png')]
		/**
		 * @private
		 */
		protected var SaveFileDisabledIconClass:Class;
		
		[Embed (source = 'fileSharePodAssets/trashcan.png')]
		/**
		 * @private
		 */
		protected var DeleteFileIconClass:Class;

		[Embed (source = 'fileSharePodAssets/trashcan_disabled.png')]
		/**
		 * @private
		 */
		protected var DeleteFileDisabledIconClass:Class;
						
		/**
		 * @private
		 */
		protected var _background:Sprite;
		
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
		public var _uploadButton:Button;
		/**
		 * @private
		 */
		public var _downloadButton:Button;
		/**
		 * @private
		 */
		public var _deleteButton:Button;
		/**
		 * @private
		 */
		public var _cancelUploadButton:Button;
		
		/**
		 * @private
		 */
		protected var _filename_dgc:DataGridColumn;
		/**
		 * @private
		 */
		protected var _size_dgc:DataGridColumn;
		/**
		 * @private
		 */
		protected var _oldFileName:String;
		/**
		 * @private
		 */
		protected var _roomManager:RoomManager;
		
		/**
		 * @private
		 */
		protected var _lastUploaded:Boolean = true;	// describes last action, download or upload
		
		/**
		 * @private
		 */
		protected var _fileGrid:DataGrid;
		/**
		 * @private
		 */
		protected var _groupDescriptors:ArrayCollection = null;
		
		/**
		 * @private
		 */
		protected var _playerCapabilities:PlayerCapabilities;
		
		/**
		 * @private
		 */
		protected var _lm:ILocalizationManager = Localization.impl;
		
		/**
		 * @private
		 */
		protected var _useSSL:Boolean = true;
		
		/**
		 * @private
		 */
		protected var _myUserID:String = "";
		
		[Inspectable(enumeration="false,true", defaultValue="false")]
		/**
		 * Specifies whether files in the pod should be deleted as the session ends. 
		 * 
		 * @default false
		 */
		public var clearUponSessionEnd:Boolean = false;

		/**
		 * @private
		 */
		protected static var OPTIONS_BOX_PAD:Number = 1;
		
		/**
		 * @private
		 */
		protected static var SIZE_LABEL_WIDTH:Number = 75;
		
		/**
		 * @private
		 */
		protected var _confirmationDialogClass:Class = FileSharePodConfirmation;				
		 /**
		 * @private
		 */
		 protected var _sharedID:String ;
		 /**
		 * @private
		 */
		 private const DEFAULT_SHARED_ID:String =  "default_FileSharePod" ;
		 /**
		  * @private
		  */
		 protected var _subscribed:Boolean = false ;
		 /**
		  * @private 
		  */		
		 protected var _connectSession:IConnectSession = new SessionContainerProxy(this as UIComponent);
            
		public function FileShare():void
		{			
			super();
		}
		
		/**
		 * @private
		 */
		public function set confirmationDialogClass(p_class:Class):void
		{
			_confirmationDialogClass = p_class;
		}
		
		/**
		 * @private
		 */
		override public function initialize():void
		{
			super.initialize();			
			
			if(!_background) {
				_background = new Sprite();
				_background.visible = false;
				addChild(_background);
			}
			
			addEventListener(KeyboardEvent.KEY_UP, onKeyUp);		
		}
		
		/**
		 * The <code>sharedID</code> corresponds to the <code>groupName</code> of the FilePublisher 
		 * and FileSubscriber used in this component. If not specified
		 * explicitly, the pod's sharedID is used. 
		 */
		public function set sharedID(p_id:String):void
		{
			_sharedID = p_id;
			_groupid = _sharedID ;
		}
		
		/**
		 * @private
		 */
		public function get sharedID():String
		{
			return _sharedID;
		}

		/**
		 * The IConnectSession with which this component is associated. 
		 * Note that this may only be set once before <code>subscribe()</code>
		 * is called; re-sessioning of components is not supported. 
		 * Defaults to the first IConnectSession created in the application.
		 */
		public function get connectSession():IConnectSession
		{
			return _connectSession;
		}
		
		/**
		 * Sets the IConnectSession with which this component is associated. 
		 */
		public function set connectSession(p_session:IConnectSession):void
		{
			_connectSession = p_session;
		}
		
		[Bindable(event="synchronizationChange")]
		/**
		 * Returns true if the component is synchronized; otherwise, false.
		 */
		public function get isSynchronized():Boolean
		{
			if ( !_fileManager ) {
				return false ;
			}
			
			return _fileManager.isSynchronized ;
		}
		
		/**
		 * Tells the component to begin synchronizing with the service. 
		 * For UIComponent-based components such as this one,
		 * <code>subscribe()</code> is called automatically upon being added to the <code>displayList</code>. 
		 * For "headless" components, this method must be called explicitly.
		 */
		public function subscribe():void
		{
			// if the id is not set , then take default shared ID if it is not set not, else take the set shared id value
			// if id is set, then if shared id is not set, take set sharedID to id and take it, otherwise , take the set shared id
			
			if ( id == null ){
				if ( sharedID == null ) {
					sharedID = DEFAULT_SHARED_ID ;
				}
				_groupid = sharedID;
			}else {
				if ( sharedID != null ) {
					_groupid = sharedID;
				}else {
					sharedID = id ;
					_groupid = sharedID ;
				}
			}
				 
			
			if (!_userManager) {
				_userManager = _connectSession.userManager;
				//if role change, file visibility
				_userManager.addEventListener(UserEvent.USER_REMOVE, onUserRemove);
				_userManager.addEventListener(UserEvent.USER_ROLE_CHANGE, onUserRoleChange);
				_userManager.addEventListener(UserEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			}
			
			if (!_fileManager) {
				_fileManager = _connectSession.fileManager;	
				_fileManager.addEventListener(CollectionNodeEvent.NODE_CREATE, onCreateGroup);
				_fileManager.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
				_fileManager.addEventListener(CollectionNodeEvent.USER_ROLE_CHANGE,onUserRoleOnCollectionChange);
				
			} 
			
			if (!_roomManager) {
				_roomManager = _connectSession.roomManager;
				_roomManager.addEventListener(RoomManagerEvent.AUTO_DISCONNECT_DISCONNECTED, onAutoDisconnectDisconnected);		
			}
		}
		
		
		/**
		 * Sets the role of a given user for files that are within this component's assigned group.
		 * 
		 * @param p_userRole The role value to set on the specified user.
		 * @param p_userID The ID of the user whose role should be set.
		 */
		public function setUserRole(p_userID:String,p_userRole:int):void
		{
			if ( p_userID == null ) 
				return ;
				
			_fileManager.setUserRole(p_userID,p_userRole,_groupid);
		}
		
		
		/**
		 *  Returns the role of a given user for files that are within this component's assigned group.
		 * 
		 * @param p_userID The user ID for the user being queried.
		 */
		public function getUserRole(p_userID:String):int
		{
			if ( p_userID == null ) {
				throw new Error("FileShare: USerId can't be null");
			}
			return _fileManager.getUserRole(p_userID,_groupid);
		}
				
		/**
		 * @private
         *
		 * CreateChildren. Creating the model and view and adding the event listeners and 
		 * setting the model in the view
		 */
		override protected function createChildren():void
		{
			super.createChildren();
			
			_playerCapabilities = PlayerCapabilities.getInstance();	
			
			if ( !_subscribed ) {
				subscribe();
				_subscribed = true ;
			}
           
           	createChildUI();
      	
		}
		
		
		
		
		/**
		 * @private
		 * Function for creating children
		 */
		protected function createChildUI():void
		{
			if(!_publisher)
			{
				_publisher = new FilePublisher();
				_publisher.initialize();				
				
				_publisher.addEventListener(Event.COMPLETE, onComplete);
				_publisher.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
				_publisher.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
				_publisher.addEventListener(ProgressEvent.PROGRESS, onProgress);
				_publisher.addEventListener(Event.SELECT, onSelect);
				_publisher.addEventListener(FileManagerEvent.FILE_ALERT,onFileAlert);
				
				//only owner can create the group
				if(!_fileManager.isGroupDefined(_groupid) && _fileManager.getUserRole(_userManager.myUserID) == UserRoles.OWNER) {
					var nodeConfig:NodeConfiguration = new NodeConfiguration;
					nodeConfig.sessionDependentItems = clearUponSessionEnd;
					_publisher.createAndUseGroup(_groupid, nodeConfig);
				}else {
					_publisher.groupName = _groupid;
				}			
				
				addChild(_publisher);
			}
			
			if(!_subscriber)
			{
				_subscriber = new FileSubscriber();
				_subscriber.addEventListener(FileManagerEvent.FILE_ALERT,onFileAlert);
				addChild(_subscriber);
			}
			
			
			if ( !_fileReference ) {
				_fileReference = new FileReference();
				// event listeners of all shapes and sizes
				_fileReference.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
				_fileReference.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
				_fileReference.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				_fileReference.addEventListener(ProgressEvent.PROGRESS, onProgress);
				_fileReference.addEventListener(Event.COMPLETE, onComplete);				
			}
								
					
										
			if(!_fileGrid){
				_fileGrid = new DataGrid();
				_fileGrid.headerHeight = _fileGrid.rowHeight;
				_fileGrid.allowMultipleSelection = true;
				_fileGrid.doubleClickEnabled = true;
				_fileGrid.setStyle("borderStyle", "none");
				
				_fileGrid.addEventListener(DataGridEvent.ITEM_EDIT_END, onEditFileName);
				_fileGrid.addEventListener(ListEvent.ITEM_DOUBLE_CLICK, onItemDoubleClick);			
				_fileGrid.addEventListener(Event.CHANGE, onChange);
				_fileGrid.addEventListener(ListEvent.ITEM_CLICK, onSelectedItem);	
				_fileGrid.addEventListener(ListEvent.ITEM_ROLL_OUT, onSelectedItem);
			 	_fileGrid.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
								
				_groupDescriptors = _fileManager.getFileDescriptors(_groupid);
								
				if(_groupDescriptors) {
					//cleanUpZombieDescriptors(_groupDescriptors);
					_fileGrid.dataProvider = _groupDescriptors;
					_groupDescriptors.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange);
				}
					
				if(!_filename_dgc) {
					_filename_dgc = new DataGridColumn();
					_filename_dgc.headerText=_lm.getString("Name");
					_filename_dgc.dataField = "name";	
					_filename_dgc.editable = true;
					//_filename_dgc.editorUsesEnterKey = true;				
					_filename_dgc.labelFunction = fileNameLabelFunction;										
				}
				
				if(!_size_dgc) {
					_size_dgc = new DataGridColumn();
					_size_dgc.headerText=_lm.getString("Size");
					_size_dgc.dataField = "size";
					_filename_dgc.editable = false;
					_size_dgc.labelFunction = fileSizeLabelFunction;
				}
															
				_fileGrid.columns = [_filename_dgc, _size_dgc];
				addChild(_fileGrid);
			}
			
				
				
			if(!_uploadButton) {				
				_uploadButton = new Button();
				_uploadButton.setStyle("icon", AddFileIconClass);		
				_uploadButton.label = _lm.getString("Upload a File...");
				_uploadButton.toolTip = _lm.getString("Upload a File");
				_uploadButton.addEventListener(MouseEvent.CLICK, uploadSelection);
				_uploadButton.addEventListener(MouseEvent.DOUBLE_CLICK, uploadSelection);
				_uploadButton.addEventListener(FlexEvent.SHOW, _uploadButtonShow);
				addChild(_uploadButton);
			}
			
			if(!_cancelUploadButton) {
				_cancelUploadButton = new Button();
				_cancelUploadButton.setStyle("icon", AddFileIconClass);		
				_cancelUploadButton.label = _lm.getString("Cancel Upload...");
				_cancelUploadButton.toolTip = _lm.getString("Cancel Uploading File");
				_cancelUploadButton.addEventListener(MouseEvent.CLICK, cancelUploadSelection);
				_cancelUploadButton.addEventListener(MouseEvent.DOUBLE_CLICK, cancelUploadSelection);				
				_cancelUploadButton.addEventListener("toolTipShow", cancelButtonToolTipChanger);				

				addChild(_cancelUploadButton);
			}

			if (!_downloadButton) {
				_downloadButton = new Button();
				_downloadButton.setStyle("icon", SaveFileIconClass);			
				_downloadButton.setStyle("disabledIcon", SaveFileDisabledIconClass);
				_downloadButton.label = _lm.getString("Save Selected File");
				_downloadButton.toolTip = _lm.getString("Save Selected File");
				_downloadButton.addEventListener(MouseEvent.CLICK, downloadSelection);
				_downloadButton.addEventListener(MouseEvent.DOUBLE_CLICK, downloadSelection);									
				_downloadButton.enabled = false;
				addChild(_downloadButton);
				_downloadButton.validateNow();
				_downloadButton.setActualSize(_downloadButton.measuredWidth, 22);
			}

			if (!_deleteButton) {
				_deleteButton = new Button();
				_deleteButton.setStyle("icon", 	DeleteFileIconClass);
				_deleteButton.setStyle("disabledIcon", DeleteFileDisabledIconClass);
				_deleteButton.setActualSize(24,22);
				_deleteButton.toolTip = _lm.getString("Delete Selected Files");
				_deleteButton.addEventListener(MouseEvent.CLICK, deleteSelection);
				_deleteButton.addEventListener(MouseEvent.DOUBLE_CLICK, deleteSelection);
				_deleteButton.enabled = false;
				addChild(_deleteButton);		
			}

			// if we are participant and host is slow creating groupid, we will diable the buttons until the group is created
			if(!_fileManager.isGroupDefined(_groupid)) {
				_uploadButton.enabled = false;
				_cancelUploadButton.enabled = false;
				_downloadButton.enabled = false;			
				_deleteButton.enabled = false;		
				
				_isDisabledUntilGroupSet = true;
			}
		}
		
		public function _uploadButtonShow(event:FlexEvent):void{
			dispatchEvent(new Event("uploadBtnVisibleStateChange"));
		}
		
		public function cancelButtonToolTipChanger(event:ToolTipEvent):void {
            ToolTipManager.currentToolTip.text = _lm.getString("Cancel Uploading File");
        }

		/**
		 * @private
		 */
		protected function onCreateGroup(p_event:CollectionNodeEvent):void
		{
			if(_isDisabledUntilGroupSet == true && _groupid == p_event.nodeName)
			{
				enableButtons();
				_isDisabledUntilGroupSet = false;
			}						
		}	 	
					
		/**
		 * Causes the pod to prompt the user to browse for a file to upload.
		 */
		public function uploadSelection(p_event:MouseEvent = null):void
		{			
			if(!amIUploadingFile())
			{
				var filter:FileFilter = new FileFilter("*.*", "*.*");
				browseFiles([filter]);
			}
		}
		
		/**
		 * Cancels the pending upload.
		 */
		public function cancelUploadSelection(p_event:MouseEvent = null):void
		{
			if(amIUploadingFile())
			{
				_fileGrid.selectedIndex = -1;
				cancelFileUpload();				
			}
		}

		[Inspectable(enumeration="false,true", defaultValue="true")]
		/**
		 * @private
		 */
		public function set useSSL(ssl:Boolean):void
		{
			_useSSL = ssl;
		}
		/**
		 * Specifies whether or not to use SSL in uploading and downloading files.
		 */
		public function get useSSL():Boolean
		{
			return _useSSL;
		}
		
		/**
		 * Provides a reference to the grid display of files.
		 * 
		 * @return 
		 * 
		 */
		public function get fileGrid():DataGrid
		{
			if ( !_subscribed ) {
				validateProperties();
				validateNow();
			}
			
			return _fileGrid;
		}
				
		/**
		 * Causes the pod to begin downloading all selected files in the display grid.
		 */
		public function downloadSelection(p_event:MouseEvent = null):void
		{
			if ( !_subscribed ) {
				validateProperties();
				validateNow();
			}
			
			if (_fileGrid.selectedItems.length>0) {
				for each (var desc:FileDescriptor in _fileGrid.selectedItems) {
					downloadFile(desc);
				} 
			}
		}
		
		/**
		 * Causes the pod to begin deleting all selected files in the display grid.
		 */
		public function deleteSelection(p_event:MouseEvent = null):void
		{
			if ( !_subscribed ) {
				validateProperties();
				validateNow();
			}
			
			if(_fileGrid.selectedItems.length>0) {
				var filename:String = FileDescriptor(_fileGrid.selectedItem).name;
				if(filename == null) {
					// if we here that means we are in uploading still 
					filename = FileDescriptor(_fileGrid.selectedItem).filename;
					filename = (filename != null)? ISO9075.decode(filename) : "";
				}
				
				var dialog:IFileShareDialog = new _confirmationDialogClass();
				dialog.addEventListener(CloseEvent.CLOSE, processDeleteAlertSelectionCloseEvent);
				dialog.addEventListener("accept", processDeleteAlertSelectionEvent);
				dialog.addEventListener("cancel", processDeleteAlertSelectionEvent);
				
				if(_lm.formatString("DELETE_SINGE_CONFIRMATION", filename) != "DELETE_SINGE_CONFIRMATION")
				{
					dialog.displayMessage = (_fileGrid.selectedItems.length==1) ? 
							_lm.formatString("DELETE_SINGE_CONFIRMATION", filename) 
							: _lm.formatString("DELETE_MULTIPLE_CONFIRMATION", _fileGrid.selectedItems.length);
				}else {
					dialog.displayMessage = (_fileGrid.selectedItems.length==1) ? 
							"Are you sure you want to delete "+ filename +"?"
							: "Are you sure you want to delete " + _fileGrid.selectedItems.length + " selected files?";
				}
				
				var d:IFlexDisplayObject = IFlexDisplayObject(dialog);
				PopUpManager.addPopUp(d, DisplayObject(Application.application), true);
				PopUpManager.centerPopUp(d);				
			}									
		}		
						
		/**
		 * @private
		 */
		protected function processDeleteAlertSelectionEvent(p_event:Event):void
		{
			if (p_event.type == "accept") {
				processDeleteAlertSelectionCloseEvent(new CloseEvent("accept", false, true, Alert.OK));
			}
			
			dispatchEvent(p_event);
		}
		/**
		 * @private
		 */
		protected function processDeleteAlertSelectionCloseEvent(p_event:CloseEvent):void
		{
			if (p_event.detail == Alert.OK) {
				
				for each (var desc:FileDescriptor in _fileGrid.selectedItems) {

					if(desc.state == FileDescriptor.FILE_UPLOAD_PROGRESS) {
						cancelFileUpload();
						_cancelUploadButton.visible = false;
						_cancelUploadButton.enabled = false;
					}else {
						removeFile(desc);
					}
				}
				
				//special case, we don't call enableButton 
				//because we don't get the refresh of selectedItem in time, so we set it here (no need to check permission since we in delete)
				 _deleteButton.enabled = false;	
				 _downloadButton.enabled = false;
				 _uploadButton.enabled = true;	
			}			
		}
		
		/**
		 * Causes the pod to rename the selected file in the display grid.
		 */
		public function renameSelection(p_event:MouseEvent = null):void
		{
			if ( !_subscribed ) {
				validateProperties();
				validateNow();
			}
			if(_fileGrid.selectedItems.length==1){	
				if (_fileManager.getUserRole(_userManager.myUserID,_groupid) >= UserRoles.PUBLISHER) { 
					_fileGrid.editable = true;
				}
				var editedItemPos:Object = new Object();
				editedItemPos.rowIndex = _fileGrid.selectedIndex;
            	editedItemPos.columnIndex = 0;
				_fileGrid.editedItemPosition = editedItemPos;				
			}
		}
		
		/**
		 * @private
		 */
		protected function onFileAlert(event:FileManagerEvent):void
		{
			showAlertMessage(event.alertMessage);
		}
		
		
		/**
		 * @private
		 */
		protected function onSelectedItem(p_event:Event=null):void
		{
			if(_fileGrid.selectedItem != null){
				
				var descriptor:FileDescriptor = FileDescriptor(_fileGrid.selectedItem);
				
				if(descriptor != null && descriptor.state != FileDescriptor.PUBLISHING_DESCRIPTOR && !_userManager.anonymousPresence){
			
					var submitUD:UserDescriptor = _userManager.getUserDescriptor(descriptor.submitterID);
					if(submitUD == null) {
						//this means our submitter has being disconnected and file is not submitted completely
						//Also added a check for anonymousPresence. In case of anonymousPresence we would have to rely on UserEvent.USER_REMOVE event to clean the zombie descriptor
						removeFile(descriptor);
					}
										
					disableButtons();
					
				}else {
					enableButtons();
				}
				
				//also notify the file menu selection.
				dispatchEvent(new Event("DataCollectionUpdate"));
			}
		}
		
		/**
		 * @private
		 */
		protected function onEditFileName(p_event:DataGridEvent):void
		{			
			//TODO: consider using itemRenderer				
			var event:FileManagerEvent = null;
			_oldFileName = p_event.target.selectedItem.name;
			_fileGrid.editable = false;
			
			if ( p_event.reason == DataGridEventReason.CANCELLED){
            	onRenameCancelled(null);       
                return;
            }			
			
			//we now do some basic filename syntax checking
			var newName:String = TextInput(p_event.currentTarget.itemEditorInstance).text;
			
			if(StringUtils.isEmpty(newName)) {			
				showAlertMessage(_lm.getString("File name cannot be empty, please enter a valid name for the file."));
				onRenameCancelled(null);  				
				return;
			}
			
			else if(newName == _oldFileName) {				
				//invalidateDisplayList();
				onRenameCancelled(null);
				return;
			}
            
			if((newName.lastIndexOf('.') + 1) == newName.length) {
				showAlertMessage(_lm.getString("FILENAME_CONTAINING_DOT_AT_THE_END")); 		
				onRenameCancelled(null);  
				return;		
			}
			
			for(var i:int=0; i< FilePublisher.INVALID_FILENAME_CHARS.length; i++) {
				if(newName.indexOf(FilePublisher.INVALID_FILENAME_CHARS.charAt(i)) >=0 ) {
					showAlertMessage(_lm.getString("Following character is not permitted in the file name:") + " '" + FilePublisher.INVALID_FILENAME_CHARS.charAt(i) + "'");
					onRenameCancelled(null);  
					return;		
				}
			}
															
			renameFile(FileDescriptor(_fileGrid.selectedItem), newName);

		}
		
		/**
		 * @private
		 */
		protected function onRenameCancelled(p_event:Event):void 
		{																		
			_fileGrid.destroyItemEditor();					
		}
		
		/**
		 * @private
		 */
		protected function onItemDoubleClick(p_event:ListEvent):void
		{			
			if(_fileGrid.selectedItem && (FileDescriptor(_fileGrid.selectedItem).state == FileDescriptor.PUBLISHING_DESCRIPTOR) ) {
				downloadFile(_fileGrid.selectedItem as FileDescriptor);	
			}
		}
		
		/**
		 * @private
		 */
		protected function onChange(p_event:Event):void
		{			
			/*if(p_event.target == _fileGrid) {		
				if(_fileGrid.selectedItem) {					
					
					var descriptor:FileDescriptor = FileDescriptor(_fileGrid.selectedItem);
					
					
					enableButtons();
					
				}
				else {
					
					enableButtons();
				}	
				
				dispatchEvent(new Event(Event.CHANGE)) ;
			}*/												
		}
		
		/**
		 * @private
		 */
		protected function onCollectionChange(p_event:CollectionEvent):void
		{
			if(p_event.kind == CollectionEventKind.ADD || p_event.kind == CollectionEventKind.RESET) {				
				enableButtons();
				dispatchEvent(new Event("DataCollectionUpdate"));
			}	
			else if (p_event.kind == CollectionEventKind.REMOVE) {		
				enableButtons();		
				dispatchEvent(new Event("DataCollectionUpdate"));
			}			
		}
		
		/**
		 * Disposes all listeners to the network and framework classes. Recommended for 
		 * proper garbage collection of the component.
		 */
		public function close():void
		{			
			if(amIUploadingFile()) {
				cancelFileUpload();
			}
			
			removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			
			_userManager.removeEventListener(UserEvent.USER_REMOVE, onUserRemove);
			_userManager.removeEventListener(UserEvent.USER_ROLE_CHANGE, onUserRoleChange);
			_userManager.removeEventListener(UserEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			
			_fileManager.removeEventListener(CollectionNodeEvent.NODE_CREATE, onCreateGroup);	
			_fileManager.removeEventListener(CollectionNodeEvent.USER_ROLE_CHANGE,onUserRoleOnCollectionChange);		
			_fileManager.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
				
			_roomManager.removeEventListener(RoomManagerEvent.AUTO_DISCONNECT_DISCONNECTED, onAutoDisconnectDisconnected);		
			
			_publisher.removeEventListener(Event.COMPLETE,onComplete);
			_publisher.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
			_publisher.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);	
			_publisher.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			_publisher.removeEventListener(Event.SELECT, onSelect);
			_publisher.removeEventListener(FileManagerEvent.FILE_ALERT,onFileAlert);
			_publisher.close();

			_subscriber.removeEventListener(FileManagerEvent.FILE_ALERT,onFileAlert);
			_subscriber.close();

			_fileReference.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
			_fileReference.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
			_fileReference.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			_fileReference.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			_fileReference.removeEventListener(Event.COMPLETE, onComplete);

			_fileGrid.removeEventListener(DataGridEvent.ITEM_EDIT_END, onEditFileName);
			_fileGrid.removeEventListener(ListEvent.ITEM_DOUBLE_CLICK, onItemDoubleClick);			
			_fileGrid.removeEventListener(Event.CHANGE, onChange);
			_fileGrid.removeEventListener(ListEvent.ITEM_CLICK, onSelectedItem);	
			_fileGrid.removeEventListener(ListEvent.ITEM_ROLL_OUT, onSelectedItem);
			_fileGrid.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			
			_groupDescriptors.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange);
			_uploadButton.removeEventListener(MouseEvent.CLICK, uploadSelection);
			_uploadButton.removeEventListener(MouseEvent.DOUBLE_CLICK, uploadSelection);
			_uploadButton.removeEventListener(FlexEvent.SHOW, _uploadButtonShow);
			
			_downloadButton.removeEventListener(MouseEvent.CLICK, downloadSelection);
			_downloadButton.removeEventListener(MouseEvent.DOUBLE_CLICK, downloadSelection);
			
			_deleteButton.removeEventListener(MouseEvent.CLICK, deleteSelection);
			_deleteButton.removeEventListener(MouseEvent.DOUBLE_CLICK, deleteSelection);
			
			_cancelUploadButton.removeEventListener(MouseEvent.CLICK, cancelUploadSelection);
			_cancelUploadButton.removeEventListener(MouseEvent.DOUBLE_CLICK, cancelUploadSelection);
			_cancelUploadButton.removeEventListener("toolTipShow", cancelButtonToolTipChanger);
			
			removeChild(_publisher);
			removeChild(_subscriber);
			removeChild(_fileGrid);
			removeChild(_uploadButton);
			removeChild(_downloadButton);
			removeChild(_deleteButton);
			removeChild(_cancelUploadButton);
			
		}
		
		/**
		 * Cancels file upload.
		 */
		public function cancelFileUpload():void
		{
			if ( !_subscribed ) {
				validateProperties();
				validateNow();
			}
			
			//if(isSelectItemsUploadingFile())
			_publisher.cancelFileUpload();						
			
			//enableButtons();
			//special case, we don't call enableButton 
			//because we don't get the refresh of selectedItem in time, so we set it here (no need to check permission since we in cancel)
			_deleteButton.enabled = false;	
			_downloadButton.enabled = false;
			_cancelUploadButton.enabled = false;
			_cancelUploadButton.visible = false;
			
			_uploadButton.enabled = true;	
			_uploadButton.visible = true;				
			
		}
		
		/**
		 * Determines whether or not the current user is uploading a file.
		 */
		public function amIUploadingFile():Boolean
		{			
			if ( !_subscribed ) {
				validateProperties();
				validateNow();
			}
			
			return _publisher.amIUploadingFile();
		}

		/**
		 * @private 
		 */
		public function isSelectItemsUploadingFile():Boolean
		{
			var selectedItems:Array = _fileGrid.selectedItems;
			
			if ( !_subscribed ) {
				validateProperties();
				validateNow();
			}
			
			if (selectedItems != null)
			{
				for (var i:int=0; i< selectedItems.length; i++)
				{	
					if (FileDescriptor(selectedItems[i]).state == FileDescriptor.FILE_UPLOAD_PROGRESS
						&& (_publisher.amIUploadingFile() || FileDescriptor(selectedItems[i]).submitterID != _userManager.myUserID) ) {
						return true;
					}
				}
			}
			return false;
		}
		
		/**
		 * @private
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth,unscaledHeight);
			
			if ( !_subscribed ) {
				return ;
			}
			
			var sideLength:Number = Math.min(Math.min(unscaledWidth, unscaledHeight) * 2/3, 100);

			//_size_dgc.width = (unscaledWidth / 4.0);	//setting last column width doesn't do anything		
			//_size_dgc.minWidth = SIZE_LABEL_WIDTH;
			//_size_dgc.width = SIZE_LABEL_WIDTH;
			var fnamewidth:Number = (unscaledWidth * 3.0)/4.0;
			_filename_dgc.minWidth = fnamewidth;
			_filename_dgc.width = fnamewidth;
			_fileGrid.width = unscaledWidth;
			_fileGrid.height = unscaledHeight-28;
			_fileGrid.validateNow();

			var theY:uint = unscaledHeight-22;
			if(_uploadButton.measuredWidth <= (unscaledWidth - _deleteButton.width - _downloadButton.width)) {
				_uploadButton.setActualSize(_uploadButton.measuredWidth, 22);
			} else { 
				_uploadButton.setActualSize(_deleteButton.width, 22);  //if upload button size is large or equal file pod size, then we use the delete button width
			}

			if (_cancelUploadButton.measuredWidth <= (unscaledWidth - _deleteButton.width - _downloadButton.width)) {
				_cancelUploadButton.setActualSize(_cancelUploadButton.measuredWidth, 22);
			} else { 
				_cancelUploadButton.setActualSize(_deleteButton.width, 22);  //if upload button size is large or equal file pod size, then we use the delete button width
			}
				
			_uploadButton.move(0,theY);
			_cancelUploadButton.move(0, theY);
			_deleteButton.move(unscaledWidth-26, theY);

			if (unscaledWidth > _downloadButton.measuredWidth+_uploadButton.width+_deleteButton.width) {
				_downloadButton.setActualSize(_downloadButton.measuredWidth, 22);
			} else { 
				_downloadButton.setActualSize(_deleteButton.width, 22);  //if upload button size is large or equal file pod size, then we use the delete button width
			}
			_downloadButton.move(_deleteButton.x-4-_downloadButton.width, theY);
			
			enableButtons();
		}		
		
		/**
		 * @private
		 */
		protected function renameFile(p_fileDesc:FileDescriptor, p_newName:String):void
		{
			try{
				_publisher.updateFilename(p_fileDesc, p_newName);			
			}catch(e:Error) {									
				showAlertMessage(_lm.formatString("FILE_RENAME_ERROR", e.message));
				onRenameCancelled(null);
			}
		}
		
		/**
		 * @private
		 */
		protected function removeFile(p_fileDesc:FileDescriptor):void
		{
			if ( p_fileDesc.submitterID == _userManager.myUserID || _fileManager.getUserRole(_userManager.myUserID,_groupid) >= UserRoles.PUBLISHER ) {
				_publisher.remove(p_fileDesc);
			}
		}
		
		/**
		 * @private
		 */
		protected function browseFiles(filterArray:Array):void
		{
			_publisher.browse(UIDUtil.createUID(), filterArray);
		}
		
		/**
		 * @private
		 */
		protected function downloadFile(p_fileDesc:FileDescriptor):void
		{
			try{
				_subscriber.download(p_fileDesc);
			}catch(e:Error) {
				showAlertMessage(e.message);				
			}
		}
		
		/**
		 * Uploads a <code>fileReference</code> to the pod.
		 */
		public function uploadFileReference(p_fileReference:FileReference):void
		{
			_publisher.uploadFileReference(p_fileReference,UIDUtil.createUID());
		}
		
		
		/**
		 * @private
		 */
		protected function onUserRemove(p_event:UserEvent):void
		{
			var removedUserID:String = p_event.userDescriptor.userID;
			
			if(_userManager.getUserRole(_userManager.myUserID) == UserRoles.OWNER)
			{
				for(var i:int=0; i<_groupDescriptors.length; i++){
					var descriptor:FileDescriptor = _groupDescriptors.getItemAt(i) as FileDescriptor;
					
					//remove the file if it is in a ghost state: user removed and file upload not complete
					if(descriptor.submitterID == removedUserID &&
						descriptor.state != FileDescriptor.PUBLISHING_DESCRIPTOR) {
						removeFile(descriptor);
						//disableButtons();					
						break;
					}
					
				}
			}
			
			/*var submitUD:UserDescriptor = _userManager.getUserDescriptor(descriptor.submitterID);
			if(submitUD == null) {
				//this means our submitter has being disconnected and file is not submitted completely
				removeFile(descriptor);
				disableButtons();
			}*/
		}
		/**
		 * @private
		 */
		protected function onUserRoleChange(p_event:UserEvent):void
		{
			invalidateDisplayList();
			dispatchEvent(p_event);
		}	
		
		/**
		 * @private
		 */
		protected function onUserRoleOnCollectionChange(p_event:CollectionNodeEvent):void
		{
			invalidateDisplayList();
			dispatchEvent(p_event);
		}				
		
		/**
		 * @private
		 */
		protected function onIoError(event:IOErrorEvent):void
		{
			invalidateDisplayList();

			_publisher.cancelFileUpload();
			
		}
		
		/**
		 * @private
		 */
		protected function onSecurityError(event:SecurityErrorEvent):void
		{
			//mx.controls.Alert.show("Crap! SecurityError: " + event.text);
			_publisher.cancelFileUpload();
		}
		
		/**
		 * @private
		 */
		protected function onHttpStatus(event:HTTPStatusEvent):void
		{
			_publisher.cancelFileUpload();					
		}				
		
		/**
		 * @private
		 */
		protected function onSelect(p_event:Event):void
		{
			invalidateDisplayList();	
			//this is to tell the filesharepod not to create upload menu
			dispatchEvent(new Event("DataCollectionUpdate"));										
		}
		
		/**
		 * @private
		 */
		protected function onProgress(p_event:ProgressEvent):void
		{									
			var progressPercent:int =  Math.round(p_event.bytesLoaded / p_event.bytesTotal * 100);									
		}
		
		/**
		 * @private
		 */
		protected function onComplete(event:Event):void
		{
			invalidateDisplayList();
						
			dispatchEvent(new Event("DataCollectionUpdate"));		
			
			dispatchEvent(event);
			
			enableButtons();
		}
		
		/**
		 * @private
		 */
		protected function onAutoDisconnectDisconnected(p_evt:RoomManagerEvent):void
		{
			_downloadButton.enabled = false;					
			_uploadButton.enabled = false;					
			_deleteButton.enabled = false;
			_fileGrid.selectable = false;
			dispatchEvent(p_evt);
		}
		
		public function refreshButtons():void
		{
			enableButtons();
		}
	
		/**
		 * @private
		 */
		protected function enableButtons():void
		{
			var bSelected:Boolean = (_fileGrid.selectedItems.length > 0 && !isSelectItemsUploadingFile()) ;	
			
			if(_roomManager.roomState == RoomSettings.ROOM_STATE_ACTIVE) {
				if(_fileManager.getUserRole(_userManager.myUserID,_groupid) >= UserRoles.PUBLISHER) {																		
					_deleteButton.visible = true;	
					_deleteButton.enabled = bSelected;	
					
					_downloadButton.visible = true;
					_downloadButton.enabled = (_fileGrid.selectedItems.length == 1 && !isSelectItemsUploadingFile());
					
					_uploadButton.visible = !_publisher.amIUploadingFile();		
					_uploadButton.enabled = !_publisher.amIUploadingFile(); 
					
					_cancelUploadButton.visible = _cancelUploadButton.enabled = _publisher.amIUploadingFile() && _publisher.canIUpload();
	
				}
				else {
					_downloadButton.visible = true;
					_downloadButton.enabled = (_fileGrid.selectedItems.length == 1 && !isSelectItemsUploadingFile());
					_uploadButton.visible = false;	
					_cancelUploadButton.visible = false;				
					_deleteButton.visible = false;	
					
				}		
			}
			else {
				_downloadButton.enabled = false;					
				_uploadButton.enabled = false;					
				_deleteButton.enabled = false;
				_cancelUploadButton.visible = _cancelUploadButton.enabled = false;
			}
		}		
		
		/**
		 * @private
		 */
		protected function disableButtons():void 
		{
			_downloadButton.enabled = false;
			
			if(_fileManager.getUserRole(_userManager.myUserID,_groupid) >= UserRoles.PUBLISHER && !_publisher.amIUploadingFile() && _roomManager.roomState == RoomSettings.ROOM_STATE_ACTIVE)
				_uploadButton.enabled = true;
				
			var descriptor:FileDescriptor = FileDescriptor(_fileGrid.selectedItem);
											
			_deleteButton.enabled = false;	
			_cancelUploadButton.visible = _cancelUploadButton.enabled = _publisher.amIUploadingFile();
			
		}				
		
		/**
		 * @private
		 */
		protected function fileNameLabelFunction(item:Object, column:DataGridColumn):String
		{
			try {
				if(item.submitterID != null) {
					if(item.name) { 																	
						return item.name;														
					}
					else {										
						var ud:UserDescriptor = _userManager.getUserDescriptor(item.submitterID);
						
						if(ud != null) 
							return _lm.formatString("USERID_UPLOADING_PERCENT", ud.displayName, item.uploadProgress);								
						else																								
							return  _lm.formatString("UPLOADING_PERCENT", item.uploadProgress);																													
					}
				}
				else
					return null;		
			}catch(e:Error) {
				return null;
			}
			
			return null;
		}
		
		/**
		 * @private
		 */
		protected function fileSizeLabelFunction(item:Object, column:DataGridColumn):String
		{
			try {
				if(item.submitterID != null) {
					if(item.size) {
						var fileSize:Number = Number(item.size);
						if(fileSize < 1024) {										
							return fileSize + " "+_lm.getString("Bytes");
						}
						else if(fileSize >= 1024 && fileSize < 1048576) {
							return Math.round(fileSize / 1024) + " "+_lm.getString("KB");
						}						
						else {
							return Math.round(fileSize / 1048576) + " "+_lm.getString("MB");
						}
					}						
					else
						return null;
				}
				else
					return null;		
			}catch(e:Error) {
				return null;
			}
			
			return null;
		}
		
		/**
		 * @private
		 */
		protected function onSynchronizationChange(p_event:UserEvent):void
		{
			_myUserID = _userManager.myUserID ;
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
		 */
		protected function onKeyUp(event:KeyboardEvent):void
		{
			if(event.keyCode == Keyboard.DELETE && _fileGrid.editable == false) {
				deleteSelection(null);
			}
			else if(event.keyCode == Keyboard.CONTROL) {
				enableButtons();
			}
			else if(event.keyCode == Keyboard.UP || event.keyCode == Keyboard.DOWN) {
				enableButtons();
			}
		}
		
		/**
		 * @private
		 */
		/*protected function cleanUpZombieDescriptors(dp:ArrayCollection):void {
			var i:int = 0;
			while(i<dp.length) {			
				var descriptor:FileDescriptor = dp.getItemAt(i) as FileDescriptor;
				if(descriptor != null 
					&& descriptor.state == FileDescriptor.FILE_UPLOAD_PROGRESS 
				    && descriptor.state != FileDescriptor.PUBLISHING_DESCRIPTOR
					&& !_publisher.amIUploadingFile()){
						
					var submitUD:UserDescriptor = _userManager.getUserDescriptor(descriptor.submitterID);
					if(submitUD == null) {
						//somehow our last upload didn't succeed, we have some zombie file descriptor laying around
						removeFile(descriptor);
						dp.removeItemAt(i);	
					}					
				}
				
				i++;
			}
		}*/
		
		/**
		 * @private
		 */
		override protected function measure():void
		{
			super.measure();
			
			minWidth = 150 ;
			minHeight = 150 ;
		}
		
		/**
		 * @private
		 */
		protected function onSyncChange(p_evt:CollectionNodeEvent):void
		{
			if ( _fileManager.isSynchronized ) {
				_uploadButton.enabled = true ;
			}else {
				_uploadButton.enabled = _downloadButton.enabled = _deleteButton.enabled = false;
			}
			
			dispatchEvent(p_evt);
		}
	}
}
