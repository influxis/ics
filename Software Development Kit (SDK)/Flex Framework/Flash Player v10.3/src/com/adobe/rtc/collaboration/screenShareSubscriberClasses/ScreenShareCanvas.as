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
package com.adobe.rtc.collaboration.screenShareSubscriberClasses
{
	import mx.containers.Canvas;
	import mx.core.EdgeMetrics;

   public class  ScreenShareCanvas extends Canvas
	{
		public function ScreenShareCanvas()
		{
			super();
		}
		
		override public function get viewMetrics():EdgeMetrics
		{
			var eM:EdgeMetrics = new EdgeMetrics(borderMetrics.left, borderMetrics.top, borderMetrics.right, borderMetrics.bottom);
			if (verticalScrollBar) {
				eM.right-=verticalScrollBar.width;
			}
			if (horizontalScrollBar) {
				eM.bottom-=horizontalScrollBar.height;
			}
			return eM;
		}

	    override public function validateDisplayList():void
	    {
	    	super.validateDisplayList();
	    	var vm:EdgeMetrics = viewMetrics;
	    	if (verticalScrollBar) {
                var h:Number = unscaledHeight - vm.top - vm.bottom;
                if (horizontalScrollBar)
                    h -= 2*horizontalScrollBar.minHeight;

                verticalScrollBar.setActualSize(
                    verticalScrollBar.minWidth, h);
	            verticalScrollBar.move(unscaledWidth - vm.right - verticalScrollBar.width -
	                                   verticalScrollBar.minWidth+1,
	                                   vm.top);
	    	}
	    	if (horizontalScrollBar) {
                var w:Number = unscaledWidth - vm.left - vm.right;
                if (verticalScrollBar)
                    w -= 2*verticalScrollBar.minWidth;

                horizontalScrollBar.setActualSize(
                    w, horizontalScrollBar.minHeight);
				horizontalScrollBar.move(vm.left,
                						unscaledHeight - vm.bottom - horizontalScrollBar.height - 
                                        horizontalScrollBar.minHeight +1);
	    		
	    	}
            if (whiteBox)
            {
                whiteBox.x = verticalScrollBar.x;
                whiteBox.y = horizontalScrollBar.y;
                whiteBox.alpha = 0.2;
            }

	    }
		
	}
}