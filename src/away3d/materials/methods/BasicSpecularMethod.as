package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;

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
		protected var _specularTexIndex : int;
		protected var _specularDataRegister : ShaderRegisterElement;
		protected var _specularDataIndex : int;

		private var _texture : Texture2DBase;

		protected var _specularData : Vector.<Number>;
		private var _specular : Number = 1;
		private var _specularColor : uint = 0xffffff;
		arcane var _specularR : Number = 1, _specularG : Number = 1, _specularB : Number = 1;
		private var _shadowRegister : ShaderRegisterElement;

		/**
		 * Creates a new BasicSpecularMethod object.
		 */
		public function BasicSpecularMethod()
		{
			super(true, true, false);
			_specularData = Vector.<Number>([1, 1, 1, 50]);
		}

		/**
		 * The sharpness of the specular highlight.
		 */
		public function get gloss() : Number
		{
			return _specularData[uint(3)];
		}

		public function set gloss(value : Number) : void
		{
			_specularData[uint(3)] = value;
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
			if (!value || !_useTexture) invalidateShaderProgram();
			_useTexture = Boolean(value);
			_texture = value;
		}

		/**
		 * Copies the state from a BasicSpecularMethod object into the current object.
		 */
		override public function copyFrom(method : ShadingMethodBase) : void
		{
			var spec : BasicSpecularMethod = BasicSpecularMethod(method);
			smooth = spec.smooth;
			repeat = spec.repeat;
			mipmap = spec.mipmap;
			numLights = spec.numLights;
			texture = spec.texture;
			specular = spec.specular;
			specularColor = spec.specularColor;
			gloss = spec.gloss;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set numLights(value : int) : void
		{
			_needsNormals = value > 0;
			_needsView = value > 0;
			super.numLights = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get needsUV() : Boolean
		{
			return _useTexture;
		}


		arcane override function reset() : void
		{
			super.reset();

			_specularTexIndex = -1;
			_specularDataIndex = -1;
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
		override arcane function getFragmentAGALPreLightingCode(regCache : ShaderRegisterCache) : String
		{
			var code : String = "";

			if (_numLights > 0) {
				_specularDataRegister = regCache.getFreeFragmentConstant();
				_specularDataIndex = _specularDataRegister.index;

				if (_useTexture) {
					_specularTexData = regCache.getFreeFragmentVectorTemp();
					regCache.addFragmentTempUsages(_specularTexData, 1);
					_specularTextureRegister = regCache.getFreeTextureReg();
					_specularTexIndex = _specularTextureRegister.index;
					code = getTexSampleCode(_specularTexData, _specularTextureRegister);
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
		override arcane function getFragmentCodePerLight(lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			var code : String = "";
			var t : ShaderRegisterElement;

			if (lightIndex > 0) {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}
			else t = _totalLightColorReg;

			// half vector
			code += "add " + t + ".xyz, " + lightDirReg + ".xyz, " + _viewDirFragmentReg + ".xyz\n" +
					"nrm " + t + ".xyz, " + t + ".xyz\n" +
					"dp3 " + t + ".w, " + _normalFragmentReg + ".xyz, " + t + ".xyz\n" +
					"sat " + t + ".w, " + t + ".w\n";

			if (_useTexture) {
				// apply gloss modulation from texture
				code += "mul " + _specularTexData + ".w, " + _specularTexData + ".y, " + _specularDataRegister + ".w\n" +
						"pow " + t + ".w, " + t + ".w, " + _specularTexData + ".w\n";
			}
			else
				code += "pow " + t + ".w, " + t + ".w, " + _specularDataRegister + ".w\n";

			// attenuate
			code += "mul " + t + ".w, " + t + ".w, " + lightDirReg + ".w\n";

			if (_modulateMethod != null) code += _modulateMethod(t, regCache);

			code += "mul " + t + ".xyz, " + lightColReg + ".xyz, " + t + ".w\n";

			if (lightIndex > 0) {
				code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + t + ".xyz\n";
				regCache.removeFragmentTempUsage(t);
			}

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCodePerProbe(lightIndex : int, cubeMapReg : ShaderRegisterElement, weightRegister : String, regCache : ShaderRegisterCache) : String
		{
			var code : String = "";
			var t : ShaderRegisterElement;

			// todo: add property that defines the indexing mode of the probe map: through view vector or reflectance vector

			// write in temporary if not first light, so we can add to total diffuse colour
			if (lightIndex > 0) {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}
			else {
				t = _totalLightColorReg;
			}

			code += "tex " + t + ", " + _viewDirFragmentReg + ", " + cubeMapReg + " <cube,linear,miplinear>\n" +
					"mul " + t + ", " + t + ", " + weightRegister + "\n";

//			if (_modulateMethod != null) {
// 				code += _modulateMethod(t, regCache);
//			}
//			code += "mul " + t + ".xyz, " + t + ".xyz, " + t + ".w\n";

			if (lightIndex > 0) {
				code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + t + ".xyz\n";
				regCache.removeFragmentTempUsage(t);
			}

			return code;
		}


		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = "";

			if (_numLights == 0)
				return code;

			if (_shadowRegister)
				code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + _shadowRegister + ".w\n";

			if (_useTexture) {
				// apply strength modulation from texture
				code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + _specularTexData + ".x\n";
				regCache.removeFragmentTempUsage(_specularTexData);
			}

			// apply material's specular reflection
			code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + _specularDataRegister + ".xyz\n" +
					"add " + targetReg + ".xyz, " + targetReg + ".xyz, " + _totalLightColorReg + ".xyz\n";
			regCache.removeFragmentTempUsage(_totalLightColorReg);

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(stage3DProxy : Stage3DProxy) : void
		{
			var context : Context3D = stage3DProxy._context3D;

			if (_numLights == 0) return;

			if (_useTexture) stage3DProxy.setTextureAt(_specularTexIndex, _texture.getTextureForStage3D(stage3DProxy));
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _specularDataIndex, _specularData, 1);
		}

//		arcane override function deactivate(stage3DProxy : Stage3DProxy) : void
//		{
//			if (_useTexture) stage3DProxy.setTextureAt(_specularTexIndex, null);
//		}

		/**
		 * Updates the specular color data used by the render state.
		 */
		private function updateSpecular() : void
		{
			_specularData[0] = _specularR = ((_specularColor >> 16) & 0xff) / 0xff * _specular;
			_specularData[1] = _specularG = ((_specularColor >> 8) & 0xff) / 0xff * _specular;
			_specularData[2] = _specularB = (_specularColor & 0xff) / 0xff * _specular;
		}

		public function set shadowRegister(shadowReg : ShaderRegisterElement) : void
		{
			_shadowRegister = shadowReg;
		}
	}
}
