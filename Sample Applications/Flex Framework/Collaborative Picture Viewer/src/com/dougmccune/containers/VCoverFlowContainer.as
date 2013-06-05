package com.dougmccune.containers
{
	import caurina.transitions.Tweener;
	
	import flash.display.DisplayObject;
	import flash.geom.ColorTransform;
	
	import mx.core.EdgeMetrics;
	
	import org.papervision3d.objects.DisplayObject3D;
	
	public class VCoverFlowContainer extends CoverFlowContainer
	{
		
		/**
		 * @private
		 * 
		 * For the vertical coverflow container we don't want to ever show reflections. Where would we put them?
		 */
		override public function set reflectionEnabled(value:Boolean):void {
			super.reflectionEnabled = false;
		}
		
		override protected function layoutCoverflow(unscaledWidth:Number, unscaledHeight:Number):void {
			
			var n:int = numChildren;
			
			for(var i:int=0; i<n; i++) {
				var child:DisplayObject = getChildAt(i);
				var plane:DisplayObject3D = lookupPlane(child);
				plane.container.visible = true;
				
				var abs:Number = Math.abs(selectedIndex - i);
				
				var horizontalGap:Number = getStyle("horizontalSpacing");
				if(isNaN(horizontalGap)) {
					horizontalGap = 10;
				}
				
				var verticalGap:Number = getStyle("verticalSpacing");
				if(isNaN(verticalGap)) {
					verticalGap = maxChildHeight/3;;
				}
				
				var yPosition:Number = selectedChild.height + ((abs-1) * verticalGap);
				var xPosition:Number = 0;
				var zPosition:Number = camera.z/2 + selectedChild.height + abs * horizontalGap;
				
				var zRotation:Number = rotationAngle;
				
				//some kinda fuzzy math here, I dunno, I was just playing with values
				//note that this only gets used if fadeEdges is true below
				var alpha:Number = (unscaledHeight/2 - yPosition) / (unscaledHeight/2);
				alpha  = Math.max(Math.min(alpha*2, 1), 0);
				
				if(i < selectedIndex) {
					yPosition *= -1;
					zRotation *= -1;
				}
				else if(i==selectedIndex) {
					yPosition = 0;
					zPosition = camera.z/2;
					zRotation = 0;
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
				
				if(i!=selectedIndex) {
					Tweener.addTween(plane, {z:zPosition, time:tweenDuration/3});
					Tweener.addTween(plane, {x:xPosition, y:yPosition, rotationX:zRotation, time:tweenDuration});
				}
				else {
					Tweener.addTween(plane, {x:xPosition, y:yPosition, z:zPosition, rotationX:zRotation, time:tweenDuration});
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