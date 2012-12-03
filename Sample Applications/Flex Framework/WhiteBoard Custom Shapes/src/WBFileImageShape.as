package 
{
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapeBase;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.sharedManagers.FileManager;
	
	import flash.display.Loader;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Image;
	
	/**
	 * @private
	 * The Idea is to use FileManager to save images and use the file or image URL's to display the image shape.
	 * Sometimes the URL might be bad the image might be broken or the image is broken if the internet connection is slow
	 * 
	 * Note:
	 * Known Issues: When a image Shape is selected, the image toolBar is displayed, and choosing an image from the toolBar would not set the
	 * new shape to be drawn.
	 */
	public class WBFileImageShape extends WBShapeBase
	{
		
		protected var _image:Image;
		protected var _imageByteArray:ByteArray;
		protected var _loader:Loader;
		protected var _imageFileURL:String;
		protected var _imageName:String;
		
		protected var _connectSession:ConnectSession;
		protected var _fileManager:FileManager;

		
		public function WBFileImageShape()
		{
			super();
			_connectSession = ConnectSession.primarySession as ConnectSession;
			_fileManager = ConnectSession.primarySession.fileManager;
		}
		
		// get the imageURL wrapped in the definitionData object. imageURL would be the propertydata and definiondata for the imageshape
		public override function get definitionData():*
		{
			var retObject:Object = new Object();
			retObject.imageName = _imageName;
			return retObject;
		}
		
		// Set the image source defined in the definitionData object.
		public override function set definitionData(p_data:*):void
		{
			if (p_data.imageName) {
				_imageName = p_data.imageName;
				_imageFileURL = constructFileURL(p_data.imageName as String);
				if (_image) {
					_image.source = _imageFileURL;
				} else {
					_image = new Image();
					_image.source = _imageFileURL;
					_image.cacheAsBitmap = false;
				}
				try {
					addChild(_image);
				} catch (error:Error) {
					trace(error.message);
				}
			}
		}
		
		public override function set propertyData(p_data:*):void
		{
			if (!_image) {
				_image = new Image();
				_imageName = p_data.imageName;
				_imageFileURL = constructFileURL(p_data.imageName as String);
				_image.source = _imageFileURL;
				addChild(_image);
				trace("adding Image @ propData");
			}
		}
		
		
		public override function get propertyData():*
		{
			var retObject:Object = new Object();
			retObject.imageName = _imageName;
			return retObject;
		}
		
		protected override function setupDrawing():void
		{
			stage.addEventListener(MouseEvent.MOUSE_MOVE, trackMouse);
		}
		
		protected override function cleanupDrawing():void
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, trackMouse);
		}
		
		protected function trackMouse(p_evt:MouseEvent):void
		{
			var pt:Point = globalToLocal(stage.localToGlobal(new Point(p_evt.stageX, p_evt.stageY)));
			width = pt.x;
			height = pt.y;
			validateNow();
		}
		
		protected override function updateDisplayList(p_w:Number, p_h:Number):void
		{
			super.updateDisplayList(p_w, p_h);
			if (_image){
				_image.maintainAspectRatio = false;
				_image.width = p_w;
				_image.height = p_h;
			}
		}
		
		// The fileURL or imageURL stored in the definition data are outdated as the file URL's use a ticket token that expires.
		protected function constructFileURL(p_fileName:String):String
		{
			var fileDescs:ArrayCollection = _fileManager.fileDescriptors;
			for (var i:int = 0; i < fileDescs.length ; i++) {
				if (p_fileName == fileDescs.getItemAt(i).name) {
					return fileDescs.getItemAt(i).downloadUrl;
				}
			}
			return null;
		}
	}
}