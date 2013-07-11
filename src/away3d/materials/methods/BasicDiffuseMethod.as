package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	
	use namespace arcane;
	
	/**
	 * BasicDiffuseMethod provides the default shading method for Lambert (dot3) diffuse lighting.
	 */
	public class BasicDiffuseMethod extends LightingMethodBase
	{
		private var _useAmbientTexture:Boolean;
		
		protected var _useTexture:Boolean;
		internal var _totalLightColorReg:ShaderRegisterElement;
		
		// TODO: are these registers at all necessary to be members?
		protected var _diffuseInputRegister:ShaderRegisterElement;
		
		private var _texture:Texture2DBase;
		private var _diffuseColor:uint = 0xffffff;
		private var _diffuseR:Number = 1, _diffuseG:Number = 1, _diffuseB:Number = 1, _diffuseA:Number = 1;
		protected var _shadowRegister:ShaderRegisterElement;
		
		protected var _alphaThreshold:Number = 0;
		protected var _isFirstLight:Boolean;
		
		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function BasicDiffuseMethod()
		{
			super();
		}

		/**
		 * Set internally if the ambient method uses a texture.
		 */
		arcane function get useAmbientTexture():Boolean
		{
			return _useAmbientTexture;
		}

		arcane function set useAmbientTexture(value:Boolean):void
		{
			if (_useAmbientTexture == value)
				return;

			_useAmbientTexture = value;

			invalidateShaderProgram();
		}
		
		override arcane function initVO(vo:MethodVO):void
		{
			vo.needsUV = _useTexture;
			vo.needsNormals = vo.numLights > 0;
		}

		/**
		 * Forces the creation of the texture.
		 * @param stage3DProxy The Stage3DProxy used by the renderer
		 */
		public function generateMip(stage3DProxy:Stage3DProxy):void
		{
			if (_useTexture)
				_texture.getTextureForStage3D(stage3DProxy);
		}

		/**
		 * The alpha component of the diffuse reflection.
		 */
		public function get diffuseAlpha():Number
		{
			return _diffuseA;
		}
		
		public function set diffuseAlpha(value:Number):void
		{
			_diffuseA = value;
		}
		
		/**
		 * The color of the diffuse reflection when not using a texture.
		 */
		public function get diffuseColor():uint
		{
			return _diffuseColor;
		}
		
		public function set diffuseColor(diffuseColor:uint):void
		{
			_diffuseColor = diffuseColor;
			updateDiffuse();
		}
		
		/**
		 * The bitmapData to use to define the diffuse reflection color per texel.
		 */
		public function get texture():Texture2DBase
		{
			return _texture;
		}
		
		public function set texture(value:Texture2DBase):void
		{
			if (Boolean(value) != _useTexture ||
				(value && _texture && (value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format))) {
				invalidateShaderProgram();
			}
			
			_useTexture = Boolean(value);
			_texture = value;
		}
		
		/**
		 * The minimum alpha value for which pixels should be drawn. This is used for transparency that is either
		 * invisible or entirely opaque, often used with textures for foliage, etc.
		 * Recommended values are 0 to disable alpha, or 0.5 to create smooth edges. Default value is 0 (disabled).
		 */
		public function get alphaThreshold():Number
		{
			return _alphaThreshold;
		}
		
		public function set alphaThreshold(value:Number):void
		{
			if (value < 0)
				value = 0;
			else if (value > 1)
				value = 1;
			if (value == _alphaThreshold)
				return;
			
			if (value == 0 || _alphaThreshold == 0)
				invalidateShaderProgram();
			
			_alphaThreshold = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			_texture = null;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function copyFrom(method:ShadingMethodBase):void
		{
			var diff:BasicDiffuseMethod = BasicDiffuseMethod(method);
			alphaThreshold = diff.alphaThreshold;
			texture = diff.texture;
			useAmbientTexture = diff.useAmbientTexture;
			diffuseAlpha = diff.diffuseAlpha;
			diffuseColor = diff.diffuseColor;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function cleanCompilationData():void
		{
			super.cleanCompilationData();
			_shadowRegister = null;
			_totalLightColorReg = null;
			_diffuseInputRegister = null;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			var code:String = "";
			
			_isFirstLight = true;
			
			if (vo.numLights > 0) {
				_totalLightColorReg = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(_totalLightColorReg, 1);
			}
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentCodePerLight(vo:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String
		{
			var code:String = "";
			var t:ShaderRegisterElement;
			
			// write in temporary if not first light, so we can add to total diffuse colour
			if (_isFirstLight)
				t = _totalLightColorReg;
			else {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}
			
			code += "dp3 " + t + ".x, " + lightDirReg + ", " + _sharedRegisters.normalFragment + "\n" +
				"max " + t + ".w, " + t + ".x, " + _sharedRegisters.commons + ".y\n";
			
			if (vo.useLightFallOff)
				code += "mul " + t + ".w, " + t + ".w, " + lightDirReg + ".w\n";
			
			if (_modulateMethod != null)
				code += _modulateMethod(vo, t, regCache, _sharedRegisters);
			
			code += "mul " + t + ", " + t + ".w, " + lightColReg + "\n";
			
			if (!_isFirstLight) {
				code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + t + "\n";
				regCache.removeFragmentTempUsage(t);
			}
			
			_isFirstLight = false;
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCodePerProbe(vo:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, regCache:ShaderRegisterCache):String
		{
			var code:String = "";
			var t:ShaderRegisterElement;
			
			// write in temporary if not first light, so we can add to total diffuse colour
			if (_isFirstLight)
				t = _totalLightColorReg;
			else {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}
			
			code += "tex " + t + ", " + _sharedRegisters.normalFragment + ", " + cubeMapReg + " <cube,linear,miplinear>\n" +
				"mul " + t + ".xyz, " + t + ".xyz, " + weightRegister + "\n";
			
			if (_modulateMethod != null)
				code += _modulateMethod(vo, t, regCache, _sharedRegisters);
			
			if (!_isFirstLight) {
				code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + t + "\n";
				regCache.removeFragmentTempUsage(t);
			}
			
			_isFirstLight = false;
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var code:String = "";
			var albedo:ShaderRegisterElement;
			var cutOffReg:ShaderRegisterElement;
			
			// incorporate input from ambient
			if (vo.numLights > 0) {
				if (_shadowRegister)
					code += applyShadow(vo, regCache);
				albedo = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(albedo, 1);
			} else
				albedo = targetReg;
			
			if (_useTexture) {
				_diffuseInputRegister = regCache.getFreeTextureReg();
				vo.texturesIndex = _diffuseInputRegister.index;
				code += getTex2DSampleCode(vo, albedo, _diffuseInputRegister, _texture);
				if (_alphaThreshold > 0) {
					cutOffReg = regCache.getFreeFragmentConstant();
					vo.fragmentConstantsIndex = cutOffReg.index*4;
					code += "sub " + albedo + ".w, " + albedo + ".w, " + cutOffReg + ".x\n" +
						"kil " + albedo + ".w\n" +
						"add " + albedo + ".w, " + albedo + ".w, " + cutOffReg + ".x\n";
				}
			} else {
				_diffuseInputRegister = regCache.getFreeFragmentConstant();
				vo.fragmentConstantsIndex = _diffuseInputRegister.index*4;
				code += "mov " + albedo + ", " + _diffuseInputRegister + "\n";
			}
			
			if (vo.numLights == 0)
				return code;
			
			code += "sat " + _totalLightColorReg + ", " + _totalLightColorReg + "\n";
			
			if (_useAmbientTexture) {
				code += "mul " + albedo + ".xyz, " + albedo + ", " + _totalLightColorReg + "\n" +
					"mul " + _totalLightColorReg + ".xyz, " + targetReg + ", " + _totalLightColorReg + "\n" +
					"sub " + targetReg + ".xyz, " + targetReg + ", " + _totalLightColorReg + "\n" +
					"add " + targetReg + ".xyz, " + albedo + ", " + targetReg + "\n";
			} else {
				code += "add " + targetReg + ".xyz, " + _totalLightColorReg + ", " + targetReg + "\n";
				if (_useTexture) {
					code += "mul " + targetReg + ".xyz, " + albedo + ", " + targetReg + "\n" +
						"mov " + targetReg + ".w, " + albedo + ".w\n";
				} else {
					code += "mul " + targetReg + ".xyz, " + _diffuseInputRegister + ", " + targetReg + "\n" +
						"mov " + targetReg + ".w, " + _diffuseInputRegister + ".w\n";
				}
			}
			
			regCache.removeFragmentTempUsage(_totalLightColorReg);
			regCache.removeFragmentTempUsage(albedo);
			
			return code;
		}

		/**
		 * Generate the code that applies the calculated shadow to the diffuse light
		 * @param vo The MethodVO object for which the compilation is currently happening.
		 * @param regCache The register cache the compiler is currently using for the register management.
		 */
		protected function applyShadow(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			return "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + _shadowRegister + ".w\n";
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			if (_useTexture) {
				stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
				if (_alphaThreshold > 0)
					vo.fragmentData[vo.fragmentConstantsIndex] = _alphaThreshold;
			} else {
				var index:int = vo.fragmentConstantsIndex;
				var data:Vector.<Number> = vo.fragmentData;
				data[index] = _diffuseR;
				data[index + 1] = _diffuseG;
				data[index + 2] = _diffuseB;
				data[index + 3] = _diffuseA;
			}
		}
		
		/**
		 * Updates the diffuse color data used by the render state.
		 */
		private function updateDiffuse():void
		{
			_diffuseR = ((_diffuseColor >> 16) & 0xff)/0xff;
			_diffuseG = ((_diffuseColor >> 8) & 0xff)/0xff;
			_diffuseB = (_diffuseColor & 0xff)/0xff;
		}

		/**
		 * Set internally by the compiler, so the method knows the register containing the shadow calculation.
		 */
		arcane function set shadowRegister(value:ShaderRegisterElement):void
		{
			_shadowRegister = value;
		}
	}
}
