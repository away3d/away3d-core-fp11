package away3d.textures
{
	import away3d.materials.utils.IVideoPlayer;
	import away3d.materials.utils.SimpleVideoPlayer;
	import away3d.tools.utils.TextureUtils;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.media.Camera;
	import flash.media.Video;
	
	public class WebcamTexture extends BitmapTexture
	{
		private var _broadcaster : Sprite;
		private var _autoPlay : Boolean;
		private var _autoUpdate : Boolean;
		private var _materialSize : uint;
		private var _video : Video;
		private var _camera : Camera;
		private var _matrix:Matrix;
		private var _smoothing:Boolean;
		
		public function WebcamTexture( cameraWidth : uint = 320, cameraHeight : uint = 240, materialSize : uint = 256, autoStart : Boolean = true, camera : Camera = null, smoothing : Boolean = true )
		{
			_broadcaster = new Sprite();
			
			// validates the size of the material
			_materialSize  = validateMaterialSize( materialSize );
			
			// martrix transform to fit the camera video inside the Pow2 texure.
			_matrix = new Matrix();
			_matrix.scale(  _materialSize / cameraWidth, _materialSize / cameraHeight );
			
			// assigns the provided camera or creates one if null.
			_camera = camera || Camera.getCamera();
			
			// creates the video object
			_video = new Video( cameraWidth, cameraHeight );
			
			// Sets up the bitmap material
			super(new BitmapData(_materialSize, _materialSize, false, 0xFF9900));
			
			// if autoplay start video
			if (autoStart)
				play();
			
			// auto update is true by default
			autoUpdate = true;
			
			// set smoothing
			_smoothing = smoothing;
		}
		
		private function play():void
		{
			_video.attachCamera( _camera );
		}
		
		private function stop():void
		{
			// you know Adobe, you could add a video.detachCamera()... Just Saying.
			_video.attachCamera( null );
		}
		
		/**
		 * Draws the video and updates the bitmap texture
		 * If autoUpdate is false and this function is not called the bitmap texture will not update!
		 */
		public function update() : void
		{
		
			// draw
			bitmapData.lock();
			bitmapData.fillRect(bitmapData.rect, 0);
			bitmapData.draw(_video, _matrix, null, null, bitmapData.rect, _smoothing);
			bitmapData.unlock();
			invalidateContent();
			
		}
		
		override public function dispose() : void
		{
			super.dispose();
			autoUpdate = false;
			bitmapData.dispose();
			_video.attachCamera( null );
			_camera = null;
			_video = null;
			_broadcaster = null;
			_matrix = null;
		}
		
		private function autoUpdateHandler(event : Event) : void
		{
			update();
		}
		
		
		private function validateMaterialSize( size:uint ):int
		{
			if (!TextureUtils.isDimensionValid(size)) {
				var oldSize : uint = size;
				size = TextureUtils.getBestPowerOf2(size);
				trace("Warning: "+ oldSize + " is not a valid material size. Updating to the closest supported resolution: " + size);
			}
			
			return size;
		}
		
		/**
		 * Indicates whether the material will redraw onEnterFrame
		 */
		public function get autoUpdate():Boolean
		{
			return _autoUpdate;
		}
		
		public function set autoUpdate(value:Boolean):void
		{
			if (value == _autoUpdate) return;
			
			_autoUpdate = value;
			
			if(value)
				_broadcaster.addEventListener(Event.ENTER_FRAME, autoUpdateHandler, false, 0, true);
			else
				_broadcaster.removeEventListener(Event.ENTER_FRAME, autoUpdateHandler);
		}
		
		public function get camera():Camera
		{
			return _camera;
		}

		public function get smoothing():Boolean
		{
			return _smoothing;
		}

		public function set smoothing(value:Boolean):void
		{
			_smoothing = value;
		}

	}
}
