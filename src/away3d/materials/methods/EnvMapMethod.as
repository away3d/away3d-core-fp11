package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.CubeTextureBase;
	import away3d.textures.Texture2DBase;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class EnvMapMethod extends EffectMethodBase
	{
		private var _cubeTexture : CubeTextureBase;
		private var _alpha : Number;
		private var _mask : Texture2DBase;

		public function EnvMapMethod(envMap : CubeTextureBase, alpha : Number = 1)
		{
			super();
			_cubeTexture = envMap;
			_alpha = alpha;
		}

		public function get mask() : Texture2DBase
		{
			return _mask;
		}

		public function set mask(value : Texture2DBase) : void
		{
			if (Boolean(value) != Boolean(_mask))
				invalidateShaderProgram();
			_mask = value;
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsNormals = true;
			vo.needsView = true;
		}

		/**
		 * The cube environment map to use for the diffuse lighting.
		 */
		public function get envMap() : CubeTextureBase
		{
			return _cubeTexture;
		}

		public function set envMap(value : CubeTextureBase) : void
		{
			_cubeTexture = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose() : void
		{
		}

		public function get alpha() : Number
		{
			return _alpha;
		}

		public function set alpha(value : Number) : void
		{
			_alpha = value;
		}

		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			vo.fragmentData[vo.fragmentConstantsIndex] = _alpha;
			stage3DProxy.setTextureAt(vo.texturesIndex, _cubeTexture.getTextureForStage3D(stage3DProxy));
			if (_mask)
				stage3DProxy.setTextureAt(vo.texturesIndex+1, _mask.getTextureForStage3D(stage3DProxy));
		}

		arcane override function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var dataRegister : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code : String = "";
			var cubeMapReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			vo.texturesIndex = cubeMapReg.index;
			vo.fragmentConstantsIndex = dataRegister.index*4;

			regCache.addFragmentTempUsages(temp, 1);

			// r = I - 2(I.N)*N
			code += "dp3 " + temp + ".w, " + _viewDirFragmentReg + ".xyz, " + _normalFragmentReg + ".xyz		\n" +
					"add " + temp + ".w, " + temp + ".w, " + temp + ".w											\n" +
					"mul " + temp + ".xyz, " + _normalFragmentReg + ".xyz, " + temp + ".w						\n" +
					"sub " + temp + ".xyz, " + temp + ".xyz, " + _viewDirFragmentReg + ".xyz					\n" +
					"tex " + temp + ", " + temp + ", " + cubeMapReg + " <cube, " + (vo.useSmoothTextures? "linear" : "nearest") + ",miplinear,clamp>\n" +
					"sub " + temp + ".w, " + temp + ".w, fc0.x									\n" +               	// -.5
					"kil " + temp + ".w\n" +	// used for real time reflection mapping - if alpha is not 1 (mock texture) kil output
					"sub " + temp + ", " + temp + ", " + targetReg + "											\n";

			if (_mask) {
				var temp2 : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
				var maskReg : ShaderRegisterElement = regCache.getFreeTextureReg();
				code += getTexSampleCode(vo, temp2, maskReg, _uvVaryingReg) +
						"mul " + temp + ", " + temp2 + ", " + dataRegister + ".x\n";
			}
			code +=	"mul " + temp + ", " + temp + ", " + dataRegister + ".x										\n" +
					"add " + targetReg + ".xyz, " + targetReg+".xyz, " + temp + ".xyz							\n";

			regCache.removeFragmentTempUsage(temp);

			return code;
		}
	}
}
