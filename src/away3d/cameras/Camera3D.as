package away3d.cameras
{
	import away3d.arcane;
	import away3d.cameras.lenses.LensBase;
	import away3d.cameras.lenses.PerspectiveLens;
	import away3d.core.partition.CameraNode;
	import away3d.core.partition.EntityNode;
	import away3d.entities.Entity;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * A Camera3D object represents a virtual camera through which we view the scene.
	 */
	public class Camera3D extends Entity
	{
		private var _viewProjectionInvalid : Boolean = true;
		private var _viewProjection : Matrix3D = new Matrix3D();
		private var _lens : LensBase;

		/**
		 * Creates a new Camera3D object
		 * @param lens An optional lens object that will perform the projection. Defaults to PerspectiveLens.
		 *
		 * @see away3d.cameras.lenses.PerspectiveLens
		 */
		public function Camera3D(lens : LensBase = null)
		{
			super();
			_lens = lens || new PerspectiveLens();
			_lens.onInvalidateMatrix = onInvalidateLensMatrix;
			z = -500;
		}

		// todo: no idea if this is correct. Also, there's no view port size knowledge, so normalized coords
		public function unproject(mX : Number, mY : Number):Vector3D
		{
			return sceneTransform.transformVector(lens.unproject(mX, mY, 0));

//			var vector : Vector3D = new Vector3D(mX, -mY, 0);
//			vector = _unprojection.transformVector(vector);
//			sceneTransform.transformVector(vector);
//			return vector;

		}

		/**
		 * The lens used by the camera to perform the projection;
		 */
		public function get lens() : LensBase
		{
			return _lens;
		}

		public function set lens(value : LensBase) : void
		{
			if (_lens == value) return;
			if (!value) throw new Error("Lens cannot be null!");
			_lens.onInvalidateMatrix = null;
			_lens = value;
			_lens.onInvalidateMatrix = onInvalidateLensMatrix;
		}

		/**
		 * The view projection matrix of the camera.
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

		/**
		 * @inheritDoc
		 */
		override protected function updateBounds() : void
		{
			_bounds.nullify();
			_boundsInvalid = false;
		}

		/**
		 * @inheritDoc
		 */
		override protected function createEntityPartitionNode() : EntityNode
		{
			return new CameraNode(this);
		}

		private function onInvalidateLensMatrix() : void
		{
			_viewProjectionInvalid = true;
		}
	}
}