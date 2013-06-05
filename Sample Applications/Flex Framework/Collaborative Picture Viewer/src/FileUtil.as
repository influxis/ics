package
{
	import com.adobe.rtc.pods.sharedWhiteBoardClasses.SharedWBModel;
	import com.adobe.rtc.session.ConnectSessionContainer;
	import com.adobe.rtc.sharedModel.SharedCollection;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Matrix;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	/**
	* NOTE: THIS EXAMPLE WORKS ONLY WITH FLASH PLAYER 10
    * FileUtil class is a utility to help with file related activities , DUH...  
	*/
	public class FileUtil extends EventDispatcher
	{

		import com.adobe.rtc.sharedManagers.descriptors.FileDescriptor;
		import mx.utils.UIDUtil;
		import com.adobe.rtc.messaging.NodeConfiguration;
		import com.adobe.rtc.messaging.UserRoles;
		import com.adobe.rtc.events.SessionEvent;
		import com.adobe.rtc.collaboration.FileSubscriber;
		import com.adobe.rtc.collaboration.FilePublisher;
		import com.adobe.rtc.sharedManagers.UserManager;
		import com.adobe.rtc.sharedManagers.FileManager;
		import mx.collections.ArrayCollection;
		protected var _fileDescriptors:ArrayCollection=new ArrayCollection();

		protected var _fileManager:FileManager;
		protected var _userManager:UserManager;
		protected var _filePublisher:FilePublisher;
		protected var _fileSubscriber:FileSubscriber;
		protected var _groupid:String;
		protected var _fileReference:FileReference;
		protected var _sharedCollection:SharedCollection;
		//Use the _sharedCollectionObject to store all the imformation pertaining to a thumbnail and dump it to the shared collection
		protected var _sharedCollectionObject:Object;

		public function FileUtil(p_sharedCollection:SharedCollection)
		{
			_sharedCollection = p_sharedCollection;
		}

		/**
		* Set a new fileGroup specific to this app if required 
		*/		
		public function set fileGroup(p_string:String):void
		{
			_groupid=p_string;
		}

		/**
		* Return the fileGroup of the file Publisher currently used to save the file.
		* fileGroup is nothing but a way to organize files similar to folders  
		*/	
		public function get fileGroup():String
		{
			return _groupid;
		}

		/**
		* Return the fileGrid that has information about all the files in the File Manager  
		*/	
		public function get fileGrid():ArrayCollection
		{
			//Verify if we can return a null file descriptor if the file Group has no files
			return _fileDescriptors;
		}

		/**
		* Upload a file and invoke (asynchronously) methods to convert the image uploaded to a thumbnail.
		*/	
		public function upload():void
		{
			if(!_filePublisher.amIUploadingFile()){
				_fileReference = new FileReference();
				_fileReference.addEventListener(Event.SELECT,onFileSelect);
				_fileReference.addEventListener(Event.COMPLETE, onFileComplete);
				_fileReference.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
	            _fileReference.addEventListener(Event.OPEN, openHandler);
	            _fileReference.addEventListener(ProgressEvent.PROGRESS, progressHandler);
	            _fileReference.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
	            _fileReference.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA,uploadCompleteDataHandler);
				var filterArray:Array=[new FileFilter("Images", "*.jpg;*.gif;*.png;*.jpeg")];
				_fileReference.browse(filterArray);
			}
		}
		
		protected function onFileSelect(p_event:Event):void
  		{
  			_fileReference.load();
  		}
 
		/**
		* Actual thumbnail generation of and upload of the image to the file Manager happens here. 
		*/	
  		protected function onFileComplete(p_event:Event):void
  		{
			// Upload the file using the file Publisher
   			_filePublisher.uploadFileReference(_fileReference,_fileReference.name);
   			_sharedCollectionObject = new Object();
   			_sharedCollectionObject["fileName"] = _fileReference.name;
   			var actualImage:ByteArray = new ByteArray(); 
   			actualImage = _fileReference.data as ByteArray;
   			var loader:Loader = new Loader();
   			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,byteImageLoaded);
   			loader.loadBytes(actualImage);
   			_fileReference.removeEventListener(Event.SELECT,onFileSelect);
			_fileReference.removeEventListener(Event.COMPLETE, onFileComplete);
			_fileReference.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            _fileReference.removeEventListener(Event.OPEN, openHandler);
            _fileReference.removeEventListener(ProgressEvent.PROGRESS, progressHandler);
            _fileReference.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
            _fileReference.removeEventListener(DataEvent.UPLOAD_COMPLETE_DATA,uploadCompleteDataHandler);
            _fileReference = null;
  		}
  		
  		protected function byteImageLoaded(p_event:Event):void
  		{
  			//Explore alternative ways to create a Thumbnail
  			var sourceBMP:Bitmap = p_event.currentTarget.loader.content as Bitmap;
  			var thumbNailBitMapData:BitmapData = new BitmapData(128,80); 
			var matrix:Matrix = new Matrix();
			//make the thumbnail 128px X 80px
			matrix.scale(128/sourceBMP.width,80/sourceBMP.height);
			thumbNailBitMapData.draw(sourceBMP.bitmapData,matrix);
			_sharedCollectionObject["width"] = 128;
			_sharedCollectionObject["height"] = 80;
			_sharedCollectionObject["bitMapData"] = toByteArray(thumbNailBitMapData);
			// Dump the Thumbnail info into the shared Collection
			_sharedCollection.addItem(_sharedCollectionObject);
			_sharedCollectionObject = null;
  		}

		/**
		* Convert Bitmap Data to Byte Array.
		*/	
		protected function toByteArray(bd:BitmapData):ByteArray
		{
			var pixels:ByteArray=new ByteArray();
			for(var i:uint=0; i < bd.width; i++) {
				for(var j:uint=0; j < bd.height; j++) {
					pixels.writeUnsignedInt(bd.getPixel(i, j));
				}
			}
			return pixels;
		}


		/**
		* Download function to save the image. Not used in the app 
		*/	
		public function download(p_fileDescriptor:FileDescriptor):void
		{
			try
			{
				_fileSubscriber.download(p_fileDescriptor);
			}
			catch(e:Error)
			{
				trace("Error download: " + e.message);
			}
		}

		/**
		* Delete a file. Simultaneously remove the thumbnail by removing the item in the shared collection 
		*/	
		public function deleteFile(p_fileDescriptor:FileDescriptor):void
		{	
			for ( var i:int = 0 ; i < _sharedCollection.length ; i++ ) {
				if ( _sharedCollection.getItemAt(i).fileName == p_fileDescriptor.name ) {
					_sharedCollection.removeItemAt(i);
					break;
				}
			}
			_filePublisher.remove(p_fileDescriptor);
		}

		public function initializeUtil(p_sessionConnector:ConnectSessionContainer):void
		{
			//A set of initializations after we are connected
			var connectSessionContainer:ConnectSessionContainer = p_sessionConnector;
			if (connectSessionContainer.isSynchronized)
			{
				//Initialize the building blocks to manage Files
				if (_fileManager == null)
				{
					_fileManager=connectSessionContainer.fileManager;
				}

				if (_filePublisher == null)
				{
					_filePublisher=new FilePublisher();
					_filePublisher.initialize();
				}

				if (_fileSubscriber == null)
				{
					_fileSubscriber=new FileSubscriber();
					_fileSubscriber.initialize();
				}

				if (_userManager == null)
				{
					_userManager=connectSessionContainer.userManager;
				}

				if (_groupid == null)
				{
					_groupid="fileShare";
				}
				//Create a new fileGroup specific to this app
				if (!_fileManager.isGroupDefined(_groupid) && _fileManager.getUserRole(_userManager.myUserID, _groupid) == UserRoles.OWNER)
				{
					//Create a new node with a new groupid.
					var nodeConfig:NodeConfiguration=new NodeConfiguration();
					nodeConfig.sessionDependentItems=false;
					//Specifies whether files in the pod should be deleted as the session ends.
					_filePublisher.createAndUseGroup(_groupid, nodeConfig);
				}
				else
				{
					//otherwise, use assigned groupid
					if (_fileManager.isGroupDefined(_groupid))
					{
						_filePublisher.groupName=_groupid;
					}
				}

				_fileDescriptors=_fileManager.getFileDescriptors(_groupid);
			}
		}
			
		private function uploadCompleteDataHandler(event:DataEvent):void {
            //trace("uploadCompleteData: " + event);
        }

        private function ioErrorHandler(event:IOErrorEvent):void {
            trace("ioErrorHandler: " + event);
        }

        private function openHandler(event:Event):void {
            //trace("openHandler: " + event);
        }

        private function progressHandler(event:ProgressEvent):void {
            var file:FileReference = FileReference(event.target);
            //trace("progressHandler name=" + file.name + " bytesLoaded=" + event.bytesLoaded + " bytesTotal=" + event.bytesTotal);
        }

        private function securityErrorHandler(event:SecurityErrorEvent):void {
            trace("securityErrorHandler: " + event);
        }


	}
}

