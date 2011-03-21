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
	 * BasicDiffuseMethod provides the default shading method for Lambert (dot3) diffuse lighting.
	 */
	public class BasicDiffuseMethod extends LightingMethodBase
	{
		protected var _useTexture : Boolean;
		internal var _totalLightColorReg : ShaderRegisterElement;

		protected var _diffuseInputRegister : ShaderRegisterElement;
		protected var _diffuseInputIndex : int;
        private var _cutOffIndex : int;

		private var _texture : Texture3DProxy;
		private var _mipmapBitmap : BitmapData;
		private var _diffuseColor : uint = 0xffffff;

		private var _diffuseData : Vector.<Number>;
		private var _cutOffData : Vector.<Number>;

		private var _diffuseR : Number, _diffuseG : Number = 0, _diffuseB : Number = 0, _diffuseA : Number;
		protected var _shadowRegister : ShaderRegisterElement;

        private var _alphaThreshold : Number = 0;

		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function BasicDiffuseMethod()
		{
			super(true, false, false);
			_diffuseData = Vector.<Number>([1, 1, 1, 1]);
			_cutOffData = new Vector.<Number>(4, true);
		}

		/**
		 * The alpha component of the diffuse reflection.
		 */
		public function get diffuseAlpha() : Number
		{
			return _diffuseA;
		}

		public function set diffuseAlpha(value : Number) : void
		{
			_diffuseData[3] = _diffuseA = value;
		}

		/**
		 * The color of the diffuse reflection when not using a texture.
		 */
		public function get diffuseColor() : uint
		{
			return _diffuseColor;
		}

		public function set diffuseColor(diffuseColor : uint) : void
		{
			_diffuseColor = diffuseColor;
			updateDiffuse();
		}

		/**
		 * The bitmapData to use to define the diffuse reflection color per texel.
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

        // todo: provide support for alpha map?
        public function get alphaThreshold() : Number
        {
            return _alphaThreshold;
        }

        public function set alphaThreshold(value : Number) : void
        {
            if (value < 0) value = 0;
            else if (value > 1) value = 1;
            if (value == _alphaThreshold) return;

            if (value == 0 || _alphaThreshold == 0)
                invalidateShaderProgram();

            _alphaThreshold = value;
            _cutOffData[0] = _alphaThreshold;
        }

        /**
		 * Marks the texture for update next on the next render.
		 */
		public function invalidateBitmapData() : void
		{
			_texture.invalidateContent();
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
		 * Copies the state from a BasicDiffuseMethod object into the current object.
		 */
		override public function copyFrom(method : ShadingMethodBase) : void
		{
			var diff : BasicDiffuseMethod = BasicDiffuseMethod(method);
			smooth = diff.smooth;
			repeat = diff.repeat;
			mipmap = diff.mipmap;
			numLights = diff.numLights;
			bitmapData = diff.bitmapData;
			diffuseAlpha = diff.diffuseAlpha;
			diffuseColor = diff.diffuseColor;
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
		override arcane function get needsUV() : Boolean
		{
			return _useTexture;
		}

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
			else {
				t = _totalLightColorReg;
			}

			code += AGAL.dp3(t+".x", lightDirReg+".xyz", _normalFragmentReg+".xyz");
			code += AGAL.sat(t+".w", t+".x");
			// attenuation
			code += AGAL.mul(t+".w", t+".w", lightDirReg+".w");

			if (_modulateMethod != null) code += _modulateMethod(t, regCache);

			code += AGAL.mul(t.toString(), t+".w", lightColReg.toString());


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
			var temp : ShaderRegisterElement;
			var cutOffReg : ShaderRegisterElement;

			// incorporate input from ambient
			if (_numLights > 0) {
				if (_shadowRegister)
					code += AGAL.mul(_totalLightColorReg+".xyz", _totalLightColorReg+".xyz", _shadowRegister+".w");
				code += AGAL.add(targetReg+".xyz", _totalLightColorReg+".xyz", targetReg+".xyz");
				code += AGAL.sat(targetReg+".xyz", targetReg+".xyz");
				regCache.removeFragmentTempUsage(_totalLightColorReg);
			}

			temp = _numLights > 0? regCache.getFreeFragmentVectorTemp() : targetReg;

            if (_useTexture) {
				_diffuseInputRegister = regCache.getFreeTextureReg();
				code += getTexSampleCode(temp, _diffuseInputRegister);
                if (_alphaThreshold > 0) {
                    cutOffReg = regCache.getFreeFragmentConstant();
                    _cutOffIndex = cutOffReg.index;
                    code += AGAL.sub(temp+".w", temp+".w", cutOffReg+".x");
                    code += AGAL.kill(temp+".w");
                    code += AGAL.add(temp+".w", temp+".w", cutOffReg+".x");
                    code += AGAL.div(temp.toString(), temp.toString(), temp+".w");
                }
			}
			else {
				_diffuseInputRegister = regCache.getFreeFragmentConstant();
				code += AGAL.mov(temp.toString(), _diffuseInputRegister.toString());
			}

            _diffuseInputIndex = _diffuseInputRegister.index;

			if (_numLights == 0)
				return code;


			code += AGAL.mul(targetReg+".xyz", temp+".xyz", targetReg+".xyz");
			code += AGAL.mov(targetReg+".w", temp+".w");

			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(context : Context3D, contextIndex : uint) : void
		{
			if (_useTexture) {
				context.setTextureAt(_diffuseInputIndex, _texture.getTextureForContext(context, contextIndex));
                if (_alphaThreshold > 0) {
                    context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _cutOffIndex, _cutOffData, 1);
                }
			}
			else context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _diffuseInputIndex, _diffuseData, 1);
		}


		arcane override function deactivate(context : Context3D) : void
		{
			if (_useTexture) context.setTextureAt(_diffuseInputIndex, null);
		}

		/**
		 * Updates the diffuse color data used by the render state.
		 */
		private function updateDiffuse() : void
		{
			_diffuseData[uint(0)] = _diffuseR = ((_diffuseColor >> 16) & 0xff)/0xff;
			_diffuseData[uint(1)] = _diffuseG = ((_diffuseColor >> 8) & 0xff)/0xff;
			_diffuseData[uint(2)] = _diffuseB = (_diffuseColor & 0xff)/0xff;
		}

		public function set shadowRegister(shadowReg : ShaderRegisterElement) : void
		{
			_shadowRegister = shadowReg;
		}
	}
}
