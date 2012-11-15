package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
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
			if (Boolean(value) != Boolean(_mask) ||
				(value && _mask && (value.hasMipMaps != _mask.hasMipMaps || value.format != _mask.format)))
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

		/**
		 * The reflectiveness of the surface
		 */
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
			var temp2 : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();

			// r = I - 2(I.N)*N
			code += "dp3 " + temp + ".w, " + _sharedRegisters.viewDirFragment + ".xyz, " + _sharedRegisters.normalFragment + ".xyz		\n" +
					"add " + temp + ".w, " + temp + ".w, " + temp + ".w											\n" +
					"mul " + temp + ".xyz, " + _sharedRegisters.normalFragment + ".xyz, " + temp + ".w						\n" +
					"sub " + temp + ".xyz, " + temp + ".xyz, " + _sharedRegisters.viewDirFragment + ".xyz					\n" +
					getTexCubeSampleCode(vo, temp, cubeMapReg, _cubeTexture, temp) +
					"sub " + temp2 + ".w, " + temp + ".w, fc0.x									\n" +               	// -.5
					"kil " + temp2 + ".w\n" +	// used for real time reflection mapping - if alpha is not 1 (mock texture) kil output
					"sub " + temp + ", " + temp + ", " + targetReg + "											\n";

			if (_mask) {
				var maskReg : ShaderRegisterElement = regCache.getFreeTextureReg();
				code += getTex2DSampleCode(vo, temp2, maskReg, _mask, _sharedRegisters.uvVarying) +
						"mul " + temp + ", " + temp2 + ", " + dataRegister + ".x\n";
			}
			code +=	"mul " + temp + ", " + temp + ", " + dataRegister + ".x										\n" +
					"add " + targetReg + ", " + targetReg+", " + temp + "										\n";

			regCache.removeFragmentTempUsage(temp);

			return code;
		}
	}
}
