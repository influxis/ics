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
	import mx.containers.HBox;
	import mx.core.ScrollPolicy;
	import mx.core.mx_internal;
	import mx.controls.Button;
	import flash.events.MouseEvent;
	import mx.core.EdgeMetrics;

	use namespace mx_internal;

	/**
	 * @private
	 */
   public class  CustomHBox extends HBox
	{
		[Embed(source="assets/leftIcon.PNG")]
 		protected var _leftIcon:Class;
		
		[Embed(source="assets/rightIcon.PNG")]
 		protected var _rightIcon:Class;
		
		protected var _leftArrow:Button;
		protected var _rightArrow:Button;

	    protected var _viewMetrics:EdgeMetrics;
		
		public function CustomHBox():void
		{
			_horizontalScrollPolicy = ScrollPolicy.OFF;
		}
		
	    override public function set horizontalScrollPolicy(value:String):void
	    {
	    	//this cannot be set for this control
	    	return;
	    }

	    override protected function measure():void
	    {
	        super.measure();        
	    }
	    
	    protected function onLeftArrowClick(p_evt:MouseEvent):void
	    {
	    	horizontalScrollPosition-=Math.max((unscaledWidth-_viewMetrics.left-_viewMetrics.right-10), 0);
	    	updateArrowsEnabledState();
	    }
	    protected function onRightArrowClick(p_evt:MouseEvent):void
	    {
	    	horizontalScrollPosition+=Math.min((unscaledWidth-_viewMetrics.left-_viewMetrics.right-10), maxHorizontalScrollPosition);
	    	updateArrowsEnabledState();
	    }

		protected function updateArrowsEnabledState():void
		{
			if (_leftArrow) {
	    		_leftArrow.enabled = (horizontalScrollPosition>0);
				_rightArrow.enabled = (horizontalScrollPosition<maxHorizontalScrollPosition);
			}
		}
		
	    override public function get viewMetrics():EdgeMetrics
	    {
	        var bm:EdgeMetrics = borderMetrics;

			if (!_leftArrow) {
				return bm;
			}
	
	        // The viewMetrics property needs to return its own object.
	        // Rather than allocating a new one each time, we'll allocate one once
	        // and then hold a reference to it.
	        if (!_viewMetrics)
	        {
	            _viewMetrics = bm.clone();
	        }
	        else
	        {
	            _viewMetrics.left = bm.left;
	            _viewMetrics.right = bm.right+32;
	            _viewMetrics.top = bm.top;
	            _viewMetrics.bottom = bm.bottom;
	        }

	 		if (horizontalScrollPosition>=maxHorizontalScrollPosition) {
	 			horizontalScrollPosition = maxHorizontalScrollPosition;	//kick it to make it follow the arrows when the CustomHBox grows
	 		}
	 			
	        return _viewMetrics;
	    }

	    override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	    {
	        super.updateDisplayList(unscaledWidth, unscaledHeight);

			var changed:Boolean = false;
			
			//trace("measuredWidth:"+measuredWidth+", explicitWidth:"+explicitWidth+", unscaledWidth:"+unscaledWidth);
	        if (measuredWidth > unscaledWidth) {
	        	//I must add the two buttons
		 		if(!_leftArrow ) {
		 			_leftArrow = new Button();
		 			_leftArrow.addEventListener(MouseEvent.CLICK, onLeftArrowClick);
		 			_leftArrow.setStyle("icon", _leftIcon);
		 			_leftArrow.setActualSize(16, 22);
		 			_leftArrow.enabled = false;
		 			_leftArrow.includeInLayout = false;
		 			rawChildren.addChild(_leftArrow);

		 			_rightArrow = new Button();
		 			_rightArrow.addEventListener(MouseEvent.CLICK, onRightArrowClick);
		 			_rightArrow.setStyle("icon", _rightIcon);	
		 			_rightArrow.setActualSize(16, 22);
		 			_rightArrow.includeInLayout = false;
		 			rawChildren.addChild(_rightArrow);
		 			changed = true;
		 		} else {
			 		updateArrowsEnabledState();
			 	}
	        } else {
	        	if (_leftArrow) {
	        		_leftArrow.removeEventListener(MouseEvent.CLICK, onLeftArrowClick);
	        		rawChildren.removeChild(_leftArrow);
	        		_leftArrow = null;
		 			changed = true;

	        		_rightArrow.removeEventListener(MouseEvent.CLICK, onRightArrowClick);
	        		rawChildren.removeChild(_rightArrow);
	        		_rightArrow = null;

					horizontalScrollPosition = 0;	//TODO: improve

		 			changed = true;
	        	}
	        }
	
			if (_leftArrow) {
				_rightArrow.move(unscaledWidth-16, 0);
				_leftArrow.move(unscaledWidth-32, 0);
			} else {
		        layoutObject.updateDisplayList(unscaledWidth, unscaledHeight);
			}
	    }	    
	}
}
