package away3d.materials.methods
{
	import away3d.lights.shadowmaps.DirectionalShadowMapper;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.errors.AbstractMethodError;
	import away3d.lights.LightBase;
	import away3d.lights.PointLight;
	import away3d.lights.shadowmaps.ShadowMapperBase;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	public class ShadowMapMethodBase extends ShadingMethodBase
	{
		protected var _castingLight : LightBase;
		protected var _shadowMapper : ShadowMapperBase;

		protected var _epsilon : Number = .002;
		protected var _alpha : Number = 1;


		public function ShadowMapMethodBase(castingLight : LightBase)
		{
			super();
			_castingLight = castingLight;
			castingLight.castsShadows = true;
			_shadowMapper = castingLight.shadowMapper;
		}

		public function get alpha() : Number
		{
			return _alpha;
		}

		public function set alpha(value : Number) : void
		{
			_alpha = value;
		}

		public function get castingLight() : LightBase
		{
			return _castingLight;
		}

		public function get epsilon() : Number
		{
			return _epsilon;
		}

		public function set epsilon(value : Number) : void
		{
			_epsilon = value;
		}

		arcane function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			throw new AbstractMethodError();
			return null;
		}
	}
}
