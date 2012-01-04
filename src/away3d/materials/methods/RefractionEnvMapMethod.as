package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.CubeTextureBase;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class RefractionEnvMapMethod extends ShadingMethodBase
	{
		private var _cubeMapIndex : int;
		private var _data : Vector.<Number>;
		private var _dataIndex : int;
		private var _envMap : CubeTextureBase;

		private var _dispersionR : Number = 0;
		private var _dispersionG : Number = 0;
		private var _dispersionB : Number = 0;
		private var _useDispersion : Boolean;

		// example values for dispersion: dispersionR : Number = -0.03, dispersionG : Number = -0.01, dispersionB : Number = .0015
		public function RefractionEnvMapMethod(envMap : CubeTextureBase, refractionIndex : Number = .9, dispersionR : Number = 0, dispersionG : Number = 0, dispersionB : Number = 0)
		{
			super(true, true, false);
			_envMap = envMap;
			_data = new Vector.<Number>(8, true);
			_dispersionR = dispersionR;
			_dispersionG = dispersionG;
			_dispersionB = dispersionB;
			_useDispersion = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
			this.refractionIndex = refractionIndex;
			_data[4] = 1;
			_data[5] = 0;
			_data[6] = 1;
			_data[7] = 1;
		}

		public function get refractionIndex() : Number
		{
			return _data[3];
		}

		public function set refractionIndex(value : Number) : void
		{
			_data[0] = _dispersionR+value;
			_data[1] = _dispersionG+value;
			_data[2] = _dispersionB+value;
			_data[3] = value;
		}

		public function get dispersionR() : Number
		{
			return _dispersionR;
		}

		public function set dispersionR(value : Number) : void
		{
			_dispersionR = value;
			_data[0] = value+_data[3];

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
			_data[1] = value+_data[3];

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
			_data[2] = value+_data[3];

			var useDispersion : Boolean = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
			if (_useDispersion != useDispersion) {
				invalidateShaderProgram();
				_useDispersion = useDispersion;
			}
		}

		arcane override function reset() : void
		{
			super.reset();
			_dataIndex = -1;
			_cubeMapIndex = -1;
		}

		public function get alpha() : Number
		{
			return _data[6];
		}

		public function set alpha(value : Number) : void
		{
			_data[6] = value;
		}

		arcane override function activate(stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _dataIndex, _data, 2);
			stage3DProxy.setTextureAt(_cubeMapIndex, _envMap.getTextureForStage3D(stage3DProxy));
		}

		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var data : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var data2 : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var code : String = "";
			var cubeMapReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			var refractionDir : ShaderRegisterElement;
			var refractionColor : ShaderRegisterElement;
			var temp : ShaderRegisterElement;

			_cubeMapIndex = cubeMapReg.index;
			_dataIndex = data.index;

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

			code +=	"tex " + refractionColor + ", " + refractionDir + ", " + cubeMapReg + " <cube, " + (_smooth? "linear" : "nearest") + ",miplinear,clamp>\n";

			if (_dispersionR != _dispersionG || _dispersionR == _dispersionB) {
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
				code +=	"tex " + temp + ", " + refractionDir + ", " + cubeMapReg + " <cube, " + (_smooth? "linear" : "nearest") + ",miplinear,clamp>\n" +
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

				code +=	"tex " + temp + ", " + refractionDir + ", " + cubeMapReg + " <cube, " + (_smooth? "linear" : "nearest") + ",miplinear,clamp>\n" +
						"mov " + refractionColor + ".z, " + temp + ".z\n";
			}

			regCache.removeFragmentTempUsage(refractionDir);

			code += "sub " + refractionColor + ".xyz, " + refractionColor + ".xyz, " + targetReg + ".xyz\n" +
					"mul " + refractionColor + ".xyz, " + refractionColor + ".xyz, " + data2 + ".z\n" +
					"add " + targetReg + ".xyz, " + targetReg+".xyz, " + refractionColor + ".xyz\n";
			regCache.removeFragmentTempUsage(refractionColor);

			// restore
			code += "neg " + _viewDirFragmentReg + ".xyz, " + _viewDirFragmentReg + ".xyz\n";

			return code;
		}
	}
}
