package away3d.entities
{
	import away3d.arcane;
	import away3d.cameras.lenses.PerspectiveLens;
	import away3d.containers.ObjectContainer3D;

	import away3d.core.managers.Texture3DProxy;

	import flash.display.BitmapData;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	// tho this is technically not an entity, to the user it functions similarly, so it's in the same package
	public class TextureProjector extends ObjectContainer3D
	{
		private var _lens : PerspectiveLens;
		private var _viewProjectionInvalid : Boolean = true;
		private var _viewProjection : Matrix3D = new Matrix3D();
		private var _texture : Texture3DProxy;

		public function TextureProjector(bitmapData : BitmapData)
		{
			_lens = new PerspectiveLens();
			_lens.onMatrixUpdate = onLensUpdate;
			_texture = new Texture3DProxy();
			_texture.bitmapData = bitmapData;
			_lens.aspectRatio = bitmapData.width/bitmapData.height;
//			lookAt(new Vector3D(0, -1000, 0));
			rotationX = -90;
		}

		public function get aspectRatio() : Number
		{
			return _lens.aspectRatio;
		}

		public function set aspectRatio(value : Number) : void
		{
			_lens.aspectRatio = value;
		}

		public function get fieldOfView() : Number
		{
			return _lens.fieldOfView;
		}

		public function set fieldOfView(value : Number) : void
		{
			_lens.fieldOfView = value;
		}

		public function get bitmapData() : BitmapData
		{
			return _texture.bitmapData;
		}

		public function set bitmapData(value : BitmapData) : void
		{
			_texture.bitmapData = value;
		}

		public function get viewProjection() : Matrix3D
		{
			if (_viewProjectionInvalid) {
				_viewProjection.copyFrom(inverseSceneTransform);
				_viewProjection.append(_lens.matrix);
				_viewProjectionInvalid = false;
			}
			return _viewProjection;
		}

		override public function dispose(deep : Boolean) : void
		{
			super.dispose(deep);
		}

		/**
		 * @inheritDoc
		 */
		override protected function invalidateSceneTransform() : void
		{
			super.invalidateSceneTransform();
			_viewProjectionInvalid = true;
		}

		private function onLensUpdate() : void
		{
			_viewProjectionInvalid = true;
		}

		arcane function get texture() : Texture3DProxy
		{
			return _texture;
		}
	}
}
