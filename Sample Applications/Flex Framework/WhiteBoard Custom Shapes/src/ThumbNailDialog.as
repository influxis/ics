package
{
	import com.adobe.coreUI.controls.whiteboardClasses.WBCanvas;
	import com.adobe.rtc.events.FileManagerEvent;
	import com.adobe.rtc.pods.SharedWhiteBoard;
	import com.adobe.rtc.sharedManagers.FileManager;
	import com.adobe.rtc.sharedManagers.descriptors.FileDescriptor;
	
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Tile;
	import mx.containers.TitleWindow;
	import mx.controls.Button;
	import mx.controls.Image;
	import mx.core.ScrollPolicy;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;

	public class ThumbNailDialog extends TitleWindow
	{
		protected var _fileManager:FileManager;
		protected var _fileDescriptors:ArrayCollection = new ArrayCollection();
		protected var _tile:Tile;
		protected var _wbFileImageShapeToolBar:WBFileImageShapeToolBar;
		protected var _addButton:Button;
		protected var _wbCanvas:WBCanvas;

		public function ThumbNailDialog(p_FileManger:FileManager, p_FileImageToolBar:WBFileImageShapeToolBar)
		{
			_wbFileImageShapeToolBar = p_FileImageToolBar;
			_fileManager = p_FileManger;
			_fileDescriptors = _fileManager.fileDescriptors;
			_fileManager.addEventListener(FileManagerEvent.UPDATED_FILE_DESCRIPTOR,onNewImageAdded);
			_fileManager.addEventListener(FileManagerEvent.CLEARED_FILE_DESCRIPTOR,onFileRemoved);
			
			width = 600;
			height = 300;
			verticalScrollPolicy = horizontalScrollPolicy = ScrollPolicy.OFF;
			layout="vertical";
			setStyle("color",0x333333);
			setStyle("backgroundColor",0x333333);
			setStyle("borderAlpha",0.15);
			setStyle("paddingTop",0);
			setStyle("paddingRight",0);
			setStyle("paddingBottom",0);
			setStyle("paddingLeft",0);
			setStyle("horizontalAlign","center");
			setStyle("backgroundAlpha",0.45);
			setStyle("borderStyle","none");
			showCloseButton = true;
			addEventListener(CloseEvent.CLOSE,onClose);
			
			_tile = new Tile();
			_tile.width = 550;
			_tile.height = 225;
			_tile.direction = "horizontal";
			_tile.setStyle("borderStyle","none");
			_tile.setStyle("color",0x333333);
			_tile.setStyle("backgroundColor",0x333333);
			_tile.setStyle("horizontalGap",10);
			_tile.setStyle("verticalGap",15);
			_tile.setStyle("color",0x323232);
			_tile.setStyle("paddingTop",10);
			_tile.setStyle("paddingBottom",10);
			_tile.setStyle("paddingLeft",10);
			_tile.setStyle("paddingRight",10);
			_tile.setStyle("backgroundAlpha",0.45);
			_tile.verticalScrollPolicy = _tile.horizontalScrollPolicy = ScrollPolicy.AUTO;
			addChild(_tile);
			processImages();
			
			_addButton = new Button();
			_addButton.label = "Add +";
			_addButton.addEventListener(MouseEvent.CLICK,uploadImage);
			_addButton.width = 80;
			_addButton.height = 25;
			addChild(_addButton);
			_addButton.x = width - (_addButton.width + 10);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			_addButton.x = width - (_addButton.width + 20);
		}
		
		protected function uploadImage(p_evt:MouseEvent):void
		{
			_wbFileImageShapeToolBar.upload();
		}
		
		protected function onNewImageAdded(p_evt:FileManagerEvent):void
		{
			var fileDescriptor:FileDescriptor = p_evt.fileDescriptor;
			if (fileDescriptor.groupName == WBFileImageShapeToolBar.groupid && fileDescriptor.uploadProgress == 100) {
				processFileDescriptor(p_evt.fileDescriptor);
			}
		}
		
		protected function onFileRemoved(p_evt:FileManagerEvent):void
		{
			_tile.removeChild(_tile.getChildByName(p_evt.fileDescriptor.name));
		}
		
		protected function processImages():void
		{
			for (var i:int=0; i<_fileDescriptors.length ; i++)
			{
				var fileDescriptor:FileDescriptor = _fileDescriptors.getItemAt(i) as FileDescriptor;
				if (fileDescriptor.groupName == WBFileImageShapeToolBar.groupid) {
					processFileDescriptor(fileDescriptor);
				}
			}
		}
		
		protected function processFileDescriptor(p_fileDescriptor:FileDescriptor):void
		{
			var fileDescriptor:FileDescriptor = p_fileDescriptor;
			var image:Image = new Image();
			image.source = fileDescriptor.downloadUrl;
			image.width = 50;
			image.height = 50;
			image.id = image.name = p_fileDescriptor.name;
			image.addEventListener(MouseEvent.CLICK, onImageClick);
			_tile.addChild(image);
		}
		
		protected function onClose(p_evt:Event):void
		{
			PopUpManager.removePopUp(this);
		}
		
		protected function onImageClick(p_evt:Event):void
		{
			_wbFileImageShapeToolBar.imageName = p_evt.currentTarget.name;
			_wbFileImageShapeToolBar.imageFileURL = p_evt.currentTarget.source;
			PopUpManager.removePopUp(this);
		}
	}
}