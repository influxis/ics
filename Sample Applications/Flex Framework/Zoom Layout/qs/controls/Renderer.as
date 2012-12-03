package qs.controls
{
	import qs.controls.fisheyeClasses.FisheyeAxis;
	import qs.controls.fisheyeClasses.FisheyeItem;
	import qs.controls.fisheyeClasses.RendererBase;

	public class Renderer extends RendererBase
	{
		/** the ideal positional data for the renderers.  When the inputs to the layout system change,
		 * this array is regenerated to represent the goal positions for each renderer.  Over time, the layout system
		 * will animate the children towards these positions */
		private var _pdata:Array = [];

		private var _mouseData:Array = [];

		/** the direction this component lays out
		 */
		private var _direction:String = "horizontal";

		/* abstractions around x/y, width/height. Instead of asking for x/y based properties directly,
		*  we go through these properties. Switch the properties, and our layout switches axis. Presto! */
		protected var major:FisheyeAxis = new FisheyeAxis();
		protected var minor:FisheyeAxis = new FisheyeAxis();

		//-----------------------------------------------------------------

		public function Renderer()		
		{
			major.direction = "horizontal";
			minor.direction = "vertical";			
		}
		/** whether we layout along the horizontal or vertical axis */
		public function set direction(value:String):void
		{
			if(value == _direction)
				return;
			_direction = value;			
			if(_direction == "vertical")
			{
				major.direction = "vertical";
				minor.direction = "horizontal";
			}
			else
			{
				major.direction = "horizontal";
				minor.direction = "vertical";
			}

			invalidateSize();
			animator.invalidateLayout();
		}

		public function get direction():String
		{
			return _direction;
		}

		override protected function measure():void
		{
			super.measure();
			animator.invalidateLayout();
		}
		override protected function commitProperties():void
		{
			var itemsChanged:Boolean = this.itemsChanged;
			super.commitProperties();
			
			_mouseData = [] ;
			_pdata = [] ;
			
			if(itemsChanged)
			{
				for(var i:int = 0;i<dataProvider.length;i++)
				{
					_pdata[i] = new FisheyeItem();
					_mouseData[i] = new FisheyeItem();
				}
			}

		}
		/** determines the pixel value along the major axis of the middle of the i-th item if it were highlighted 
		 *  the relevant value is stored in the FisheyeItem structure corresponding to the item. But that value is stored relative
		 *  to an anchor point...either the left, middle, or right (or top, middle, bottom) of the component based on the alignment style.
		 *  This function converts it to an absolute pixel value.
		 */
		private function midPointFor(i:int):Number
		{
			var pdata:FisheyeItem = _mouseData[i];
			return pdata[major.pos] + pdata[major.EOM] * pdata.scale/2;
		}
		
		override protected function generateLayout():void
		{
			var minorAlignValue:String = getStyle(minor.align);
			var itemCount:int = dataProvider.length;

			var targetIndex:Number = (isNaN(hilightedItemIndex)? selectedItemIndex:hilightedItemIndex);
			var pdata:FisheyeItem;
			
			if(itemCount == 0)
				return;
				
			if(isNaN(targetIndex))
			{
				populateMajorAxisForDefault(_pdata,major,this[major.unscaled]);			
				align(_pdata,major);		
			}
			else
			{
				if ( _pdata[targetIndex]["eomHeight"] == 0 && _pdata[targetIndex]["eomWidth"] == 0 ) {
					_pdata[targetIndex]["eomHeight"] = height ;
					_pdata[targetIndex]["eomWidth"] = (this[major.unscaled] - 10)/_pdata.length ;
				}
				pdata = _pdata[targetIndex];
				
				var targetPosition:Number = midPointFor(targetIndex) - pdata[major.EOM]*maxScaleWithDefault/2;
				if(targetPosition < 0)
					targetPosition = 0;
				if(targetPosition + pdata[major.EOM]*maxScaleWithDefault > this[major.unscaled])
					targetPosition = this[major.unscaled] - pdata[major.EOM]*maxScaleWithDefault;
					
				populateMajorAxisFor(_pdata.slice(targetIndex),0,this[major.unscaled] - targetPosition,major);
				
				var i:int ;
				for (i = targetIndex;i<itemCount;i++)
					_pdata[i][major.pos] += targetPosition;
				if(targetIndex > 0)
				{
					populateMajorAxisFor(_pdata.slice(0,targetIndex),targetIndex,targetPosition - defaultSpacingWithDefault,major);
					pdata = _pdata[targetIndex - 1];
					var offset:Number = targetPosition - (pdata[major.pos] + pdata[major.EOM] * pdata.scale + defaultSpacingWithDefault);
					for(i = 0;i<targetIndex;i++)
						_pdata[i][major.pos] += offset;
				}				
			}
			for(i = 0;i<itemCount;i++)
			{
				pdata = _pdata[i];
				var target:LayoutTarget = animator.targetFor(renderers[i]);
				target.scaleX = target.scaleY = pdata.scale;
				target.unscaledHeight = pdata.eomHeight;
				target.unscaledWidth = pdata.eomWidth;
				target[major.pos] = pdata[major.pos];
				target[minor.pos] = (minorAlignValue == "top" || minorAlignValue == "left")? 0:
					   (minorAlignValue == "right" || minorAlignValue == "bottom")? this[minor.unscaled] - pdata.scale*pdata[minor.EOM]:
					   						this[minor.unscaled]/2 - pdata.scale*pdata[minor.EOM]/2;
			}
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{

			populateMajorAxisForDefault(_mouseData,major,this[major.unscaled]);
			align(_mouseData,major);

			super.updateDisplayList(unscaledWidth,unscaledHeight);
			
		}

		override protected function findItemForPosition(xPos:Number,yPos:Number):Number
		{
			var majorPos:Number = (_direction == "horizontal"? xPos:yPos);
			var minorPos:Number = (_direction == "horizontal"? yPos:xPos);
			
			var minDist:Number = Infinity;
			var result:Number;
			for(var i:int = 0; i < dataProvider.length; i++)
			{
				var dist:Number = majorPos - midPointFor(i);
				if (Math.abs(dist) < Math.abs(minDist))				
				{
					minDist = dist;
					result = i;
				}
				else
				{
//					break;
				}				
			}
			return result;
		}

	}
}

