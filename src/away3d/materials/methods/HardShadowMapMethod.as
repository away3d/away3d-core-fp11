package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.lights.LightBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix3D;

	use namespace arcane;

	public class HardShadowMapMethod extends ShadowMapMethodBase
	{
		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function HardShadowMapMethod(castingLight : LightBase)
		{
			super(castingLight);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var depthMapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var epsReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var depthCol : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code : String = "";

			_decIndex = decReg.index;

			code += "tex " + depthCol + ", " + _depthMapVar + ", " + depthMapRegister + " <2d, nearestNoMip, clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"add " + targetReg + ".w, " + _depthMapVar+".z, " + epsReg+".x\n" +    // offset by epsilon

					"slt " + targetReg + ".w, " + targetReg + ".w, " + depthCol+".z\n";   // 0 if in shadow


			_depthMapIndex = depthMapRegister.index;

			return code;
		}
	}
}
