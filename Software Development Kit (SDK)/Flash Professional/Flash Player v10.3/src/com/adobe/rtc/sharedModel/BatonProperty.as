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
package com.adobe.rtc.sharedModel
{
	import com.adobe.rtc.events.SharedModelEvent;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.session.ISessionSubscriber;
	
	import flash.events.Event;

	/**
	 * Dispatched when the baton holder for the string is assigned or when the string 
	 * becomes available.
	 */
	[Event(name="batonHolderChange", type="com.adobe.rtc.events.SharedModelEvent")]

	/**
	 * BatonProperty is a model component which manages a property of any type that 
	 * only one user can edit at a time. It exposes a standard Baton component to 
	 * manage this workflow.
	 * <p>
	 * This component supports "piggybacking" on existing CollectionNodes through its 
	 * constructor. Developers can avoid CollectionNode proliferation in their applications
	 * by pre-supplying a CollectionNode and a <code>nodeName</code> for the <code>
	 * BatonProperty</code> to use. If none is supplied, the <code>BatonProperty</code> will 
	 * create its own CollectionNode for sending and receiving messages.
	 * 
	 * @see com.adobe.rtc.sharedModel.Baton
	 * @see com.adobe.rtc.sharedModel.CollectionNode
	 */
   public class  BatonProperty extends SharedProperty implements ISessionSubscriber
	{
		/**
		 * @private
		 */
		protected var _baton:Baton;
		
		/**
		 * @private
		 */
		protected var _cachedValueForToggle:*;

		/**
		 * @private
		 */
		protected var _nodeNameResource:String = "cID";
		
		
		/**
		 * Constructor.
		 * 
		 * @param p_id 				The unique component ID.
		 * @param p_collectionNode	If you'd like to "bring your own" collection node, pass it here.
		 * @param p_nodeNameValue	If you'd like to specify the node name to use for property's value, pass it here.
		 * @param p_nodeNameBaton	If you'd like to specify the node name to use for the baton, pass it here.
		 */
		public function BatonProperty():void
		{
			_sharedID = "_BatonProperty";
			_baton = new Baton();
		}
		
		/**
		 * Returns a reference to the Baton used by this <code>BatonProperty</code>.
		 */
		public function get baton():Baton
		{
			return _baton;
		}
		
		/**
		 * Sets the CollectionNode to be used in setting up the property and baton nodes, when used in "piggybacking"
		 */
		override public function set collectionNode(p_collectionNode:CollectionNode):void
		{
			super.collectionNode = p_collectionNode ;	
			_baton.collectionNode = _collectionNode ;
		}
		
		/**
		 * Defines the logical location of the component on the service - typically this assigns the sharedID of the collectionNode
		 * used by the component. If this is used to "piggyback" on an existing collectionNode, sharedID specifies the nodeName
		 * to use for the property itself. sharedIDs should be unique within a room (if they're expressing 2 unique locations). Note that
		 * this can only be assigned once (before <code>subscribe()</code> is called). For components with an <code class="property">id</code> property, 
		 * sharedID defaults to that value.
		 */
		override public function set sharedID(p_id:String):void
		{
			super.sharedID = p_id ;
		}
		
		/**
		 * Gets the sharedId
		 */
		override public function get sharedID():String
		{
			return _sharedID ;
		}
		
		/**
		 * Node Name for the baton
		 */
		public function set nodeNameBaton(p_nodeNameBaton:String):void
		{
			_baton.nodeName = _nodeNameResource ;	
		}
		
		/**
		 * When used with "piggybacking" on an existing CollectionNode, specifies the node name for the baton
		 */
		public function get nodeNameBaton():String
		{
			return _baton.nodeName ;
		}
		
		
		/**
		 * Tells the component to begin synchronizing with the service.  
		 * For "headless" components such as this one, this method must be called explicitly.
		 */
		override public function subscribe():void
		{
			super.subscribe() ;
			_baton.sharedID = sharedID ;
//			_baton.timeOut = 0 ;
			_baton.collectionNode = _collectionNode ;
			_baton.nodeName = _nodeNameResource ;
			_baton.subscribe();
			_baton.addEventListener(SharedModelEvent.BATON_HOLDER_CHANGE, onBatonHolderChange);
		}
		

		/**
		 * Cleans up all listeners and network connections: recommended for garbage collection.
		 */
		override public function close():void
		{
			super.close();
			
			_baton.removeEventListener(SharedModelEvent.BATON_HOLDER_CHANGE, onBatonHolderChange);
			_baton.close();
			_cachedValueForToggle = null;
		}
		
		/**
		 * The value of the BatonProperty which a user can only set it if the user is in 
		 * control of it.
		 * <p>
		 * If the BatonProperty is not yet synchrnonized, the value will be cached and 
		 * sent when the BatonProperty is back in sync.
		 * <p>
		 * If the BatonProperty is available, setting the value will also try to grab 
		 * control of the BatonProperty before setting the text.
		 */
		override public function set value(p_value:*):void
		{
			if (p_value == value) {	//no need to set it again
				return;
			}
			
			if (_collectionNode.isSynchronized) {
				if (_baton.amIHolding) {
					_cachedValueForSending = p_value;
					_sendDataTimer.reset();
					_sendDataTimer.start();
					_baton.extendTimer();
				} else if (_baton.available) {
					if (!_cachedValueForToggle) {	//only toggle the first time
						_baton.grab();
					}
					_cachedValueForToggle = p_value;	//overwrite the value that will eventually be published
				}
			} else {
				_cachedValueForSync = p_value;
			}
		}
		
		/**
		 * @private
		 */
		protected function onBatonHolderChange(p_evt:SharedModelEvent):void
		{
			if (_baton.amIHolding && _cachedValueForToggle) {
				value = _cachedValueForToggle;
				_cachedValueForToggle = null;
			}
			dispatchEvent(p_evt);
		}

		/**
		 * @private
		 */
		override protected function onSynchronizationChange(p_evt:Event):void
		{
			if (_collectionNode.isSynchronized) {
			} else {
				//clear model
				_cachedValueForToggle = null;
			}

			super.onSynchronizationChange(p_evt);
		}
		
		
		/**
		 * @inheritDoc
		 */
		override public function canUserEdit(p_userID:String):Boolean
		{
			// This is different from the super, because in addition to asking
			//   "can the user edit the text?", we must also ask "can the user
			//   grab the baton?"
			
			return super.canUserEdit(p_userID) && baton.canUserGrab(p_userID);
			
		}
		
		/**
		 * @inheritDoc
		 */
		override public function allowUserToEdit(p_userID:String):void
		{
			// Let the user grab the baton.
			baton.setUserRole(p_userID, UserRoles.PUBLISHER);
			
			// Let the user edit the text.
			super.allowUserToEdit(p_userID);
		}
		
		
		/**
		 * @private
		 */
		override public function set publishModel(p_publishModel:int):void
		{	
			_baton.publishModel = p_publishModel ;
			super.accessModel = p_publishModel;
		}
		
		/**
		 * Role Value required to publish on the property
		 */
		override public function get publishModel():int
		{
			return _baton.publishModel ;
		}
		
		/**
		 * @private
		 */
		override public function set accessModel(p_accessModel:int):void
		{	
			_baton.accessModel = p_accessModel ;
			super.accessModel = p_accessModel;
		}
		
		/**
		 * Role value which is required for accessing the property value
		 */
		override public function get accessModel():int
		{
			return _baton.accessModel ;
		}
			
		/**
		 *  Returns the role of a given user for the property.
		 * 
		 * @param p_userID UserID of the user in question
		 */
		override public function getUserRole(p_userID:String):int
		{
			return _baton.getUserRole(p_userID);
		}
		
		/**
		 *  Sets the role of a given user for the property.
		 * 
		 * @param p_userID UserID of the user whose role we are setting
		 * @param p_userRole Role value we are setting
		 */
		override public function setUserRole(p_userID:String ,p_userRole:int):void
		{
			_baton.setUserRole(p_userID,p_userRole);
			super.setUserRole(p_userID, p_userRole);
		}
	}
}
