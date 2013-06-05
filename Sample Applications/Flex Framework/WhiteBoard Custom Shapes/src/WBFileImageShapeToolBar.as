package
{
	import com.adobe.coreUI.controls.whiteboardClasses.IWBPropertiesToolBar;
	import com.adobe.coreUI.events.WBCanvasEvent;
	import com.adobe.rtc.collaboration.FilePublisher;
	import com.adobe.rtc.events.FileManagerEvent;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.sharedManagers.FileManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.FileDescriptor;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.FileFilter;
	
	import mx.containers.HBox;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	import mx.utils.UIDUtil;

	/**
	 * @private
	 * The Idea is to use FileManager to save images and use the file or image URL's to display the image shape.
	 * Sometimes the URL might be bad the image might be broken or the image is broken if the internet connection is slow
	 * Note:
	 * Known Issues: When a image Shape is selected, the image toolBar is displayed, and choosing an image from the toolBar would not set the
	 * new shape to be drawn.
	 */
	public class WBFileImageShapeToolBar extends UIComponent implements IWBPropertiesToolBar
	{
		protected var _imageComboBox:ComboBox;
		protected var _imageFileURL:String;
		protected var _imageName:String;
		protected var _hBoxHolder:HBox;
		
		protected var _connectSession:ConnectSession;
		protected var _filePublisher:FilePublisher;
		protected var _fileManager:FileManager;
		protected var _userManager:UserManager;
		public static const groupid:String = "toolBarImages";
		protected var _thumbNailDialog:ThumbNailDialog;
		
		//Initialize the FileManager and initialize a thumb nail dialog to display the images.
		public function WBFileImageShapeToolBar()
		{
			super();
			_connectSession = ConnectSession.primarySession as ConnectSession;
			_filePublisher = new FilePublisher();
			_filePublisher.initialize();				
			_filePublisher.addEventListener(FileManagerEvent.FILE_ALERT,onFileAlert);
			
			_fileManager = ConnectSession.primarySession.fileManager;
			_fileManager.addEventListener(FileManagerEvent.UPDATED_FILE_DESCRIPTOR,onNewImageAdded);
			_userManager = ConnectSession.primarySession.userManager;
			
			_thumbNailDialog = new ThumbNailDialog(_fileManager,this);
			
			if(!_fileManager.isGroupDefined(groupid) && _fileManager.getUserRole(_userManager.myUserID) == UserRoles.OWNER) {
				var nodeConfig:NodeConfiguration = new NodeConfiguration();
				nodeConfig.sessionDependentItems = false;
				_filePublisher.createAndUseGroup(groupid, nodeConfig);
			}else {
				_filePublisher.groupName = groupid;
			}			
		}
		
		// set the imageURL to the latest file uploaded. imageURL would be the propertydata and definiondata for the imageshape
		protected function onNewImageAdded(p_evt:FileManagerEvent):void
		{
			var fileDescriptor:FileDescriptor = p_evt.fileDescriptor;
			if (fileDescriptor.groupName == groupid && fileDescriptor.uploadProgress == 100) {
				_imageFileURL = fileDescriptor.downloadUrl;
				_imageName = fileDescriptor.name;
			}
		}
		
		// set the imageURL to the latest file uploaded. imageURL would be the propertydata and definiondata for the imageshape
		public function set imageFileURL(p_URL:String):void
		{
			_imageFileURL = p_URL;
		}
		
		public function set imageName(p_imageName:String):void
		{
			_imageName = p_imageName;
		}
		
		protected function onFileAlert(p_evt:FileManagerEvent):void
		{
			trace(p_evt.alertMessage);
		}
		

		
		//Return the property data ie imageURL of the image selected in the ThumbNailDialog
		public function get propertyData():*
		{
			var returnObj:Object = new Object();
			returnObj.imageName = _imageName;
			return  returnObj;
		}
		
		public function set propertyData(p_data:*):void
		{
			_imageName = p_data.imageName;
		}
		
		public function set isFilledShape(p_filled:Boolean):void
		{
			//do nothing for now...
		}
		
		// Add the buttons and their eventlisteners needed for the property toolBar. There is room for more controls :)
		override protected function createChildren():void
		{
			//<mx:HBox id="shapeController" alpha="1.0" backgroundColor="#000000" backgroundAlpha="0.5" left="5" right="5" bottom="10" paddingBottom="5" paddingTop="5" paddingLeft="5" paddingRight="5" verticalAlign="middle">
			var maxHeight:Number = 0;
			_hBoxHolder = new HBox();
			addChild(_hBoxHolder);
			_hBoxHolder.alpha = 1.0;
			_hBoxHolder.setStyle("backgroundColor","#000000");
			_hBoxHolder.setStyle("backgroundAlpha",0.5);
			_hBoxHolder.percentHeight = 100;
			_hBoxHolder.percentWidth = 100;
			
			var addButton:Button = new Button();
			addButton.label = "Add Image";
			addButton.addEventListener(MouseEvent.CLICK,uploadImage);
			addButton.width = 120;
			addButton.height = 25;
			_hBoxHolder.height = Math.max(addButton.height,maxHeight);
			maxHeight = _hBoxHolder.height;
			_hBoxHolder.width += addButton.width;
			_hBoxHolder.addChild(addButton);
			
			var removeButton:Button = new Button();
			removeButton.label = "Choose..";
			removeButton.addEventListener(MouseEvent.CLICK,removeImage);
			removeButton.width = 90;
			removeButton.height = 25;
			_hBoxHolder.height = Math.max(removeButton.height,maxHeight);
			maxHeight = _hBoxHolder.height;
			_hBoxHolder.width += removeButton.width;
			_hBoxHolder.addChild(removeButton);
			
			//Add edges & Border & padding at the end
			_hBoxHolder.width += 20;
			_hBoxHolder.height += 10;
			_hBoxHolder.setStyle("paddingTop",5);
			_hBoxHolder.setStyle("paddingRight",5);
			_hBoxHolder.setStyle("paddingBottom",5);
			_hBoxHolder.setStyle("paddingLeft",5);
		}
		
		public function upload():void
		{
			uploadImage();
		}
		
		//Upload Image using the FilePublisher
		protected function uploadImage(p_evt:Event=null):void
		{
			var filterArray:Array=[new FileFilter("Images", "*.jpg;*.gif;*.png;*.jpeg")];
			_filePublisher.browse(UIDUtil.createUID(), filterArray);
			if (_thumbNailDialog.isPopUp) {
				PopUpManager.removePopUp(_thumbNailDialog);
			}
		}
		
		protected function removeImage(p_evt:Event):void
		{
			PopUpManager.addPopUp(_thumbNailDialog,parent);
			PopUpManager.centerPopUp(_thumbNailDialog);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
	}
}