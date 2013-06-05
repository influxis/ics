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
package com.adobe.rtc.pods.horizontalRosterClasses
{
	import mx.controls.TileList;
	import mx.controls.scrollClasses.ScrollBar;
	import mx.core.EdgeMetrics;
	import mx.core.ScrollPolicy;
	import mx.controls.listClasses.TileBaseDirection;
	import mx.controls.Label;
	import mx.core.ClassFactory;
	import flash.display.Graphics;
	import mx.core.mx_internal;
	import mx.controls.listClasses.IListItemRenderer;
	import flash.events.MouseEvent;
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;
	import flash.events.Event;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.display.GradientType;

	use namespace mx_internal;

	/**
	 * @private
	 */
   public class  RosterTileList extends TileList
	{
//		protected const ROLE_LABEL_PADDING:uint = 8;
		
		protected var _roleLabel:Label;
		protected var _roleText:String;
		protected var _roleTextChanged:Boolean;
		protected static const NINETY_DEGREES:Number = Math.PI/2;
		
		public function RosterTileList():void
		{
		}

		
		override protected function drawHighlightIndicator(p_indicator:Sprite, p_x:Number, p_y:Number, p_width:Number, p_height:Number,
															 p_color:uint, p_itemRenderer:IListItemRenderer):void
		{
			var g:Graphics = p_indicator.graphics;
			
			var rotationMatrix:Matrix;
			
			rotationMatrix = new Matrix();
			rotationMatrix.createGradientBox(1, p_height, NINETY_DEGREES);
			g.beginGradientFill(GradientType.LINEAR, [0x7A7A7A, 0x494949],
								 [1,1], [0,255], rotationMatrix);
			g.drawRect(0, 0, 1, p_height);
			
			g.beginGradientFill(GradientType.LINEAR, [0xA8A8A8, 0x747474],
								 [1,1], [0,255], rotationMatrix);
			g.drawRect(1, 0, 1, p_height);
			
			g.beginGradientFill(GradientType.LINEAR, [0xA8A8A8, 0x747474],
								 [1,1], [0,255], rotationMatrix);
			g.drawRect(p_width-1, 0, 1, p_height);

			g.beginGradientFill(GradientType.LINEAR, [0x7A7A7A, 0x494949],
								 [1,1], [0,255], rotationMatrix);
			g.drawRect(p_width-2, 0, 1, p_height);

			rotationMatrix = new Matrix();
			rotationMatrix.createGradientBox(p_width-4, p_height, NINETY_DEGREES);
			g.beginGradientFill(GradientType.LINEAR, [0x999999, 0x5C5C5C],
								 [1,1], [0,255], rotationMatrix);
			g.drawRect(2, 0, p_width-4, p_height);
			
			p_indicator.x = p_x;
			p_indicator.y = p_y;

		}

		override protected function drawSelectionIndicator(p_indicator:Sprite, p_x:Number, p_y:Number, p_width:Number, p_height:Number,
															 p_color:uint, p_itemRenderer:IListItemRenderer):void
		{
			var g:Graphics = p_indicator.graphics;
			
			var rotationMatrix:Matrix;
			
			rotationMatrix = new Matrix();
			rotationMatrix.createGradientBox(1, p_height, NINETY_DEGREES);
			g.beginGradientFill(GradientType.LINEAR, [0x434343, 0x5c5c5c],
								 [1,1], [0,255], rotationMatrix);
			g.drawRect(0, 0, 1, p_height);
			
			g.beginGradientFill(GradientType.LINEAR, [0x767676, 0x8F8F8F],
								 [1,1], [0,255], rotationMatrix);
			g.drawRect(1, 0, 1, p_height);
			
			g.beginGradientFill(GradientType.LINEAR, [0x767676, 0x8F8F8F],
								 [1,1], [0,255], rotationMatrix);
			g.drawRect(p_width-1, 0, 1, p_height);

			g.beginGradientFill(GradientType.LINEAR, [0x434343, 0x5c5c5c],
								 [1,1], [0,255], rotationMatrix);
			g.drawRect(p_width-2, 0, 1, p_height);

			rotationMatrix = new Matrix();
			rotationMatrix.createGradientBox(p_width-4, p_height, NINETY_DEGREES);
			g.beginGradientFill(GradientType.LINEAR, [0x545454, 0x737373],
								 [1,1], [0,255], rotationMatrix);
			g.drawRect(2, 0, p_width-4, p_height);
			
			p_indicator.x = p_x;
			p_indicator.y = p_y;

		}

		override public function initialize():void
		{
			super.initialize();
			
			verticalScrollPolicy = ScrollPolicy.OFF;
			horizontalScrollPolicy = ScrollPolicy.AUTO;
			maxRows = 1;
			direction = TileBaseDirection.VERTICAL;
			
			setStyle("backgroundColor", 0x3b454e);
			setStyle("backgroundAlpha", 0);
//			setStyle("color", 0xFFFFFF);
			setStyle("borderThickness", 0);
			setStyle("selectionColor", 0x3b454e);
			setStyle("rollOverColor", 0xFF0000);
			setStyle("paddingTop", 0);
			
			
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(_roleTextChanged) {
				_roleLabel.text = _roleText;
				_roleTextChanged = true;
			}
		}
		
		override protected function createChildren():void
		{
			if(!_roleLabel) {
				_roleLabel = new Label();
				_roleLabel.setStyle("color", getStyle("color"));
				_roleLabel.setStyle("fontSize", getStyle("fontSize"));
				_roleLabel.setStyle("fontWeight", getStyle("fontWeight"));
				addChild(_roleLabel);
			}
			super.createChildren();
			
			listContent.mask = maskShape;
			
		}
		
		override protected function measure():void
		{
			super.measure();
//			measuredWidth = measuredMinWidth = Math.max(columnWidth * dataProvider.length, _roleLabel.width + ROLE_LABEL_PADDING * 2);
			measuredWidth = measuredMinWidth = Math.max((columnWidth+1) * dataProvider.length,
				_roleLabel.width + getStyle("roleLabelPaddingRight") + getStyle("roleLabelPaddingLeft")+((horizontalScrollBar)?horizontalScrollBar.minWidth:0));
			measuredHeight = measuredMinHeight = measuredHeight + 16;
		}
		
		
		// TODO: There's got to be a better way to set styles on the horizontalScrollBar before it's created...
		override protected function setScrollBarProperties(totalColumns:int, visibleColumns:int,
                                        totalRows:int, visibleRows:int):void
        {
        	super.setScrollBarProperties(totalColumns, visibleColumns, totalRows, visibleRows);
        	
        	if(horizontalScrollBar) {
	   			horizontalScrollBar.setStyle("cornerRadius", 0);
				horizontalScrollBar.setStyle("fillColors", [0x737C83, 0x3B454E]);
        	}

        }
		
		
		override protected function collectionChangeHandler(event:Event):void
		{
			if(dataProvider.length > 0)
				super.collectionChangeHandler(event);
		}

		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var vm:EdgeMetrics = viewMetrics;
			
			// Shenanigans ahead:
			// ScrollControlBase.updateDisplayList() does everything we want it to already, but we
			//   want to change its behavior regarding a very specific part of it: how it lays out
			//   the horizontal scroll bar.  (Ours is offset from the left side to make room for
			//   the label.)
			// We trick it by telling it that there's no horizontalScrollBar to lay out.  Then we
			//   let it do what it wants, and handle the horizontalScrollBar on our own terms.
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var mask:DisplayObject = maskShape;
			mask.y -= 30;
			mask.height += 30;
			
			// Find out how long the roleLabel wants to be, since the size and position of the scroll bar depends on it.
			var roleLabelWidth:int = _roleLabel.measuredWidth;
			
			var barHeight:int = 16;
			
			// Draw the horizontal scroll bar.
	        if (horizontalScrollBar)
	        {
	            horizontalScrollBar.setActualSize(unscaledWidth - vm.left - vm.right - roleLabelWidth
	            			- getStyle("roleLabelPaddingRight") - getStyle("roleLabelPaddingLeft"), barHeight);
	            horizontalScrollBar.move(vm.left + roleLabelWidth + getStyle("roleLabelPaddingRight")
	            			+ getStyle("roleLabelPaddingLeft"), unscaledHeight - vm.bottom);
	
	            horizontalScrollBar.visible = (horizontalScrollBar.visible && 
	                horizontalScrollBar.width >= horizontalScrollBar.minWidth &&
	                unscaledHeight > horizontalScrollBar.height);
	
	            horizontalScrollBar.enabled = enabled;
	            
	            barHeight = horizontalScrollBar.height;
	        }
	        
	        
	        _roleLabel.setActualSize(_roleLabel.measuredWidth, _roleLabel.measuredHeight);
	        _roleLabel.move(vm.left + getStyle("roleLabelPaddingLeft") - 1, listContent.height - 1);
		}
		
		
		override public function get viewMetrics():EdgeMetrics
		{
			var newMetrics:EdgeMetrics = borderMetrics.clone();
			newMetrics.bottom += 16;
			return newMetrics; 
		}
		
		override public function get borderMetrics():EdgeMetrics
		{
			var newMetrics:EdgeMetrics = super.borderMetrics.clone();
//			newMetrics.bottom += 16;
			return newMetrics; 
		}
		
		

		
/*		override public function get height():Number
		{
			if(horizontalScrollBar)
				return super.height + horizontalScrollBar.height;
			return super.height;
		}*/
		
		
		
		
		public function set roleText(p_text:String):void
		{
			_roleText = p_text;
			_roleTextChanged = true;
			
			invalidateProperties();
			invalidateDisplayList();
		}

	    mx_internal override function mouseEventToItemRendererOrEditor(
	                                event:MouseEvent):IListItemRenderer
	    {
	        var target:DisplayObject = DisplayObject(event.target);
	        if (target == listContent)
	        {
	            var pt:Point = new Point(event.stageX, event.stageY);
	            pt = listContent.globalToLocal(pt);
	            
	            var yy:Number = 0;
	            
	            var n:int = listItems.length;
	            for (var i:int = 0; i < n; i++)
	            {
	                if (listItems[i].length)
	                {
	                    if (pt.y < yy + rowInfo[i].height)
	                    {
	                        var j:int = Math.floor(pt.x / columnWidth);
	                        return listItems[i][j];
	                    }
	                }
	                yy += rowInfo[i].height;
	            }
	        }
	        else if (target == highlightIndicator)
	        {
	            return lastHighlightItemRenderer;
	        }
	
	        while (target && target != this)
	        {
	            if (target is IListItemRenderer && target.parent == listContent)
	            {
	                if (target.visible)
	                    return IListItemRenderer(target);
	                break;
	            }
	
	            target = target.parent;
	        }
	
	        return null;
	    }
		
		
	}
}