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

	// doesn't work anymore
	public class TripleFilteredShadowMapMethod extends ShadowMapMethodBase
	{
		private var _stepSize : Number;

		/**
		 * Creates a new BasicDiffuseMethod object.
		 *
		 * @param castingLight The light casting the shadow
		 */
		public function TripleFilteredShadowMapMethod(castingLight : LightBase)
		{
			super(castingLight);
			_stepSize = stepSize;
			_data[5] = 1/3;
			_data[6] = castingLight.shadowMapper.depthMapSize;
			_data[7] = _stepSize = 1/castingLight.shadowMapper.depthMapSize;
		}

		public function get stepSize() : Number
		{
			return _stepSize;
		}

		public function set stepSize(value : Number) : void
		{
			_stepSize = value;
			_data[7] = _stepSize;
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
			var code : String;
            _decIndex = decReg.index;

			regCache.addFragmentTempUsages(depthCol, 1);

			uvReg = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(uvReg, 1);

			code = 	"mov " + uvReg + ", " + _depthMapVar + "\n" +
//					"sub " + uvReg+".x, " + _depthMapVar+".x, " + dataReg+".w	\n" +
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"sub " + depthCol+".z, " + depthCol+".z, " + dataReg + ".x		\n" +	// offset by epsilon
					"slt " + uvReg+".z, " + _depthMapVar+".z, " + depthCol + ".z	\n" +    // 0 if in shadow

					"add " + uvReg+".x, " + uvReg+".x, " + dataReg+".w		\n" + // (1, 0)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"sub " + depthCol+".z, " + depthCol+".z, " + dataReg+".x		\n" + 	// offset by epsilon
					"slt " + uvReg+".w, " + _depthMapVar+".z, " + depthCol+".z		\n" +    // 0 if in shadow

					"div " + depthCol+".x, " + _depthMapVar+".x, " + dataReg+".w		\n" +
					"frc " + depthCol+".x, " + depthCol+".x		\n" +
					"sub " + uvReg+".w, " + uvReg+".w, " + uvReg+".z		\n" +
					"mul " + uvReg+".w, " + uvReg+".w, " + depthCol+".x		\n" +
					"add " + _viewDirFragmentReg+".w, " + uvReg+".z, " + uvReg+".w		\n" +

					"sub " + uvReg+".x, " + _depthMapVar+".x, " + dataReg+".w	\n" +
					"add " + uvReg+".y, " + _depthMapVar+".y, " + dataReg+".w	\n" +	// (0, 1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
					"dp4 " + depthCol + ".z, " + depthCol + ", " + decReg + "\n" +
					"sub " + depthCol + ".z, " + depthCol+".z, " + dataReg+".x		\n" + 	// offset by epsilon
					"slt " + uvReg + ".z, " + _depthMapVar+".z, " + depthCol+".z		\n" +   // 0 if in shadow

					"add " + uvReg + ".x, " + uvReg+".x, " + dataReg+".w						\n" +	// (1, 1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
					"dp4 " + depthCol + ".z, " + depthCol + ", " + decReg + "\n" +
					"sub " + depthCol + ".z, " + depthCol+".z, " + dataReg+".x				\n" +	// offset by epsilon
					"slt " + uvReg + ".w, " + _depthMapVar+".z, " + depthCol+".z			\n" +   // 0 if in shadow

					// recalculate fraction, since we ran out of registers :(
					"mul " + depthCol + ".x, " + _depthMapVar+".x, " + dataReg+".z			\n" +
					"frc " + depthCol + ".x, " + depthCol + ".x								\n" +
					"sub " + uvReg + ".w, " + uvReg + ".w, " + uvReg + ".z					\n" +
					"mul " + uvReg + ".w, " + uvReg + ".w, " + depthCol + ".x				\n" +
					"add " + uvReg + ".w, " + uvReg + ".z, " + uvReg + ".w					\n" +

					"mul " + depthCol + ".x, " + _depthMapVar + ".y, " + dataReg+".z		\n" +
					"frc " + depthCol + ".x, " + depthCol + ".x								\n" +
					"sub " + uvReg + ".w, " + uvReg+".w, " + _viewDirFragmentReg+".w		\n" +
					"mul " + uvReg + ".w, " + uvReg+".w, " + depthCol + ".x					\n" +
					"add " + targetReg + ".w, " + _viewDirFragmentReg+".w, " + uvReg+".w	\n" +



//					"mov " + uvReg + ".x, " + _depthMapVar+".x						\n" +
					"sub " + uvReg + ".xy, " + _depthMapVar+".xy, " + dataReg+".ww		\n" +
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
					"dp4 " + depthCol + ".z, " + depthCol + ", " + decReg + "\n" +
					"sub " + depthCol + ".z, " + depthCol + ".z, " + dataReg+".x	\n" +	// offset by epsilon
					"slt " + uvReg + ".z, " + _depthMapVar + ".z, " + depthCol+".z	\n" +   // 0 if in shadow

					"add " + uvReg + ".x, " + uvReg+".x, " + dataReg+".w			\n" +	// (1, 0)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
					"dp4 " + depthCol + ".z, " + depthCol + ", " + decReg + "\n" +
					"sub " + depthCol + ".z, " + depthCol + ".z, " + dataReg + ".x				\n" +	// offset by epsilon
					"slt " + uvReg+".w, " + _depthMapVar+".z, " + depthCol+".z					\n" +   // 0 if in shadow

					"div " + depthCol+".x, " + _depthMapVar+".x, " + dataReg+".w		\n" +
					"frc " + depthCol+".x, " + depthCol+".x								\n" +
					"sub " + uvReg+".w, " + uvReg+".w, " + uvReg+".z					\n" +
					"mul " + uvReg+".w, " + uvReg+".w, " + depthCol+".x					\n" +
					"add " + _viewDirFragmentReg + ".w, " + uvReg+".z, " + uvReg + ".w	\n" +

					"mov " + uvReg+".x, " + _depthMapVar + ".x							\n" +
					"add " + uvReg+".y, " + uvReg+".y, " + dataReg + ".w				\n" +	// (0, 1)
					"tex " + depthCol + ", " + uvReg+ ", " + depthMapRegister+ " <2d, nearest, clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"sub " + depthCol+".z, " + depthCol + ".z, " + dataReg + ".x		\n" +	// offset by epsilon
					"slt " + uvReg+".z, " + _depthMapVar + ".z, " + depthCol + ".z		\n" +   // 0 if in shadow

					"add " + uvReg+".x, " + uvReg+".x, " + dataReg + ".w				\n" +	// (1, 1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"sub " + depthCol+".z, " + depthCol+".z, " + dataReg + ".x			\n" +	// offset by epsilon
					"slt " + uvReg+".w, " + _depthMapVar + ".z, " + depthCol + ".z		\n" +   // 0 if in shadow

					// recalculate fraction, since we ran out of registers :(
					"mul " + depthCol + ".x, " + _depthMapVar + ".x, " + dataReg + ".z		\n" +
					"frc " + depthCol + ".x, " + depthCol + ".x								\n" +
					"sub " + uvReg + ".w, " + uvReg + ".w, " + uvReg + ".z					\n" +
					"mul " + uvReg + ".w, " + uvReg + ".w, " + depthCol + ".x				\n" +
					"add " + uvReg + ".w, " + uvReg + ".z, " + uvReg + ".w					\n" +

					"mul " + depthCol + ".x, " + _depthMapVar + ".y, " + dataReg + ".z					\n" +
					"frc " + depthCol + ".x, " + depthCol + ".x											\n" +
					"sub " + uvReg + ".w, " + uvReg + ".w, " + _viewDirFragmentReg + ".w				\n" +
					"mul " + uvReg + ".w, " + uvReg + ".w, " + depthCol + ".x							\n" +
					"add " + _viewDirFragmentReg + ".w, " + _viewDirFragmentReg + ".w, " + uvReg + ".w	\n" +
					"add " + targetReg + ".w, " + targetReg + ".w, " + _viewDirFragmentReg + ".w		\n";


			code +=	"add " + uvReg + ".xy, " + _depthMapVar + ".xy, " + dataReg + ".ww						\n" +	// (1, 0)
//					"mov " + uvReg + ".y, " + _depthMapVar + ".y										\n" +	// (1, 0)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
					"dp4 " + depthCol + ".z, " + depthCol + ", " + decReg + 		"\n" +
					"sub " + depthCol + ".z, " + depthCol + ".z, " + dataReg + ".x						\n" +	// offset by epsilon
					"slt " + uvReg + ".z, " + _depthMapVar + ".z, " + depthCol + ".z					\n" +   // 0 if in shadow

					"add " + uvReg + ".x, " + uvReg + ".x, " + dataReg + ".w							\n" +	// (2, 0)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
					"dp4 " + depthCol + ".z, " + depthCol + ", " + decReg +		"\n" +
					"sub " + depthCol + ".z, " + depthCol + ".z, " + dataReg + ".x						\n" +	// offset by epsilon
					"slt " + uvReg + ".w, " + _depthMapVar + ".z, " + depthCol + ".z					\n" +   // 0 if in shadow

					"div " + depthCol + ".x, " + _depthMapVar + ".x, " + dataReg + ".w					\n" +
					"frc " + depthCol + ".x, " + depthCol + ".x											\n" +
					"sub " + uvReg + ".w, " + uvReg + ".w, " + uvReg + ".z								\n" +
					"mul " + uvReg + ".w, " + uvReg + ".w, " + depthCol + ".x							\n" +
					"add " + _viewDirFragmentReg + ".w, " + uvReg + ".z, " + uvReg + ".w				\n" +

					"add " + uvReg+".xy, " + _depthMapVar+".xy, " + dataReg+".ww						\n" +	// (0, 1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
					"dp4 " + depthCol + ".z, " + depthCol + ", " + decReg +		"\n" +
					"sub " + depthCol + ".z, " + depthCol+".z, " + dataReg + ".x						\n" +	// offset by epsilon
					"slt " + uvReg + ".z, " + _depthMapVar+".z, " + depthCol + ".z						\n" +   // 0 if in shadow

					"add " + uvReg+".x, " + uvReg+".x, " + dataReg+".w									\n" +	// (1, 1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + 		"\n" +
					"sub " + depthCol+".z, " + depthCol+".z, " + dataReg+".x							\n" +	// offset by epsilon
					"slt " + uvReg+".w, " + _depthMapVar+".z, " + depthCol+".z							\n" +   // 0 if in shadow

					// recalculate fraction, since we ran out of registers :(
					"mul " + depthCol + ".x, " + _depthMapVar + ".x, " + dataReg + ".z					\n" +
					"frc " + depthCol + ".x, " + depthCol + ".x											\n" +
					"sub " + uvReg + ".w, " + uvReg + ".w, " + uvReg + ".z								\n" +
					"mul " + uvReg + ".w, " + uvReg + ".w, " + depthCol + ".x							\n" +
					"add " + uvReg + ".w, " + uvReg + ".z, " + uvReg + ".w								\n" +

					"mul " + depthCol + ".x, " + _depthMapVar+".y, " + dataReg + ".z					\n" +
					"frc " + depthCol + ".x, " + depthCol + ".x											\n" +
					"sub " + uvReg + ".w, " + uvReg + ".w, " + _viewDirFragmentReg + ".w				\n" +
					"mul " + uvReg + ".w, " + uvReg + ".w, " + depthCol + ".x							\n" +
					"add " + _viewDirFragmentReg + ".w, " + _viewDirFragmentReg + ".w, " + uvReg + ".w	\n" +
					"add " + targetReg + ".w, " + targetReg + ".w, " + _viewDirFragmentReg + ".w		\n" +


					"mul " + targetReg+".w, " + targetReg+".w, " + dataReg + ".y						\n";


			regCache.removeFragmentTempUsage(depthCol);
			regCache.removeFragmentTempUsage(uvReg);

			_depthMapIndex = depthMapRegister.index;

			return code;
		}

	}
}
