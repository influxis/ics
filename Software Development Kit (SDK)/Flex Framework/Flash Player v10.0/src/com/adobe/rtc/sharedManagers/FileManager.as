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
package com.adobe.rtc.sharedManagers
{
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.FileManagerEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.sharedManagers.descriptors.FileDescriptor;
	import com.adobe.rtc.sharedModel.CollectionNode;
	
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;


	/**
	 * Dispatched when the manager goes in and out of sync either on connect or disconnect.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	

	/**
	 * Dispatched when a new <code>fileDescriptor</code> is sent to the service. Note that this doesn't 
	 * indicate that a file has been uploaded but rather that a user has begun uploading a file.
	 */
	[Event(name="newFileDescriptor", type="com.adobe.rtc.events.FileManagerEvent")]	
	/**
	 * Dispatched when the my role with respect to a stream changes.
	 */
	[Event(name="myRoleChange", type="com.adobe.rtc.events.CollectionNodeEvent")]
	/**
	 * Dispatched when the user's role with respect to a stream changes.
	 */
	[Event(name="userRoleChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	

	/**
	 * Dispatched when a <code>fileDescriptor</code> has been updated. This may mean any of 
	 * the properties on the FileDescriptor has changed. If the <code>uploadProgress</code> is 100, the 
	 * file is ready for download.
	 */
	[Event(name="updatedFileDescriptor", type="com.adobe.rtc.events.FileManagerEvent")]	

	/**
	 * Dispatched when a <code>fileDescriptor</code> is retracted from the service, 
	 * and its corresponding file has been deleted.
	 */
	[Event(name="clearedFileDescriptor", type="com.adobe.rtc.events.FileManagerEvent")]	

	/**
	 * Dispatched when a user's request to upload has been validated.
	 */
	[Event(name="readyForUpload", type="com.adobe.rtc.events.FileManagerEvent")]	

	/**
	 * One of the "4 pillars" of a room, the FileManager represents the shared model for files 
	 * available for download for the client. It expresses a variety of methods for other 
	 * components to access, modify, or publish specific files. FileManager uses FileDescriptors 
	 * as control metadata to represent the available files; files themselves may be added, 
	 * modified, and downloaded through FileSubscriber and FilePublisher.
	 * 
	 * <p>
	 * The FileManager keeps files in "groups," with permissions settable on a per-group basis. 
	 * Users with the owner role are able to add, modify, and delete these groups. By default, 
	 * only users with a publisher role and higher may publish a file to a group, while those with
	 * role of viewer or higher are able to download.</p>
	 * 
	 * <p>Note: If you're listening to the <code>NEW_FILE_DESCRIPTOR</code> and <code>UPDATE_FILE_DESCRIPTOR</code>
	 * events, just because the Manager dispatches a <code>NEW_FILE_DESCRIPTOR</code> does not mean that the 
	 * file is ready for download. On the contrary, the <code>NEW_FILE_DESCRIPTOR</code> is emitted when the 
	 * file is ready to begin uploading, not after it's uploaded. Instead, listen to <code>UPDATE_FILE_DESCRIPTOR</code>, 
	 * and check to see when the <code class="property">uploadProgress</code> property of FileDescriptor equals 100.</p>
	 * 
	 * <p>Each IConnectSession handles creation/setup of its own FileManager instance.  Use an <code>IConnectSession</code>'s
	 * <code class="property">fileManager</code> property to access it.</p>
	 *  
	 * @see com.adobe.rtc.sharedManagers.descriptors.FileDescriptor
	 * @see com.adobe.rtc.collaboration.FilePublisher
	 * @see com.adobe.rtc.collaboration.FileSubscriber
	 * @see com.adobe.rtc.collaboration.BinaryPublisher
	 * @see com.adobe.rtc.collaboration.BinarySubscriber
	 * @see com.adobe.rtc.events.FileManagerEvent
	 * @see com.adobe.rtc.session.IConnectSession
 	 */
   public class  FileManager extends EventDispatcher implements ISessionSubscriber
	{
		
		/**
		 * The name of the CollectionNode used to represent the FileManager's shared model.
		 */		
		public static const COLLECTION_NAME:String = "FileManager";
		
		/**
		 * @private
		 */
		protected static const GLOBALSETTINGS:String = "__globalSettings__";
		
		/**
		 * @private
		 */
		protected static const MAXFILESIZE:String = "maxFileSize";
		
		/**
		 * The set of all <code>fileDescriptors</code> in the room.
		 */
		public var fileDescriptors:ArrayCollection;	
		
		/**
		 * @private
		 * The set of all fileDescriptors, keyed by ID.
		 */
		protected var _fileDescriptorTable:Object;
		
		/**
		 * @private 
		 */		
		protected var _connectSession:IConnectSession = ConnectSession.primarySession;
		
		/**
		 * @private
		 * hashmap where key is descriptor ID, value is the name of its group
		 */
		protected var _idToGroupTable:Object;			
		
		
		// TODO: raph - make this bindable
		/**
		 * @private
		 * 	hashmap where key is name of group, value is an ArrayCollection containing all of its descriptors
		 */
		protected var _groups:Object;					
		
		/**
		 * @private
		 */
		protected var _collectionNode:CollectionNode;
		
		/**
		 * @private
		 */
		protected var _userManager:UserManager;
		
		/**
		 * @private
		 */
		protected var _maxFileSize:Number;
		
		/**
		 * @private
		 */
		private var _isMeUploadingFile:Boolean = false;
		 /**
		 * @private
		 */
		 private static const ALPHA_CHAR_CODES:Array = [48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69, 70];


		/**
		 * Constructor.
		 */
		public function FileManager():void
		{
			fileDescriptors = new ArrayCollection();
			_fileDescriptorTable = {};
			_idToGroupTable = {};
			_groups = {};
		}
		
		
		
		/* Public methods
		//////////////////////////////////////////////////////////////////////////////////////////////////////////*/

		/**
		 * (Read Only) Specifies the IConnectSession to which this manager is assigned. 
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
		 * @private 
		 */
		public function get sharedID():String
		{
			return COLLECTION_NAME;
		}
		
		/**
		 * 
		 * @private
		 * 
		 */
		public function set sharedID(p_id:String):void
		{
			// NO-OP
		}
		
		[Bindable(event="synchronizationChange")]
		/**
		 * Returns true if the model is synchronized.
		 */
		public function get isSynchronized():Boolean
		{
			return _collectionNode.isSynchronized ;
		}
		
		/**
		 * @private
		 */
		public function close():void
		{
			//NO OP
		}

		/**
		 * Sets the specified user's role to the indicated role for the node. Only users with an owner role may call this method.
		 * 
		 * @param p_userID The specified user's <code>userID</code>.
		 * @param p_role The role desired.
		 * @param p_groupName The group name for which the user role is being set. The default is null.
		 */ 
		public function setUserRole(p_userID:String, p_role:int,  p_groupName:String ):void
		{
			if ( _collectionNode.isNodeDefined(p_groupName)) {
				_collectionNode.setUserRole(p_userID, p_role, p_groupName);
			}
		}
		
		/**
		 * Gets the role of the specified user for a particular group. 
		 * 
		 * @param p_userID The specified user's <code>userID</code>.
		 * @param p_groupName The group name for which to get the user role. The default is null.
		 * 
		 * @return int which is the user role value
		 */
		public function getUserRole(p_userID:String, p_groupName:String=null ):int
		{
			if (!_collectionNode) {
				return -1;
			}
			return _collectionNode.getUserRole(p_userID, p_groupName);
		}
		
		/**
		 * Gets the NodeConfiguration of a node within a group.
		 *  
		 * @param p_groupName The group name for the node on which to get the node configuration. The default is null.
		 * 
		 */
		public function getNodeConfiguration( p_groupName:String ):NodeConfiguration
		{
			return _collectionNode.getNodeConfiguration(p_groupName);
		}
		
		/**
		 * Sets the NodeConfiguration of a node within a group.
		 *  
		 * @param p_groupName The group name for the node on which to set the node configuration. The default is null.
		 * 
		 */
		public function setNodeConfiguration( p_nodeConf:NodeConfiguration,p_groupName:String ):void
		{
			return _collectionNode.setNodeConfiguration(p_groupName,p_nodeConf);
		}
		
		/**
		 * Announces to the service that a file will be uploaded for the first time by the 
		 * local client or by somebody else. Only a host can request that someone else upload a file.  
		 * To specify this, set <code>p_associatedUserID</code> to another user's <code>userID</code>.
		 * Also if the <code>p_associatedUserID</code>is set to another user's <code>userID</code> and if
		 * the <code>UserManager.anonymousPresence</code> is set to true, then please do check if the
		 *  <code>UserManager</code> has the intended user uploaders <code>UserDescriptor</code>
		 * 
		 * 
		 * @param p_descriptor The file descriptor to publish.
		 * @param p_associatedUserID The ID of the intended uploader of the file.
		 * 
		 */
		public function publishFileDescriptor(p_descriptor:FileDescriptor, p_associatedUserID:String=null):void
		{
			// Do I have permission to publish at all?
			if(!_collectionNode.canUserPublish(_userManager.myUserID, p_descriptor.groupName)) {
				throw new Error("FileManager.publishFileDescriptor: You have insufficient privileges to publish.");
				return;
			}
			
			// Don't publish this if the descriptor exists.
//			if(_fileDescriptorTable[p_descriptor.id] || !canIUpload()) {
			if(_fileDescriptorTable[p_descriptor.id]) {
				throw new Error("FileManager.publishFileDescriptor: The file already exists. Did you want updateFileDescriptor instead?");
				return;
			}
			
			// FileManager expects all descriptors to have IDs.  If it doesn't, reject it.
			if(!p_descriptor.id) {
				throw new Error("FileManager.publishFileDescriptor: File descriptors must have their ID field set.");
				return;
			}
			
			// If p_associatedUserID is set...
			if(p_associatedUserID) {
				// ... do I have permission to tell someone else to publish?
				if(getUserRole(_userManager.myUserID,p_descriptor.groupName) != UserRoles.OWNER) {
					throw new Error("FileManager.publishFileDescriptor: You have insufficient privileges for upload prompt.");
					return;
				}
				
				// ... does that user exist?
				if(!_userManager.getUserDescriptor(p_associatedUserID)) {
					throw new Error("FileManager.publishFileDescriptor: The user does not exist, or the UserManager.anonymousPresence is set to true and the User's information has not been fetched.Please call UserManager.getUserDescriptor(p_associatedUserID) and call this method after the UserDescriptor for the p_associatedUserID is fetched.");
					return;
				}
			}
			
			// The guy checks out; publish.
			
			if ( p_descriptor.groupName == null ) {
				p_descriptor.groupName = createUID();
			}
			
			// Does this group exist? If not, create it.
			if(!_collectionNode.isNodeDefined(p_descriptor.groupName)) {
				createGroupNode(p_descriptor.groupName);
			}
			
			// TODO: POSSIBLE ERROR HERE: need asynchronous handling (maybe can't publish immediately)? /////////////////////////////////////////////
			
			
			var item:MessageItem = new MessageItem(p_descriptor.groupName, p_descriptor.createValueObject());
			item.itemID = p_descriptor.id;
			if(p_associatedUserID)
				item.associatedUserID = p_associatedUserID;
			_collectionNode.publishItem(item);
		}
		
		/**
		 * Updates any field of a file descriptor except for its <code>ID</code>, <code>submitterID</code>, 
		 * and <code>lastModified</code>.
		 * 
		 * 
		 * @param p_id				The ID of the descriptor to change.
		 * @param p_name			The new name (if null, no change).
		 * @param p_filename		The new filename (if null, no change).
		 * @param p_url				The new URL (if null, no change)
		 * @param p_type			The new type (if null, no change)
		 * @param p_size			The new size (-1, no change)
		 * @param p_uploadProgress	The new uploadProgress (if -1, no change)
		 * @param p_state 			The new state (one of the constants defined on FileDescriptor. If null, no change)
		 * @see com.adobe.rtc.sharedManagers.descriptors.FileDescriptor
		 */		 
		public function updateFileDescriptor(p_id:String, p_name:String=null, p_filename:String=null, p_url:String=null,
								p_type:String=null, p_size:int=-1, p_uploadProgress:Number=-1, p_state:String = null):void
		{
			
			// You can only update an existing file descriptor -- error if it doesn't.
			if(!_fileDescriptorTable[p_id]) {
				throw new Error("FileManager.publishFileDescriptor: The file does not exist. Did you want publishFileDescriptor instead?");
				return;
			}
			
			if(!_collectionNode.canUserPublish(_userManager.myUserID, _fileDescriptorTable[p_id].groupName)) {
				throw new Error("FileManager.publishFileDescriptor: You have insufficient privileges for update.");
				return;
			}
			
			
			// Users can't overwrite files that they aren't associated with, unless they're hosts.
			if(getUserRole(_userManager.myUserID,(_fileDescriptorTable[p_id] as FileDescriptor).groupName) != UserRoles.OWNER && _userManager.myUserID != _fileDescriptorTable[p_id].submitterID) {
				throw new Error("FileManager.publishFileDescriptor: You have insufficient privileges for update. You are not the publisher associated with this file.");
				return;
			}			
			
			var fileDescriptor:FileDescriptor = _fileDescriptorTable[p_id].clone();
			if(p_name) {
				fileDescriptor.name = p_name;
			}
			if(p_filename) {
				fileDescriptor.filename = p_filename;
			}
			if(p_url) {
				fileDescriptor.url = p_url;
			}
			if(p_type) {
				fileDescriptor.type = p_type;
			}
			if(p_size != -1) {
				fileDescriptor.size = p_size;
			}
			if(p_uploadProgress != -1) {
				fileDescriptor.uploadProgress = p_uploadProgress;
			}
			if(p_state != null) {
				fileDescriptor.state = p_state;
			}
			_collectionNode.publishItem(new MessageItem(fileDescriptor.groupName, fileDescriptor.createValueObject(), fileDescriptor.id), true);
		}
		 

		
		
		
		/**
		 * Updates the name field in an existing file descriptor.
		 * 
		 * @param p_id The ID of the file descriptor to change.
		 * @param p_name The new name.
		 * @param p_filename The new filename.
		 */		
		public function updateFilename(p_id:String, p_name:String, p_filename:String):void
		{
			// User must have sufficient privileges.
			if(!_collectionNode.canUserPublish(_userManager.myUserID, _idToGroupTable[p_id])) {
				throw new Error("FileManager.updateFilename: You have insufficient privileges for update.");
				return;
			}
			
			// You can only update an existing file descriptor -- error if it doesn't.
			if(!_fileDescriptorTable[p_id]) {
				throw new Error("FileManager.updateFilename: The file does not exist.");
				return;
			}
			
			// REMOVED: Users can't overwrite files that they aren't associated with, unless they're hosts.
			/*if(_userManager.myUserRole != UserRoles.OWNER && _userManager.myUserID != _fileDescriptorTable[p_id].submitterID) {
				throw new Error("FileManager.updateFilename: You have insufficient privileges for update.  You are not the publisher associated with this file.");
				return;
			}*/		
			
			var fileDescriptor:FileDescriptor = _fileDescriptorTable[p_id].clone();
			fileDescriptor.previousName = fileDescriptor.name;
			fileDescriptor.previousFilename = fileDescriptor.filename;
			fileDescriptor.name = p_name;
			fileDescriptor.filename = p_filename;
			_collectionNode.publishItem(new MessageItem(_idToGroupTable[p_id], fileDescriptor.createValueObject(), fileDescriptor.id), true);
		}
		
		/**
		 * Updates the <code>uploadProgress</code> field in an existing file descriptor.
		 * 
		 * @param p_id The ID of the file descriptor to change.
		 * @param p_uploadProgress The new upload progress percentage.
		 */		
		public function updateUploadProgress(p_id:String, p_uploadProgress:Number):void
		{
			// User must have sufficient privileges.
			if(!_collectionNode.canUserPublish(_userManager.myUserID, _idToGroupTable[p_id])) {
				throw new Error("FileManager.updateUploadProgress: You have insufficient privileges for update.");
				return;
			}
			
			// You can only update an existing file descriptor -- error if it doesn't.
			if(!_fileDescriptorTable[p_id]) {
				throw new Error("FileManager.updateUploadProgress: The file does not exist.  Did you want publishFileDescriptor instead?");
				return;
			}
			
			// Users can't overwrite files that they aren't associated with, unless they're hosts.
			if(getUserRole(_userManager.myUserID,(_fileDescriptorTable[p_id] as FileDescriptor).groupName) != UserRoles.OWNER && _userManager.myUserID != _fileDescriptorTable[p_id].submitterID) {
				throw new Error("FileManager.updateUploadProgress: You have insufficient privileges for update.  You are not the publisher associated with this file.");
				return;
			}		
			
			var fileDescriptor:FileDescriptor = _fileDescriptorTable[p_id].clone();
			fileDescriptor.uploadProgress = p_uploadProgress;
			fileDescriptor.state = FileDescriptor.FILE_UPLOAD_PROGRESS; 
			_collectionNode.publishItem(new MessageItem(_idToGroupTable[p_id], fileDescriptor.createValueObject(), fileDescriptor.id), true);
		}
		
		
		/**
		 * Updates the submitter field in an existing file descriptor. Only hosts can use this.
		 * 
		 * @param p_id The ID of the file descriptor to change.
		 * @param p_submitterID The new submitter's ID.
		 */		
		public function updateSubmitterID(p_id:String, p_submitterID:String):void
		{
			// You can only update an existing file descriptor -- error if it doesn't.
			if(!_fileDescriptorTable[p_id]) {
				throw new Error("FileManager.updateFilename: The file does not exist.  Did you want publishFileDescriptor instead?");
				return;
			}
			
			// Only hosts can update this MessageItem.
			if(getUserRole(_userManager.myUserID,(_fileDescriptorTable[p_id] as FileDescriptor).groupName) != UserRoles.OWNER) {
				throw new Error("FileManager.updateFilename: You have insufficient privileges for update. You are not a host.");
				return;
			}		
			
			var descriptor:FileDescriptor = _fileDescriptorTable[p_id];
			var item:MessageItem = new MessageItem(_idToGroupTable[p_id], descriptor.createValueObject(), descriptor.id);
			item.associatedUserID = p_submitterID;
			_collectionNode.publishItem(item, true);
		}

		
		/**
		 * Clears a file descriptor by retracting the file in question and thereby making it
		 * unavailable for download.
		 * 
		 * @param p_id The ID of the file descriptor.
		 */		
		public function clearFileDescriptor(p_id:String):void
		{
			// User must have sufficient privileges.
			if(!_collectionNode.canUserPublish(_userManager.myUserID, _idToGroupTable[p_id])) {
				throw new Error("FileManager.clearFileDescriptor: You have insufficient privileges for update.");
				return;
			}
			
			// You can only update an existing file descriptor -- error if it doesn't.
			if(!_fileDescriptorTable[p_id]) {
				throw new Error("FileManager.clearFileDescriptor: The file does not exist. Did you want publishFileDescriptor instead?");
				return;
			}
			
			//REMOVED Users can't clear files that they aren't associated with, unless they're hosts.
			/*if(_userManager.myUserRole < UserRoles.PUBLISHER && _userManager.myUserID != _fileDescriptorTable[p_id].submitterID) {
				throw new Error("FileManager.clearFileDescriptor: You have insufficient privileges for delete.  You are not the publisher associated with this file.");
				return;
			}*/		
			
			_collectionNode.retractItem(_idToGroupTable[p_id], p_id);
		}
		
		/**
		 * Returns a specific file descriptor.
		 * 
		 * @param p_id The ID of the file descriptor.
		 * 
		 * @return The filedescriptor.
		 * 
		 */		
		public function getFileDescriptor(p_id:String):FileDescriptor
		{
			return _fileDescriptorTable[p_id];
		}
		
		/**
		 * Indicates whether or not the local client has upload privileges on the chosen group.
		 * 
		 * @return True if we can, false if not.
		 */		
		public function canIUpload(p_groupName:String):Boolean
		{
			// check permissions; ensure that space quota hasn't been exceeded, etc.
			// TODO: raph - fill this in once file storage system is set up (in, like, October)
			return _collectionNode.canUserPublish(_userManager.myUserID, p_groupName);
		}
		
		/**
		 * Returns the group name of which the indicated descriptor is a member.
		 * 
		 * @param p_id The ID of the descriptor to look up.
		 * 
		 * @return The name of the group of which the indicated descriptor is a member.
		 */
		public function findGroupFor(p_id:String):String
		{
			return _idToGroupTable[p_id];
		}
				
		/**
		 * Returns the set of <code>fileDescriptors</code> in a specified group.
		 *
		 * @param p_groupName The name of the group to query.
		 * 
		 * @return An ArrayCollection of FileDescriptors.
		 * 
		 */
		public function getFileDescriptors(p_groupName:String):ArrayCollection
		{
			if (!_groups[p_groupName]) {
				// TODO : nigel : think this through. We want the group to be "bindable" and stateless
				_groups[p_groupName] = new ArrayCollection();
			}
			return _groups[p_groupName];
		}
		
		/*
		 * Returns a FileDescriptor corresponding to an ID in a specific group.
		 * 
		 * @param p_groupName The name of the group to query.
		 * @param p_fileID The ID of the FileDescriptor.
		 * 
		 * @return The specified FileDescriptor.
		 * 
		 
		 // this function already exists as getFileDescriptor
		public function getFileDescriptorInGroup( p_fileID:String , p_groupName:String ):FileDescriptor
		{
			if (!_groups[p_groupName]) {
				throw new Error("FileManager.getDescriptorInGroup: No such group exists.");
				return null;
			}
			
			var group:ArrayCollection = _groups[p_groupName];
			for each(var i:Object in group) {
				if((i as FileDescriptor).id == p_fileID)
					return i as FileDescriptor;
			}
			return null;
		}*/
		
		/**
		 * Returns whether or not a specified group exists. 
		 * 
		 * @param p_groupName The name of the group to query.
		 * @return True if the group exists; false if not.
		 */
		public function isGroupDefined(p_groupName:String):Boolean
		{
			if(_groups[p_groupName]) {
				return true;
			}
			else {
				return false;
			}
		}
		
		
		
		/**
		 * Returns all the group names. 
		 * 
		 * @return An array of group names
 		 */
		public function getGroupNames():Array
		{
			var groupNameArray:Array = new Array();
			for (var groupName:String in _groups ) {
				groupNameArray.push(groupName);
			}
			
			return groupNameArray ;
		}
		
		
		/**
		 * Creates a new group for files with the specified name and <code>nodeConfiguration</code>.
		 * 
		 * @param p_groupName The name for the new group.
		 * @param p_nodeConfiguration The settings for the new group; most notably, <code>accessModel</code> 
		 * and <code>publishModel</code> for rights.
		 */
		public function createGroup(p_groupName:String, p_nodeConfiguration:NodeConfiguration = null):void
		{
			if(isGroupDefined(p_groupName)) {
				throw new Error("FileManager.createGroup: That group already exists.");
				return;
			}
			
			createGroupNode(p_groupName, p_nodeConfiguration);
		}
		
		/**
		 * Removes a group if it does exist as well as the nodes associated with it.
		 * 
		 * @param p_groupName The group Name.
 		 */
		public function removeGroup(p_groupName:String):void
		{
			if (_collectionNode.isSynchronized && isGroupDefined(p_groupName) && _collectionNode.isNodeDefined(p_groupName)) {
				_collectionNode.removeNode(p_groupName);
			}
		}
		
		/**
		 * Specifies the maximum filesize allowed.
		 */
		public function get maxFileSize():Number
		{
			return _maxFileSize;
		}
		
		/**
		 * @private
		 */
		public function set amIUploadingFile(b:Boolean):void
		{
			_isMeUploadingFile = b;	
		}
		
		/**
		 * Specifies whether the current user is currently uploading a file. Note that only one file 
		 * may be uploaded at a time.
		 */
		public function get amIUploadingFile():Boolean
		{
			return _isMeUploadingFile;
		}
		
		/* Helper functions
		//////////////////////////////////////////////////////////////////////////////////////////////////////////*/
		
		


		/**
		* @private
		* Tells the manager to retrieve items from the network (used in ConnectSession).
		*/
		public function subscribe():void
		{
			_userManager = _connectSession.userManager;
			// Clear the model.
			_fileDescriptorTable = {};
			fileDescriptors.removeAll();
			_idToGroupTable = {};
			_groups = {};
			
			_collectionNode = new CollectionNode();
			_collectionNode.sharedID = COLLECTION_NAME;
			_collectionNode.connectSession = _connectSession;
			_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			_collectionNode.addEventListener(CollectionNodeEvent.NODE_CREATE, onNodeCreate);
			_collectionNode.addEventListener(CollectionNodeEvent.NODE_DELETE, onNodeDelete);
			_collectionNode.addEventListener(CollectionNodeEvent.MY_ROLE_CHANGE,onMyRoleChange);
			_collectionNode.addEventListener(CollectionNodeEvent.USER_ROLE_CHANGE,onUserRoleChange);
			_collectionNode.subscribe();
		}



		
		/**
		 * @private
		 * Helper function to add a descriptor to the list of descriptors consistently.
		 * @private
		 */
		protected function addFileDescriptorToModel(p_fileDescriptor:FileDescriptor, p_groupName:String):void
		{
			// Assert it doesn't already exist.
			if(!_fileDescriptorTable[p_fileDescriptor.id]) {
				
/**
				// Preprocessing first - anything we need to change about it?
				// If the URL doesn't begin with http, prepend it with local domain.
				if(p_fileDescriptor.url && p_fileDescriptor.url.substr(0, 4).toLowerCase() != "http") {
					var urlPrefix:String = "http://localhost:8080"; // default if loaderinfo.url isn't on HTTP
					if(Application.application.loaderInfo.url.substr(0, 4).toLowerCase() == "http") {
						urlPrefix = Application.application.loaderInfo.url.split("/").slice(0,3).join("/");
					}
					p_fileDescriptor.url = urlPrefix + p_fileDescriptor.url;
				}

				if (p_fileDescriptor.url != null && p_fileDescriptor.url.substring(0,1)=="/") {
					var hostURL:String = Application.application.loaderInfo.url;
					hostURL = URLUtil.getProtocol(hostURL)
					  + "://" + URLUtil.getServerNameWithPort(hostURL);
					p_fileDescriptor.url = hostURL
					  + p_fileDescriptor.url;
				}
*/				

				// add to file descriptors
				fileDescriptors.addItem(p_fileDescriptor);
				_fileDescriptorTable[p_fileDescriptor.id] = p_fileDescriptor;
				
				_idToGroupTable[p_fileDescriptor.id] = p_groupName;
				
				if(!_groups[p_groupName]) {
					_groups[p_groupName] = new ArrayCollection();
				}
				(_groups[p_groupName] as ArrayCollection).addItem(p_fileDescriptor);
				
				
				// dispatch change event
				var event:FileManagerEvent = new FileManagerEvent(FileManagerEvent.NEW_FILE_DESCRIPTOR);
				event.fileDescriptor = p_fileDescriptor;
				dispatchEvent(event);
			}
		}
		
		
		/**
		 * Helper function to modify a descriptor in place.
		 * @private
		 */
		protected function updateFileDescriptorInModel(p_fileDescriptor:FileDescriptor):void
		{
			// if it already exists, we're updating.
			if(_fileDescriptorTable[p_fileDescriptor.id]) {
				var tmpId:String = p_fileDescriptor.id;
				for(var i:int = 0; i < fileDescriptors.length; i++) {
					if(tmpId == fileDescriptors[i].id) {
						fileDescriptors.setItemAt(p_fileDescriptor, i);
						break;
					}
				}
				_fileDescriptorTable[tmpId] = p_fileDescriptor;
				// No need to change "group" data structures... right?
				var groupName:String = findGroupFor(tmpId);
				var groupCollection:ArrayCollection = _groups[groupName] as ArrayCollection;
				var l:int = groupCollection.length;
				for(i=0; i < l ; i++) {
					if(tmpId == groupCollection[i].id) {						 
						groupCollection.setItemAt(p_fileDescriptor, i);
						break;
					}
				}
				
				var event:FileManagerEvent = new FileManagerEvent(FileManagerEvent.UPDATED_FILE_DESCRIPTOR);
				event.fileDescriptor = p_fileDescriptor;
				dispatchEvent(event);
			}
			else {
				throw new Error("updateFileDescriptorInModel: That FileDescriptor does not exist.");
			}
		}		
		
		
		/**
		 * Helper function to remove a descriptor from the model.
		 * @private
		 */
		protected function clearFileDescriptorFromModel(p_fileDescriptor:FileDescriptor):void
		{
			if(_fileDescriptorTable[p_fileDescriptor.id]) {
				// if we wanted to be real freaks for efficiency, set up another table to jump to the arraycollection's index.
				// This operation is too rare to justify for now.
				for(var i:int = 0; i < fileDescriptors.length; i++) {
					if(p_fileDescriptor.id == fileDescriptors[i].id) {
						fileDescriptors.removeItemAt(i);
						break;
					}
				}
				delete _fileDescriptorTable[p_fileDescriptor.id];
				
				var group:ArrayCollection = _groups[_idToGroupTable[p_fileDescriptor.id]];
				// If it's the only member of the group, kill the group.
				// TODO: Raph - decide whether or not to kill the node on the CollectionNode, too?
				if(group.length == 1) {
					group.removeAll();
					//delete _groups[_idToGroupTable[p_fileDescriptor.id]];
				}
				else {
					for (var idx:int = 0; idx < group.length; idx++) {
						if (p_fileDescriptor.id == group[idx].id) {
							group.removeItemAt(idx);
							break;
						}
					}
				}
				
				delete _idToGroupTable[p_fileDescriptor.id];
				
				var event:FileManagerEvent = new FileManagerEvent(FileManagerEvent.CLEARED_FILE_DESCRIPTOR);
				event.fileDescriptor = p_fileDescriptor;
				dispatchEvent(event);
			}
		}
		
		/**
		 * @private
		 * Reconstructs a FileDescriptor out of a message item and its attached value object.
		 * 
		 * @param p_item The MessageItem with FileDescriptor body to reconstruct.
		 * @return The reconstructed descriptor.
		 */		
		protected function buildFileDescriptor(p_item:MessageItem):FileDescriptor
		{
			var descriptor:FileDescriptor = new FileDescriptor();
			descriptor.readValueObject(p_item.body);
			var tokenStr:String = "?mst="+ _userManager.myTicket+"&token="+ descriptor.token;
			descriptor.downloadUrl = descriptor.url + descriptor.filename + tokenStr ;
			descriptor.lastModified = p_item.timeStamp;
			descriptor.submitterID = p_item.associatedUserID;
			descriptor.id = p_item.itemID;
			return descriptor;
		}
		
		/**
		 * @private
		 * Creates a new group node.
		 * 
		 * @param p_groupName The name of the node.
		 */		
		protected function createGroupNode(p_groupName:String, p_nodeConfiguration:NodeConfiguration = null):void
		{
			if(!p_nodeConfiguration) {
				p_nodeConfiguration = new NodeConfiguration();
				p_nodeConfiguration.itemStorageScheme = NodeConfiguration.STORAGE_SCHEME_MANUAL;
				p_nodeConfiguration.modifyAnyItem = false;
			}
			_collectionNode.createNode(p_groupName, p_nodeConfiguration);
		}
		
		
		/* Event handlers
		//////////////////////////////////////////////////////////////////////////////////////////////////////////*/

		
		
		
		
		/**
		 * Event handler for <code>CollectionNodeEvent.ITEM_RECEIVE</code>. This function is 
		 * responsible for keeping the internal representation of data consistent with the 
		 * logical representation "agreed on" by all the other client instances; it must 
		 * respond consistently to incoming transaction messages.
		 * 
		 * @param p_event The event to handle.
		 * @private
		 */		
		protected function onItemReceive(p_event:CollectionNodeEvent):void
		{
			var item:MessageItem = p_event.item;
												
			if(item.nodeName == GLOBALSETTINGS){
				if(item.itemID == MAXFILESIZE) {
					_maxFileSize = item.body;
				}
				return;
			}
										
			var fileDescriptor:FileDescriptor = buildFileDescriptor(item);
			
			// Get it into the model somehow.
			if(getFileDescriptor(fileDescriptor.id)) {
				updateFileDescriptorInModel(fileDescriptor);
			}
			else {
				addFileDescriptorToModel(fileDescriptor, p_event.nodeName);
			}
			
			// This item may be an actual "file-uploading" message, or it might be a descriptor announcing
			//   the intention to upload one later.
			if(fileDescriptor.state == FileDescriptor.ANNOUNCING_INTENTION_TO_PUBLISH
				&& fileDescriptor.submitterID == _userManager.myUserID) {
				
				var newEvent:FileManagerEvent = new FileManagerEvent(FileManagerEvent.READY_FOR_UPLOAD);
				newEvent.fileDescriptor = fileDescriptor;
				dispatchEvent(newEvent);
			}
		}
	
		/**
		 * Event handler for <code>CollectionNodeEvent.ITEM_RETRACT</code>. Like <code>onItemReceive</code>, 
		 * this function is responsible for keeping the internal representation of data consistent with the 
		 * logical representation "agreed on" by all the other client instances. It must respond consistently 
		 * to incoming transaction messages. This handler deals specifically with retractions of existing 
		 * MessageItems.
		 * 
		 * <p>For the FileManager, this involves clearing retracted FileDescriptors from storage.</p>
		 * 
		 * @param p_event The event to handle.
		 * @private
		 */		
		protected function onItemRetract(p_event:CollectionNodeEvent):void
		{
			var item:MessageItem = p_event.item;
			var fileDescriptor:FileDescriptor = buildFileDescriptor(item);
	
			// Erase it from storage.
			clearFileDescriptorFromModel(fileDescriptor);
		}
		
		/**
		 * Event handler for <code>CollectionNodeEvent.SYNCHRONIZATION_CHANGE</code>. This handles 
		 * two cases: when the CollectionNode instance has received all previous MessageItems and 
		 * is synchronized with other instances on the server and when the CollectionNode 
		 * falls out of synchronization due to a connection failure or some other reason.
		 * 
		 * <p>The first host to enter the room also bears the responsibility of creating and configuring the
		 * file upload node.  Aside from that, the handler's other duty is to clear out the local model on
		 * disconnect so that the next time synchronization happens the model will be ready for repopulating
		 * from scratch.</p>
		 * 
		 * @param p_event The event to handle.
		 * @private
		 */		
		protected function onSynchronizationChange(p_event:CollectionNodeEvent):void
		{
			// Just synced up.  If I'm a host, I need to create the node now.
			if(_collectionNode.isSynchronized) {
/*				if(!_collectionNode.isNodeDefined(NODE_NAME_FILES) && _collectionNode.canUserConfigure(_userManager.myUserID)) {
					var config:NodeConfiguration = new NodeConfiguration();
					config.itemStorageScheme = NodeConfiguration.STORAGE_SCHEME_QUEUE;
					config.modifyAnyItem = false;
					_collectionNode.createNode(NODE_NAME_FILES, config);
				} */
				
			}
			// Just lost connection.
			else {
				amIUploadingFile = false; //Incase a file upload operation was terminated
				_collectionNode.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
				_collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
				_collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
				_collectionNode.removeEventListener(CollectionNodeEvent.NODE_CREATE, onNodeCreate);
				_collectionNode.removeEventListener(CollectionNodeEvent.NODE_DELETE, onNodeDelete);
				_collectionNode.removeEventListener(CollectionNodeEvent.MY_ROLE_CHANGE,onMyRoleChange);
				_collectionNode.removeEventListener(CollectionNodeEvent.USER_ROLE_CHANGE,onUserRoleChange);
				// throw away our old collectionNode - connectSession will tell us to make a new one manually
				_collectionNode.unsubscribe();
			}
			
			dispatchEvent(p_event);
		}
		
		
		/**
		 * @private
		 */
		protected function onNodeCreate(p_event:CollectionNodeEvent):void 
		{
			var nodeName:String = p_event.nodeName;
			if (!_groups[nodeName]) {
				_groups[nodeName] = new ArrayCollection();
			}
			dispatchEvent(p_event);
		}
		
		/**
		 * @private
		 */
		protected function onNodeDelete(p_event:CollectionNodeEvent):void {
			_groups[p_event.nodeName] = null;
			dispatchEvent(p_event);
		}
		
			
		/**
		 * @private
		 * handles the my role change event
		 */
		protected function onMyRoleChange(p_evt:CollectionNodeEvent):void
		{
			dispatchEvent(p_evt);	// bubble it up
		}
		
		/**
		 * @private
		 * handles the onuser role change event
		 */
		protected function onUserRoleChange(p_evt:CollectionNodeEvent):void
		{
			dispatchEvent(p_evt);	// bubble it up
		}
		
		
		
		/**
		 * @private
		 * Internal function for generating the unique Ids
		 */
		private function createUID():String
	    {
	        var uid:Array = new Array(36);
	        var index:int = 0;
	        
	        var i:int;
	        var j:int;
	        
	        for (i = 0; i < 8; i++)
	        {
	            uid[index++] = ALPHA_CHAR_CODES[Math.floor(Math.random() *  16)];
	        }
	
	        for (i = 0; i < 3; i++)
	        {
	            uid[index++] = 45; // charCode for "-"
	            
	            for (j = 0; j < 4; j++)
	            {
	                uid[index++] = ALPHA_CHAR_CODES[Math.floor(Math.random() *  16)];
	            }
	        }
	        
	        uid[index++] = 45; // charCode for "-"
	
	        var time:Number = new Date().getTime();
	        // Note: time is the number of milliseconds since 1970,
	        // which is currently more than one trillion.
	        // We use the low 8 hex digits of this number in the UID.
	        // Just in case the system clock has been reset to
	        // Jan 1-4, 1970 (in which case this number could have only
	        // 1-7 hex digits), we pad on the left with 7 zeros
	        // before taking the low digits.
	        var timeString:String = ("0000000" + time.toString(16).toUpperCase()).substr(-8);
	        
	        for (i = 0; i < 8; i++)
	        {
	            uid[index++] = timeString.charCodeAt(i);
	        }
	        
	        for (i = 0; i < 4; i++)
	        {
	            uid[index++] = ALPHA_CHAR_CODES[Math.floor(Math.random() *  16)];
	        }
	        
	        return String.fromCharCode.apply(null, uid);
	    }
		
		
	}
}
