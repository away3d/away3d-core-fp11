package away3d.lights
{
	import away3d.arcane;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.bounds.NullBounds;
	import away3d.core.partition.DirectionalLightNode;
	import away3d.core.partition.EntityNode;
	import away3d.lights.shadowmaps.DirectionalShadowMapper;
	import away3d.lights.shadowmaps.ShadowMapperBase;

	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * DirectionalLight represents an idealized light "at infinity", to be used for distant light sources such as the sun.
	 * In any position in the scene, the light raytracing will always be parallel.
	 * Although the position of the light does not impact its effect, it can be used along with lookAt to intuitively
	 * create day cycles by orbiting the position around a center point and using lookAt at that position.
	 */
	public class DirectionalLight extends LightBase
	{
		private var _direction : Vector3D;
		private var _tmpLookAt : Vector3D;
		private var _sceneDirection : Vector3D;

		/**
		 * Creates a new DirectionalLight object.
		 * @param xDir The x-component of the light's directional vector.
		 * @param yDir The y-component of the light's directional vector.
		 * @param zDir The z-component of the light's directional vector.
		 */
		public function DirectionalLight(xDir : Number = 0, yDir : Number = -1, zDir : Number = 1)
		{
			super();
			direction = new Vector3D(xDir, yDir, zDir);
			_sceneDirection = new Vector3D();
		}

		override protected function createEntityPartitionNode() : EntityNode
		{
			return new DirectionalLightNode(this);
		}

		/**
		 * The direction of the light in scene coordinates.
		 */
		public function get sceneDirection() : Vector3D
		{
			return _sceneDirection;
		}

		/**
		 * The direction of the light.
		 */
		public function get direction() : Vector3D
		{
			return _direction;
		}

		public function set direction(value : Vector3D) : void
		{
			_direction = value;
			//lookAt(new Vector3D(x + _direction.x, y + _direction.y, z + _direction.z));
			if(!_tmpLookAt) _tmpLookAt = new Vector3D();
			_tmpLookAt.x = x + _direction.x;
			_tmpLookAt.y = y + _direction.y;
			_tmpLookAt.z = z + _direction.z;
			
			lookAt(_tmpLookAt);
		}

		/**
		 * @inheritDoc
		 */
		override protected function getDefaultBoundingVolume() : BoundingVolumeBase
		{
			// directional lights are to be considered global, hence always in view
			return new NullBounds();
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateBounds() : void
		{
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateSceneTransform() : void
		{
			super.updateSceneTransform();
			sceneTransform.copyColumnTo(2, _sceneDirection);
			_sceneDirection.normalize();
		}

		override protected function createShadowMapper() : ShadowMapperBase
		{
			return new DirectionalShadowMapper();
		}
	}
}