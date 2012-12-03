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
	import mx.core.Container;
	import mx.containers.HBox;
	import flash.events.MouseEvent;
	import mx.core.ContainerCreationPolicy;
	import mx.core.UIComponentDescriptor;
	import flash.geom.Point;
//	import flash.utils.getDefinitionByName;
	import mx.containers.Canvas;
	import mx.effects.Fade;
	import flash.events.Event;
	import mx.effects.Effect;
	import mx.effects.Blur;
	import mx.events.EffectEvent;
	import mx.controls.Button;
	import mx.controls.Menu;
	import mx.core.UIComponent;
	import mx.containers.VBox;
	import mx.core.IDeferredInstance;
	import flash.utils.setTimeout;
	import mx.events.MoveEvent;
	import mx.events.ResizeEvent;

		[DefaultProperty("disclosedComponent")]
	/**
	 * @private
	 * 
	 * This class causes a hidden UIComponent to pop up over the UIComponent in its <code>target</code>
	 * parameter when an event happens.  This should be used for pods, widgets, and other UIComponents where
	 * functionality can be hidden away until the user begins to interact meaningfully with it.
	 * 
	 * <p>To use it, set the <code>target</code> and <code>disclosedComponent</code> properties.  
	 * By default, the disclosure and undisclosure (hiding) events are <code>MouseOver</code> and <code>MouseOut
	 * </code>, but these can be changed through their respective properties.</p>
	 */
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
   public class  ProgressiveDisclosureContainer extends UIComponent
	{

		protected var _target:UIComponent;
		protected var _targetChanged:Boolean;
		
		protected var _disclosedComponent:IDeferredInstance;
		protected var _subContainer:Canvas;
		
		protected var _oldDiscloseEventType:String;
		protected var _discloseEventType:String;
		protected var _discloseEventTypeChanged:Boolean;
		
		protected var _oldUndiscloseEventType:String;
		protected var _undiscloseEventType:String;
		protected var _undiscloseEventTypeChanged:Boolean;

		protected var bitmapOverlay:BitmapComponent;
		private var _hasCreated:Boolean=false;
		private var _fadeIn:Fade;
		private var _fadeOut:Fade;
		private var _blurIn:Blur;
		
		private var _fadeAlpha:Number = .6;
		private var _fadeInDuration:Number = 250;
		private var _fadeOutDuration:Number = 400;


		/**
		* How long after the disclosure event the actual disclosure should happen.
		*/
		public var warmUp:uint=0;
		/**
		* How long after the undisclosure event the actual undisclosure should happen.
		*/
		public var coolDown:uint=0;


		/**
		 * Constructor.
		 */
		public function ProgressiveDisclosureContainer()
		{
//			creationPolicy = ContainerCreationPolicy.NONE;
		}
		



		/* Creation functions
		*************************************************************************/		

		/**
		 * @private
		 */
		override protected function createChildren():void
		{
			super.createChildren();
			
//			discloseEventType = MouseEvent.MOUSE_OVER;
//			undiscloseEventType = MouseEvent.MOUSE_OUT;
		}

		/**
		 * @private
		 */
		override protected function measure():void
		{
			super.measure();
			measuredHeight = measuredWidth = measuredMinHeight = measuredMinWidth = 0;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth,unscaledHeight);
			
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(_targetChanged) {
				if(_subContainer) {
					_subContainer.owner = _target;
				}
				
				if(_discloseEventType) {
					target.addEventListener(_discloseEventType, discloseHandler);
				}
				
				if(_undiscloseEventType) {
					target.addEventListener(_undiscloseEventType, undiscloseHandler);
				}
			}
			
			if(_discloseEventTypeChanged) {
				// unset old discloseEventType
				if(_oldDiscloseEventType) {
					if(target)
						target.removeEventListener(_oldDiscloseEventType, discloseHandler);
				}
	
				// set new discloseEventType
				if(target && _discloseEventType) {
					target.addEventListener(_discloseEventType, discloseHandler);
				}
				
				_discloseEventTypeChanged = false;
			}
			
			if(_undiscloseEventTypeChanged) {
				// unset old undiscloseEventType
				if(_oldUndiscloseEventType) {
					if(target)
						target.removeEventListener(_oldUndiscloseEventType, undiscloseHandler);
					if(_subContainer)
						_subContainer.removeEventListener(_oldUndiscloseEventType, undiscloseHandler);
				}
	
				// set new undiscloseEventType
				if(target) {
					target.addEventListener(_undiscloseEventType, undiscloseHandler);
				}
				if(_subContainer) {
					_subContainer.addEventListener(_undiscloseEventType, undiscloseHandler);
				}
				
				_undiscloseEventTypeChanged = false;
			}
		}


		/* Getters and setters
		*************************************************************************/		
		
		/**
		 * @private
		 */
		public function set target(p_component:UIComponent):void
		{
			_target = p_component;
			_targetChanged = true;
			
			invalidateProperties();			
		}
		
		/**
		 * The component that is always displayed.
		 * 
		 * <p>Setting this will set the <code>disclosedComponent</code>'s <code>owner</code> property
		 * to the <code>mainComponent</code> if the <code>disclosedComponent</code> has been defined.</p>
		 */
		public function get target():UIComponent
		{
			return _target;
		}
		
		/**
		 * @private
		 */
		public function set disclosedComponent(p_component:IDeferredInstance):void
		{
			_disclosedComponent = p_component;

/*			if(_target) {
				_disclosedComponent.owner = _target;
			}*/

			invalidateSize();
			invalidateDisplayList();
		}
		
		/**
		 * The component that is initially hidden and later disclosed.
		 * 
		 * <p>Setting this will set the disclosedComponent's <code>owner</code> property
		 * to the <code>mainComponent</code> if the mainComponent has been defined.</p>
		 */
		public function get disclosedComponent():IDeferredInstance
		{
			return _disclosedComponent;
		}		
		
		
		/**
		 * @private
		 */
		public function set discloseEventType(p_eventType:String):void
		{
			_oldDiscloseEventType = _undiscloseEventType;
			_discloseEventType = p_eventType;
			_discloseEventTypeChanged = true;
			
			invalidateProperties();
		}
		
		/**
		 * The event type to listen for that triggers the disclosure.
		 * 
		 * @default MouseEvent.MOUSE_OVER
		 */
		public function get discloseEventType():String
		{
			return _discloseEventType;
		}
		

		/**
		 * @private
		 */		
		public function set undiscloseEventType(p_eventType:String):void
		{
			_oldUndiscloseEventType = _undiscloseEventType;
			_undiscloseEventType = p_eventType;
			_undiscloseEventTypeChanged = true;
			
			invalidateProperties();

		}
		
		/**
		 * The event type to listen for that triggers the undisclosure.
		 * 
		 * @default MouseEvent.MOUSE_OUT
		 */
		public function get undiscloseEventType():String
		{
			return _undiscloseEventType;
		}
		
	
		
		/* Public functions
		*************************************************************************/		
		
		/**
		 * Makes the hidden content appear and causes the creation of the hidden content
		 * if it does not yet exist.
		 */
		public function disclose():void
		{
			
			if(_disclosedComponent) {
			
			
				// if the _subContainer has been created or is in the process of being created,
				// then the _subContainer has been disclosed.  do nothing.
				if (_subContainer!=null && _subContainer.visible || bitmapOverlay!=null && bitmapOverlay.visible) {
					return;
				}
				
				// deferred instantiation for the _subContainer
				if(!_subContainer) {
					_subContainer = new Canvas();
					var instance:UIComponent = UIComponent(_disclosedComponent.getInstance());
					if (!instance) {
						return;
					}
					if(_target) {
						instance.owner = _target;
						_target.addEventListener(MoveEvent.MOVE, sizeAndPositionContainer, false, 0, true);
						_target.addEventListener(ResizeEvent.RESIZE, sizeAndPositionContainer, false, 0, true);
					}
					
					_subContainer.visible = false;
					addChild(_subContainer);
					_subContainer.addChild(instance);
					_subContainer.validateNow();
					instance.validateNow();
					_subContainer.width = instance.width;
					_subContainer.height = instance.height;
					_subContainer.validateNow();
					
					if(_undiscloseEventType) {
						_subContainer.addEventListener(_undiscloseEventType, undiscloseHandler);
					}	
					
					
				}
				sizeAndPositionContainer();
				// fade that shizzle in!
				addBitmapOverlay();
				
			
			}
			invalidateSize();
			invalidateDisplayList();
		}
		
		/**
		 * Hides the <code>disclosedContent</code> from view.
		 */
		public function undisclose():void
		{
			// for this to happen, the _subContainer must exist and be visible
			if(_subContainer && _subContainer.visible) {
				_subContainer.visible = false;	// poof!
				
				if(bitmapOverlay) {
					// fade the overlay out
					bitmapOverlay.visible = true;
					_fadeOut = new Fade(bitmapOverlay);
					_fadeOut.alphaFrom = _fadeAlpha;
					_fadeOut.alphaTo = 0;
					_fadeOut.addEventListener(EffectEvent.EFFECT_END, undiscloseEnd);
					_fadeOut.duration = _fadeOutDuration;
					_fadeOut.play();
				}
			}
		}
		
		
		
		/* Internal helper functions
		*************************************************************************/		

		/**
		 * Handles the user-specified event that triggers disclosure.
		 * 
		 * @private
		 */
		protected function discloseHandler(p_evt:Event, p_isWarm:Boolean=false):void
		{
			if (!p_isWarm && warmUp>0) {
				setTimeout(discloseHandler, warmUp, p_evt, true);
				return;
			}
			if(_undiscloseEventType == MouseEvent.MOUSE_OUT && _subContainer) {
				if(target.mouseX < 0 || target.mouseX >= target.width || target.mouseY < 0 || target.mouseY > target.height) {
					return;
				}
			}
			disclose();
		}

		/**
		 * 
		 * Handles the user-specified event that triggers undisclosure. If special cases 
		 * arise where undisclosure is undesirable, catch and handle it here.
		 * 
		 * @private
		 */
		protected function undiscloseHandler(p_evt:Event, p_isCool:Boolean=false):void
		{
			if (!p_isCool && coolDown>0) {
				setTimeout(undiscloseHandler, coolDown, p_evt, true);
				return;
			}
			// a mouseOut caused by going from the mainComponent to the subComponent, or vice versa, doesn't count.
			if(_undiscloseEventType == MouseEvent.MOUSE_OUT && _subContainer) {
				if(target.mouseX >= 0 && target.mouseX < target.width && target.mouseY >= 0 && target.mouseY < target.height) {
					return;
				}
			}
			
			undisclose();
		}

		/**
		 * @private
		 */
		protected function addBitmapOverlay():void
		{
			_subContainer.visible = false;
			if (bitmapOverlay==null) {
				
				bitmapOverlay = new BitmapComponent();
				bitmapOverlay.displayObjectToClone = _subContainer;
				addChild(bitmapOverlay);
			}
			bitmapOverlay.visible = true;
			_blurIn = new Blur(bitmapOverlay);
			_blurIn.blurXFrom = 5;
			_blurIn.blurXTo = 2;
			_blurIn.duration = _fadeInDuration;
			_blurIn.play();
			_fadeIn = new Fade(bitmapOverlay);
			_fadeIn.addEventListener("effectEnd", fadeInEnd);
			_fadeIn.alphaFrom = 0;
			_fadeIn.alphaTo = _fadeAlpha;
			_fadeIn.duration = _fadeInDuration;
			_fadeIn.play();
		}

		/**
		 * @private
		 */
		protected function fadeInEnd(p_evt:Event):void
		{

//			bitmapOverlay.visible = false;
			_fadeOut = new Fade(bitmapOverlay);
			_fadeOut.alphaFrom = _fadeAlpha;
			_fadeOut.alphaTo = 0;
			_fadeOut.addEventListener(EffectEvent.EFFECT_END, fadeOutEnd);
			_fadeOut.duration = _fadeOutDuration;
			_fadeOut.play();

			_fadeIn = new Fade(_subContainer);
			_fadeIn.alphaFrom = _fadeAlpha;
			_fadeIn.alphaTo = 1;
			_fadeIn.duration = _fadeInDuration;
			_fadeIn.play();

//			_disclosedComponent.alpha = .9;
			_subContainer.visible = true;
			
			// if the user mouseOuted before the blur happened, 
			// the _subContainer doesn't disappear for some reason.
			// fix that here by checking to see that the mouse is still over this
			if(_undiscloseEventType == MouseEvent.MOUSE_OUT) {
				if(target.mouseX < 0 || target.mouseX > target.width || target.mouseY < 0 || target.mouseY > target.height) {
					undisclose();
				}
			}
		}

		/**
		 * @private
		 */
		protected function fadeOutEnd(p_evt:Event):void
		{
			if (bitmapOverlay) {
				bitmapOverlay.visible = false;
			}
		}


		/**
		 * @private
		 */
		protected function undiscloseEnd(p_evt:Event):void
		{
			removeChild(bitmapOverlay);
			bitmapOverlay = null;
		}



		/**
		 * @private
		 */
		public function sizeAndPositionContainer(p_evt:Event=null):void
		{
		
			var topStyle:Number = (getStyle("top")==undefined) ? -1 : getStyle("top");
			var bottomStyle:Number = (getStyle("bottom")==undefined) ? -1 : getStyle("bottom");
			var leftStyle:Number = (getStyle("left")==undefined) ? -1 : getStyle("left");
			var rightStyle:Number = (getStyle("right")==undefined) ? -1 : getStyle("right");
			

			var originalPt:Point = new Point();

			_subContainer.cacheAsBitmap = false;
			
			if (topStyle!=-1) {
				originalPt.y = topStyle;
				if (bottomStyle!=-1) {
					// need to stretch
					_subContainer.height = target.height - topStyle - bottomStyle;
				}
			} else if (bottomStyle!=-1) {
				// TODO : nigel : normalize height against owner
				originalPt.y = target.y + target.height - _subContainer.height - bottomStyle; 
			} else {
				originalPt.y = target.y + (target.height - _subContainer.height)/2;
			}

			
			if (leftStyle!=-1) {
				originalPt.x = leftStyle;
				if (rightStyle!=-1) {
					// need to stretch
					_subContainer.width = target.width - leftStyle - rightStyle;
				}
			} else if (rightStyle!=-1) {
				// TODO : nigel : normalize width against owner
				originalPt.x = target.x + target.width - _subContainer.width - rightStyle; 
			} else {
				//originalPt.x = target.x + (target.width - _subContainer.width)/2;
				originalPt.x = target.x ;
			}


			var ownerPt:Point = target.parent.localToGlobal(originalPt);
			var _subContainerPt:Point = _subContainer.parent.globalToLocal(ownerPt);
			_subContainer.move(originalPt.x, _subContainerPt.y);
			if (bitmapOverlay) {
//				bitmapOverlay.x = _subContainerPt.x;
//				bitmapOverlay.y = _subContainerPt.y;
			}
		}


	}
}