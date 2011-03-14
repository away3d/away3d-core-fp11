package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Texture3DProxy;
	import away3d.materials.utils.AGAL;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display.BitmapData;
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
		protected var _specularTexIndex : uint;
		protected var _specularDataRegister : ShaderRegisterElement;
		protected var _specularDataIndex : uint;

		protected var _mipmapBitmap : BitmapData;
		private var _texture : Texture3DProxy;

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
			super(true, false);
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

			// specular is now either disabled or enabled
			if (_specular == 0 || value == 0) invalidateShaderProgram();

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
		 * in the green channel.
		 */
		public function get bitmapData() : BitmapData
		{
			return _texture? _texture.bitmapData : null;
		}

		public function set bitmapData(value : BitmapData) : void
		{
			if (!value || !_useTexture)
				invalidateShaderProgram();

			_useTexture = Boolean(value);

			if (_useTexture) {
				_texture ||= new Texture3DProxy(_mipmapBitmap);
				_texture.bitmapData = value;
			}
			else {
				if (_texture) {
					_texture.dispose(false);
					_texture = null;
				}
			}
		}

		/**
		 * Marks the texture for update next on the next render.
		 */
		public function invalidateBitmapData() : void
		{
			_texture.invalidateContent();
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
			bitmapData = spec.bitmapData;
			specular = spec.specular;
			specularColor = spec.specularColor;
			gloss = spec.gloss;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose(deep : Boolean) : void
		{
			if (_texture) _texture.dispose(deep);
			if (_mipmapBitmap) _mipmapBitmap.dispose();
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set numLights(value : int) : void
		{
			_needsNormals = value > 0;
			super.numLights = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get needsView() : Boolean
		{
			return true;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get needsUV() : Boolean
		{
			return _useTexture;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function reset() : void
		{
			super.reset();
			_shadowRegister = null;
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
			else {
				_specularDataRegister = null;
				_specularTextureRegister = null;
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
			code += AGAL.add(t+".xyz", lightDirReg+".xyz", _viewDirFragmentReg+".xyz");
			code += AGAL.normalize(t+".xyz", t+".xyz");
            code += AGAL.dp3(t+".w", _normalFragmentReg+".xyz", t+".xyz");
			code += AGAL.sat(t+".w", t+".w");

			if (_useTexture) {
				code += AGAL.mul(_specularTexData+".w", _specularTexData+".y", _specularDataRegister+".w");
				code += AGAL.pow(t+".w", t+".w", _specularTexData+".w");
			}
			else
				code += AGAL.pow(t+".w", t+".w", _specularDataRegister+".w");

			// attenuate
			code += AGAL.mul(t+".w", t+".w", lightDirReg+".w");

			if (_modulateMethod != null) code += _modulateMethod(t, regCache);

			code += AGAL.mul(t+".xyz", lightColReg+".xyz", t+".w");

			if (lightIndex > 0) {
                code += AGAL.add(_totalLightColorReg+".xyz", _totalLightColorReg+".xyz", t+".xyz");
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

			if (_numLights == 0) {
				_specularTextureRegister = null;
				return "";
			}

			if (_shadowRegister)
				code += AGAL.mul(_totalLightColorReg+".xyz", _totalLightColorReg+".xyz", _shadowRegister+".w");

			if (_useTexture) {
				code += AGAL.mul(_totalLightColorReg+".xyz", _totalLightColorReg+".xyz", _specularTexData+".x");
				regCache.removeFragmentTempUsage(_specularTexData);
			}

			code += AGAL.mul(_totalLightColorReg+".xyz", _totalLightColorReg+".xyz", _specularDataRegister+".xyz");
			code += AGAL.add(targetReg+".xyz", targetReg+".xyz", _totalLightColorReg+".xyz");
			regCache.removeFragmentTempUsage(_totalLightColorReg);

			return code;
		}

		/**
		 * The register element containing the specular data.
		 *
		 * @private
		 */
		arcane function get specularDataRegister() : ShaderRegisterElement
		{
			return _specularDataRegister;
		}

		/**
		 * The register element containing the specular map data.
		 *
		 * @private
		 */
		arcane function get specularTextureRegister() : ShaderRegisterElement
		{
			return _specularTextureRegister;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(context : Context3D, contextIndex : uint) : void
		{
			super.activate(context, contextIndex);
			if (_numLights == 0) return;

			if (_useTexture) context.setTextureAt(_specularTexIndex, _texture.getTextureForContext(context, contextIndex));
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _specularDataIndex, _specularData, 1);
		}

		arcane override function deactivate(context : Context3D) : void
		{
			if (_useTexture) context.setTextureAt(_specularTexIndex, null);
		}

		/**
		 * Updates the specular color data used by the render state.
		 */
		private function updateSpecular() : void
		{
			_specularData[0] = _specularR = ((_specularColor >> 16) & 0xff)/0xff*_specular;
			_specularData[1] = _specularG = ((_specularColor >> 8) & 0xff)/0xff*_specular;
			_specularData[2] = _specularB = (_specularColor & 0xff)/0xff*_specular;
		}

		public function set shadowRegister(shadowReg : ShaderRegisterElement) : void
		{
			_shadowRegister = shadowReg;
		}
	}
}
