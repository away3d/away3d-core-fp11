package away3d.textures
{
	import away3d.tools.utils.TextureUtils;
	
	import flash.display.BitmapData;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix;
	import flash.media.Camera;
	import flash.media.Video;
	
	public class WebcamTexture extends BitmapTexture
	{
		private var _materialSize : uint;
		private var _video : Video;
		private var _camera : Camera;
		private var _matrix:Matrix;
		private var _smoothing : Boolean;
		private var _playing : Boolean;
		private var _autoUpdate : Boolean;
		
		public function WebcamTexture( cameraWidth : uint = 320, cameraHeight : uint = 240, materialSize : uint = 256, autoStart : Boolean = true, camera : Camera = null, smoothing : Boolean = true )
		{
			_materialSize  = validateMaterialSize( materialSize );
			
			super(new BitmapData(_materialSize, _materialSize, false, 0));
			
			// Use default camera if none supplied
			_camera = camera || Camera.getCamera();
			_video = new Video( cameraWidth, cameraHeight );
			
			_matrix = new Matrix();
			_matrix.scale(  _materialSize / cameraWidth, _materialSize / cameraHeight );
			
			if (autoStart) {
				_autoUpdate = true;
				start();
			}
			
			_smoothing = smoothing;
		}
		
		
		/**
		 * Defines whether the texture should automatically update while camera stream is
		 * playing. If false, the update() method must be invoked for the texture to redraw.
		*/
		public function get autoUpdate() : Boolean
		{
			return _autoUpdate;
		}
		public function set autoUpdate(val : Boolean) : void
		{
			_autoUpdate = val;
			
			if (_autoUpdate && _playing)
				invalidateContent();
		}
		
		
		/**
		 * The Camera instance (webcam) used by this texture.
		*/
		public function get camera():Camera
		{
			return _camera;
		}
		
		
		/**
		 * Toggles smoothing on the texture as it's drawn (and potentially scaled)
		 * from the video stream to a BitmapData object.
		 */
		public function get smoothing():Boolean
		{
			return _smoothing;
		}
		
		public function set smoothing(value:Boolean):void
		{
			_smoothing = value;
		}
		
		
		/**
		 * Start subscribing to camera stream. For the texture to update the update()
		 * method must be repeatedly invoked, or autoUpdate set to true.
		*/
		public function start():void
		{
			_video.attachCamera( _camera );
			_playing = true;
			invalidateContent();
		}
		
		
		/**
		 * Detaches from the camera stream.
		*/
		public function stop():void
		{
			_playing = false;
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
		
		
		/**
		 * Clean up used resources.
		*/
		override public function dispose() : void
		{
			super.dispose();
			stop();
			bitmapData.dispose();
			_video.attachCamera( null );
			_camera = null;
			_video = null;
			_matrix = null;
		}
		
		
		
		override protected function uploadContent(texture:TextureBase):void
		{
			super.uploadContent(texture);
			
			if (_playing && _autoUpdate) {
				// Keep content invalid so that it will
				// be updated again next render cycle
				update();
			}
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
