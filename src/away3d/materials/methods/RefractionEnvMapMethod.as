package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.CubeTextureBase;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class RefractionEnvMapMethod extends EffectMethodBase
	{
		private var _envMap : CubeTextureBase;

		private var _dispersionR : Number = 0;
		private var _dispersionG : Number = 0;
		private var _dispersionB : Number = 0;
		private var _useDispersion : Boolean;
		private var _refractionIndex : Number;
		private var _alpha : Number = 1;

		// example values for dispersion: dispersionR : Number = -0.03, dispersionG : Number = -0.01, dispersionB : Number = .0015
		public function RefractionEnvMapMethod(envMap : CubeTextureBase, refractionIndex : Number = .9, dispersionR : Number = 0, dispersionG : Number = 0, dispersionB : Number = 0)
		{
			super();
			_envMap = envMap;
			_dispersionR = dispersionR;
			_dispersionG = dispersionG;
			_dispersionB = dispersionB;
			_useDispersion = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
			_refractionIndex = refractionIndex;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			var index : int = vo.fragmentConstantsIndex;
			var data : Vector.<Number> = vo.fragmentData;
			data[index+4] = 1;
			data[index+5] = 0;
			data[index+7] = 1;
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsNormals = true;
			vo.needsView = true;
		}

		public function get refractionIndex() : Number
		{
			return _refractionIndex;
		}

		public function set refractionIndex(value : Number) : void
		{
			_refractionIndex = value;
		}

		public function get dispersionR() : Number
		{
			return _dispersionR;
		}

		public function set dispersionR(value : Number) : void
		{
			_dispersionR = value;

			var useDispersion : Boolean = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
			if (_useDispersion != useDispersion) {
				invalidateShaderProgram();
				_useDispersion = useDispersion;
			}
		}

		public function get dispersionG() : Number
		{
			return _dispersionG;
		}

		public function set dispersionG(value : Number) : void
		{
			_dispersionG = value;

			var useDispersion : Boolean = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
			if (_useDispersion != useDispersion) {
				invalidateShaderProgram();
				_useDispersion = useDispersion;
			}
		}

		public function get dispersionB() : Number
		{
			return _dispersionB;
		}

		public function set dispersionB(value : Number) : void
		{
			_dispersionB = value;

			var useDispersion : Boolean = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
			if (_useDispersion != useDispersion) {
				invalidateShaderProgram();
				_useDispersion = useDispersion;
			}
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
			var index : int = vo.fragmentConstantsIndex;
			var data : Vector.<Number> = vo.fragmentData;
			data[index] = _dispersionR + _refractionIndex;
			if (_useDispersion) {
				data[index+1] = _dispersionG + _refractionIndex;
				data[index+2] = _dispersionB + _refractionIndex;
			}
			data[index+3] = _alpha;
			stage3DProxy.setTextureAt(vo.texturesIndex, _envMap.getTextureForStage3D(stage3DProxy));
		}

		arcane override function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			// todo: data2.x could use common reg, so only 1 reg is used
			var data : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var data2 : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var code : String = "";
			var cubeMapReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			var refractionDir : ShaderRegisterElement;
			var refractionColor : ShaderRegisterElement;
			var temp : ShaderRegisterElement;

			vo.texturesIndex = cubeMapReg.index;
			vo.fragmentConstantsIndex = data.index*4;

			refractionDir = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(refractionDir, 1);
			refractionColor = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(refractionColor, 1);

			temp = regCache.getFreeFragmentVectorTemp();

			code += "neg " + _viewDirFragmentReg + ".xyz, " + _viewDirFragmentReg + ".xyz\n";

			code +=	"dp3 " + temp + ".x, " + _viewDirFragmentReg + ".xyz, " + _normalFragmentReg + ".xyz\n" +
					"mul " + temp + ".w, " + temp + ".x, " + temp + ".x\n" +
					"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
					"mul " + temp + ".w, " + data + ".x, " + temp + ".w\n" +
					"mul " + temp + ".w, " + data + ".x, " + temp + ".w\n" +
					"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
					"sqt " + temp + ".y, " + temp + ".w\n" +

					"mul " + temp + ".x, " + data + ".x, " + temp + ".x\n" +
					"add " + temp + ".x, " + temp + ".x, " + temp + ".y\n" +
					"mul " + temp + ".xyz, " + temp + ".x, " + _normalFragmentReg + ".xyz\n" +

					"mul " + refractionDir + ", " + data + ".x, " + _viewDirFragmentReg + "\n" +
					"sub " + refractionDir + ".xyz, " + refractionDir+ ".xyz, " + temp+ ".xyz\n" +
					"nrm " + refractionDir + ".xyz, " + refractionDir+ ".xyz\n";

			code +=	"tex " + refractionColor + ", " + refractionDir + ", " + cubeMapReg + " <cube, " + (vo.useSmoothTextures? "linear" : "nearest") + ",miplinear,clamp>\n";

			if (_useDispersion) {
				// GREEN

				code +=	"dp3 " + temp + ".x, " + _viewDirFragmentReg + ".xyz, " + _normalFragmentReg + ".xyz\n" +
						"mul " + temp + ".w, " + temp + ".x, " + temp + ".x\n" +
						"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
						"mul " + temp + ".w, " + data + ".y, " + temp + ".w\n" +
						"mul " + temp + ".w, " + data + ".y, " + temp + ".w\n" +
						"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
						"sqt " + temp + ".y, " + temp + ".w\n" +

						"mul " + temp + ".x, " + data + ".y, " + temp + ".x\n" +
						"add " + temp + ".x, " + temp + ".x, " + temp + ".y\n" +
						"mul " + temp + ".xyz, " + temp + ".x, " + _normalFragmentReg + ".xyz\n" +

						"mul " + refractionDir + ", " + data + ".y, " + _viewDirFragmentReg + "\n" +
						"sub " + refractionDir + ".xyz, " + refractionDir+ ".xyz, " + temp+ ".xyz\n" +
						"nrm " + refractionDir + ".xyz, " + refractionDir+ ".xyz\n";
	//
				code +=	"tex " + temp + ", " + refractionDir + ", " + cubeMapReg + " <cube, " + (vo.useSmoothTextures? "linear" : "nearest") + ",miplinear,clamp>\n" +
						"mov " + refractionColor + ".y, " + temp + ".y\n";



				// BLUE

				code +=	"dp3 " + temp + ".x, " + _viewDirFragmentReg + ".xyz, " + _normalFragmentReg + ".xyz\n" +
						"mul " + temp + ".w, " + temp + ".x, " + temp + ".x\n" +
						"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
						"mul " + temp + ".w, " + data + ".z, " + temp + ".w\n" +
						"mul " + temp + ".w, " + data + ".z, " + temp + ".w\n" +
						"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
						"sqt " + temp + ".y, " + temp + ".w\n" +

						"mul " + temp + ".x, " + data + ".z, " + temp + ".x\n" +
						"add " + temp + ".x, " + temp + ".x, " + temp + ".y\n" +
						"mul " + temp + ".xyz, " + temp + ".x, " + _normalFragmentReg + ".xyz\n" +

						"mul " + refractionDir + ", " + data + ".z, " + _viewDirFragmentReg + "\n" +
						"sub " + refractionDir + ".xyz, " + refractionDir+ ".xyz, " + temp+ ".xyz\n" +
						"nrm " + refractionDir + ".xyz, " + refractionDir+ ".xyz\n";

				code +=	"tex " + temp + ", " + refractionDir + ", " + cubeMapReg + " <cube, " + (vo.useSmoothTextures? "linear" : "nearest") + ",miplinear,clamp>\n" +
						"mov " + refractionColor + ".z, " + temp + ".z\n";
			}

			regCache.removeFragmentTempUsage(refractionDir);

			code += "sub " + refractionColor + ".xyz, " + refractionColor + ".xyz, " + targetReg + ".xyz\n" +
					"mul " + refractionColor + ".xyz, " + refractionColor + ".xyz, " + data + ".w\n" +
					"add " + targetReg + ".xyz, " + targetReg+".xyz, " + refractionColor + ".xyz\n";
			regCache.removeFragmentTempUsage(refractionColor);

			// restore
			code += "neg " + _viewDirFragmentReg + ".xyz, " + _viewDirFragmentReg + ".xyz\n";

			return code;
		}
	}
}
