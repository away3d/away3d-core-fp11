package away3d.materials
{


	import away3d.errors.DeprecationError;
	import away3d.materials.utils.IVideoPlayer;
	import away3d.materials.utils.SimpleVideoPlayer;

	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;

	[Deprecated(message="Use texture composition instead of inheritance", replacement="TextureMaterial", since="4.0a")]
	public class VideoMaterial extends BitmapMaterial
	{
		
		private var _broadcaster:Sprite;
		private var _autoPlay:Boolean;
		private var _autoUpdate:Boolean;
		private var _materialSize:int;
		private var _player:IVideoPlayer;
		private var _clippingRect:Rectangle;
		
		
		public function VideoMaterial(source:String, materialSize:int = 256, loop:Boolean = true, autoPlay:Boolean = false, player:IVideoPlayer = null)
		{
			// used to capture the onEnterFrame event
			_broadcaster = new Sprite();
			
			// validates the size of the video
			_materialSize = materialSize;
			
			// this clipping ensures the bimapdata size is valid.
			_clippingRect = new Rectangle(0, 0, _materialSize, _materialSize);
			
			// assigns the provided player or creates a simple player if null.
			_player = player || new SimpleVideoPlayer();
			_player.loop = loop;
			_player.source = source;
			_player.width = _player.height = _materialSize;
			
			// sets autplay
			_autoPlay = autoPlay;
			
			// Sets up the bitmap material
			super( new BitmapData(_materialSize, _materialSize, true, 0x00ffffff), true, false, false);
			
			// if autoplay start video
			if(autoPlay)
				_player.play();
			
			// auto update is true by default 
			autoUpdate = true;

			throw new DeprecationError("VideoMaterial", "4.0a", "Please use new TextureMaterial(new VideoTexture(source)) instead.");
		}
		
		
		
		/**
		 * Draws the video and updates the bitmap material
		 * If this function is not called the bitmap material will not update! 
		 */
		public function update():void
		{
			
			if(_player.playing && !_player.paused)
			{
				
				bitmapData.lock();
				bitmapData.draw( _player.container, null, null, null, _clippingRect);
				updateBitmapData();
				bitmapData.unlock();
			}
			
		}
		
		
		override public function dispose():void
		{
			
			autoUpdate = false;
			_player.dispose();
			_player = null;
			_broadcaster = null;
			_clippingRect = null;
			
			super.dispose();
		}
		
		private function autoUpdateHandler( e:Event ):void
		{
			update();
		}
		
		//////////////////////////////////////////////////////
		// private class methods (static)
		//////////////////////////////////////////////////////
		
		
		/**
		 * Validates the size of the BitmapMaterial. 
		 * Supported size are 2, 4, 8, 16, 32, 64, 128, 512, 1024, 2048.
		 * Example: 145 would return 128. 
		 * @param size
		 * @return int A valid size.
		 * 
		 */		
		
		public static function validateMaterialSize( size:int ):int
		{
			
			var sizes:Array = [2, 4, 8, 16, 32, 64, 128, 512, 1024, 2048];
			var validSize:int = Math.abs( size );
			
			if( sizes.indexOf( validSize ) == -1 )
			{
				
				for(var i:uint = 1; i < sizes.length; ++i)
				{
					if( sizes[i] > validSize )
					{
						// finds the closest match
						validSize = ( Math.abs( sizes[i] - validSize ) < Math.abs( sizes[i-1] - validSize ) )? sizes[i] : sizes[i - 1];
						break;
					}
				}
				
				validSize = (validSize > 2048)? 2048 : validSize;
				
				trace("Warning: "+ size + " is not a valid material size. Updating to the closest supported resolution: " + validSize);
				
			}
			
			
			return validSize;
			
		}
		
		
		
		//////////////////////////////////////////////////////
		// get / set functions
		//////////////////////////////////////////////////////
	
		
		/**
		 * Indicates whether the video will start playing on initialisation.
		 * If false, only the first frame is displayed.
		 */
		public function set autoPlay(b:Boolean):void
		{
			_autoPlay = b; 
		}
		public function get autoPlay():Boolean
		{
			return _autoPlay;		
		}
		
		
		/**
		 * Size of the bitmap used to render the video. This must be a supported resolution
		 * [2, 4, 8, 16, 32, 64, 128, 512, 1024, 2048]
		 * The size will be adjusted if an invalid value is passed
		 */		
		public function set materialSize(value:int):void
		{
			_materialSize = validateMaterialSize( value );
			_player.width = _player.height = _materialSize;
			_clippingRect = new Rectangle(0, 0, _materialSize, _materialSize);
		}
		
		public function get materialSize():int
		{
			return _materialSize;
		}

		
		/**
		 * Indicates whether the material will redraw onEnterFrame
		 */
		public function set autoUpdate(value:Boolean):void
		{
			_autoUpdate = value;
			
			if(value)
			{
				if(!_broadcaster.hasEventListener(Event.ENTER_FRAME))
					_broadcaster.addEventListener(Event.ENTER_FRAME, autoUpdateHandler, false, 0, true);
			}
			else
			{
				if(_broadcaster.hasEventListener(Event.ENTER_FRAME))
					_broadcaster.removeEventListener(Event.ENTER_FRAME, autoUpdateHandler);
			}
		}
		
		public function get autoUpdate():Boolean
		{
			return _autoUpdate;
		}

		public function get player():IVideoPlayer
		{
			return _player;
		}
	
	}
}