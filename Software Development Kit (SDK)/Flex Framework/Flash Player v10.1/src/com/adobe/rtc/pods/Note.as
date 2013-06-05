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
package com.adobe.rtc.pods
{
	/**
	 * We import the View, model, event and UIComponent classes. 
	 */
	import com.adobe.coreUI.controls.CustomMenu;
	import com.adobe.coreUI.controls.CustomTextEditor;
	import com.adobe.coreUI.controls.ProgressiveDisclosureContainer;
	import com.adobe.coreUI.localization.ILocalizationManager;
	import com.adobe.coreUI.localization.Localization;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.NoteEvent;
	import com.adobe.rtc.events.SharedModelEvent;
	import com.adobe.rtc.events.SharedPropertyEvent;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.pods.noteClasses.NoteModel;
	import com.adobe.rtc.pods.noteClasses.NoteUndoRedo;
	import com.adobe.rtc.pods.noteClasses.NotepodToolBar;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
	import com.adobe.rtc.sharedManagers.UserManager;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Label;
	import mx.controls.textClasses.TextRange;
	import mx.core.DeferredInstanceFromFunction;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.DropdownEvent;
	import mx.events.MenuEvent;
	import mx.events.ScrollEvent;
	import mx.managers.IFocusManagerComponent;
	
	
	
	
	[Style(name="fillColors", type="Array", inherit="no")]
	[Style(name="fillAlphas", type="Array", inherit="no")]
	/**
	 * Dispatched when the component either loses its connection to the session or regains it
	 * and has finished re-synchronizing itself to the rest of the room.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	
	/**
	 * Dispatched when the user's role with respect to the component changes.
	 */
	[Event(name="myRoleChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	
	/**
	 * Dispatched when the note text changes.
	 */
	[Event(name="change", type="com.adobe.rtc.events.SharedPropertyEvent")]

	/**
	 * The Note component is a high-level pod component which allows multiple users to 
	 * collaboratively edit within a text editor. In the model-view-controller sense, the note is the view 
	 * and controller to the NoteModel's model since it consumes user events, drives them 
	 * to the model, accepts model events, and updates the view.
	 * <p>
	 * In general, users with publisher role and higher can edit the note while users with 
	 * a viewer role can see the note. The note pod features synchronized text, selection, and 
	 * scroll position, as well as a list of users who are currently editing.
	 * 
	 * @see com.adobe.rtc.pods.noteClasses.NoteModel
	 */
   public class  Note extends UIComponent implements IFocusManagerComponent,ISessionSubscriber
	{
		/**
		 * uses the customText Editor as its text
		 * @private
		 */
		protected var _editor:CustomTextEditor;

		/**
		 * The toolBar for getting controls like bold/italic/bullet/color. 
		 * 
		 * @private
		 */		
		protected var _editorToolBar:NotepodToolBar;

		/**
		* @private
		*/			
		protected var _noteUndoRedo:NoteUndoRedo;
		
		/**
		 * @private
		 */
		protected var _sendDataTimer:Timer;
		
		/**
		* @private
		*/		
		protected var _scrollTimer:Timer;
		
		/**
		* @private
		*/		
		protected var _editorToolBarTimer:Timer;
		
		/**
		* @private
		*/
		protected var _isUndoRedo:Boolean=false;
		
		/**
		* @private
		*/		
		protected var _toolbarContainer:ProgressiveDisclosureContainer;
		
		/**
		* @private
		*/
		protected var _usersTypingLabel:Label;
		
		/**
		* @private
		*/		
		protected var k_CONTROLBARHEIGHT:int = 25;
		
		/**
		* @private
		*/		
		protected var _model:NoteModel;
		
		/**
		* @private
		*/		
		protected var _iAmEditing:Boolean = false;
				
		/**
		* @private
		*/			
		protected var _editingUsersListChanged:Boolean = true;	//it's important that this starts as true
	
		/**
		* @private
		*/			
		protected var _titleBarMenu:CustomMenu;
		
		/**
		* @private
		*/			
		protected var _userManager:UserManager;

		/**
		* @private
		*/			
		protected var _setFocusOnClose:Boolean = false;	//what's this?

		/**
		* @private
		*/			
		protected var _sessionDependentItems:Boolean = false;

		/**
		* @private
		*/			
    	protected var _showSaveButton:Boolean = false;
    	    	
		/**
		* @private
		*/			
		protected var _lm:ILocalizationManager = Localization.impl;
		
		/**
		* @private
		*/			
		protected var _updatingScrollFromModel:Boolean = false;
		
		/**
		* @private
		*/			
		protected var _multipleUsersTypingBg:Sprite;

		/**
		* @private
		*/			
		protected var _editorBottomOffset:uint = 0;
		/**
		 * @private
		 */
		protected var _groupName:String ;
				
		/**
		* @private
		*/			
		public var titleBarMenuData:XML;
            
        /**
		 * @private
		 */
		protected var _sharedID:String ;
		/**
		 * @private
		 */
		 private const DEFAULT_SHARED_ID:String = "default_Note";
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
		public function Note():void
		{
			super();
		}
		[Inspectable(enumeration="false,true", defaultValue="false")]
		/**
		 * Specifies whether or not the data in the note will persist after the session ends.
		 * 
		 * @default false
		 */
		public function get sessionDependentItems():Boolean
		{
			return _sessionDependentItems;
		}

		/**
		* @private
		*/			
		public function set sessionDependentItems(p_sessionDependent:Boolean):void
		{
			_sessionDependentItems = p_sessionDependent;
		}

		/**
		* @private
		*/			
    	public function set showSaveButton(p_showIt:Boolean):void
    	{
    		_showSaveButton = p_showIt;
    		//TODO: commitProperties and stuff
    	}

		/**
		* @private
		*/			
		public function get textEditor():CustomTextEditor
		{
			return _editor;
		}
				
		[Bindable(event="synchronizationChange")]
		/**
		 * Returns true if the model is synchronized; otherwise, false.
		 */
		public function get isSynchronized():Boolean
		{
			return _model.isSynchronized;
		}
		
		/**
		 * Determines whether the current user is editing the note.
		 */
		public function get editing():Boolean
		{
			return _iAmEditing;
		}
				
		/**
		* @private
		*/			
		public function get editorToolBar():ProgressiveDisclosureContainer
		{
			return _toolbarContainer;
		}
	
		/**
		* @private
		*/			
		public function get titleBarMenu():CustomMenu
		{
			return _titleBarMenu;
		}

		/**
		 * Allows access to the model component of the note.
		 */
		public function get model():NoteModel
		{
			return _model;
		}

		/**
		 * Determines the text in the note.
		 */
		public function get htmlText():String
		{
			return _editor.htmlText;
		}
		
		/**
		 * Performs an undo on the last text edit.
		 */
		public function undo():void
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER || !_model.isSynchronized) {
				return;	//just in case
			}

			_noteUndoRedo.undo();
			if ( _noteUndoRedo.head >= -1) {
				_isUndoRedo = true;
				_model.htmlText = _noteUndoRedo.text;
			}
		}	
		
		/**
		 * Performs a redo on the last un-done text edit.
		 */
		public function redo():void
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER || !_model.isSynchronized) {
				return;	//just in case
			}

			var head:Number=_noteUndoRedo.head;
			_noteUndoRedo.redo();
			if (_noteUndoRedo.head != head) {
				_isUndoRedo = true;
				_model.htmlText = _noteUndoRedo.text;
			}
		}
		
		
		/**
		 * @private
		 */
		public function set groupName(p_groupName:String):void
		{
			if ( p_groupName != _groupName ) {
				if (_model) {
					_model.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
					_model.removeEventListener(SharedPropertyEvent.CHANGE, onModelValueCommit);
					_model.removeEventListener(SharedModelEvent.SCROLL_UPDATE, onModelScroll);
					_model.removeEventListener("typingListUpdate", onEditingListUpdate);
					_model.removeEventListener(NoteEvent.SELECTION_CHANGE, onModelSelectionChange);
					_model.removeEventListener(NoteEvent.CLICK_INDEX_CHANGE, onModelClickIndexChange);
					_model.removeEventListener(CollectionNodeEvent.MY_ROLE_CHANGE, onMyRoleChange);
				}
				
				_model = null ;
				
				_groupName = p_groupName ;
				createModel(_groupName);
			}
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
			return _groupName ;
		}
			
		
		/**
		 * Clears all text from the note.
		 */
		public function clear():void
		{
			_model.htmlText = "";		
			_editor.htmlText = "";	
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
		 * Disposes all listeners to the network and framework classes. 
		 * Recommended for proper garbage collection of the component.
		 */
		public function close():void
		{
			if ( _model ) {
				_model.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
				_model.removeEventListener( SharedPropertyEvent.CHANGE, onModelValueCommit);
				_model.removeEventListener(SharedModelEvent.SCROLL_UPDATE, onModelScroll);
				_model.removeEventListener("typingListUpdate", onEditingListUpdate);
				_model.removeEventListener(NoteEvent.SELECTION_CHANGE, onModelSelectionChange);
				_model.removeEventListener(NoteEvent.CLICK_INDEX_CHANGE, onModelClickIndexChange);
				_model.removeEventListener(CollectionNodeEvent.MY_ROLE_CHANGE, onMyRoleChange);
				_model.close();
			}
			
			if ( _editor ) {
				_editor.removeEventListener(ScrollEvent.SCROLL, onEditorScroll);	
				_editor.removeEventListener(Event.CHANGE, onEditorChange);
				_editor.removeEventListener(MouseEvent.CLICK, onEditorClick);
				_editor.removeEventListener(MouseEvent.MOUSE_UP, onEditorMouseUp);	
			}
			
			if ( _toolbarContainer ) {
				_toolbarContainer.removeEventListener(MouseEvent.MOUSE_OVER, onDisclosureMouseOver);
			    _toolbarContainer.removeEventListener(MouseEvent.MOUSE_OUT, onDisclosureMouseOut);
			}

		}
		
		/**
		 * Tells the component to begin synchronizing with the service. 
		 * For UIComponent-based components such as this one,
		 * <code>subscribe()</code> is called automatically upon being added to the <code>displayList</code>. 
		 * For "headless" components, this method must be called explicitly.
		 */
		public function subscribe():void
		{
			if ( !_userManager ) {
				_userManager = _connectSession.userManager;
			}
			
			if ( !_model ) {
				// if the id is not set , then take default shared ID if it is not set not, else take the set shared id value
				// if id is set, then if shared id is not set, take set sharedID to id and take it, otherwise , take the set shared id
				
				if ( id == null ){
					if ( sharedID == null ) {
						sharedID = DEFAULT_SHARED_ID ;
					}
				}else {
					if ( sharedID == null ) {
						sharedID = id ;
					}
				}
				
			    if ( _groupName != null ) {
            		sharedID += _groupName ;
            	 }	
			
				_model = new NoteModel(_sessionDependentItems);
				_model.sharedID = sharedID ;
				_model.connectSession = _connectSession ;
				_model.subscribe() ;
				_model.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
				_model.addEventListener( SharedPropertyEvent.CHANGE, onModelValueCommit);
				_model.addEventListener(SharedModelEvent.SCROLL_UPDATE, onModelScroll);
				_model.addEventListener("typingListUpdate", onEditingListUpdate);
				_model.addEventListener(NoteEvent.SELECTION_CHANGE, onModelSelectionChange);
				_model.addEventListener(NoteEvent.CLICK_INDEX_CHANGE, onModelClickIndexChange);
				_model.addEventListener(CollectionNodeEvent.MY_ROLE_CHANGE, onMyRoleChange);
			}
			
		}
		
		/**
		 *  Sets the role of a given user for the note.
		 * 
		 * @param p_userRole The role value to set on the specified user.
		 * @param p_userID The ID of the user whose role should be set.
		 */
		public function setUserRole(p_userID:String ,p_userRole:int):void
		{
			if ( p_userID == null ) 
				return ;
				
			_model.setUserRole(p_userID,p_userRole);
		}
		
		
		/**
		 *  Returns the role of a given user for the note.
		 * 
		 * @param p_userID The user ID for the user being queried.
		 */
		public function getUserRole(p_userID:String):int
		{
			if ( p_userID == null ) {
				throw new Error("Note: The user ID can't be null");
			}
			
			return _model.getUserRole(p_userID);
		}
		
		
		/**
		* @private
		*/			
		override protected function createChildren():void
		{
			super.createChildren();

			if ( !_subscribed ) {
				subscribe();
				_subscribed = true ;
			}
					
			if(!_editor) {
				_editor = new CustomTextEditor();
				_editor.horizontalScrollPolicy = ScrollPolicy.OFF;
				_editor.addEventListener(ScrollEvent.SCROLL, onEditorScroll);	
				_editor.addEventListener(Event.CHANGE, onEditorChange);
				_editor.addEventListener(MouseEvent.CLICK, onEditorClick);
				_editor.addEventListener(MouseEvent.MOUSE_UP, onEditorMouseUp);					
				addChild(_editor);				
			}
			
			if (!_toolbarContainer) {
				_toolbarContainer= new ProgressiveDisclosureContainer();
				_toolbarContainer.target=this;
			    _toolbarContainer.disclosedComponent = new DeferredInstanceFromFunction(createToolBar);
			    _toolbarContainer.setStyle("bottom", -2);
			    _toolbarContainer.setStyle("left",0);
			    _toolbarContainer.addEventListener(MouseEvent.MOUSE_OVER, onDisclosureMouseOver);
			    _toolbarContainer.addEventListener(MouseEvent.MOUSE_OUT, onDisclosureMouseOut);
				addChild(_toolbarContainer);
			}

			if (!_multipleUsersTypingBg) {
				_multipleUsersTypingBg = new Sprite();
				addChild(_multipleUsersTypingBg);
			}
			
			if (!_usersTypingLabel) {
				_usersTypingLabel = new Label();
				_usersTypingLabel.setStyle("color", 0xcacaca);
				_usersTypingLabel.setStyle("fontFamily", "Arial");
				_usersTypingLabel.setStyle("fontStyle", "italic");
				_usersTypingLabel.setStyle("fontSize", 10);
 				addChild(_usersTypingLabel);
			}
			
			if ( !_scrollTimer ) {
				_scrollTimer = new Timer(3000, 1); //if a viewer doesnot scroll for 5 seconds, then he gets back syncd
				_scrollTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onModelScroll);
			}
						
			onMyRoleChange();			
			if (_model && _model.isSynchronized) {
				setUpFromModel();
			}
			
			invalidateProperties();
						
		}
		
		
		/**
		 * @private
		 */
		protected function createModel(p_groupName:String = null ):void
		{
			if (!_model ) {
                subscribe();
			}
		}
		
		/**
		 * When the role of the user changes TODO: . . . finish comment.
		 * @private
		 */
		protected function onMyRoleChange(p_evt:CollectionNodeEvent=null):void
		{
			
			if (_model.getUserRole(_userManager.myUserID) >= UserRoles.PUBLISHER)
			{
				if (!_sendDataTimer) {
					_sendDataTimer = new Timer(300, 1);
					_sendDataTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onSendDataTimerComplete);
				}

				if (_editorToolBar) {
					removeEditorToolBarListeners();	//in case we're going from presenter to host
					_editorToolBar.addEventListener(NoteEvent.SAVE, onSaveBtnClick);
					_editorToolBar.addEventListener(DropdownEvent.OPEN,onOpenDropDown);
					_editorToolBar.addEventListener(DropdownEvent.CLOSE,onCloseDropDown);
					_editorToolBar.addEventListener(NoteEvent.INCREASE_FONT, onFontSizeChange);
					_editorToolBar.addEventListener(NoteEvent.DECREASE_FONT, onFontSizeChange);
				}
				
				if (!_editorToolBarTimer) {
					_editorToolBarTimer = new Timer(10000, 1);	//same as the editing timer in the notemodel
					_editorToolBarTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onEditorToolBarTimerComplete);
				}

				if (!_noteUndoRedo) {
					_noteUndoRedo = new NoteUndoRedo();
				}
				
				if (hasEventListener(KeyboardEvent.KEY_UP)) {
					removeEventListener(KeyboardEvent.KEY_UP, note_onKeyUp);	//in case we're going from presenter to host
				}
				addEventListener(KeyboardEvent.KEY_UP, note_onKeyUp);
				
				if (hasEventListener(KeyboardEvent.KEY_DOWN)) {
					removeEventListener(KeyboardEvent.KEY_DOWN, note_onKeyDown);	//in case we're going from presenter to host
				}
				addEventListener(KeyboardEvent.KEY_DOWN, note_onKeyDown);


				if (_editor) {
					_editor.editable = true;
					removeEditorListeners();	//in case we're going from presenter to host
					_editor.addEventListener(Event.CHANGE, onEditorChange);
					_editor.addEventListener(MouseEvent.CLICK, onEditorClick);
					_editor.addEventListener(MouseEvent.MOUSE_UP, onEditorMouseUp);
				}
				
				if (!_titleBarMenu) {
					createTitleBarMenu();
				}
			}
			else	//viewers
			{
				if (_sendDataTimer) {
					_sendDataTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onSendDataTimerComplete);
					_sendDataTimer.stop();	//in case it war running
					_sendDataTimer = null;
				}

				//focusEnabled = false;
				
				if (_editorToolBar) {	//since we don't destroy it (grrr), I have to at least remove the listeners
					removeEditorToolBarListeners();
					hideToolBar();
				}
				
				if (_editorToolBarTimer) {
					_editorToolBarTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onEditorToolBarTimerComplete);
					_editorToolBarTimer.stop();	//in case it was running
					_editorToolBarTimer = null;
				}

				if (_noteUndoRedo) {
					_noteUndoRedo = null;
				}

				removeEventListener(KeyboardEvent.KEY_UP, note_onKeyUp);
				removeEventListener(KeyboardEvent.KEY_DOWN, note_onKeyDown);
				_editor.editable = false;
				removeEditorListeners();
				
				if (_titleBarMenu) {
	           		_titleBarMenu.removeEventListener("itemClick", onItemClick);
					_titleBarMenu = null;
				}
			}

			invalidateProperties();
			if (p_evt) {
				dispatchEvent(p_evt);	//bubble it up
			}
		}
		
		/**
		* @private
		*/			
		protected function removeEditorToolBarListeners():void
		{
			if (_editorToolBar) {
				_editorToolBar.removeEventListener(NoteEvent.SAVE, onSaveBtnClick);
				_editorToolBar.removeEventListener(DropdownEvent.OPEN, onOpenDropDown);
				_editorToolBar.removeEventListener(DropdownEvent.CLOSE, onCloseDropDown);
				_editorToolBar.removeEventListener(NoteEvent.INCREASE_FONT, onFontSizeChange);
				_editorToolBar.removeEventListener(NoteEvent.DECREASE_FONT, onFontSizeChange);			
			}
		}

		/**
		* @private
		*/			
		protected function removeEditorListeners():void
		{
			if (_editor) {
				_editor.removeEventListener(Event.CHANGE, onEditorChange);
				_editor.removeEventListener(MouseEvent.CLICK, onEditorClick);
				_editor.removeEventListener(MouseEvent.MOUSE_UP, onEditorMouseUp);
			}			
		}
		/**
		 * @private
		 * If we are using the menu and not the meeting preferences, then
		 * the following functions create and destroy the menu
		 * Function for createTitleBarMenu
		 */				
		protected function createTitleBarMenu():void 
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER) {
				return;	//just in case
			}
			
			if ( !_titleBarMenu ) {
				titleBarMenuData = 
						<root>  
							<fontSizeMenuItem label={_lm.getString("Font Size")}>
								<fontSizeItem label={_lm.getString("8")} type="radio" size="8" groupName="fontSize" />
								<fontSizeItem label={_lm.getString("10")} type="radio" size="10" groupName="fontSize" />
								<fontSizeItem label={_lm.getString("12")} type="radio" size="12" groupName="fontSize" />
								<fontSizeItem label={_lm.getString("14")} type="radio" size="14" groupName="fontSize" />
								<fontSizeItem label={_lm.getString("16")} type="radio" size="16" groupName="fontSize" />
								<fontSizeItem label={_lm.getString("20")} type="radio" size="20" groupName="fontSize" />
								<fontSizeItem label={_lm.getString("24")} type="radio" size="24" groupName="fontSize" />
								<fontSizeItem label={_lm.getString("36")} type="radio" size="36" groupName="fontSize" />
								<fontSizeItem label={_lm.getString("48")} type="radio" size="48" groupName="fontSize" />
							</fontSizeMenuItem> 
							<boldItem label={_lm.getString("Bold")}/> 
							<italicItem label={_lm.getString("Italic")}/> 
							<menuitem type="separator" />
							<undoMenuItem label={_lm.getString("Undo")}/> 
							<redoMenuItem label={_lm.getString("Redo")}/>
							<menuitem type="separator" />
							<clearAllMenuItem label={_lm.getString("Clear All Text")} />
							<menuitem type="separator" />
							<deleteMenuItem label={_lm.getString("Delete")}/> 
							<menuitem type="separator" />
							<selectAllMenuItem label={_lm.getString("Select All - CTRL+A")}/> 
						</root>;
						
				_titleBarMenu = CustomMenu.createCustomMenu(this, titleBarMenuData, false);
            	_titleBarMenu.labelField="@label";
           		_titleBarMenu.addEventListener("itemClick", onItemClick);
           		dispatchEvent(new NoteEvent(NoteEvent.TITLE_MENU_CREATED));
			}
		}
		
		//This fixes the bug where the menu steals focus AFTER the close tween.  Basicly we are stealing
		//focus back, if the select all command is used, see bug 	#1628229
		/**
		* @private
		*/			
		protected function textLostFocus(p_evt:Event):void
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER || !_model.isSynchronized) {
				return;	//just in case
			}
			
			if (_setFocusOnClose) {
				_editor.setFocus();
				_setFocusOnClose = false;
			} else {
				_editor.removeEventListener(FocusEvent.FOCUS_OUT, textLostFocus);
			}
		}
		
		/**
		* @private
		*/			
		override protected function focusOutHandler(event:FocusEvent):void
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER || !_model.isSynchronized) {
				return;	//just in case
			}
			
			super.focusOutHandler(event);
			
			//TODO: what?????
			
			if ( _editor ) {
				//_editor.focusEnabled = false;
//				setFocus();
				//we do not want the focus to remain when the focus sets out so which was a 
				//problem because of shared selecttion, we need to set out for all the shared also...
			}
			
			if ( _model.getUserRole(_userManager.myUserID) > UserRoles.VIEWER && _model) {
				var textRange:TextRange = _editor.selection;
				var selectionObj:Object = new Object();
				selectionObj.beginIndex = 0;
				selectionObj.endIndex = 0;
				_model.selection = selectionObj;
			}
		}
		
		/**
		* @private
		*/			
		protected function onNewMessageFocusIn(p_evt:FocusEvent):void
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER || !_model.isSynchronized) {
				return;	//just in case
			}
			
			_editor.removeEventListener(FocusEvent.FOCUS_IN, onNewMessageFocusIn);
			var tf:TextFormat = new TextFormat();	
			tf.bold = false ;
			tf.italic = false ;
			tf.color = 0x000000 ;
			tf.underline = false ;
			tf.bullet = false ;	
			textEditor.defaultTextFormat = tf ;
			_editor.htmlText = "";
			//leave the (empty) model alone, it will update after I type
		}
		
		/**
		* @private
		*/			
		protected function onItemClick(p_evt:MenuEvent):void
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER || !_model.isSynchronized) {
				return;	//just in case
			}
			
			//manifacture onEditorChange event because I want to set _iAmEditing to true
			onEditorChange();
			
			var item:XML = (p_evt.item as XML);
			switch (item.name().toString())
			{
				case "fontSizeItem":
				{
					_editor.setTextStyles('size', item.@size);
					break;
				}
				case "clearAllMenuItem":
				{
					clear();
					break;
				}
				case "boldItem":
				{
	    			_editor.setTextStyles('bold', !_editor.boldSelected);
					break;
				}
				case "italicItem":
				{
					_editor.setTextStyles('italic', !_editor.italicSelected);
					break;
				}
				case "undoMenuItem":
				{
					undo();
					break;
				}
				case "redoMenuItem":
				{
					redo();
					break;
				}
				case "selectAllMenuItem":
				{
					_editor.selectAllText();		
					_editor.setFocus();							
					_setFocusOnClose = true; //set focus twice (since its lost twice!)
					_editor.addEventListener( flash.events.FocusEvent.FOCUS_OUT ,	textLostFocus);	
					break;
				}
				case "deleteMenuItem":
				{
					if (_editor.htmlText != _noteUndoRedo.text) {
						_noteUndoRedo.addKeyCommand(_editor.htmlText, _editor.caretIndex);
					}
					_editor.deleteText();	
					break;
				}
			}
			dispatchEvent(p_evt);	//bubble it
		}
		
		/**
		* @private
		*/			
		protected function createToolBar():NotepodToolBar
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER || !_model.isSynchronized) {
				return null;	//just in case
			}
			
			_editorToolBar = new NotepodToolBar();

			//TODO: we never destroy this puppy!
			
			_editorToolBar.showFontType = false;
			_editorToolBar.showSaveButton = _showSaveButton;
			_editorToolBar.textEditor = _editor;
			if (_model.getUserRole(_userManager.myUserID) >= UserRoles.PUBLISHER) {
				_editorToolBar.addEventListener(NoteEvent.SAVE, onSaveBtnClick);
				_editorToolBar.addEventListener(DropdownEvent.OPEN, onOpenDropDown);
				_editorToolBar.addEventListener(DropdownEvent.CLOSE, onCloseDropDown);
				_editorToolBar.addEventListener(NoteEvent.INCREASE_FONT, onFontSizeChange);
				_editorToolBar.addEventListener(NoteEvent.DECREASE_FONT, onFontSizeChange);
			}
			invalidateDisplayList();
			
//			dispatchEvent(new NoteEvent(NoteEvent.TOOL_BAR_CREATED));			
			return _editorToolBar;
		}
		
		//if a toolbar dropDown is present, don't time out
		/**
		* @private
		*/			
		protected function onOpenDropDown(p_evt:DropdownEvent):void
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER || !_model.isSynchronized) {
				return;	//just in case
			}
			
			if (_editorToolBarTimer) {
				_editorToolBarTimer.stop();
			}
		}		
		//start timeout when the dropDown closes (it will get reset if you type)
		/**
		* @private
		*/			
		protected function onCloseDropDown(p_evt:DropdownEvent):void
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER || !_model.isSynchronized) {
				return;	//just in case
			}
			
			if (_editorToolBarTimer) {
				_editorToolBarTimer.reset();
				_editorToolBarTimer.start();
			}
		}
		
		
		/**
		* @private
		*/			
		protected function onFontSizeChange(p_evt:NoteEvent):void
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER || !_model.isSynchronized) {
				return;	//just in case
			}
			
			var fontSizeList:XMLList = titleBarMenuData[0].fontSizeMenuItem.children();
			var l:uint = fontSizeList.length();
			for (var i:int=0; i< l; i++) {
				fontSizeList[i].@toggled = false;
			}
			//TODO: now what??? this looks unfinished...don't we set it on the editor now?
		}
		
		/**
		* @private
		*/			
	    protected function onEditorScroll(p_evt:ScrollEvent=null):void
	    {
			if ((p_evt!=null && p_evt.direction != "vertical") || !_model.isSynchronized) {
				return;	//horizontal or offline is always un-synched
			}
			
			if (_updatingScrollFromModel && !_scrollTimer.running) {
				_updatingScrollFromModel = false;
				_editor.verticalScrollPosition = (_model.verticalScrollPos+2)*_editor.maxVerticalScrollPosition;	//catch up			
				return;
			}

			

			/*
			spec here: https://zerowing.corp.adobe.com/display/happ/Brio+2+Note+Pod+Spec?focusedCommentId=66527240#comment-66527240
		    *  If No-one is typing:
		          o In this case, when a participant or host scrolls (using the scrollbar), everyone followso
		          o If an audience member scrolls, they are "detaching themselves" from the sync position - 5 seconds after they let go of the toolbar they will be brought back to the synchronized position
		    * If One or more participants/hosts are typing:
		          o In this case, when the user(s) typing scroll or click or select, everyone follows - when there is more than one editor, the last action wins - this is ok since it's a small, temporary case
		          o If an participant or host scrolls, they are "detaching themselves" from the sync position - 5 seconds after they let go of the toolbar they will be brought back to the synchronized positiono
		          o If an audience member scrolls, they are "detaching themselves" from the sync position - 5 seconds after they let go of the toolbar they will be brought back to the synchronized position (same as above)
			*/
			
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER)
			{
				_scrollTimer.reset();
				_scrollTimer.start();	//detaching myself
			}
			else {
				var a:ArrayCollection = _model.usersEditing;
				if (a.length == 0) {
					_model.verticalScrollPos = p_evt.position/_editor.maxVerticalScrollPosition - 2;	//follow me!
				} else {
					if (_iAmEditing) {
						_model.verticalScrollPos = p_evt.position/_editor.maxVerticalScrollPosition - 2;	//follow me!
					} else {
						_scrollTimer.reset();
						_scrollTimer.start();	//detaching myself
					}
				}
			}
		}
	
		/**
		* @private
		*/			
	    protected function onModelScroll(p_evt:Event):void //can be either SharedModelEvent or TimerEvent
	    {
			if (_scrollTimer.running) {	//I am detached
				return;
			}
			
			if (!isNaN(_model.verticalScrollPos) && !_iAmEditing) {	//ignore scroll from wire if I am editing!
				updateScrollPositionFromModel();
				invalidateDisplayList();
			}
	    }
		
		/**
		 * @private
		 */			
		protected function note_onKeyDown(p_event:KeyboardEvent):void
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER || !_model.isSynchronized) {
				return;	//just in case
			}
			var nextKey:String = getNextKey(p_event);
			if (nextKey == 'Ctrl+Z') {
				undo();
				this.textEditor.addEventListener(TextEvent.TEXT_INPUT, preventTyping);
				setFocus();
			} else if (nextKey == 'Ctrl+Y') {
				redo();
				this.textEditor.addEventListener(TextEvent.TEXT_INPUT, preventTyping);
				setFocus();
			} else if (nextKey == 'Ctrl+X' || nextKey == 'Ctrl+V') {
				if (_editor.htmlText != _noteUndoRedo.text) {
					_noteUndoRedo.addKeyCommand(_editor.htmlText, _editor.caretIndex);
					this.textEditor.addEventListener(TextEvent.TEXT_INPUT, preventTyping);
				}
			} else if (nextKey.substring(0,5) == 'Ctrl+') {
				//this.textEditor.addEventListener(TextEvent.TEXT_INPUT, preventTyping);
			}
		}
			
		protected function preventTyping(p_event:TextEvent):void
		{
			p_event.preventDefault();
			this.textEditor.removeEventListener(TextEvent.TEXT_INPUT, preventTyping);
		}

			
		/**
		 * @private
		 */ 
		protected function getNextKey(p_event:KeyboardEvent):String
		{
			var ctrlKey:String = "";
			if (p_event.ctrlKey) {
				ctrlKey += "Ctrl+";
			}
			
			ctrlKey += String.fromCharCode(p_event.charCode).toUpperCase();
			
			return ctrlKey;
		}
	    
		/**
		* @private
		*/			
	    protected function note_onKeyUp(event:KeyboardEvent):void
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER || !_model.isSynchronized) {
				return;	//just in case
			}

			if (event.keyCode == Keyboard.DELETE || event.keyCode == Keyboard.BACKSPACE) {								
				if (_editor.htmlText != _noteUndoRedo.text) {
					_noteUndoRedo.addKeyCommand(_editor.htmlText, _editor.caretIndex);
				}					
			}
			else //why limit it? --- if ( (event.charCode >=65 && event.charCode <= 90) || (event.charCode >=97 && event.charCode <= 122) ) { 
			{ 
				_sendDataTimer.reset();
				_sendDataTimer.start();
			}				

			_model.verticalScrollPos = _editor.verticalScrollPosition/_editor.maxVerticalScrollPosition -2;
		}
		
		/**
		 * @private
		 * When the time completes,i add the command to the list of commands for undo/redo.
		 */
		protected function onSendDataTimerComplete(p_evt:TimerEvent):void
		{
			//this gets triggered 300ms after the last set value call
			if (_editor.htmlText != _noteUndoRedo.text) {
				//save it on the stack
				_noteUndoRedo.addKeyCommand(_editor.htmlText, _editor.caretIndex);
			}
		}
	
		/**
		* @private
		*/			
		protected function onEditingListUpdate(p_evt:Event=null):void
		{
			_editingUsersListChanged = true;
			invalidateDisplayList();	
		}

		/**
		* @private
		*/			
		protected function onDisclosureMouseOver(p_evt:MouseEvent):void
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER || !_model.isSynchronized) {
				return;	//just in case
			}
			
			if (_editorToolBarTimer) {
				_editorToolBarTimer.stop();
			}
		}
		
		/**
		* @private
		*/			
		protected function onDisclosureMouseOut(p_evt:MouseEvent):void
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER || !_model.isSynchronized) {
				return;	//just in case
			}
			
			if (_editorToolBarTimer) {
				_editorToolBarTimer.reset();
				_editorToolBarTimer.start();	//editing will reset it
			}
		}
		
		
		/**
		* @private
		*/			
		protected function onEditorToolBarTimerComplete(p_evt:TimerEvent):void
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER || !_model.isSynchronized) {
				return;	//just in case
			}
			
			if (_editorToolBarTimer) {
				hideToolBar();
			}
		}
				
		/**
		 * @private
		 * The text in the model has changed, update the view if needed
		 */
		protected function onModelValueCommit(p_event:SharedPropertyEvent):void
		{
			if ( !_iAmEditing || _isUndoRedo) {				
				updateEditorTextFromModel();
			}
			
			if ( _noteUndoRedo && _model.htmlText != null && !_iAmEditing) {
				_noteUndoRedo.startingText = _model.htmlText ;
			}
			
			if (_isUndoRedo) {
				_updatingScrollFromModel = true;
				_editor.selectionBeginIndex = _noteUndoRedo.endIndex;
				_editor.selectionEndIndex = _noteUndoRedo.endIndex;
				_isUndoRedo = false;
			}
			
			dispatchEvent(new SharedPropertyEvent(p_event.type,p_event.publisherID));
		}	
		
		/**
		 * When the synchronization changed
		 * @private
		 */
		protected function onSynchronizationChange(p_evt:CollectionNodeEvent):void
		{
			if( _model.isSynchronized) {
				setUpFromModel();
				onMyRoleChange();
			} else {
				
				if (_editor) {
					_editor.editable = false;	//no need to set it to true again because on reconnect we totally recreate the pod
				}
				if (_sendDataTimer) {
					_sendDataTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onSendDataTimerComplete);
					_sendDataTimer.stop();	//in case it war running
					_sendDataTimer = null;
				}
				
				//TODO: remove even more listeners
			}
			
			if ( _connectSession && _connectSession.archiveManager && _connectSession.archiveManager.isPlayingBack ) {
				_editor.enabled = false ;
			}
			
			invalidateProperties();
			invalidateDisplayList();
			dispatchEvent(p_evt);	//bubble it up
		}	

		/**
		* @private
		*/			
		protected function setUpFromModel():void
		{
			//populate the view from the model
			if (_noteUndoRedo) {
				_noteUndoRedo.startingText = _model.htmlText;
			}
			updateEditorTextFromModel();
			updateScrollPositionFromModel();
			onEditingListUpdate();
		}
		
		/**
		* @private
		*/			
		protected function updateEditorTextFromModel():void
		{
			if (_model.htmlText == null || _model.htmlText == "") {
				//if it's empty, and I'm a publisher, show the newmessage and listen to focus in
				_updatingScrollFromModel = true;
				if (_model.getUserRole(_userManager.myUserID) >= UserRoles.PUBLISHER && !_iAmEditing) {
					_editor.addEventListener(FocusEvent.FOCUS_IN, onNewMessageFocusIn);	//it will get removed on the first focus-in
					//Make the font textformat as default before again entering new text .. :)
					var tf:TextFormat = new TextFormat();	
					tf.bold = false ;
					tf.italic = false ;
					tf.color = 0x000000 ;
					tf.underline = false ;
					tf.bullet = false ;	
					_editor.defaultTextFormat = tf ;
					_editor.validateProperties();
					_editor.validateNow();
					_editor.htmlText = "<font color=\"#000000\"><i>"+_lm.getString("Enter note here")+"</i></font>";
				} else {
					_editor.htmlText = "";
				}
			} else {
				_editor.removeEventListener(FocusEvent.FOCUS_IN, onNewMessageFocusIn);	//in case it was on
				_updatingScrollFromModel = true;
				_editor.highlightURLs = true;
				_editor.removeAndAddTextField();
				_editor.htmlText = _model.htmlText;
				
			}
		}
	
		/**
		* @private
		*/			
		protected function updateScrollPositionFromModel():void
		{
			_updatingScrollFromModel = true;
			onEditorScroll();
		}
		
		/**
		* @private
		*/			
		protected function hideToolBar():void
		{
			if (!_model.isSynchronized) {
				return;	//just in case
			}
			
			//focusEnabled = false;
			if(focusManager)
			{
				if ( focusManager.getFocus() != null && contains(DisplayObject(focusManager.getFocus())) ) {
					setFocus();	
				}
			}

			if (_editorToolBar &&_editorToolBarTimer && _editorToolBarTimer.running == true) {
				_editorToolBarTimer.reset();
				_editorToolBarTimer.stop();
			}

			if (_toolbarContainer) {
				_toolbarContainer.undisclose();
			}

			_iAmEditing = false;
			
			if(_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER) {
				return;
			}
			
			//setUpFromModel();	//catch up with everyone else
			//remove updateScrollPosition when hiding the toolbar, 
			//so we don't always drag scroll bar to the bottom 
			if (_noteUndoRedo) {
				_noteUndoRedo.startingText = _model.htmlText;
			}
			updateEditorTextFromModel();
			//updateScrollPositionFromModel();
			onEditingListUpdate();
		}
		
		/**
		* @private
		*/			
		protected function onSaveBtnClick(p_evt:NoteEvent):void
		{
			dispatchEvent(new NoteEvent(NoteEvent.SAVE));
		}
		
		/**
		* @private
		*/			
		protected function onModelClickIndexChange(p_evt:NoteEvent):void
		{
			if ( _model.verticalScrollPos != -1 && !_iAmEditing) {
				//var lineNumber:Number = _editor.editorTextField.getLineIndexOfChar(_model.clickIndex);
				var lineNumber:Number = _model.verticalScrollPos;
				if( !isNaN(lineNumber) && lineNumber < _editor.editorTextField.scrollV-1 || lineNumber > _editor.editorTextField.bottomScrollV-1 ) {
					_updatingScrollFromModel = true;
					_editor.editorTextField.scrollV = lineNumber + 1;
				}
			}
		}
		
		/**
		* @private
		*/			
		protected function onModelSelectionChange(p_evt:NoteEvent):void
		{
			if ( _model.selection && !_iAmEditing) {
				_updatingScrollFromModel = true;
				_editor.editorTextField.setSelection(_model.selection.beginIndex,_model.selection.endIndex);
			}
		}
		
		/**
		* @private
		*/			
		protected function onEditorMouseUp(p_evt:MouseEvent=null):void
		{
			if (_model.getUserRole(_userManager.myUserID) < UserRoles.PUBLISHER || !_model.isSynchronized) {
				return;
			}
			
			var textRange:TextRange = _editor.selection;
			
			if (textRange && textRange.beginIndex != textRange.endIndex) {
				var selectionObj:Object = new Object();
				selectionObj.beginIndex = textRange.beginIndex;
				selectionObj.endIndex = textRange.endIndex;
				_model.selection = selectionObj;
			}
		}
				
		//I need this because the text changes not just on keyUp, also by formatting and selecting
		/**
		* @private
		*/			
		protected function onEditorChange(p_evt:Event=null):void
		{
			if (!_iAmEditing) { 
				_toolbarContainer.target = this ;
				_toolbarContainer.disclose();
				_editor.highlightURLs = false;
				_editor.removeAndAddTextField();
				_editor.htmlText = _model.htmlText;	//this will remove the url highlights which we need to do
			}
			
			_iAmEditing = true;			
			_editorToolBarTimer.reset();
			_editorToolBarTimer.start();
			_model.iAmEditing();

			if (_model.htmlText != _editor.htmlText && !_isUndoRedo) {
				//otherwise we update on simple clicks which is not necessary
				_model.htmlText = _editor.htmlText;	//this will send the data on a timer, not every time
			}
		}
		
		/**
		* @private
		*/			
		protected function onEditorClick(p_evt:MouseEvent):void
		{
			var index:Number = _editor.editorTextField.getLineIndexAtPoint(p_evt.localX,p_evt.localY);
				
			if (_model.getUserRole(_userManager.myUserID) >= UserRoles.PUBLISHER ){
				_editor.setFocus();
				
				// This is for the shared click feature
				if (index!= -1) {
					var a:ArrayCollection = _model.usersEditing;
					if (a.length == 0 || (a.length != 0 && _iAmEditing) ) {
						// this function hits when I am clicking  
						// now i want the click to be synced in two cases  
						// a) no one is typing and I am clicking
						// b)  I am clicking and i am typing also 
						_model.verticalScrollPos = index ;
					} 
				}
				
				var textRange:TextRange = _editor.selection;
				if (	textRange 
						&& textRange.beginIndex == textRange.endIndex 	//it's a click and not a selection
						&& _model.selection.beginIndex != _model.selection.endIndex //the model is a range
					) {
					var selectionObj:Object = new Object();
					selectionObj.beginIndex = textRange.beginIndex;
					selectionObj.endIndex = textRange.beginIndex;	//the same spot
					_model.selection = selectionObj;
				}
			}
		}
			
		/**
		* @private
		*/			
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if ( unscaledWidth == 0 || unscaledHeight == 0 ) {
				return ;
			}
								
			if (_toolbarContainer) {
				_toolbarContainer.width = unscaledWidth;
				//_toolbarContainer.x = this.x ;
			}						

			if (_editingUsersListChanged) {
				_editingUsersListChanged = false;
				_multipleUsersTypingBg.graphics.clear();
				
				var userEditingString:String = _model.usersEditingString;
				if (userEditingString == "") {	//either no-one is editing or I'm the only person editing
					_editorBottomOffset = 0;
					_usersTypingLabel.visible = false;
				} else {
					_usersTypingLabel.text = _lm.formatString("typing",_model.usersEditingString);
					_usersTypingLabel.setActualSize(unscaledWidth-8, _usersTypingLabel.getExplicitOrMeasuredHeight());
					_usersTypingLabel.visible = true;
				}
			}

			if (_usersTypingLabel && _usersTypingLabel.visible) {
				if (_iAmEditing) {	//that means that someone else is editing as well, or the string wouldn't be "". Show above the toolbar and shrink the editor
					_editorBottomOffset = _usersTypingLabel.measuredHeight;
					_usersTypingLabel.move(4, unscaledHeight-k_CONTROLBARHEIGHT-_usersTypingLabel.measuredHeight+3);
					_multipleUsersTypingBg.y = unscaledHeight-k_CONTROLBARHEIGHT-_usersTypingLabel.measuredHeight;
					_multipleUsersTypingBg.graphics.beginFill(0x454545);
					_multipleUsersTypingBg.graphics.drawRect(-3, 0, unscaledWidth+6, _usersTypingLabel.measuredHeight);	//hack! we gotta ship!
					_multipleUsersTypingBg.graphics.endFill();
				} else {	//that means that someone else (one or more) is editing but not me, show at the bottom
					_editorBottomOffset = 0;
					_usersTypingLabel.move(4, unscaledHeight-k_CONTROLBARHEIGHT+3);
				}
			}
			if (_editor) {
				_editor.setActualSize(unscaledWidth, unscaledHeight-k_CONTROLBARHEIGHT-3-_editorBottomOffset);
			}
			
			
		}
		
		
		
		
		/**
		 * @private 
		 */
		override protected function measure():void
		{
			super.measure() ;
			_editor.minHeight = 150 ;
			_editor.minWidth = 150 ;
			
			minHeight = measuredMinHeight = _editor.minHeight + k_CONTROLBARHEIGHT  ;
			minWidth = measuredMinWidth = _editor.minWidth ;
			
			
		}	
	}
}