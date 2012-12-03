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
package com.adobe.coreUI.controls
{
	import com.adobe.coreUI.localization.ILocalizationManager;
	import com.adobe.coreUI.localization.Localization;
	
	import mx.controls.Label;
	import mx.core.UIComponent;

	/**
	 * @private
	 */
   public class  ControllingUserBar extends UIComponent
	{
		protected const SHADOW_OFFSET:uint = 1;
		
		protected var _userLabelShadow:Label;
		protected var _userLabel:Label;
		
		private var _id:String ;
		
		protected var _lm:ILocalizationManager = Localization.impl;
		
		/**
		 * Overridding the CreateChildren
		* @private
		*/		
    	override protected function createChildren():void
    	{
    		super.createChildren();
    		if (!_userLabelShadow) {
    			_userLabelShadow = new Label();
    			_userLabelShadow.setStyle("fontFamily", "Arial");
    			addChild(_userLabelShadow);
    		}

    		if (!_userLabel) {
    			_userLabel = new Label();
    			_userLabel.setStyle("color", 0xFFFFFF);
    			_userLabel.setStyle("fontFamily", "Arial");
    			addChild(_userLabel);
    		}

    		setStyle("cornerRadius",50);
    		//setStyle("borderColor", 0x808080);
    		//setStyle("backgroundColor", 0xc0c0c0);
    	}
    	
    	/**
    	 * Sets the User Name of the user who is currently in control and is editing 
    	 * @param p_label User Label
    	 */    	
    	public function set controlUserLabel(p_label:String):void
		{
			if (_userLabel ) {
				_userLabel.text = _userLabelShadow.text = _lm.formatString("USER_EDITING", p_label);
			}
		}
		
		
		public function set cameraUserID(p_id:String):void
		{
			if ( p_id != null && p_id != _id ) {
				_id = p_id ;
			}
			
			invalidateDisplayList();
			validateNow();	
		}
		
		
		public function get cameraUserID():String
		{
			return _id ;
		}
		
		
		public function get cameraUserLabel():String 
		{
			return _userLabel.text;
		}
		
		public function set cameraUserLabel(p_label:String):void
		{
			if (_userLabel) {
				_userLabel.text = _userLabelShadow.text = p_label; 
			}
			invalidateDisplayList();
			validateNow();
		}
		
		
		public function get textHeight():Number
		{
			if (_userLabel.text) {
				return _userLabel.textHeight+SHADOW_OFFSET+3;
			}else {
				return 20;
			}
		}
		/**
		 * Overridding the createChildren
		 * @private
		* @param unscaledWidth Width
		 * @param unscaledHeight Height
		*/		
    	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
    	{
    		super.updateDisplayList(unscaledWidth,unscaledHeight);    		
    		
    		if (_userLabel) {
    			_userLabelShadow.move(SHADOW_OFFSET, SHADOW_OFFSET);
    			_userLabelShadow.setActualSize(unscaledWidth-SHADOW_OFFSET, _userLabelShadow.measuredHeight-SHADOW_OFFSET);
    			_userLabel.setActualSize(unscaledWidth-SHADOW_OFFSET,_userLabel.measuredHeight-SHADOW_OFFSET);
    		}
    	}
	}
}