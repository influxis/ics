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
	import com.adobe.coreUI.controls.WhiteBoard;
	import com.adobe.coreUI.controls.whiteboardClasses.IWBShapeFactory;
	import com.adobe.coreUI.controls.whiteboardClasses.ToolBarDescriptors.WBToolBarDescriptor;
	import com.adobe.coreUI.controls.whiteboardClasses.WBModel;
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapesToolBar;
	import com.adobe.coreUI.events.WBCanvasEvent;
	import com.adobe.coreUI.events.WBModelEvent;
	import com.adobe.coreUI.localization.Localization;
	import com.adobe.rtc.collaboration.SharedCursorPane;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.pods.sharedWhiteBoardClasses.SharedWBModel;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
	
	import mx.core.UIComponent;
	
	/**
	 * Dispatched when the whiteboard goes in and out of sync.
	 */
	[Event(name="synchronizationChange", type="com.adobe.coreUI.events.WBModelEvent")]	
	
	/**
	 * The SharedWhiteBoard is a UIComponent that allows multiple users to 
	 * collaboratively draw on a shared canvas. In general, users with a publisher
	 * role and higher are allowed to publish and users with a viewer role can 
	 * see the drawing.
	 * 
	 * TODO: Due to extreme complexity, full documentation is still forthcoming... I know we said we would do this, 
	 * it's on the list for the next beta drop =)
	 */
   public class  SharedWhiteBoard extends WhiteBoard implements ISessionSubscriber
	{
		
		/**
		 * @private
		 */
		protected var _cursorPane:SharedCursorPane;
		
		[Inspectable(enumeration="false,true", defaultValue="false")]
		/**
		 * Whether or not the whiteboard should be cleaned upon the end of the session.
		 */
		public var sessionDependent:Boolean = false;
		
		/**
		 * @private
		 */
		public var isStandalone:Boolean = true;
		
		/**
		 * @private
		 */
		protected var _sharedID:String;
		
		/**
		 * @private
		 */
		private const DEFAULT_SHARED_ID:String = "default_WB";
		
		/**
		 * @private
		 */
		protected var _subscribed:Boolean = false ;
		
		/**
		 * @private 
		 */		
		protected var _connectSession:IConnectSession = new SessionContainerProxy(this as UIComponent);
		
		
		/**
		 * Disposes all listeners to the network and framework classes. Recommended 
		 * for proper garbage collection of the component.
		 */
		public function close():void
		{
			if (_cursorPane ) {
				_cursorPane.close();
			}
			if ( _model ) {
				SharedWBModel(_model).close();
			}
			if (_toolBar) {
				_toolBar.visible = false;
				if (contains(_toolBar)) {
					removeChild(_toolBar);
					_toolBar = null;
				}
			}
			if (_propsBar) {
				_propsBar.visible = false;
				if (contains(_propsBar)) {
					removeChild(_propsBar);
				}
				_propsBar = null;
			}
			_canvas.close();
			if (contains(_canvas)) {
				removeChild(_canvas);
			}
			_canvas = null;
		}
		
		/**
		 * Defines the logical location of the component on the service, usually the <code>sharedID</code> of the collectionNode 
		 * the component uses. <code>sharedIDs</code> should be unique within a room if they're expressing two unique locations. 
		 * Note that this can only be assigned once and it is assigned before <code>subscribe()</code> is called. 
		 * For components with an <code class="property">id</code> property, <code>sharedID</code> defaults to that value.
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
		
		/**
		 * @private
		 */
		override protected function createChildren():void
		{
			super.createChildren();
			_toolBar.visible = false;
		}
		
		/**
		 * Tells the component to begin synchronizing with the service. 
		 * For UIComponent-based components such as this one,
		 * <code>subscribe()</code> is called automatically upon being added to the <code>displayList</code>. 
		 * For "headless" components, this method must be called explicitly.
		 */
		public function subscribe():void
		{
			if (!_model) {
				if ( id == null ){
					if ( sharedID == null ) {
						sharedID = DEFAULT_SHARED_ID ;
					}
				}else {
					if ( sharedID == null ) {
						sharedID = id ;
					}
				}
				
				_model = new SharedWBModel();
				_canvas.model = _model;
				var sharedWBModel:SharedWBModel = SharedWBModel(_model) ;
				sharedWBModel.sessionDependent = sessionDependent;
				sharedWBModel.sharedID = sharedID;
				sharedWBModel.connectSession = _connectSession ;
				sharedWBModel.subscribe();
				sharedWBModel.addEventListener(WBModelEvent.MY_ROLE_CHANGE, onMyRoleChange);
				sharedWBModel.addEventListener("synchronizationChange", onSyncChange);
				// since the canvas's model has changed, we need to assign it to the toolbar
				
			}
		}
		
		/**
		 * 
		 * @inheritdoc
		 * 
		 */
		override public function set model(p_wbModel:WBModel):void
		{
			super.model = p_wbModel;
			if (p_wbModel.isSynchronized) {
				onSyncChange(); 
			}
			var sharedWBModel:SharedWBModel = p_wbModel as SharedWBModel;
			sharedWBModel.addEventListener(WBModelEvent.MY_ROLE_CHANGE, onMyRoleChange);
			sharedWBModel.addEventListener("synchronizationChange", onSyncChange);
		} 
		
		/**
		 *  Sets the role of a given user for the WhiteBoard.
		 * 
		 * @param p_userRole The role value to set on the specified user.
		 * @param p_userID The ID of the user whose role should be set.
		 */
		public function setUserRole(p_userID:String,p_userRole:int):void
		{
			if ( p_userID == null ) 
				return ;
			
			SharedWBModel(_model).setUserRole(p_userID,p_userRole);
		}
		
		
		/**
		 *  Returns the role of a given user for the WhiteBoard.
		 * 
		 * @param p_userID The user ID for the user being queried.
		 */
		public function getUserRole(p_userID:String):int
		{
			if ( p_userID == null ) {
				throw new Error("CameraModel: USerId can't be null");
			}
			
			return SharedWBModel(_model).getUserRole(p_userID);
		}
		
		[Bindable(event="synchronizationChange")]
		/**
		 * Returns true if the model is synchronized; otherwise, false.
		 */
		public function get isSynchronized():Boolean
		{
			if ( !_model ) {
				return false ;
			}
			
			return _model.isSynchronized ;
		}
		
		/**
		 * Registers the factory class for creating a custom shape. Custom Shapes are not drawn if the Shapes class is not 
		 * registered. The custom shapes are always registered with the SharedWhiteBoard when they are added to the toolBar.
		 * This method is needed when shapes are added programatically or using other UIComponents such as the button.
		 * <code>SharedWhiteBoard.registerFactory(new WBCustomShapeFactory(CustomShape,null,null))</code>  
		 */
		public function registerFactory(p_factory:IWBShapeFactory):void
		{
			_canvas.registerFactory(p_factory);
		}

		
		/**
		 * @private
		 */
		override protected function commitProperties():void
		{
			if ( !_subscribed ) {
				subscribe();
				_subscribed = true ;
				
			}
			
			
			if (!_cursorPane) {
				_cursorPane = new SharedCursorPane();
				_canvas.addEventListener(WBCanvasEvent.CURSOR_CHANGE, onCursorChange);
				SharedWBModel(_model).sharedCursorPane = _cursorPane;
				addChild(_cursorPane);
			}
			super.commitProperties();
			
		}
		
		
		/**
		 * @private
		 */
		protected function onCursorChange(p_evt:WBCanvasEvent):void
		{
			_cursorPane.myCursorClass = _canvas.currentCursorClass;
		}
		
		/**
		 * @private
		 */
		protected function onSyncChange(p_evt:WBModelEvent=null):void
		{
			if (SharedWBModel(_model).isSynchronized) {
				onMyRoleChange();
			} else {
				// we disconnected
				if (_toolBar && _toolBar.visible) {
					if (allowSave) {
						_toolBar.dataProvider = 
							[
								{type:"label", label:Localization.impl.getString("Actions")},
								{type:"command", toolTip:Localization.impl.getString("Save as File"), icon:WBToolBarDescriptor.ICON_SAVE, command:WBToolBarDescriptor.COMMAND_SAVE}
							];
					} else {
						_toolBar.visible = false;
					}
				}
				if (currentPropertiesToolBar) {
					currentPropertiesToolBar.visible = false;
				}
				_canvas.selectedShapeIDs = [];
				_canvas.enableShapeSelection = false;
				_canvas.currentShapeFactory = null;
			}
			if (p_evt!=null) {
				dispatchEvent(p_evt);
			}
		}
		
		/**
		 * @private
		 */
		protected function onMyRoleChange(p_evt:WBModelEvent=null):void
		{
			if (SharedWBModel(_model).canUserDraw(_connectSession.userManager.myUserID)) {
				if (_toolBar) {
					_toolBar.visible = true;
				}
				if (currentPropertiesToolBar) {
					currentPropertiesToolBar.visible = true;
				}
			} else {
				if (_toolBar) {
					_toolBar.visible = false;
				}
				if (currentPropertiesToolBar) {
					currentPropertiesToolBar.visible = false;
				}
				_canvas.selectedShapeIDs = [];
				_canvas.enableShapeSelection = false;
				_canvas.currentShapeFactory = null;
				_canvas.clearTextEditor();
			}
			if (p_evt) {
				dispatchEvent(p_evt);
			}
		}
		
		/**
		 * @private
		 */
		override protected function updateDisplayList(p_width:Number, p_height:Number):void
		{
			super.updateDisplayList(p_width, p_height);
			if (_cursorPane) {
				if (!isStandalone) {
					_cursorPane.setActualSize(p_width*Math.min(_zoomLevel, 1), p_height*Math.min(_zoomLevel, 1));
				} else {
					_cursorPane.setActualSize(p_width, p_height);
				}
			}
		}
		
		
		
		
	}
}