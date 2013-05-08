package away3d.materials.methods {
	import away3d.*;
	import away3d.core.managers.*;
	import away3d.materials.compilation.*;
	import away3d.textures.*;

	use namespace arcane;

	/**
	 * BasicSpecularMethod provides the default shading method for Blinn-Phong specular highlights.
	 */
	public class BasicSpecularMethod extends LightingMethodBase
	{
		protected var _useTexture : Boolean;
		protected var _totalLightColorReg : ShaderRegisterElement;
		protected var _specularTextureRegister : ShaderRegisterElement;
		protected var _specularTexData : ShaderRegisterElement;
		protected var _specularDataRegister : ShaderRegisterElement;

		private var _texture : Texture2DBase;

		private var _gloss : int = 50;
		private var _specular : Number = 1;
		private var _specularColor : uint = 0xffffff;
		arcane var _specularR : Number = 1, _specularG : Number = 1, _specularB : Number = 1;
		private var _shadowRegister : ShaderRegisterElement;
		protected var _isFirstLight : Boolean;

		
		/**
		 * Creates a new BasicSpecularMethod object.
		 */
		public function BasicSpecularMethod()
		{
			super();
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsUV = _useTexture;
			vo.needsNormals = vo.numLights > 0;
			vo.needsView = vo.numLights > 0;
		}

		/**
		 * The sharpness of the specular highlight.
		 */
		public function get gloss() : Number
		{
			return _gloss;
		}

		public function set gloss(value : Number) : void
		{
			_gloss = value;
		}

		/**
		 * The overall strength of the specular highlights.
		 */
		public function get specular() : Number
		{
			return _specular;
		}

		public function set specular(value : Number) : void
		{
			if (value == _specular) return;

			_specular = value;
			updateSpecular();
		}
		
		/**
		 * The colour of the specular reflection of the surface.
		 */
		public function get specularColor() : uint
		{
			return _specularColor;
		}

		public function set specularColor(value : uint) : void
		{
			if (_specularColor == value) return;

			// specular is now either enabled or disabled
			if (_specularColor == 0 || value == 0) invalidateShaderProgram();
			_specularColor = value;
			updateSpecular();
		}

		/**
		 * The bitmapData that encodes the specular highlight strength per texel in the red channel, and the sharpness
		 * in the green channel. You can use SpecularBitmapTexture if you want to easily set specular and gloss maps
		 * from greyscale images, but prepared images are preffered.
		 */
		public function get texture() : Texture2DBase
		{
			return _texture;
		}

		public function set texture(value : Texture2DBase) : void
		{
			if (Boolean(value) != _useTexture ||
				(value && _texture && (value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format)))
				invalidateShaderProgram();
			_useTexture = Boolean(value);
			_texture = value;
		}

		/**
		 * Copies the state from a BasicSpecularMethod object into the current object.
		 */
		override public function copyFrom(method : ShadingMethodBase) : void
		{
			var spec : BasicSpecularMethod = BasicSpecularMethod(method);
			texture = spec.texture;
			specular = spec.specular;
			specularColor = spec.specularColor;
			gloss = spec.gloss;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_shadowRegister = null;
			_totalLightColorReg = null;
			_specularTextureRegister = null;
			_specularTexData = null;
			_specularDataRegister = null;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPreLightingCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			var code : String = "";

			_isFirstLight = true;

			if (vo.numLights > 0) {
				_specularDataRegister = regCache.getFreeFragmentConstant();
				vo.fragmentConstantsIndex = _specularDataRegister.index*4;

				if (_useTexture) {
					_specularTexData = regCache.getFreeFragmentVectorTemp();
					regCache.addFragmentTempUsages(_specularTexData, 1);
					_specularTextureRegister = regCache.getFreeTextureReg();
					vo.texturesIndex = _specularTextureRegister.index;
					code = getTex2DSampleCode(vo, _specularTexData, _specularTextureRegister, _texture);
				}
				else
					_specularTextureRegister = null;

				_totalLightColorReg = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(_totalLightColorReg, 1);
			}

			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentCodePerLight(vo : MethodVO, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			var code : String = "";
			var t : ShaderRegisterElement;

			if (_isFirstLight)
				t = _totalLightColorReg;
			else {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}

			var viewDirReg : ShaderRegisterElement = _sharedRegisters.viewDirFragment;
			var normalReg : ShaderRegisterElement  = _sharedRegisters.normalFragment;
			
			// blinn-phong half vector model
			code += "add " + t + ", " + lightDirReg + ", " + viewDirReg + "\n" +
					"nrm " + t + ".xyz, " + t + "\n" +
					"dp3 " + t + ".w, " + normalReg + ", " + t + "\n" +
					"sat " + t + ".w, " + t + ".w\n";
			
			
			if (_useTexture) {
				// apply gloss modulation from texture
				code += "mul " + _specularTexData + ".w, " + _specularTexData + ".y, " + _specularDataRegister + ".w\n" +
						"pow " + t + ".w, " + t + ".w, " + _specularTexData + ".w\n";
			}
			else
				code += "pow " + t + ".w, " + t + ".w, " + _specularDataRegister + ".w\n";

			// attenuate
			if (vo.useLightFallOff)
				code += "mul " + t + ".w, " + t + ".w, " + lightDirReg + ".w\n";

			if (_modulateMethod != null) code += _modulateMethod(vo, t, regCache, _sharedRegisters);

			code += "mul " + t + ".xyz, " + lightColReg + ", " + t + ".w\n";

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
		arcane override function getFragmentCodePerProbe(vo : MethodVO, cubeMapReg : ShaderRegisterElement, weightRegister : String, regCache : ShaderRegisterCache) : String
		{
			var code : String = "";
			var t : ShaderRegisterElement;

			// write in temporary if not first light, so we can add to total diffuse colour
			if (_isFirstLight)
				t = _totalLightColorReg;
			else {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}

			var normalReg : ShaderRegisterElement = _sharedRegisters.normalFragment;
			var viewDirReg : ShaderRegisterElement = _sharedRegisters.viewDirFragment;
			code += "dp3 " + t + ".w, " + normalReg + ", " + viewDirReg + "\n" +
					"add " + t + ".w, " + t + ".w, " + t + ".w\n" +
					"mul " + t + ", " + t + ".w, " + normalReg + "\n" +
					"sub " + t + ", " + t + ", " + viewDirReg + "\n" +
					"tex " + t + ", " + t + ", " + cubeMapReg + " <cube," + (vo.useSmoothTextures? "linear" : "nearest") + ",miplinear>\n" +
					"mul " + t + ".xyz, " + t + ", " + weightRegister + "\n";

			if (_modulateMethod != null) code += _modulateMethod(vo, t, regCache, _sharedRegisters);

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
		override arcane function getFragmentPostLightingCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = "";

			if (vo.numLights == 0)
				return code;

			if (_shadowRegister)
				code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + _shadowRegister + ".w\n";

			if (_useTexture) {
				// apply strength modulation from texture
				code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + _specularTexData + ".x\n";
				regCache.removeFragmentTempUsage(_specularTexData);
			}

			// apply material's specular reflection
			code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + _specularDataRegister + "\n" +
					"add " + targetReg + ".xyz, " + targetReg + ", " + _totalLightColorReg + "\n";
			regCache.removeFragmentTempUsage(_totalLightColorReg);

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			//var context : Context3D = stage3DProxy._context3D;

			if (vo.numLights == 0) return;

			if (_useTexture) stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
			var index : int = vo.fragmentConstantsIndex;
			var data : Vector.<Number> = vo.fragmentData;
			data[index] = _specularR;
			data[index+1] = _specularG;
			data[index+2] = _specularB;
			data[index+3] = _gloss;
		}

		/**
		 * Updates the specular color data used by the render state.
		 */
		private function updateSpecular() : void
		{
			_specularR = ((_specularColor >> 16) & 0xff) / 0xff * _specular;
			_specularG = ((_specularColor >> 8) & 0xff) / 0xff * _specular;
			_specularB = (_specularColor & 0xff) / 0xff * _specular;
		}

		arcane function set shadowRegister(shadowReg : ShaderRegisterElement) : void
		{
			_shadowRegister = shadowReg;
		}
	}
}
