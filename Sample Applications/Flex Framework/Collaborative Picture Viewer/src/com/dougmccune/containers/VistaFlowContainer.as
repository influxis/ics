package com.dougmccune.containers
{
	import caurina.transitions.Tweener;
	
	import flash.display.DisplayObject;
	import flash.events.KeyboardEvent;
	import flash.geom.ColorTransform;
	import flash.ui.Keyboard;
	
	import mx.managers.IFocusManagerComponent;
	
	import org.papervision3d.objects.DisplayObject3D;
	

	
	public class VistaFlowContainer extends CoverFlowContainer implements IFocusManagerComponent
	{
		public function VistaFlowContainer()
		{
			super();
			
			this.rotationAngle = -25;
			
			addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
		}
		
		override public function addChild(child:DisplayObject):DisplayObject {
			var child:DisplayObject = super.addChild(child);
		
			var plane:DisplayObject3D = lookupPlane(child);
			plane.material.doubleSided = true;
			
			var reflection:DisplayObject3D = lookupReflection(child);
			if(reflection)
				reflection.material.doubleSided = true;
			
			return child;
		}
		
		override protected function keyDownHandler(event:KeyboardEvent):void {
			if(event.keyCode == Keyboard.LEFT || event.keyCode == Keyboard.UP) {
				if(selectedIndex < numChildren - 1) {
					selectedIndex++;
				}
				else {
					selectedIndex=0;
				}
			}
			else if(event.keyCode == Keyboard.RIGHT || event.keyCode == Keyboard.DOWN) {
				if(selectedIndex > 0) {
					selectedIndex--;
				}
				else {
					selectedIndex = numChildren-1;
				}
			}
		}
		
		override protected function layoutChildren(unscaledWidth:Number, unscaledHeight:Number):void {
			layoutVistaFlow(unscaledWidth, unscaledHeight);
		}
		
		protected function layoutVistaFlow(uncaledWidth:Number, unscaledHeight:Number):void {
			var n:int = numChildren;
			
			for(var i:int=0; i<n; i++) {
				var child:DisplayObject = getChildAt(i);
				child.visible = false;
				
				var plane:DisplayObject3D = lookupPlane(child);
				
				if(plane == null) {
					continue;
				}
				
				plane.container.visible = true;
				
				var stackIndex:int = (i - selectedIndex);
				
				var horizontalGap:Number = getStyle("horizontalSpacing");
				if(isNaN(horizontalGap)) {
					//this seems to work fairly well as a default
					horizontalGap = maxChildHeight/3;
				}
				
				var verticalGap:Number = getStyle("verticalSpacing");
				if(isNaN(verticalGap)) {
					verticalGap = 10;
				}
				
				var xPosition:Number = -stackIndex * horizontalGap;
				var yPosition:Number = -(maxChildHeight - child.height)/2;
				var zPosition:Number = camera.z/2 + stackIndex * verticalGap + 100;
				
				var yRotation:Number = rotationAngle;
				
				
				
				if(i < selectedIndex) {
					xPosition += horizontalGap*3;
					yPosition -= 150;
					zPosition += 100;
				}
				
				
				if(reflectionEnabled) {
					var reflection:DisplayObject3D = lookupReflection(child);
					
					if(fadeEdges) {
						reflection.material.updateBitmap();
					}
					
					//drop the reflection down below the plane and put in a gap of 2 pixels. Why 2 pixels? I think it looks nice.
					var reflY:Number = yPosition - child.height - 2;
					
					reflection.visible = i >= selectedIndex;
					
					reflection.rotationY = yRotation;
					
					Tweener.addTween(reflection, {z:zPosition, time:tweenDuration/3});
					Tweener.addTween(reflection, {x:xPosition, y:reflY, rotationY:yRotation, time:tweenDuration});
				}
				
				plane.rotationY = yRotation;
				
				Tweener.addTween(plane, {z:zPosition, time:tweenDuration/3});
				Tweener.addTween(plane, {x:xPosition, y:yPosition, time:tweenDuration});
			}
		}
		
	}
}