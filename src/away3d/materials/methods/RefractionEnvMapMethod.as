package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.CubeTextureBase;
	
	use namespace arcane;

	/**
	 * RefractionEnvMapMethod provides a method to add refracted transparency based on cube maps.
	 */
	public class RefractionEnvMapMethod extends EffectMethodBase
	{
		private var _envMap:CubeTextureBase;
		
		private var _dispersionR:Number = 0;
		private var _dispersionG:Number = 0;
		private var _dispersionB:Number = 0;
		private var _useDispersion:Boolean;
		private var _refractionIndex:Number;
		private var _alpha:Number = 1;

		/**
		 * Creates a new RefractionEnvMapMethod object. Example values for dispersion are: dispersionR: -0.03, dispersionG: -0.01, dispersionB: = .0015
		 * @param envMap The environment map containing the refracted scene.
		 * @param refractionIndex The refractive index of the material.
		 * @param dispersionR The amount of chromatic dispersion of the red channel. Defaults to 0 (none).
		 * @param dispersionG The amount of chromatic dispersion of the green channel. Defaults to 0 (none).
		 * @param dispersionB The amount of chromatic dispersion of the blue channel. Defaults to 0 (none).
		 */
		public function RefractionEnvMapMethod(envMap:CubeTextureBase, refractionIndex:Number = .1, dispersionR:Number = 0, dispersionG:Number = 0, dispersionB:Number = 0)
		{
			super();
			_envMap = envMap;
			_dispersionR = dispersionR;
			_dispersionG = dispersionG;
			_dispersionB = dispersionB;
			_useDispersion = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
			_refractionIndex = refractionIndex;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initConstants(vo:MethodVO):void
		{
			var index:int = vo.fragmentConstantsIndex;
			var data:Vector.<Number> = vo.fragmentData;
			data[index + 4] = 1;
			data[index + 5] = 0;
			data[index + 7] = 1;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(vo:MethodVO):void
		{
			vo.needsNormals = true;
			vo.needsView = true;
		}
		
		/**
		 * The cube environment map to use for the refraction.
		 */
		public function get envMap():CubeTextureBase
		{
			return _envMap;
		}
		
		public function set envMap(value:CubeTextureBase):void
		{
			_envMap = value;
		}

		/**
		 * The refractive index of the material.
		 */
		public function get refractionIndex():Number
		{
			return _refractionIndex;
		}
		
		public function set refractionIndex(value:Number):void
		{
			_refractionIndex = value;
		}

		/**
		 * The amount of chromatic dispersion of the red channel. Defaults to 0 (none).
		 */
		public function get dispersionR():Number
		{
			return _dispersionR;
		}
		
		public function set dispersionR(value:Number):void
		{
			_dispersionR = value;
			
			var useDispersion:Boolean = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
			if (_useDispersion != useDispersion) {
				invalidateShaderProgram();
				_useDispersion = useDispersion;
			}
		}

		/**
		 * The amount of chromatic dispersion of the green channel. Defaults to 0 (none).
		 */
		public function get dispersionG():Number
		{
			return _dispersionG;
		}
		
		public function set dispersionG(value:Number):void
		{
			_dispersionG = value;
			
			var useDispersion:Boolean = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
			if (_useDispersion != useDispersion) {
				invalidateShaderProgram();
				_useDispersion = useDispersion;
			}
		}

		/**
		 * The amount of chromatic dispersion of the blue channel. Defaults to 0 (none).
		 */
		public function get dispersionB():Number
		{
			return _dispersionB;
		}
		
		public function set dispersionB(value:Number):void
		{
			_dispersionB = value;
			
			var useDispersion:Boolean = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
			if (_useDispersion != useDispersion) {
				invalidateShaderProgram();
				_useDispersion = useDispersion;
			}
		}

		/**
		 * The amount of transparency of the object. Warning: the alpha applies to the refracted color, not the actual
		 * material. A value of 1 will make it appear fully transparent.
		 */
		public function get alpha():Number
		{
			return _alpha;
		}
		
		public function set alpha(value:Number):void
		{
			_alpha = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			var index:int = vo.fragmentConstantsIndex;
			var data:Vector.<Number> = vo.fragmentData;
			data[index] = _dispersionR + _refractionIndex;
			if (_useDispersion) {
				data[index + 1] = _dispersionG + _refractionIndex;
				data[index + 2] = _dispersionB + _refractionIndex;
			}
			data[index + 3] = _alpha;
			stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _envMap.getTextureForStage3D(stage3DProxy));
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			// todo: data2.x could use common reg, so only 1 reg is used
			var data:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var data2:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var code:String = "";
			var cubeMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
			var refractionDir:ShaderRegisterElement;
			var refractionColor:ShaderRegisterElement;
			var temp:ShaderRegisterElement;
			
			vo.texturesIndex = cubeMapReg.index;
			vo.fragmentConstantsIndex = data.index*4;
			
			refractionDir = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(refractionDir, 1);
			refractionColor = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(refractionColor, 1);
			
			temp = regCache.getFreeFragmentVectorTemp();
			
			var viewDirReg:ShaderRegisterElement = _sharedRegisters.viewDirFragment;
			var normalReg:ShaderRegisterElement = _sharedRegisters.normalFragment;
			
			code += "neg " + viewDirReg + ".xyz, " + viewDirReg + ".xyz\n";
			
			code += "dp3 " + temp + ".x, " + viewDirReg + ".xyz, " + normalReg + ".xyz\n" +
				"mul " + temp + ".w, " + temp + ".x, " + temp + ".x\n" +
				"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
				"mul " + temp + ".w, " + data + ".x, " + temp + ".w\n" +
				"mul " + temp + ".w, " + data + ".x, " + temp + ".w\n" +
				"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
				"sqt " + temp + ".y, " + temp + ".w\n" +
				
				"mul " + temp + ".x, " + data + ".x, " + temp + ".x\n" +
				"add " + temp + ".x, " + temp + ".x, " + temp + ".y\n" +
				"mul " + temp + ".xyz, " + temp + ".x, " + normalReg + ".xyz\n" +
				
				"mul " + refractionDir + ", " + data + ".x, " + viewDirReg + "\n" +
				"sub " + refractionDir + ".xyz, " + refractionDir + ".xyz, " + temp + ".xyz\n" +
				"nrm " + refractionDir + ".xyz, " + refractionDir + ".xyz\n";
			
			code += getTexCubeSampleCode(vo, refractionColor, cubeMapReg, _envMap, refractionDir) +
				"sub " + refractionColor + ".w, " + refractionColor + ".w, fc0.x	\n" +
				"kil " + refractionColor + ".w\n";
			
			if (_useDispersion) {
				// GREEN
				
				code += "dp3 " + temp + ".x, " + viewDirReg + ".xyz, " + normalReg + ".xyz\n" +
					"mul " + temp + ".w, " + temp + ".x, " + temp + ".x\n" +
					"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
					"mul " + temp + ".w, " + data + ".y, " + temp + ".w\n" +
					"mul " + temp + ".w, " + data + ".y, " + temp + ".w\n" +
					"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
					"sqt " + temp + ".y, " + temp + ".w\n" +
					
					"mul " + temp + ".x, " + data + ".y, " + temp + ".x\n" +
					"add " + temp + ".x, " + temp + ".x, " + temp + ".y\n" +
					"mul " + temp + ".xyz, " + temp + ".x, " + normalReg + ".xyz\n" +
					
					"mul " + refractionDir + ", " + data + ".y, " + viewDirReg + "\n" +
					"sub " + refractionDir + ".xyz, " + refractionDir + ".xyz, " + temp + ".xyz\n" +
					"nrm " + refractionDir + ".xyz, " + refractionDir + ".xyz\n";
				//
				code += getTexCubeSampleCode(vo, temp, cubeMapReg, _envMap, refractionDir) +
					"mov " + refractionColor + ".y, " + temp + ".y\n";
				
				// BLUE
				
				code += "dp3 " + temp + ".x, " + viewDirReg + ".xyz, " + normalReg + ".xyz\n" +
					"mul " + temp + ".w, " + temp + ".x, " + temp + ".x\n" +
					"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
					"mul " + temp + ".w, " + data + ".z, " + temp + ".w\n" +
					"mul " + temp + ".w, " + data + ".z, " + temp + ".w\n" +
					"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
					"sqt " + temp + ".y, " + temp + ".w\n" +
					
					"mul " + temp + ".x, " + data + ".z, " + temp + ".x\n" +
					"add " + temp + ".x, " + temp + ".x, " + temp + ".y\n" +
					"mul " + temp + ".xyz, " + temp + ".x, " + normalReg + ".xyz\n" +
					
					"mul " + refractionDir + ", " + data + ".z, " + viewDirReg + "\n" +
					"sub " + refractionDir + ".xyz, " + refractionDir + ".xyz, " + temp + ".xyz\n" +
					"nrm " + refractionDir + ".xyz, " + refractionDir + ".xyz\n";
				
				code += getTexCubeSampleCode(vo, temp, cubeMapReg, _envMap, refractionDir) +
					"mov " + refractionColor + ".z, " + temp + ".z\n";
			}
			
			regCache.removeFragmentTempUsage(refractionDir);
			
			code += "sub " + refractionColor + ".xyz, " + refractionColor + ".xyz, " + targetReg + ".xyz\n" +
				"mul " + refractionColor + ".xyz, " + refractionColor + ".xyz, " + data + ".w\n" +
				"add " + targetReg + ".xyz, " + targetReg + ".xyz, " + refractionColor + ".xyz\n";
			regCache.removeFragmentTempUsage(refractionColor);
			
			// restore
			code += "neg " + viewDirReg + ".xyz, " + viewDirReg + ".xyz\n";
			
			return code;
		}
	}
}
