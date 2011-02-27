package away3d.materials.utils
{
	import flash.display.Sprite;
	import flash.events.AsyncErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	public class SimpleVideoPlayer implements IVideoPlayer
	{
		
		private var _src:String;
		private var _video:Video;
		private var _ns:NetStream;
		private var _nc:NetConnection;
		private var _nsClient:Object;
		private var _soundTransform:SoundTransform;
		private var _loop:Boolean;
		private var _playing:Boolean;
		private var _paused:Boolean;
		private var _lastVolume:Number;
		private var _container:Sprite;
		
		public function SimpleVideoPlayer()
		{
			
			// default values
			_soundTransform = new SoundTransform();
			_loop = false;
			_playing = false;
			_paused = false;
			_lastVolume = 1;
			
			
			// client object that'll redirect various calls from the video stream
			_nsClient = {};
			_nsClient["onCuePoint"] = metaDataHandler;
			_nsClient["onMetaData"] = metaDataHandler;
			_nsClient["onBWDone"] = onBWDone;
			_nsClient["close"] = streamClose;
			
			// NetConnection
			_nc = new NetConnection();
			_nc.client = _nsClient;
			_nc.addEventListener(NetStatusEvent.NET_STATUS, 		netStatusHandler, false, 0, true);
			_nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler, false, 0, true);
			_nc.addEventListener(IOErrorEvent.IO_ERROR, 			ioErrorHandler, false, 0, true);
			_nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, 		asyncErrorHandler, false, 0, true);
			_nc.connect(null);
			
			// NetStream
			_ns = new NetStream(_nc);
			_ns.checkPolicyFile = true;
			_ns.client = _nsClient;
			_ns.addEventListener(NetStatusEvent.NET_STATUS, 	netStatusHandler, false, 0, true);
			_ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, 	asyncErrorHandler, false, 0, true);
			_ns.addEventListener(IOErrorEvent.IO_ERROR, 		ioErrorHandler, false, 0, true);
			
			// video
			_video = new Video();
			_video.attachNetStream( _ns );
			
			// container
			_container = new Sprite();
			_container.addChild( _video );
		}
		
		
		//////////////////////////////////////////////////////
		// public methods
		//////////////////////////////////////////////////////
		
		public function play():void
		{
			
			if(!_src)
			{
				trace("Video source not set.");
				return;
			}
			
			if(_paused)
			{
				_ns.resume();
				_paused = false;
				_playing = true;
			}
			else if(!_playing)
			{
				_ns.play(_src);
				_playing = true;
				_paused = false;
			}
		}
		
		public function pause():void
		{
			if(!_paused)
			{
				_ns.pause();
				_paused = true;
			}
		}
		
		public function seek(val:Number):void
		{
			pause();
			_ns.seek( val );
			_ns.resume();
		}
		
		public function stop():void
		{
			_ns.close();
			_playing = false;
			_paused = false;
		}

		
		public function dispose():void
		{
			
			_ns.close();
			
			_video.attachNetStream( null );
			
			_ns.removeEventListener( NetStatusEvent.NET_STATUS, 	netStatusHandler );
			_ns.removeEventListener( AsyncErrorEvent.ASYNC_ERROR, 	asyncErrorHandler );
			_ns.removeEventListener( IOErrorEvent.IO_ERROR,			ioErrorHandler );
			
			_nc.removeEventListener( NetStatusEvent.NET_STATUS, 		netStatusHandler );
			_nc.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler );
			_nc.removeEventListener( IOErrorEvent.IO_ERROR, 			ioErrorHandler );
			_nc.removeEventListener( AsyncErrorEvent.ASYNC_ERROR, 		asyncErrorHandler );
			
			_nsClient["onCuePoint"] = null;
			_nsClient["onMetaData"]	= null;
			_nsClient["onBWDone"] 	= null;
			_nsClient["close"]		= null;
			
			_container.removeChild( _video );
			_container = null;
			
			_src =  null;
			_ns = null;
			_nc = null;
			_nsClient = null;
			_video = null;
			_soundTransform = null;

			_playing = false;
			_paused = false;
			
		}
		
		
		
		
		//////////////////////////////////////////////////////
		// event handlers
		//////////////////////////////////////////////////////
		
		
		private function asyncErrorHandler(event:AsyncErrorEvent): void
		{
			// Must be present to prevent errors, but won't do anything
		}
		
		private function metaDataHandler(oData:Object = null):void
		{
			// Offers info such as oData.duration, oData.width, oData.height, oData.framerate and more (if encoded into the FLV)
			//this.dispatchEvent( new VideoEvent(VideoEvent.METADATA,_netStream,file,oData) );
		}
		
		private function ioErrorHandler(e:IOErrorEvent):void
		{
			trace("An IOerror occured: "+e.text);
		}
		
		private function securityErrorHandler(e:SecurityErrorEvent):void
		{
			trace("A security error occured: "+e.text+" Remember that the FLV must be in the same security sandbox as your SWF.");
		}
		
		private function onBWDone():void
		{
			// Must be present to prevent errors for RTMP, but won't do anything
		}
		private function streamClose():void
		{
			trace("The stream was closed. Incorrect URL?");
		}
		
		
		private function netStatusHandler(e:NetStatusEvent):void
		{
			switch (e.info["code"]) {
				case "NetStream.Play.Stop": 
					//this.dispatchEvent( new VideoEvent(VideoEvent.STOP,_netStream, file) ); 
					if(loop)
						_ns.play(_src);
					
					break;
				case "NetStream.Play.Play":
					//this.dispatchEvent( new VideoEvent(VideoEvent.PLAY,_netStream, file) );
					break;
				case "NetStream.Play.StreamNotFound":
					trace("The file "+ _src +" was not found", e);
					break;
				case "NetConnection.Connect.Success":
					trace("Connected to stream", e);
					break;
			}
		}
		
		
		//////////////////////////////////////////////////////
		// get / set functions
		//////////////////////////////////////////////////////
		
		
		public function get source():String
		{
			return _src;
		}
		
		public function set source(src:String):void
		{
			_src = src;
			if(_playing) _ns.play(_src);
		}
		
		public function get loop():Boolean
		{
			return _loop;
		}
		
		public function set loop(val:Boolean):void
		{
			_loop = val;
		}
		
		public function get volume():Number
		{
			return _ns.soundTransform.volume;
		}
		
		public function set volume(val:Number):void
		{
			_soundTransform.volume = val;
			_ns.soundTransform = _soundTransform;
			_lastVolume = val;
		}
		
		public function get pan():Number
		{
			return _ns.soundTransform.pan;
		}
		
		public function set pan(val:Number):void
		{
			_soundTransform.pan = pan;
			_ns.soundTransform = _soundTransform;
		}
		
		public function get mute():Boolean
		{
			return _ns.soundTransform.volume == 0;
		}
		
		public function set mute(val:Boolean):void
		{
			_soundTransform.volume = (val)? 0 : _lastVolume;
			_ns.soundTransform = _soundTransform;
		}
		
		public function get soundTransform():SoundTransform
		{
			return _ns.soundTransform;
		}
		
		public function set soundTransform(val:SoundTransform):void
		{
			_ns.soundTransform = val;
		}
		
		public function get width():int
		{
			return _video.width;
		}
		
		public function set width(val:int):void
		{
			_video.width = val;
		}
		
		public function get height():int
		{
			return _video.height;
		}
		
		public function set height(val:int):void
		{
			_video.height = val;
		}
		
		
		//////////////////////////////////////////////////////
		// read-only vars
		//////////////////////////////////////////////////////
		
		public function get container():Sprite
		{
			return _container;
		}
		
		public function get time():Number
		{
			return _ns.time;
		}
		
		public function get playing():Boolean
		{
			return _playing;
		}

		public function get paused():Boolean
		{
			return _paused;
		}
		
		
	}
}