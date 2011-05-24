package away3d.lights
{
	import away3d.arcane;
	import away3d.core.base.IRenderable;
	import away3d.errors.AbstractMethodError;
	import away3d.lights.shadowmaps.ShadowMapperBase;
	import away3d.materials.MaterialBase;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.LightNode;
	import away3d.entities.Entity;

	import flash.display3D.Context3D;
	import flash.geom.Matrix3D;

	use namespace arcane;

	/**
	 * LightBase provides an abstract base class for subtypes representing lights.
	 */
	public class LightBase extends Entity
	{
		private var _color : uint = 0xffffff;
		private var _colorR : Number = 1;
		private var _colorG : Number = 1;
		private var _colorB : Number = 1;

		private var _specular : Number = 1;
		arcane var _specularR : Number = 1;
		arcane var _specularG : Number = 1;
		arcane var _specularB : Number = 1;

		private var _diffuse : Number = 1;
		arcane var _diffuseR : Number = 1;
		arcane var _diffuseG : Number = 1;
		arcane var _diffuseB : Number = 1;

		private var _castsShadows : Boolean;

		protected var _fragmentDirReg : ShaderRegisterElement;
		protected var _shaderConstantIndex : uint;
		private var _shadowMapper : ShadowMapperBase;


		/**
		 * Create a new LightBase object.
		 * @param positionBased Indicates whether or not the light has a valid position, or is "infinite" such as a DirectionalLight.
		 */
		public function LightBase()
		{
			super();
		}

		public function get castsShadows() : Boolean
		{
			return _castsShadows;
		}

		public function set castsShadows(value : Boolean) : void
		{
			if (_castsShadows == value) return;

			_castsShadows = value;

			if (value) {
				_shadowMapper ||= createShadowMapper();
			} else {
				_shadowMapper.dispose();
				_shadowMapper = null;
			}
		}

		protected function createShadowMapper() : ShadowMapperBase
		{
			throw new AbstractMethodError();
		}

		/**
		 * The specular reflection strength of the light.
		 */
		public function get specular() : Number
		{
			return _specular;
		}


		public function set specular(value : Number) : void
		{
			if (value < 0) value = 0;
			_specular = value;
			updateSpecular();
		}

		/**
		 * The diffuse reflection strength of the light.
		 */
		public function get diffuse() : Number
		{
			return _diffuse;
		}

		public function set diffuse(value : Number) : void
		{
			if (value < 0) value = 0;
			else if (value > 1) value = 1;
			_diffuse = value;
			updateDiffuse();
		}

		/**
		 * The color of the light.
		 */
		public function get color() : uint
		{
			return _color;
		}

		public function set color(value : uint) : void
		{
			_color = value;
			_colorR = ((_color >> 16) & 0xff)/0xff;
			_colorG = ((_color >> 8) & 0xff)/0xff;
			_colorB = (_color & 0xff)/0xff;
			updateDiffuse();
			updateSpecular();
		}

		/**
		 * Gets the optimal projection matrix to render a light-based depth map for a single object.
		 * @param renderable The IRenderable object to render to a depth map.
		 * @param target An optional target Matrix3D object. If not provided, an instance will be created.
		 * @return A Matrix3D object containing the projection transformation.
		 */
		arcane function getObjectProjectionMatrix(renderable : IRenderable, target : Matrix3D = null) : Matrix3D
		{
			throw new AbstractMethodError();
		}

		/**
		 * @inheritDoc
		 */
		override protected function createEntityPartitionNode() : EntityNode
		{
			return new LightNode(this);
		}

		/**
		 * Updates the total specular components of the light.
		 */
		private function updateSpecular() : void
		{
			_specularR = _colorR*_specular;
			_specularG = _colorG*_specular;
			_specularB = _colorB*_specular;
		}

		/**
		 * Updates the total diffuse components of the light.
		 */
		private function updateDiffuse() : void
		{
			_diffuseR = _colorR*_diffuse;
			_diffuseG = _colorG*_diffuse;
			_diffuseB = _colorB*_diffuse;
		}

		arcane function getVertexCode(regCache : ShaderRegisterCache, globalPositionRegister : ShaderRegisterElement, pass : MaterialPassBase) : String
		{
			return "";
		}

		arcane function getFragmentCode(regCache : ShaderRegisterCache, pass : MaterialPassBase) : String
		{
			return "";
		}

		arcane function getAttenuationCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement, pass : MaterialPassBase) : String
		{
			return "";
		}

		arcane function get fragmentDirectionRegister() : ShaderRegisterElement
		{
			return _fragmentDirReg;
		}

		arcane function get shaderConstantIndex() : uint
		{
			return _shaderConstantIndex;
		}

		arcane function setRenderState(context : Context3D, inputIndex : int, pass : MaterialPassBase) : void
		{

		}

		arcane function get positionBased() : Boolean
		{
			return false;
		}

		public function get shadowMapper() : ShadowMapperBase
		{
			return _shadowMapper;
		}
	}
}