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
	import mx.controls.Menu;
	import mx.core.mx_internal;
	import flash.display.DisplayObjectContainer;
	import mx.core.Application;
	import flash.display.DisplayObject;
	import mx.core.UIComponent;
	import mx.core.EdgeMetrics;
	import com.adobe.coreUI.controls.customMenuClasses.CustomMenuBorder;
	import mx.core.IFactory;
	import mx.utils.GraphicsUtil;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.controls.menuClasses.IMenuItemRenderer;
	import mx.managers.PopUpManager;
	import flash.geom.Point;
	import flash.events.MouseEvent;
	import mx.events.MenuEvent;
	import flash.utils.clearInterval;
	import flash.utils.setTimeout;
	import flash.geom.Matrix;
	import flash.display.GradientType;
	import flash.geom.Rectangle;
	import mx.effects.Tween;
	import mx.effects.easing.Sine;
	import flash.display.Sprite;
	import flash.display.Graphics;
	import mx.graphics.RectangularDropShadow;
	import flash.ui.ContextMenu;
	import mx.controls.List;
	import mx.controls.listClasses.ListItemRenderer;
	import mx.controls.menuClasses.MenuItemRenderer;
	import mx.core.UIComponentGlobals;
	import mx.core.EventPriority;
	import flash.events.FocusEvent;
	import flash.system.Capabilities;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;
	
	use namespace mx_internal;
	/**
	 * @private
	 * A panel-menu, as shown here:
	 * http://treebeard.macromedia.com/download/attachments/17095/UserStrip_useroptions.png
	 * 
	 * <p>In addition to the functions of the standard menu, it allows icons next to each menu option, as well
	 * as an additional row of buttons on top of the menu.</p>
	 * 
	 * @see author basu
	 */
   public class  CustomMenu extends Menu
	{
		[Embed("../skins/customMenuAssets/menu_check.png")]
		private static var menuCheck:Class;
		[Embed("../skins/customMenuAssets/menu_separator.png")]
		private static var menuSeparator:Class;
		[Embed("../skins/customMenuAssets/menu_arrow.png")]
		private static var menuArrow:Class;
		
		private static var classConstructed:Boolean = classConstruct();
		
	
		private static function classConstruct():Boolean
		{
			var styleDeclaration:CSSStyleDeclaration = StyleManager.getStyleDeclaration("CustomMenu");
	
			// If there's no style declaration already, create one.
			if (!styleDeclaration)
				styleDeclaration = new CSSStyleDeclaration();
			
			styleDeclaration.defaultFactory = function ():void {
				this.showSubmenuBottomOffsetNormal = 29;
				this.showSubmenuBottomOffsetMaximized = 26; /* When maximized, it shinks because there's no drop shadow. */
				this.useRollOver = true;
				this.color = 0xFFFFFF;	
				this.backgroundColor = 0x35393E;
				this.rollOverColor = 0x638a79;
				this.textRollOverColor = 0xffffff;
				this.textSelectedColor = 0xffffff;
	
				this.borderThickness = 1;
				this.borderColors = [0x3b3b3b, 0x656565];
				this.borderAlphas = [1, 1];
		
				this.disabledColor = 0x555555;
				this.topBorderColor = 0x3b3b3b;
				this.bottomBorderColor = 0x656565;
	
				this.dropShadowEnabled = true;
				this.shadowDirection = "right";
				this.shadowDistance = 5;
		
				this.bottomPadding = 0; /* also set dynamically in meeting.mxml */
	
				this.checkIcon = menuCheck;
				this.separatorSkin = menuSeparator;
				this.branchIcon = menuArrow;
			}
			StyleManager.setStyleDeclaration("Roster", styleDeclaration, false);
			return true;
		}


		protected var _headerFactory:IFactory;
		protected var _header:UIComponent;
		protected var _headerFactoryChanged:Boolean;
		
		protected var _nonRetardedlyPrivateSubMenu:CustomMenu;
		protected var _nonRetardedlyPrivateAnchorRow:IListItemRenderer
		
		public static const SLIDE_DOWN:String = "slideDown";
		public static const SLIDE_UP:String = "slideUp";
		public var slideDirection:String = SLIDE_DOWN;
		
		protected static const OPEN_DURATION:int = 250;
		protected static const CLOSE_DURATION:int = 150;
		
		protected var _borderSprite:Sprite;
		protected var _shadowSprite:Sprite;
		protected var _dropShadow:RectangularDropShadow;
		
		protected var _showing:Boolean = false;
		
		override public function initialize():void
		{
			super.initialize();
		}
		
		override protected function createChildren():void
		{
			_shadowSprite = new Sprite();
			addChild(_shadowSprite);

			_borderSprite = new Sprite();
			addChild(_borderSprite);			
			super.createChildren();
		}
		
		public function get showing():Boolean
		{
			return _showing;
		}
		
	    override protected function focusOutHandler(event:FocusEvent):void
	    {
	    	//no-op for now
	    }
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(_headerFactoryChanged) {
				_headerFactoryChanged = false;
				
				// Remove old header if there is one
				if(_header && contains(_header)) {
					removeChild(_header);
					_header = null;
				}
				
				// If there's a new header, create it and update headerHeight.
				if(_headerFactory) {
					_header = _headerFactory.newInstance();
					addChild(_header);
				}
			}
			
			
		}
		
		
		
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			// Something relatively nutty is happening in this function, so I'll try to explain it here.
			// The CustomMenuBorder, our border of choice, is dependent on this CustomMenu for its style definitions.
			//   One of the styles it needs to know is the headerHeight -- the height of the header that
			//   sticks out on top of the menu.  We set it here because only now is the header's measure()
			//   function guaranteed to have occured.
			// Once that's set, we're free to allow super.updateDisplayList to run, drawing the CustomMenuBorder,
			//   etc.
			// Finally, if, again, there is a header, we render it.  We're also doing something tricky here:
			//   we're paying attention not to the viewMetrics but the borderMetrics.  That is because the
			//   viewMetrics is lying to us so that super.updateDisplayList will draw a little lower than
			//   it really should be, so that we have room to put the header area over it.  But the borderMetrics
			//   holds the true values, and we're going to lay things out based on what it says.
			
			if(_header) {
				setStyle("headerHeight", headerHeight);
			}
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if(_header) {
				_header.setActualSize(_header.getExplicitOrMeasuredWidth(), _header.getExplicitOrMeasuredHeight());
				_header.move(borderMetrics.left, borderMetrics.top);
				
				var radius:Number = getStyle("cornerRadius");
			}
			
			// Don't use the border; we're going to draw our own chrome.
			border.visible = false;
			
			var g:Graphics = _borderSprite.graphics;
			// Draw the background!
			g.clear();
			
			g.beginFill(getStyle("backgroundColor"));
			g.drawRect(0, 0, unscaledWidth, unscaledHeight);
			g.endFill();
			
			g.beginFill(getStyle("topBorderColor"));
			g.drawRect(0, 0, unscaledWidth, 1);
			g.endFill();
			
			g.beginFill(getStyle("bottomBorderColor"));
			g.drawRect(0, unscaledHeight - 1, unscaledWidth, 1);
			g.endFill();
			
			var rotationMatrix:Matrix = new Matrix();
			rotationMatrix.createGradientBox(unscaledWidth, unscaledHeight, Math.PI/2);
			g.beginGradientFill(GradientType.LINEAR, getStyle("borderColors"), getStyle("borderAlphas"), [0,255], rotationMatrix);
			g.drawRect(0, 0, 1, unscaledHeight);
			g.drawRect(unscaledWidth - 1, 0, 1, unscaledHeight);
			g.endFill();			
			
			drawDropShadow(0,0,unscaledWidth, unscaledHeight);
		}
		
	
		
		override public function get borderMetrics():EdgeMetrics
		{
			var newMetrics:EdgeMetrics = super.borderMetrics.clone();
			newMetrics.left += getStyle("borderThickness");
			newMetrics.right += getStyle("borderThickness");
			return newMetrics;
		}
		
		
		
		override public function show(xShow:Object=null, yShow:Object=null):void
		{

			super.show(xShow, yShow);

			// Contain the Menu within the bounds of the application.
	        if (xShow !== null && !isNaN(Number(xShow)) &&
	        	yShow !== null && !isNaN(Number(yShow))) {
	
				var globalPoint:Point;
				
				if(owner is CustomMenu)
					globalPoint = new Point(xShow as Number, yShow as Number);
				else
					globalPoint = owner.localToGlobal(new Point(xShow as Number, yShow as Number));
				
				var stageWidth:Number = (Capabilities.hasScreenBroadcast) ? Number(Object(Object(owner.stage).window).width) : owner.stage.width;
				var stageHeight:Number = (Capabilities.hasScreenBroadcast) ? Number(Object(Object(owner.stage).window).height) : owner.stage.height;
				if(globalPoint.x + getExplicitOrMeasuredWidth() > stageWidth) {
					xShow = stageWidth - getExplicitOrMeasuredWidth();
				}

				if(globalPoint.y + getExplicitOrMeasuredHeight() > stageHeight) {
					yShow = stageHeight - getExplicitOrMeasuredHeight();
				}

				move(Number(xShow), Number(yShow));
			}
			


			cacheAsBitmap = false;
			
			// Nullify superclass's tween wipe.
			if(popupTween)
				popupTween.pause();
			
			// Create our own tween... muahaha.
			var slideTween:Tween;
			if(slideDirection == SLIDE_DOWN)
				slideTween = new Tween(this, height, 0, OPEN_DURATION);
			else {
				slideTween = new Tween(this, -height, 0, OPEN_DURATION);
			}
			slideTween.setTweenHandlers(slideTweenUpdate, slideTweenEnd);
			slideTween.easingFunction = mx.effects.easing.Sine.easeOut;
			
			_showing = true;
		}
		
		mx_internal function slideTweenUpdate(value:Object):void
		{
			var shadowDistance:Number = getStyle("shadowDistance");
			scrollRect = new Rectangle(0, value as Number, unscaledWidth+shadowDistance, unscaledHeight+shadowDistance);
		}
		
		mx_internal function slideTweenEnd(value:Object):void
		{
			super.onTweenEnd(value);
			slideTweenUpdate(value);
		}
		
		
					
		mx_internal function slideTweenEndAndHide(value:Object):void
		{
			slideTweenEnd(value);
			
	        if (visible)
	        {
	            // Kill any tween that's currently running
	            if (popupTween)
	                popupTween.endTween();
	
	            clearSelected();
	            if (_nonRetardedlyPrivateAnchorRow)
	            {
	                drawItem(_nonRetardedlyPrivateAnchorRow, false, false);
	                _nonRetardedlyPrivateAnchorRow = null;
	            }
	
	        }
	        
	        if(!_showing)
		        super.hide();
		
		}
		
		
		
		


		
		override public function get viewMetrics():EdgeMetrics {
			var newMetrics:EdgeMetrics = super.viewMetrics.clone();
			
			if(_header)
				newMetrics.top += _header.getExplicitOrMeasuredHeight();
				
			newMetrics.top += 5;
			newMetrics.bottom += 5;
			return newMetrics;
		}
		
		
		
		
		public function set header(p_object:IFactory):void
		{
			_headerFactory = p_object;
			_headerFactoryChanged = true;
			invalidateProperties();
			invalidateDisplayList();
		}
		
		
		
		
		public function get headerHeight():Number
		{
			return _header ? _header.getExplicitOrMeasuredHeight() : 0;
		}
		
		
		
		
		
		/**
		 * Copied from Menu
		 */
		public static function createCustomMenu(parent:DisplayObjectContainer, mdp:Object, showRoot:Boolean=true):CustomMenu
		{
			
	        var panu:CustomMenu = new CustomMenu();
	        panu.tabEnabled = false;
	        panu.owner = DisplayObjectContainer(Application.application);
	        panu.showRoot = showRoot;
	        
	        // TODO: make these setStyles defaults the right way: CSS
			panu.setStyle("borderColor", 0x666666);
			panu.setStyle("borderSkin", CustomMenuBorder);
			panu.setStyle("borderStyle", "applicationControlBar");
			panu.setStyle("cornerRadius", 6);
			panu.setStyle("fillColors", [0xffffff, 0xc8c8c8]);
			panu.setStyle("fillAlphas", [1, 1]);
			panu.setStyle("shadowDistance", 3);
			panu.setStyle("dropShadowEnabled", true);
			panu.setStyle("shadowDirection", "right");
			panu.setStyle("shadowDistance", 5);
			panu.setStyle("borderThickness", 1);
//			panu.setStyle("panelHeight", 40);
			panu.setStyle("paddingLeft", 4);
			panu.setStyle("paddingRight", 4);
			panu.setStyle("paddingBottom", 4);
			
	        popUpCustomMenu(panu, parent, mdp);			
	        return panu;
		}
		
		/**
		 * Copied from Menu
		 */
	    public static function popUpCustomMenu(panu:CustomMenu, parent:DisplayObjectContainer, mdp:Object):void
	    {
	        panu.parentDisplayObject = parent ?
	                                   parent :
	                                   DisplayObject(Application.application);
	
	        if (!mdp)
	            mdp = new XML();
	
	        panu.supposedToLoseFocus = true;
	        panu.dataProvider = mdp;
	        
	    }
	    
	    override mx_internal function openSubMenu(row:IListItemRenderer):void
	    {
	        supposedToLoseFocus = true;
	
	        var r:CustomMenu = getRootMenu() as CustomMenu;
	        var menu:CustomMenu;
	
	        // check to see if the menu exists, if not create it
	        if (!IMenuItemRenderer(row).menu)
	        {
	            menu = new CustomMenu();
	            menu.parentMenu = this;
	            menu.owner = this;
	            menu.showRoot = showRoot;
	            menu.dataDescriptor = r.dataDescriptor;
	            menu.styleName = r;
	            menu.labelField = r.labelField;
	            menu.labelFunction = r.labelFunction;
	            menu.iconField = r.iconField;
	            menu.iconFunction = r.iconFunction;
	            menu.itemRenderer = r.itemRenderer;
	            menu.rowHeight = r.rowHeight;
	            menu.scaleY = r.scaleY;
	            menu.scaleX = r.scaleX;
	
	            // if there's data and it has children then add the items
	            if (row.data && 
	                _dataDescriptor.isBranch(row.data) &&
	                _dataDescriptor.hasChildren(row.data))
	            {
	                menu.dataProvider = _dataDescriptor.getChildren(row.data);
	            }
	            menu.sourceMenuBar = sourceMenuBar;
	            menu.sourceMenuBarItem = sourceMenuBarItem;
	
	            IMenuItemRenderer(row).menu = menu;
	            PopUpManager.addPopUp(menu, r, false);
	        }
	        else
	        {
	            menu = IMenuItemRenderer(row).menu as CustomMenu;
	        }
	
	        var _do:DisplayObject = DisplayObject(row);
	        var pt:Point = new Point(0,0);
	        pt = _do.localToGlobal(pt);
	        // when loadMovied, you may not be in global coordinates
	        if (_do.root)   //verify this is sufficient
	            pt = _do.root.globalToLocal(pt);

			if((width + pt.x) > stage.stageWidth) {				
				menu.show(x - (menu.width - 7), Math.min(pt.y - 7, this.stage.height - menu.height - getStyle("bottomPadding")));
			} else {
				menu.show(pt.x + width - 7, Math.min(pt.y - 7, this.stage.height - menu.height - getStyle("bottomPadding")));
			}
	        		
	        _nonRetardedlyPrivateSubMenu = menu;
	        openSubMenuTimer = 0;
	    }
	    
	  
	     /**
	     *  @private
	     *  Extend the behavior from ScrollSelectList to pop up submenus
	     */
	    override protected function mouseOverHandler(event:MouseEvent):void
	    {
	        if (!enabled || !selectable || !visible) 
	            return;
	            
	        var row:IListItemRenderer = mouseEventToItemRenderer(event);
	
	        if (!row) {
	        	//disableSeperatorMouseClicks(event);
	            return;
	        }
	
	        var item:Object;
	        if (row && row.data)
	            item = row.data;
	
	        if (row && row != _nonRetardedlyPrivateAnchorRow)
	        {
	            if (_nonRetardedlyPrivateAnchorRow)
	                // no longer on anchor so close its submenu
	                drawItem(_nonRetardedlyPrivateAnchorRow, false, false);
	            if (_nonRetardedlyPrivateSubMenu)
	            {
	                _nonRetardedlyPrivateSubMenu.supposedToLoseFocus = true;
	                _nonRetardedlyPrivateSubMenu.closeTimer = setTimeout(nonRetardedlyPrivateCloseSubMenu, 250, _nonRetardedlyPrivateSubMenu);
	            }
	            _nonRetardedlyPrivateSubMenu = null;
	            _nonRetardedlyPrivateAnchorRow = null;
	        }
	        else if (_nonRetardedlyPrivateSubMenu && _nonRetardedlyPrivateSubMenu._nonRetardedlyPrivateSubMenu)
	        {
	            // Close grandchild submenus - only children are allowed to be open
	            _nonRetardedlyPrivateSubMenu._nonRetardedlyPrivateSubMenu.hide();
	        }
	        
	        // Update the view
	        if (_dataDescriptor.isBranch(item) && _dataDescriptor.isEnabled(item))
	        {
	            _nonRetardedlyPrivateAnchorRow = row;
	
	            // If there's a timer waiting to close this menu, cancel the
	            // timer so that the menu doesn't close
	            if (_nonRetardedlyPrivateSubMenu && _nonRetardedlyPrivateSubMenu.closeTimer)
	            {
	                clearInterval(_nonRetardedlyPrivateSubMenu.closeTimer);
	                _nonRetardedlyPrivateSubMenu.closeTimer = 0;
	            }
	
	            // If the menu is not visible, pop it up after a short delay
	            if (!_nonRetardedlyPrivateSubMenu || !_nonRetardedlyPrivateSubMenu.visible)
	            {
	                if (openSubMenuTimer)
	                    clearInterval(openSubMenuTimer);
	 
	                openSubMenuTimer = setTimeout(
	                    function(row:IListItemRenderer):void
	                    {
	                        openSubMenu(row);
	                    },
	                    250,
	                    row);
	            }
	        }
	            
	            // Send event and update view
	        if (item && _dataDescriptor.isEnabled(item))
	        {
	            // we're rolling onto different subpieces of ourself or our highlight indicator
	            if (event.relatedObject)
	            {
	                if (itemRendererContains(row, event.relatedObject) ||
	                    row == lastHighlightItemRenderer ||
	                    event.relatedObject == highlightIndicator)
	                        return;
	            }
	        }
	
	        if (row)
	        {
	            drawItem(row, false, Boolean(item && _dataDescriptor.isEnabled(item)));
	            
	            if (item && _dataDescriptor.isEnabled(item))
	            {
	                // Fire the appropriate rollover event
	                var menuEvent:MenuEvent = new MenuEvent(MenuEvent.ITEM_ROLL_OVER);
	                menuEvent.menu = this;
	                menuEvent.index = nonRetardedlyPrivateGetRowIndex(row);
	                menuEvent.menuBar = sourceMenuBar;
	                menuEvent.label = itemToLabel(item);
	                menuEvent.item = item;
	                menuEvent.itemRenderer = row;
	                getRootMenu().dispatchEvent(menuEvent);
	            }
	        }
	        
	        
	    }
	    
	    
	    protected function disableSeperatorMouseClicks(p_evt:MouseEvent):void
	    {
			for (var i:int = 0; i < listItems.length; i++){
                var myRow:MenuItemRenderer = listItems[i][0];
                if (myRow && myRow.data && _dataDescriptor.getType(myRow.data) == "separator") {
                	myRow.mouseEnabled = false ;
                }
            }
	    }
	    
	    /**
	     * Given a row, find the row's index in the Menu. 
	     */
	     protected function nonRetardedlyPrivateGetRowIndex(row:IListItemRenderer):int
	     {
	        for (var i:int = 0; i < listItems.length; i++)
	        {
	            var item:IListItemRenderer = listItems[i][0];
	            if (item && item.data && !(_dataDescriptor.getType(item.data) == "separator"))
	                if (item == row)
	                    return i;
	        }
	        return -1;
	     }
	    
	    
	    /**
	     *  @private
	     */
	    protected function nonRetardedlyPrivateCloseSubMenu(menu:Menu):void
	    {
	        menu.hide();
	        menu.closeTimer = 0;
	    }
	    
	    
	    /**
	     *  Hides the Menu control and any of its submenus if the Menu control is
	     *  visible.  
	     */
	    override public function hide():void
	    {
			// Create our own tween... muahaha.
			var slideTween:Tween;
			if(slideDirection == SLIDE_DOWN) {
				slideTween = new Tween(this, 0, height, CLOSE_DURATION);
			}
			else {
				slideTween = new Tween(this, 0, -height, CLOSE_DURATION);
			}
			slideTween.setTweenHandlers(slideTweenUpdate, slideTweenEndAndHide);
			slideTween.easingFunction = mx.effects.easing.Sine.easeOut;
			
			_showing = false;

	    }
	    
	    
	    
     override mx_internal function deleteDependentSubMenus():void
    {
        var n:int = listItems.length;
        for (var i:int = 0; i < n; i++)
        {
            
            // Check to see if the listItems array has a renderer at this index.
            if (listItems[i][0])
            {
                var subMenu:Menu = IMenuItemRenderer(listItems[i][0]).menu;
                if (subMenu)
                {
/*                    if(subMenu.hasEventListener(MouseEvent.MOUSE_DOWN)) {
						subMenu.systemManager.removeEventListener(MouseEvent.MOUSE_DOWN,
						                                                   mouseDownOutsideHandler);                    
                    }*/ // We can't do this because mouseDownOutsideHandler is private.
                    subMenu.deleteDependentSubMenus();
                    PopUpManager.removePopUp(subMenu);
                    IMenuItemRenderer(listItems[i][0]).menu = null;
                }
            }
        }
    }	    
	    
	    
		/**
		 *  @private
		 *  Apply a drop shadow using a bitmap filter.
		 *
		 *  Bitmap filters are slow, and their slowness is proportional
		 *  to the number of pixels being filtered.
		 *  For a large HaloBorder, it's wasteful to create a big shadow.
		 *  Instead, we'll create the shadow offscreen
		 *  and stretch it to fit the HaloBorder.
		 */
		private function drawDropShadow(p_x:Number, p_y:Number, 
										p_width:Number, p_height:Number,
										p_tlRadius:Number=0, p_trRadius:Number=0, 
										p_brRadius:Number=0, p_blRadius:Number=0):void
		{
			// Do I need a drop shadow in the first place?  If not, return
			// immediately.
			var isEnabled:* = getStyle("dropShadowEnabled");
			if ( isEnabled == false || 
			    isEnabled == "false" ||
				p_width == 0 || 
				p_height == 0)
			{
				return;
			}
	
			// Calculate the angle and distance for the shadow
			var distance:Number = getStyle("shadowDistance");
			var direction:String = getStyle("shadowDirection");
			var angle:Number;		
			if (getStyle("borderStyle") == "applicationControlBar")
			{
				var docked:Boolean = getStyle("docked");
				angle = docked ? 90 : getDropShadowAngle(distance, direction);
				distance = Math.abs(distance);
			}
			else
			{
				angle = getDropShadowAngle(distance, direction);
				distance = Math.abs(distance) + 2;
			}
			
			// Create a RectangularDropShadow object, set its properties,
			// and draw the shadow
			if (!_dropShadow)
				_dropShadow = new RectangularDropShadow();
	
			_dropShadow.distance = distance;
			_dropShadow.angle = angle;
			_dropShadow.color = getStyle("dropShadowColor");
			_dropShadow.alpha = 0.4;
	
			_dropShadow.tlRadius = p_tlRadius;
			_dropShadow.trRadius = p_trRadius;
			_dropShadow.blRadius = p_blRadius;
			_dropShadow.brRadius = p_brRadius;
			var g:Graphics = _shadowSprite.graphics;
			g.clear();
			_dropShadow.drawShadow(g, p_x, p_y, p_width, p_height);
		}		
		
		
		/**
		 *  @private
		 *  Convert the value of the shadowDirection property
		 *  into a shadow angle.
		 */
		private function getDropShadowAngle(p_distance:Number,
											p_direction:String):Number
		{
			if (p_direction == "left")
				return p_distance >= 0 ? 135 : 225;
	
			else if (p_direction == "right")
				return p_distance >= 0 ? 45 : 315;
			
			else // direction == "center"
				return p_distance >= 0 ? 90 : 270;
		}
	     

	}
}