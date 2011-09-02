package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.lights.LightBase;
	import away3d.lights.shadowmaps.ShadowMapperBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix3D;

	use namespace arcane;

	public class SoftShadowMapMethod extends ShadowMapMethodBase
	{
		private var _stepSize : Number;

		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function SoftShadowMapMethod(castingLight : LightBase, stepSize : Number = .00025)
		{
			super(castingLight);
			_stepSize = stepSize;
			_data[5] = 1/9;
			_data[6] = stepSize;
			_data[7] = 0;
		}

		public function get stepSize() : Number
		{
			return _stepSize;
		}

		public function set stepSize(value : Number) : void
		{
			_stepSize = value;
			_data[6] = _stepSize;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var depthMapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var depthCol : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var uvReg : ShaderRegisterElement;
			var code : String = "";
            _decIndex = decReg.index;

			regCache.addFragmentTempUsages(depthCol, 1);

			uvReg = regCache.getFreeFragmentVectorTemp();

			code += "mov " + uvReg + ", " + _depthMapVar + "\n" +

					"tex " + depthCol + ", " + _depthMapVar + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"add " + uvReg+".z, " + _depthMapVar+".z, " + dataReg+".x\n" +     // offset by epsilon
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + targetReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow

					"sub " + uvReg+".x, " + _depthMapVar+".x, " + dataReg+".z\n" + 	// (-1, 0)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +

					"add " + uvReg+".x, " + _depthMapVar+".x, " + dataReg+".z\n" + 		// (1, 0)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +

					"mov " + uvReg+".x, " + _depthMapVar+".x\n" +
					"sub " + uvReg+".y, " + _depthMapVar+".y, " + dataReg+".z\n" + 	// (0, -1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +

					"add " + uvReg+".y, " + _depthMapVar+".y, " + dataReg+".z\n" +	// (0, 1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +  // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n";

			code += "sub " + uvReg+".xy, " + _depthMapVar+".xy, " + dataReg+".zz\n" + // (0, -1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +   // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +

					"add " + uvReg+".y, " + _depthMapVar+".y, " + dataReg+".z\n" +	// (-1, 1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +   // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +

					"add " + uvReg+".xy, " + _depthMapVar+".xy, " + dataReg+".zz\n" +  // (1, 1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +   // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +

					"sub " + uvReg+".y, " + _depthMapVar+".y, " + dataReg+".z\n" +	// (1, -1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +   // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n";

			regCache.removeFragmentTempUsage(depthCol);
			code += "mul " + targetReg+".w, " + targetReg+".w, " + dataReg+".y\n";  // average

			_depthMapIndex = depthMapRegister.index;

			return code;
		}
	}
}
