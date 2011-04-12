package away3d.lights
{
	import away3d.arcane;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.bounds.NullBounds;
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.OrthographicOffCenterLens;
	import away3d.containers.Scene3D;
	import away3d.core.math.Matrix3DUtils;
	import away3d.core.render.DepthRenderer;

	import away3d.lights.shadowmaps.DirectionalShadowMapper;
	import away3d.lights.shadowmaps.ShadowMapperBase;
	import away3d.materials.MaterialBase;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterCache;

	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * DirectionalLight represents an idealized light "at infinity", to be used for distant light sources such as the sun.
	 * In any position in the scene, the light rays will always be parallel.
	 * Although the position of the light does not impact its effect, it can be used along with lookAt to intuitively
	 * create day cycles by orbiting the position around a center point and using lookAt at that position.
	 */
	public class DirectionalLight extends LightBase
	{
		private var _direction : Vector3D;
		private var _sceneDirection : Vector3D;


		// shader-related
		private var _directionData : Vector.<Number> = Vector.<Number>([0, 0, 0, 1]);

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
			_sceneDirection = new Vector3D(0, 0, 0);
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
			lookAt(new Vector3D(x + _direction.x, y + _direction.y, z + _direction.z));
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
			sceneTransform.copyRowTo(2, _sceneDirection);
			_directionData[0] = -_sceneDirection.x;
			_directionData[1] = -_sceneDirection.y;
			_directionData[2] = -_sceneDirection.z;
		}

		/**
		 * @inheritDoc
		 */
		override protected function invalidateSceneTransform() : void
		{
			super.invalidateSceneTransform();
		}

		arcane override function getVertexCode(regCache : ShaderRegisterCache, globalPositionRegister : ShaderRegisterElement, pass : MaterialPassBase) : String
		{
			return super.getVertexCode(regCache, globalPositionRegister, pass);
		}

		arcane override function getFragmentCode(regCache : ShaderRegisterCache, pass : MaterialPassBase) : String
		{
			_fragmentDirReg = regCache.getFreeFragmentConstant();
			_shaderConstantIndex = _fragmentDirReg.index;
			return "";
		}

		arcane override function setRenderState(context : Context3D, inputIndex : int, pass : MaterialPassBase) : void
		{
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, inputIndex, _directionData, 1);
		}


		override protected function createShadowMapper() : ShadowMapperBase
		{
			return new DirectionalShadowMapper(this);
		}
	}
}