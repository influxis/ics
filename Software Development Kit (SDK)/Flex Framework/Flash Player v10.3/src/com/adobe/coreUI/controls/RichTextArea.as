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
	import com.adobe.coreUI.util.StringUtils;
	
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	
	import mx.controls.TextArea;
	
	/**
	 * @private
	 * Extends the TextArea and adds url and email highLighting to it
	 */
   public class  RichTextArea extends TextArea
	{
		/**
		*@private
		 * Private variable for keeping changedTextFormat
		 */
		protected var _explicitHTMLText:String;
		
		//sometimes you want to turn this off
		protected var _highlightURLs:Boolean = true;
		
		public function get highlightURLs():Boolean
		{
			return _highlightURLs;
		}
		public function set highlightURLs(p_doit:Boolean):void
		{
			_highlightURLs = p_doit;
		}
		
		public function RichTextArea()
 		{
        	super();
			addEventListener(Event.CHANGE, onChange);
    	}
    	
    	override public function get htmlText():String
    	{
    		return _explicitHTMLText;
    	}

		override public function set htmlText(p_value:String):void
		{
			_explicitHTMLText = p_value;
			try {
				super.htmlText = (_highlightURLs) ? StringUtils.highLightURLs(_explicitHTMLText) : _explicitHTMLText;
			}catch(e:Error) {
				//this is work around for bug 1670209, we swallow the exception.
				//too much data for string util to hightlight urls.
				super.htmlText = _explicitHTMLText;
				_highlightURLs = false;
			}
		}

	    override public function set text(p_text:String):void
	    {
	    	super.text = p_text;
	    }

	    protected function onChange(p_evt:Event):void
	    {
			_explicitHTMLText = super.htmlText;
//	    	htmlText = super.text;
	    }
	    
	  
	}
}