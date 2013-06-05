package qs.controls
{
	import com.adobe.coreUI.controls.CameraUserBar;
	import com.adobe.coreUI.controls.VideoComponent;
	import com.adobe.rtc.collaboration.WebcamSubscriber;
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.events.UserEvent;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.sharedManagers.StreamManager;
	import com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor;
	
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	import mx.containers.Canvas;;

	public class MyWebcamSubscriber extends WebcamSubscriber
	{
		//import com.adobe.rtc.core.session_internal ;
		private var zoomComponent:ZoomComponent ;
		private var mySubscriber:Canvas ;
		private var selectedSubscriber:Canvas ;
		private var webcamSubscriber:WebcamSubscriber ;
		
		public function MyWebcamSubscriber()
		{
			super();
		}
		
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if (!mySubscriber ) {
				mySubscriber = new Canvas();
				addChild(mySubscriber);
			}
			
			
			if ( !selectedSubscriber ) {
				selectedSubscriber = new Canvas();
				mySubscriber.addChild(selectedSubscriber);
			}
			
			if ( !zoomComponent ) {
				zoomComponent = new ZoomComponent();
				mySubscriber.addChild(zoomComponent);
			}
		}
		
		/**
		 *plays the stream with the given stream type and stream's publisher ID	  
		 * @param p_streamPublisherID Publisher of the Stream
		 */
		override public function playStream(p_streamPublisherID:String):void
		{
			
			var streamDescriptor:StreamDescriptor = _streamManager.getStreamDescriptor(StreamManager.CAMERA_STREAM,p_streamPublisherID,_groupName);
			
			if ( streamDescriptor != null ) {
				_streamDescriptorTable[streamDescriptor.id] = streamDescriptor;
				if ( streamDescriptor.streamPublisherID != _userManager.myUserID || _isMyPaused) { 
					_netStreamTable[streamDescriptor.id]=new NetStream(_connectSession.sessionInternals.session_internal::connection as NetConnection);
            		_netStreamTable[streamDescriptor.id].play(streamDescriptor.id);
    			}else {
    				 if ( _cam && _cam.muted )
    					return;
    				
    			}
   			}
   			var vC:VideoComponent;
            if(_videoTable[streamDescriptor.id] == null ) {
            	vC = new VideoComponent();
            	_videoTable[streamDescriptor.id] = vC;
				streamCount++;
            }
            vC = _videoTable[streamDescriptor.id];
            if (streamDescriptor.streamPublisherID != _userManager.myUserID || _isMyPaused) { 
            	vC.attachNetStream(_netStreamTable[streamDescriptor.id]); 
            } else {
            	vC.attachCamera(_cam);
            }
            
            // If I am an ownder or if I am a publisher and It is my stream 
            if (!_cameraUserBarObj[streamDescriptor.id] && displayUserBars) {
            	var cBar:CameraUserBar = new CameraUserBar();
               	cBar.addEventListener(Event.CLOSE,onMyCameraClose);
            	cBar.addEventListener(Event.CHANGE,onCameraPause);
            	cBar.pause = streamDescriptor.pause ;            	
           		cBar.showStopPauseBtn = (_streamManager.getUserRole(_userManager.myUserID,StreamManager.CAMERA_STREAM,_groupName) == UserRoles.OWNER || (_streamManager.getUserRole(_userManager.myUserID,StreamManager.CAMERA_STREAM, _groupName) == UserRoles.PUBLISHER && streamDescriptor.streamPublisherID == _userManager.myUserID));	
            	_cameraUserBarObj[streamDescriptor.id] = cBar;
            }
         
		}	
		
		
			/**
		 *  @private
		 *	deletes the stream with the given stream id...for local use 
		 */
		override protected function deleteStream(p_stream:StreamDescriptor):void
		{			
			var vC:VideoComponent = _videoTable[p_stream.id];
			if (!vC) {
				return;
			}
			if (p_stream.streamPublisherID == _userManager.myUserID ) {
//				_netStreamTable[p_stream.id].attachCamera(null);
				vC.attachCamera(null);
			} 
			
			delete _netStreamTable[p_stream.id];
			
			if (vC) { 
				vC.clear();
				vC.close();
				delete _videoTable[p_stream.id];
			}
			
			
			var videos:Array = new Array();
			for ( var id:String in _videoTable ) {
				videos.push(_videoTable[id]);
			}
			
			if ( videos.length > 0 ) {
				zoomComponent.dataProvider = videos ;
			}
			
			if ( displayUserBars ) {
				//removeChild(_cameraUserBarObj[p_stream.id]);
				delete _cameraUserBarObj[p_stream.id];
			}
			delete _streamDescriptorTable[p_stream.id];
			streamCount--;
			
			if ( webcamSubscriber && webcamSubscriber.publisherIDs[0] == _userManager.myUserID ) {
				webcamSubscriber.publisherIDs = [] ;
				selectedSubscriber.removeChild(webcamSubscriber);
				webcamSubscriber = null ;	
			}
			
			zoomComponent.dataProvider = [] ;
			zoomComponent.hilightedItemIndex = NaN ;
			layoutCameraStreams();
		}
		
		
		
		override protected function layoutCameraStreams():void
		{
			var images:Array = new Array() ;
			var xOffSet:Number = 0 ;
			
			for (var id:String in _streamDescriptorTable) {
				if( _videoTable[id] != null) {
					if ( _cameraUserBarObj[id] && displayUserBars ) {
						var canvas:Canvas = new Canvas();
						canvas.id = id ;
						canvas.setStyle("borderThickness",2);
						canvas.setStyle("borderStyle","solid");
						canvas.setStyle("borderColor",0xcccccc);
						canvas.addChild(_videoTable[id]);
						_videoTable[id].percentWidth = 99.9 ;
						_videoTable[id].percentHeight = 99.9 ;
						canvas.addChild(_cameraUserBarObj[id]);
						_cameraUserBarObj[id].percentWidth = 99.9 ;
						_cameraUserBarObj[id].cameraUserLabel = _userManager.getUserDescriptor(_streamDescriptorTable[id].streamPublisherID).displayName ;
						_cameraUserBarObj[id].cameraUserID = _userManager.getUserDescriptor(_streamDescriptorTable[id].streamPublisherID).userID ;
						canvas.addEventListener(MouseEvent.CLICK,onCanvasClick);
						images.push(canvas);	
					}else {
						var vC:VideoComponent = _videoTable[id];
						images.push(vC);
					}
		 				
		 	 	}	
			}
			
			if ( mySubscriber ) {
				mySubscriber.width = width ;
				mySubscriber.height = height ;
			}
			
			if (selectedSubscriber ) {
				selectedSubscriber.percentHeight = 100 ;
				selectedSubscriber.percentWidth = 100 ;
				selectedSubscriber.x = 0 ;
				selectedSubscriber.y = 0 ;
			}
			
			if ( zoomComponent ) {
		 	 	zoomComponent.dataProvider = images ;
		 	 	zoomComponent.percentHeight = 40 ;
				zoomComponent.percentWidth = 100 ;
				zoomComponent.y = 0.60*height ;
				zoomComponent.x = 0 ;
		 	}
		 	
		 	if ( webcamSubscriber ) {
		 		webcamSubscriber.percentHeight = 100 ;
				webcamSubscriber.percentWidth = 100 ;
		 	}
			
		}
		
		
		
		
		private function onCanvasClick(p_evt:MouseEvent):void
		{
			if ( !webcamSubscriber ) {
				webcamSubscriber = new WebcamSubscriber() ;
				webcamSubscriber.publisherIDs = [] ;
				webcamSubscriber.webcamPublisher = this.webcamPublisher ;
				webcamSubscriber.addEventListener(UserEvent.USER_BOOTED,LargeCameraClose);
				webcamSubscriber.addEventListener(UserEvent.STREAM_CHANGE,LargeCameraPause);
				selectedSubscriber.addChild(webcamSubscriber);
				webcamSubscriber.percentHeight = 100 ;
				webcamSubscriber.percentWidth = 100 ;
			}
			
			webcamSubscriber.publisherIDs = new Array(_streamDescriptorTable[p_evt.currentTarget.id].streamPublisherID) ;
		}
		
		/**
		 * @private
		*/
		protected function LargeCameraClose(p_evt:UserEvent):void
		{
			var userStreams:Array = _streamManager.getStreamsForPublisher(p_evt.userDescriptor.userID,StreamManager.CAMERA_STREAM);
			_streamManager.deleteStream(StreamManager.CAMERA_STREAM,userStreams[0].streamPublisherID,_groupName);
		}
		
		/**
		* @private
		*/
		protected function LargeCameraPause(p_evt:UserEvent):void
		{
			var userStreams:Array = _streamManager.getStreamsForPublisher(p_evt.userDescriptor.userID,StreamManager.CAMERA_STREAM);
			
			var streamDescriptor:StreamDescriptor = userStreams[0];
			if ( streamDescriptor.streamPublisherID == _userManager.myUserID ) {
				_streamManager.pauseStream(StreamManager.CAMERA_STREAM,!streamDescriptor.pause,streamDescriptor.streamPublisherID);
			}else {
				if ( !streamDescriptor.pause ) {
					webcamSubscriber.pausePlayStreamLocally(streamDescriptor.type,streamDescriptor.streamPublisherID);
				}
			}
		}
		
			/**
		 * @private
		 */
		override protected function onMyCameraClose(p_evt:Event):void
		{
			var userDescriptors:Array = _userManager.userCollection.source ; 
			for ( var i:int = 0 ; i< userDescriptors.length ; i++ ) {
				if ( userDescriptors[i].userID == p_evt.target.cameraUserID ) {
					var userStreams:Array = _streamManager.getStreamsForPublisher(userDescriptors[i].userID,StreamManager.CAMERA_STREAM);
					_streamManager.deleteStream(StreamManager.CAMERA_STREAM,userStreams[0].streamPublisherID);
					break;
				}
			}
			
		}
		
		
		/**
		 * @private
		 */
		override protected function onCameraPause(p_evt:Event):void
		{
			var userDescriptors:Array = _userManager.userCollection.source ; 
			for ( var i:int = 0 ; i< userDescriptors.length ; i++ ) {
				if ( userDescriptors[i].userID == p_evt.currentTarget.cameraUserID ) {
					var userStreams:Array = _streamManager.getStreamsForPublisher(userDescriptors[i].userID,StreamManager.CAMERA_STREAM);
					var streamDescriptor:StreamDescriptor = userStreams[0];
					if ( streamDescriptor.streamPublisherID == _userManager.myUserID ) {
						_streamManager.pauseStream(StreamManager.CAMERA_STREAM,!streamDescriptor.pause,streamDescriptor.streamPublisherID);
					}else {
						if ( !streamDescriptor.pause ) {
							webcamSubscriber.pausePlayStreamLocally(streamDescriptor.type,streamDescriptor.streamPublisherID);
						}
					}
					break;
				}
			}
		}
	
		
	}
}