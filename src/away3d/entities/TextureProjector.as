package away3d.entities
{
	import away3d.arcane;
	import away3d.cameras.lenses.PerspectiveLens;
	import away3d.containers.ObjectContainer3D;
	import away3d.events.LensEvent;
	import away3d.textures.Texture2DBase;

	import flash.geom.Matrix3D;

	use namespace arcane;

	/**
	 * TextureProjector is an object in the scene that can be used to project textures onto geometry. To do so,
	 * the object's material must have a ProjectiveTextureMethod method added to it with a TextureProjector object
	 * passed in the constructor.
	 * This can be used for various effects apart from acting like a normal projector, such as projecting fake shadows
	 * unto a surface, the impact of light coming through a stained glass window, ...
	 *
	 * @see away3d.materials.methods.ProjectiveTextureMethod
	 */
	public class TextureProjector extends ObjectContainer3D
	{
		private var _lens : PerspectiveLens;
		private var _viewProjectionInvalid : Boolean = true;
		private var _viewProjection : Matrix3D = new Matrix3D();
		private var _texture : Texture2DBase;

		/**
		 * Creates a new TextureProjector object.
		 * @param texture The texture to be projected on the geometry. Since any point that is projected out of the range
		 * of the projector's cone is clamped to the texture's edges, the edges should be entirely neutral.
		 */
		public function TextureProjector(texture : Texture2DBase)
		{
			_lens = new PerspectiveLens();
			_lens.addEventListener(LensEvent.MATRIX_CHANGED, onInvalidateLensMatrix, false, 0, true);
			_texture = texture;
			_lens.aspectRatio = texture.width/texture.height;
			rotationX = -90;
		}

		/**
		 * The aspect ratio of the texture or projection. By default this is the same aspect ratio of the texture (width/height)
		 */
		public function get aspectRatio() : Number
		{
			return _lens.aspectRatio;
		}

		public function set aspectRatio(value : Number) : void
		{
			_lens.aspectRatio = value;
		}

		/**
		 * The vertical field of view of the projection, or the angle of the cone.
		 */
		public function get fieldOfView() : Number
		{
			return _lens.fieldOfView;
		}

		public function set fieldOfView(value : Number) : void
		{
			_lens.fieldOfView = value;
		}

		/**
		 * The texture to be projected on the geometry.
		 * IMPORTANT: Since any point that is projected out of the range of the projector's cone is clamped to the texture's edges,
		 * the edges should be entirely neutral. Depending on the blend mode, the neutral color is:
		 * White for MULTIPLY,
		 * Black for ADD,
		 * Transparent for MIX
		 */
		public function get texture() : Texture2DBase
		{
			return _texture;
		}

		public function set texture(value : Texture2DBase) : void
		{
			if (value == _texture) return;
			_texture = value;
		}

		/**
		 * The matrix that projects a point in scene space into the texture coordinates.
		 */
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
