package away3d.entities
{
	import away3d.arcane;
	import away3d.cameras.lenses.PerspectiveLens;
	import away3d.containers.ObjectContainer3D;
	import away3d.events.LensEvent;
	import away3d.textures.Texture2DBase;

	import flash.geom.Matrix3D;

	use namespace arcane;

	// tho this is technically not an entity, to the user it functions similarly, so it's in the same package
	public class TextureProjector extends ObjectContainer3D
	{
		private var _lens : PerspectiveLens;
		private var _viewProjectionInvalid : Boolean = true;
		private var _viewProjection : Matrix3D = new Matrix3D();
		private var _texture : Texture2DBase;

		public function TextureProjector(texture : Texture2DBase)
		{
			_lens = new PerspectiveLens();
			_lens.addEventListener(LensEvent.MATRIX_CHANGED, onInvalidateLensMatrix, false, 0, true);
			_texture = texture;
			_lens.aspectRatio = texture.width/texture.height;
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

		public function get texture() : Texture2DBase
		{
			return _texture;
		}

		public function set bitmapData(value : Texture2DBase) : void
		{
			if (value == _texture) return;
			_texture = value;
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

		/**
		 * @inheritDoc
		 */
		override protected function invalidateSceneTransform() : void
		{
			super.invalidateSceneTransform();
			_viewProjectionInvalid = true;
		}

		private function onInvalidateLensMatrix(event : LensEvent) : void
		{
			_viewProjectionInvalid = true;
		}
	}
}
