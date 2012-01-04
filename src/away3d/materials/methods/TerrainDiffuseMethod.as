package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class TerrainDiffuseMethod extends BasicDiffuseMethod
	{
		private var _blendingTexture : Texture2DBase;
		private var _splats : Vector.<Texture2DBase>;
		private var _tileData : Vector.<Number>;
		private var _numSplattingLayers : uint;
		private var _tileRegisterIndex : int;
		private var _splatTextureIndex : int;
		private var _blendingTextureIndex : int;

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

			_tileData = new Vector.<Number>(4, true);
			_tileData[0] = tileData ? tileData[0] : 1;
			for (var i : int = 1; i < 4; ++i) {
				_tileData[i] = tileData ? tileData[i] : 50;
			}
			_blendingTexture = blendingTexture;
			_numSplattingLayers = _splats.length;
			if (_numSplattingLayers > 3) throw new Error("More than 3 splatting layers is not supported!");
		}

		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = "";
			var albedo : ShaderRegisterElement;
			var scaleRegister : ShaderRegisterElement;

			// incorporate input from ambient
			if (_numLights > 0) {
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

			var uv : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(uv, 1);

			scaleRegister = regCache.getFreeFragmentConstant();

			code += "mul " + uv + ", " + _uvFragmentReg + ", " + scaleRegister + ".x\n" +
					getSplatSampleCode(albedo, _diffuseInputRegister, uv);


			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var blendTexReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			_blendingTextureIndex = blendTexReg.index;
			code += getTexSampleCode(temp, blendTexReg);
			var splatTexReg : ShaderRegisterElement;

			_tileRegisterIndex = scaleRegister.index;
			var comps : Array = [ ".x",".y",".z",".w" ];

			for (var i : int = 0; i < _numSplattingLayers; ++i) {
				splatTexReg = regCache.getFreeTextureReg();
				if (i == 0) _splatTextureIndex = splatTexReg.index;
				code += "mul " + uv + ", " + _uvFragmentReg + ", " + scaleRegister + comps[i+1] + "\n" +
						getSplatSampleCode(uv, splatTexReg, uv) +
						"sub " + uv + ", " + uv + ", " + albedo + "\n" +
						"mul " + uv + ", " + uv + ", " + temp + comps[i] + "\n" +
						"add " + albedo + ", " + albedo + ", " + uv + "\n";
			}
			regCache.removeFragmentTempUsage(uv);

			_diffuseInputIndex = _diffuseInputRegister.index;

			if (_numLights == 0)
				return code;

			code += "mul " + targetReg + ".xyz, " + albedo + ".xyz, " + targetReg + ".xyz\n" +
					"mov " + targetReg + ".w, " + albedo + ".w\n";

			regCache.removeFragmentTempUsage(albedo);

			return code;
		}

		arcane override function activate(stage3DProxy : Stage3DProxy) : void
		{
			super.activate(stage3DProxy);
			stage3DProxy.setTextureAt(_blendingTextureIndex, _blendingTexture.getTextureForStage3D(stage3DProxy));

			for (var i : int = 0; i < _numSplattingLayers; ++i)
				stage3DProxy.setTextureAt(i + _splatTextureIndex, _splats[i].getTextureForStage3D(stage3DProxy));

			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _tileRegisterIndex, _tileData, 1);
		}

		override public function set alphaThreshold(value : Number) : void
		{
			if (value > 0)
				throw new Error("Alpha threshold not supported for TerrainDiffuseMethod");
		}

		protected function getSplatSampleCode(targetReg : ShaderRegisterElement, inputReg : ShaderRegisterElement, uvReg : ShaderRegisterElement = null) : String
		{
			// TODO: not used
			// var wrap : String = "wrap";
			var filter : String;

			if (_smooth) filter = _mipmap ? "linear,miplinear" : "linear";
			else filter = _mipmap ? "nearest,mipnearest" : "nearest";

			uvReg ||= _uvFragmentReg;
			return "tex " + targetReg + ", " + uvReg + ", " + inputReg + " <2d," + filter + ",wrap>\n";
		}
	}
}
