// ActionScript file
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
package com.adobe.rtc.pods.cameraClasses
{
	import com.adobe.rtc.events.CameraModelEvent;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedModel.CollectionNode;
	
	import flash.events.EventDispatcher;

	/**
	 * Dispatched when the CameraModel has fully connected and synchronized with the service 
	 * or when it loses that connection.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	
	/**
	 * Dispatched when the user's role with respect to this component changes.
	 */
	[Event(name="myRoleChange", type="com.adobe.rtc.events.CollectionNodeEvent")]
	/**
	 * Dispatched when the quality settings for the web camera change.
	 */
	[Event(name="qualityChange", type="com.adobe.rtc.events.CameraModelEvent")]
	/**
	 * Dispatched when the layout settings for the web camera change.
	 */
	[Event(name="layoutChange", type="com.adobe.rtc.events.CameraModelEvent")]
	 


	/**
	 * CameraModel is a model component which drives the WebCamera pod  
	 * and keeps the shared properties of the WebCamera pod synchronized 
	 * across multiple users. It exposes methods for manipulating that shared 
	 * model and emits events indicating when that model changes. In general, users 
	 * with a publisher role and higher can change camera settings, while those 
	 * with the viewer role can see the results. The CameraModel features synchronized
	 * quality options and layout settings among web camera pods. The rest of 
	 * the model for WebCamera comes from the StreamManager.
	 * <p>
	 * 
	 * @see com.adobe.rtc.pods.WebCamera
	 * @see com.adobe.rtc.sharedModel.CollectionNode
	 * @see com.adobe.rtc.sharedManagers.StreamManager
	 */
   public class  CameraModel extends EventDispatcher implements ISessionSubscriber
	 {	
	 	/**
	 	 * Constant value for the "slow images" quality setting for use in low-bandwidth situations.
	 	 */
	 	public static const SLOW_IMAGES:String = "slow";
	 	/**
	 	 * Constant value for the "fast images" quality setting for use when motion is more important 
		 * than picture quality.
	 	 */
	 	public static const FAST_IMAGES:String = "fast";
	 	/**
	 	 * Constant value for the "high quality" quality setting for use when picture quality 
		 * is of the most importance.
	 	 */
	 	public static const HIGH_QUALITY:String = "high_q";
	 	/**
	 	 * Constant value for the "High Bandwidth" quality setting for use in high-bandwidth situations.
	 	 */
	 	public static const HIGH_BW:String = "high_bw";
		
	 	/**
	 	 * Constant value for the "side by side" layout setting.
	 	 */
		public static const SIDE_BY_SIDE:String = "sbs";
	 	
		/**
	 	 * <strong>Deprecated</strong>: Constant value for the "picture in picture" layout setting. 
		 * This functionality is scheduled to be reworked.
	 	 */
		public static const PICTURE_IN_PICTURE:String = "pip";
	 	
		/**
	 	 * <strong>Deprecated</strong>: Constant value for the "new picture in picture" layout setting.
		 * This functionality is scheduled to be reworked.
	 	 */
		public static const NEW_PICTURE_IN_PICTURE:String = "npip";
		
		/**
		 * @private
		 */
		protected const VIDEO_SETTING_NODE_NAME:String = "videoQuality";

		/**
		 * @private
		 */
		protected const LAYOUT_SETTING_NODE_NAME:String = "layoutMode";
	 	
		/**
		 * @private
		 */
		protected var _collectionNode:CollectionNode;

		/**
		* @private
		*/		
		protected var _videoSetting:String = CameraModel.HIGH_BW;

		/**
		* @private
		*/		
		protected var _cachedVideoSetting:String;

		/**
		* @private
		*/		
		protected var _layoutSetting:String = CameraModel.SIDE_BY_SIDE;

		/**
		* @private
		*/		
		protected var _cachedLayoutSetting:String;

		/**
		 * @private
		 */
		protected var _userManager:UserManager;
		/**
		 * @private
		 */
		protected var _sharedID:String = "default_WebCamera";
		
		/**
		 * 
		 * @private
		 */
		protected var _videoSettingStringTable:Object;
		/**
		 * @private 
		 */		
		protected var _connectSession:IConnectSession = ConnectSession.primarySession;
			
		/**
		 * Constructor. 
		 *
		 * @param p_id The unique ID for this model that is typically passed down 
		 * from the pod component's ID.
		 */
		public function CameraModel():void
		{
			
		}
		
		
		/**
		 * Tells the component to begin synchronizing with the service.  
		 * For "headless" components such as this one, this method must be called explicitly.
		 */
		public function subscribe():void
		{
			_collectionNode = new CollectionNode();
			_collectionNode.sharedID = sharedID ;
			_collectionNode.connectSession = _connectSession ;
			_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.subscribe();
			
			_userManager = _connectSession.userManager;

			_videoSettingStringTable = new Object();
			_videoSettingStringTable[CameraModel.SLOW_IMAGES] = "Slow Images";
			_videoSettingStringTable[CameraModel.FAST_IMAGES] = "Fast Images";
			_videoSettingStringTable[CameraModel.HIGH_QUALITY] = "High Quality Images";
			_videoSettingStringTable[CameraModel.HIGH_BW] = "High Bandwidth";
		}
		
		/**
		 *  Sets the role of a given user for video streams, within the group this component is assigned to.
		 * 
		 * @param p_userID UserID of the user whose role we are setting
		 * @param p_userRole Role value we are setting
		 */
		public function setUserRole(p_userID:String, p_role:Number, p_nodeName:String=null):void
		{
			if ( p_userID == null ) 
				return ;
				
			
			if ( (p_role < 0 || p_role > 100) && p_role != CollectionNode.NO_EXPLICIT_ROLE ) 
				return ; 
				
			
			if (p_nodeName) {
				if ( _collectionNode.isNodeDefined(p_nodeName)) {
					 _collectionNode.setUserRole(p_userID,p_role,p_nodeName);
				}else {
					throw new Error("CameraModel: The node on which role is being set doesn't exist");
				}
			}else {
				_collectionNode.setUserRole(p_userID,p_role);
			}	
		}
		
		/**
		 *  Returns the role of a given user for video streams, within the group this component is assigned to.
		 * 
		 * @param p_userID UserID of the user in question
		 */
		public function getUserRole(p_userID:String):int
		{
			if ( p_userID == null ) {
				throw new Error("CameraModel: USerId can't be null");
			}
			
			return _collectionNode.getUserRole(p_userID);
		}
		
		
		/**
		 * @private
		 * The <code>sharedID</code> is the ID of the class 
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
		 * The IConnectSession with which this component is associated. Note that this may only be set once before <code>subscribe</code>
		 * is called; re-sessioning of components is not supported. Defaults to the first IConnectSession created in the application.
		 */
		public function get connectSession():IConnectSession
		{
			return _connectSession;
		}
		
		public function set connectSession(p_session:IConnectSession):void
		{
			_connectSession = p_session;
		}
		
		//[Bindable(event="synchronizationChange")]
		/**
		 * Determines whether the CameraModel is connected and fully synchronized with the service.
		 */
		public function get isSynchronized():Boolean
		{
			return _collectionNode.isSynchronized;	//no need to check baton since it uses my collection
		}
		
		/**
		 * Specifies the video quality settings which is selected from one of the setting constants 
		 * belonging to this class.
		 * 
		 * @return 
		 */
		public function get videoSetting():String
		{
			return _videoSetting;	
		}
		
		/**
		 * Returns a human-readable string for the selected video quality setting.
		 */
		public function get videoSettingString():String
		{
			return _videoSettingStringTable[_videoSetting];
		}
		
		/**
		 * @private
		 */
		public function set videoSetting(p_value:String):void
		{
			if (p_value == _videoSetting) {
				return;
			}
			

			switch (p_value) {
				case CameraModel.SLOW_IMAGES:
				case CameraModel.FAST_IMAGES:
				case CameraModel.HIGH_QUALITY:
				case CameraModel.HIGH_BW:
					break;
				default:
					throw new Error("Invalid videoSetting parameter");
					return;
			}

			// detect if this request is happening on initialization
			if(!_collectionNode.isSynchronized)
				_cachedVideoSetting = p_value;
			else {
				_collectionNode.publishItem(new MessageItem(VIDEO_SETTING_NODE_NAME, p_value));
			}
		}


		/**
		 * Specifies the layout setting of the camera. It is chosen from among this class's 
		 * layout setting constants. The following values are allowed: 
		 * <ul>
		 * <li><strong>sbs</strong>: Side-by-side. This is the default and is <strong>currently the 
		 * only one that works properly.</strong></li>
		 * <li><strong>pip</strong>: Deprecated. Value for the "picture in picture" layout setting. 
		 * TODO: This functionality is  scheduled to be reworked. </li>
		 * <li><strong>npip</strong>: New picture in a picture. </li>
		 * </ul>
		 * 
		 * @default sbs 
		 */
		public function get layoutSetting():String
		{
			return _layoutSetting;
		}
			
		/**
		 * @private
		 */
		public function set layoutSetting(p_value:String):void
		{
			if (p_value == _layoutSetting) {
				return;
			}
			
			switch (p_value) {
				case CameraModel.PICTURE_IN_PICTURE:
				case CameraModel.SIDE_BY_SIDE:
				case CameraModel.NEW_PICTURE_IN_PICTURE:
					break;
				default:
					throw new Error("Invalid layoutSetting parameter");
					return;
			}

			// detect if this request is happening on initialization
			if(!_collectionNode.isSynchronized)
				_cachedLayoutSetting = p_value;
			else {
				_collectionNode.publishItem(new MessageItem(LAYOUT_SETTING_NODE_NAME, p_value));
			}
		}

		/**
		 * Disposes all listeners to the network and framework classes. Use of <code>close()</code>
		 * is recommended for proper component garbage collection.
		 */
		public function close():void
		{
			_collectionNode.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			_collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.unsubscribe();
			_collectionNode.close();
			_collectionNode = null ;
			
		}
		
		
		/**
		 * Gets the NodeConfiguration on a specific node in the NodeModel. If the node is not defined, it will return null
		 * @param p_nodeName The node name of the Node Configuration.
		 */
		public function getNodeConfiguration(p_nodeName:String):NodeConfiguration
		{	
			if ( _collectionNode.isNodeDefined(p_nodeName)) {
				return _collectionNode.getNodeConfiguration(p_nodeName).clone();
			}
			
			return null ;
		}
		
		/**
		 * Sets the NodeConfiguration on a already defined node. If the node is not defined, it will not do anything.
		 * @param p_nodeConfiguration The node Configuration on a node in the NodeConfiguration.
		 * @param p_nodeName The node name of the Node Configuration.
		 */
		public function setNodeConfiguration(p_nodeName:String,p_nodeConfiguration:NodeConfiguration):void
		{	
			if ( _collectionNode.isNodeDefined(p_nodeName)) {
				_collectionNode.setNodeConfiguration(p_nodeName,p_nodeConfiguration) ;
			}
			
		}
		
	
		/**
		 * The synchronization change handler. 
		 *
		 * @private
		 */
		protected function onSynchronizationChange(event:CollectionNodeEvent):void
		{			
			if (_collectionNode.isSynchronized) {
				//If collection node is synchronized then create the nodeconfiguration and the nodes
				// if node for scrolling indices is not defined ( created ), then create it with the node configuration
				if (!_collectionNode.isNodeDefined(VIDEO_SETTING_NODE_NAME) && _collectionNode.canUserConfigure(_userManager.myUserID)){
					//create the node by publishing the default value
					_collectionNode.publishItem(new MessageItem(VIDEO_SETTING_NODE_NAME, CameraModel.HIGH_BW));
				}
				if (!_collectionNode.isNodeDefined(LAYOUT_SETTING_NODE_NAME) && _collectionNode.canUserConfigure(_userManager.myUserID)){
					_collectionNode.publishItem(new MessageItem(LAYOUT_SETTING_NODE_NAME, CameraModel.SIDE_BY_SIDE));
				}
			
				// if the cached scroll position is  not null, then update the model with it and set the cached value to null
				if (_videoSetting == null && _cachedVideoSetting != null){
					videoSetting = _cachedVideoSetting;
					_cachedVideoSetting=null;
				}

				if (_layoutSetting == null && _cachedLayoutSetting != null){
					layoutSetting = _cachedLayoutSetting;
					_cachedLayoutSetting=null;
				}					
			} else {
				//clean up local model, it will "come back" when I reconnect
			}
			
			dispatchEvent(event);	//bubble it
		}		
		
		
		/**
		 * @private
		 */
		protected function onItemReceive(event:CollectionNodeEvent):void
		{
			var theItem:MessageItem = event.item;
			
			switch(theItem.nodeName) {
				case VIDEO_SETTING_NODE_NAME:
					_videoSetting = theItem.body;
					dispatchEvent(new CameraModelEvent(CameraModelEvent.QUALITY_CHANGE));
					break;
				case LAYOUT_SETTING_NODE_NAME:
					_layoutSetting = theItem.body;
					dispatchEvent(new CameraModelEvent(CameraModelEvent.LAYOUT_CHANGE));
					break;
			}
		}
		
		/**
		 * Handler for the <code>myRoleChange</code>.
		 * @private
		 */
		protected function onMyRoleChange(p_evt:CollectionNodeEvent):void
		{
			dispatchEvent(p_evt);
		}
	}
}