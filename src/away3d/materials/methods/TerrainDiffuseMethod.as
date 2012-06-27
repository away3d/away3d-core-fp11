package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.methods.MethodVO;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class TerrainDiffuseMethod extends BasicDiffuseMethod
	{
		private var _blendingTexture : Texture2DBase;
		private var _splats : Vector.<Texture2DBase>;
		private var _numSplattingLayers : uint;
		private var _detailTexture : Texture2DBase;
		private var _tileData : Array;
		private var _blendFactors : Array;

		/**
		 *
		 * @param splatTextures An array of Texture2DProxyBase containing the detailed textures to be tiled.
		 * @param blendData The texture containing the blending data. The red, green, and blue channels contain the blending values for each of the textures in splatTextures, respectively.
		 * @param tileData The amount of times each splat texture needs to be tiled. The first entry in the array applies to the base texture, the others to the splats. If omitted, the default value of 50 is assumed for each.
		 */
		public function TerrainDiffuseMethod(splatTextures : Array, blendingTexture : Texture2DBase, tileData : Array)
		{
			super();
			_splats = Vector.<Texture2DBase>(splatTextures);
			_tileData = tileData;
			_blendingTexture = blendingTexture;
			_numSplattingLayers = _splats.length;
			if (_numSplattingLayers > 3) throw new Error("More than 3 splatting layers is not supported!");
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			var data : Vector.<Number> = vo.fragmentData;
			var index : int = vo.fragmentConstantsIndex;
			data[index] = _tileData ? _tileData[0] : 1;
			for (var i : int = 1; i < 4; ++i) {
				data[index+i] = _tileData ? _tileData[i] : 50;
			}
		}

		public function setDetailTexture(detail : Texture2DBase = null, tileData  : Array = null, blendFactors : Array = null) : void
		{
			if (Boolean(detail) != Boolean(_detailTexture)) invalidateShaderProgram();
			_blendFactors = blendFactors;
			_detailTexture = detail;
		}

		arcane override function getFragmentPostLightingCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = "";
			var albedo : ShaderRegisterElement;
			var scaleRegister : ShaderRegisterElement;
			var detailScaleRegister : ShaderRegisterElement;
			var detailBlendFactorRegister : ShaderRegisterElement;
			var detailTexRegister : ShaderRegisterElement;

			// incorporate input from ambient
			if (vo.numLights > 0) {
				if (_shadowRegister)
					code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + _shadowRegister + ".w\n";
				code += "add " + targetReg + ".xyz, " + _totalLightColorReg + ".xyz, " + targetReg + ".xyz\n" +
						"sat " + targetReg + ".xyz, " + targetReg + ".xyz\n";
				regCache.removeFragmentTempUsage(_totalLightColorReg);

				albedo = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(albedo, 1);
			}
			else
				albedo = targetReg;

			if (!_useTexture) throw new Error("TerrainDiffuseMethod requires a diffuse texture!");
			_diffuseInputRegister = regCache.getFreeTextureReg();
			vo.texturesIndex = _diffuseInputRegister.index;
			var blendTexReg : ShaderRegisterElement = regCache.getFreeTextureReg();

			scaleRegister = regCache.getFreeFragmentConstant();

			if (_detailTexture) {
				detailScaleRegister = regCache.getFreeFragmentConstant();
				detailBlendFactorRegister = regCache.getFreeFragmentConstant();
				detailTexRegister = regCache.getFreeTextureReg();
			}

			var uv : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(uv, 1);

			code += "mul " + uv + ", " + _uvFragmentReg + ", " + scaleRegister + ".x\n" +
					getSplatSampleCode(vo, albedo, _diffuseInputRegister, uv);

			if (_detailTexture) {
				code += "mul " + uv + ", " + _uvFragmentReg + ", " + detailScaleRegister + ".x\n" +
						getSplatSampleCode(vo, uv, detailTexRegister, uv) +
						"mul " + uv + ", " + uv + ", " + detailBlendFactorRegister + ".x\n" +
						"mul " + albedo + ", " + albedo + ", " + uv + ".x\n";
			}

			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(temp, 1);
			var temp2 : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();

			code += "tex "+temp+", "+_uvFragmentReg +", "+blendTexReg+" <2d,linear,miplinear,clamp>\n";
			var splatTexReg : ShaderRegisterElement;

			vo.fragmentConstantsIndex = scaleRegister.index*4;
			var comps : Array = [ ".x",".y",".z",".w" ];

			for (var i : int = 0; i < _numSplattingLayers; ++i) {
				splatTexReg = regCache.getFreeTextureReg();
				code += "mul " + uv + ", " + _uvFragmentReg + ", " + scaleRegister + comps[i+1] + "\n" +
						getSplatSampleCode(vo, uv, splatTexReg, uv);

				if (_detailTexture) {
					code += "mul " + temp2 + ", " + _uvFragmentReg + ", " + detailScaleRegister + comps[i+1] + "\n" +
							getSplatSampleCode(vo, temp2, detailTexRegister, temp2) +
							"mul " + temp2 + ", " + temp2 + ", " + detailBlendFactorRegister + comps[i+1] + "\n" +
							"mul " + uv + ", " + temp2 + comps[i+1] + ", " + uv + "\n";
				}

				code += "sub " + uv + ", " + uv + ", " + albedo + "\n" +
						"mul " + uv + ", " + uv + ", " + temp + comps[i] + "\n" +
						"add " + albedo + ", " + albedo + ", " + uv + "\n";
			}
			regCache.removeFragmentTempUsage(uv);
			regCache.removeFragmentTempUsage(temp);

			if (vo.numLights == 0)
				return code;

			code += "mul " + targetReg + ".xyz, " + albedo + ".xyz, " + targetReg + ".xyz\n" +
					"mov " + targetReg + ".w, " + albedo + ".w\n";

			regCache.removeFragmentTempUsage(albedo);
			return code;
		}

		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			var i : int;
			var texIndex : int = vo.texturesIndex;
			super.activate(vo, stage3DProxy);
			stage3DProxy.setTextureAt(texIndex+1, _blendingTexture.getTextureForStage3D(stage3DProxy));

			if (_detailTexture) {
				var data : Vector.<Number> = vo.fragmentData;
				var index : int = vo.fragmentConstantsIndex+4;
				for (i = 0; i < 4; ++i) {
					data[index+i] = _tileData ? _tileData[i] : 50;
					data[index+i] = _blendFactors? _blendFactors[i] : 1;
				}
				stage3DProxy.setTextureAt(texIndex + 2, _detailTexture.getTextureForStage3D(stage3DProxy));
				++texIndex;
			}

			texIndex += 2;
			for (i = 0; i < _numSplattingLayers; ++i)
				stage3DProxy.setTextureAt(i + texIndex, _splats[i].getTextureForStage3D(stage3DProxy));
		}

		override public function set alphaThreshold(value : Number) : void
		{
			if (value > 0)
				throw new Error("Alpha threshold not supported for TerrainDiffuseMethod");
		}

		protected function getSplatSampleCode(vo : MethodVO, targetReg : ShaderRegisterElement, inputReg : ShaderRegisterElement, uvReg : ShaderRegisterElement = null) : String
		{
			// TODO: not used
			// var wrap : String = "wrap";
			var filter : String;

			if (vo.useSmoothTextures) filter = vo.useMipmapping ? "linear,miplinear" : "linear";
			else filter = vo.useMipmapping ? "nearest,mipnearest" : "nearest";

			uvReg ||= _uvFragmentReg;
			return "tex " + targetReg + ", " + uvReg + ", " + inputReg + " <2d," + filter + ",wrap>\n";
		}
	}
}
