package com.dougmccune.containers
{
	import caurina.transitions.Tweener;
	
	import flash.display.DisplayObject;
	import flash.geom.ColorTransform;
	
	import mx.core.EdgeMetrics;
	import mx.core.UIComponent;
	
	import org.papervision3d.objects.DisplayObject3D;
	
	public class CoverFlowContainer extends BasePV3DContainer
	{
		/**
		 * The angle that each Plane is rotated on the y axis. This corresponds to PaperVision's yRotation property on
		 * the Plane. This is in degrees and should range from 0-90. A value of 0 means no rotation is applied and a value of 90
		 * would mean the Plane is rotated so much that it would effectively disappear.
		 */
		public var rotationAngle:Number = 70;
		
		/**
		 * If true the Planes near the edge of the component will fade to transparent. Kind of a cool effect sometimes
		 * if you want it.
		 */
		public var fadeEdges:Boolean = false;
		
		/**
		 * @private
		 * 
		 * For some of the layout stuff we need to know the max height of all the children. As children are
		 * added we make sure to update maxChildHeight.
		 */
		protected var maxChildHeight:Number;
		
		/**
		 * @private
		 * 
		 * For some of the layout stuff we need to know the max width of all the children. As children are
		 * added we make sure to update maxChildWidth.
		 */
		protected var maxChildWidth:Number;
		
		override public function addChild(child:DisplayObject):DisplayObject {
			super.addChild(child);
			
			var childHeight:Number = child is UIComponent ? UIComponent(child).getExplicitOrMeasuredHeight() : child.height;
			
			if(isNaN(maxChildHeight) || childHeight > maxChildHeight) {
				maxChildHeight = childHeight;
			}
			
			return child;
		}
		
		override protected function layoutChildren(unscaledWidth:Number, unscaledHeight:Number):void {
			super.layoutChildren(unscaledWidth, unscaledHeight);
			
			layoutCoverflow(unscaledWidth, unscaledHeight);
		}
		
		override public function removeChild(child:DisplayObject):DisplayObject {
			
			
			return super.removeChild(child);
			
		}
			
		protected function layoutCoverflow(uncaledWidth:Number, unscaledHeight:Number):void {
				
			var n:int = numChildren;
			
			for(var i:int=0; i<n; i++) {
				var child:DisplayObject = getChildAt(i);
				var plane:DisplayObject3D = lookupPlane(child);
				
				if(plane == null) {
					continue;
				}
				
				plane.container.visible = true;
				
				var abs:Number = Math.abs(selectedIndex - i);
				
				var horizontalGap:Number = getStyle("horizontalSpacing");
				if(isNaN(horizontalGap)) {
					//this seems to work fairly well as a default
					horizontalGap = maxChildHeight/3;
				}
				
				var verticalGap:Number = getStyle("verticalSpacing");
				if(isNaN(verticalGap)) {
					verticalGap = 10;
				}
				
				var xPosition:Number = selectedChild.width + ((abs-1) * horizontalGap);
				var yPosition:Number = -(maxChildHeight - child.height)/2;
				var zPosition:Number = camera.z/2 + selectedChild.width + abs * verticalGap;
				
				var yRotation:Number = rotationAngle;
				
				//some kinda fuzzy math here, I dunno, I was just playing with values
				//note that this only gets used if fadeEdges is true below
				var alpha:Number = (unscaledWidth/2 - xPosition) / (unscaledWidth/2);
				alpha  = Math.max(Math.min(alpha*2, 1), 0);
				
				if(i < selectedIndex) {
					xPosition *= -1;
					yRotation *= -1;
				}
				else if(i==selectedIndex) {
					xPosition = 0;
					zPosition = camera.z/2;
					yRotation = 0;
					alpha = 1;
				}
				
				if(fadeEdges) {
					//here's something sneaky. PV3D applies the colorTransform of the source movie clip to the
					//bitmapData that's created. So if we adjust the colorTransform that will be shown in the
					//3D plane as well. Cool, huh?
					var colorTransform:ColorTransform  = child.transform.colorTransform;
					colorTransform.alphaMultiplier = alpha;
					child.transform.colorTransform = colorTransform;
					plane.material.updateBitmap();
				}
				
				if(reflectionEnabled) {
					var reflection:DisplayObject3D = lookupReflection(child);
					
					if(fadeEdges) {
						reflection.material.updateBitmap();
					}
					
					//drop the reflection down below the plane and put in a gap of 2 pixels. Why 2 pixels? I think it looks nice.
					reflection.y = yPosition - child.height - 2;
					
					if(i!=selectedIndex) {
						Tweener.addTween(reflection, {z:zPosition, time:tweenDuration/3});
						Tweener.addTween(reflection, {x:xPosition, rotationY:yRotation, time:tweenDuration});
					}
					else {
						Tweener.addTween(reflection, {x:xPosition, z:zPosition, rotationY:yRotation, time:tweenDuration});
					}
				}
				
				if(i!=selectedIndex) {
					Tweener.addTween(plane, {z:zPosition, time:tweenDuration/3});
					Tweener.addTween(plane, {x:xPosition, y:yPosition, rotationY:yRotation, time:tweenDuration});
				}
				else {
					Tweener.addTween(plane, {x:xPosition, y:yPosition, z:zPosition, rotationY:yRotation, time:tweenDuration});
				}
				
				if(i == selectedIndex) {
					var bm:EdgeMetrics = borderMetrics;
		
					//We need to adjust the location of the selected child so
					//it exactly lines up with where our 3D plane will be. 
					child.x = unscaledWidth/2 - child.width/2 - bm.top;
					child.y = unscaledHeight/2 - child.height/2 - yPosition - bm.left;
					
					//the normal ViewStack sets the visibility of the selectedChild. That's no good for us,
					//so we just reset it back. 
					child.visible = false;
				}
			}
		}
	}
}