package away3d.textures
{
	import away3d.tools.utils.TextureUtils;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.media.Camera;
	import flash.media.Video;
	
	public class WebcamTexture extends BitmapTexture
	{
		private var _broadcaster : Sprite;
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
			super(new BitmapData(_materialSize, _materialSize, false, 0));
			
			// if autoplay start video
			if (autoStart)
				start();
			
			// set smoothing
			_smoothing = smoothing;
		}
		
		public function start():void
		{
			_video.attachCamera( _camera );
			_broadcaster.addEventListener(Event.ENTER_FRAME, autoUpdateHandler, false, 0, true);
		}
		
		public function stop():void
		{
			// you know Adobe, you could add a video.detachCamera()... Just Saying.
			_video.attachCamera( null );
			_broadcaster.removeEventListener(Event.ENTER_FRAME, autoUpdateHandler);
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
			stop();
			bitmapData.dispose();
			_video.attachCamera( null );
			_camera = null;
			_video = null;
			_broadcaster = null;
			_matrix = null;
		}
		
		/**
		 * Flips the image from the webcam horizontally
		 */
		public function flipHorizontal():void
		{
			_matrix.a=-1*_matrix.a;
			_matrix.a > 0 ? _matrix.tx = _video.x - _video.width * Math.abs( _matrix.a ) : _matrix.tx = _video.width * Math.abs( _matrix.a ) +  _video.x;
		}
		
		/**
		 * Flips the image from the webcam vertically
		 */
		public function flipVertical():void
		{
			_matrix.d=-1*_matrix.d;
			_matrix.d > 0 ? _matrix.ty = _video.y - _video.height * Math.abs( _matrix.d ) : _matrix.ty = _video.height * Math.abs( _matrix.d ) +  _video.y;
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
		
		
	}
}
