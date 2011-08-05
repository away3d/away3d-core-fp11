package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.BitmapDataTextureCache;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.managers.Texture3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
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

		private var _texture : Texture3DProxy;

		protected var _specularData : Vector.<Number>;
		private var _specular : Number = 1;
		private var _specularColor : uint = 0xffffff;
		arcane var _specularR : Number = 1, _specularG : Number = 1, _specularB : Number = 1;
		private var _shadowRegister : ShaderRegisterElement;

		private var _specularMap : BitmapData;
		private var _glossMap : BitmapData;
		private var _specularGlossMap : BitmapData;
		private var _specularGlossMapDirty : Boolean;


		/**
		 * Creates a new BasicSpecularMethod object.
		 */
		public function BasicSpecularMethod()
		{
			super(true, false, false);
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
		 * in the green channel. Alternatively, use the specularMap and glossMap properties if the maps are present in
		 * seperate BitmapData objects.
		 */
		public function get bitmapData() : BitmapData
		{
			return _texture? _texture.bitmapData : null;
		}

		public function set bitmapData(value : BitmapData) : void
		{
			if (value == bitmapData) return;

			if (!value || !_useTexture)
				invalidateShaderProgram();

			if (_useTexture) {
				BitmapDataTextureCache.getInstance().freeTexture(_texture);
				_texture = null;
			}

			_useTexture = Boolean(value);

			if (_useTexture)
				_texture = BitmapDataTextureCache.getInstance().getTexture(value);
		}

		/**
		 * A specular map that defines the strength of specular reflections for each texel.
		 */
		public function get specularMap() : BitmapData
		{
			return _specularMap;
		}

		public function set specularMap(value : BitmapData) : void
		{
			var newMap : BitmapData;

			if (_specularMap == value) return;

			_specularMap = value;

			newMap = _specularGlossMap;
			if (value)
				newMap ||= new BitmapData(_specularMap.width, _specularMap.height, false);
			else if (!_glossMap && newMap) {
				newMap.dispose();
				newMap = null;
			}

			_specularGlossMap = newMap;
			_specularGlossMapDirty = true;

			_needsUV = _useTexture = Boolean(_glossMap) || Boolean(_specularMap);
		}

		/**
		 * A specular map that defines the power of specular reflections for each texel.
		 */
		public function get glossMap() : BitmapData
		{
			return _specularMap;
		}

		public function set glossMap(value : BitmapData) : void
		{
			var newMap : BitmapData;

			if (_glossMap == value) return;

			_glossMap = value;

			newMap = _specularGlossMap;
			if (value)
				newMap ||= new BitmapData(_glossMap.width, _glossMap.height, false);
			else if (!_specularMap && newMap) {
				newMap.dispose();
				newMap = null;
			}

			_specularGlossMap = newMap;
			_specularGlossMapDirty = true;

			_needsUV = _useTexture = Boolean(_glossMap) || Boolean(_specularMap);
		}

		/**
		 * Marks the texture for update next on the next render.
		 */
		public function invalidateBitmapData() : void
		{
			if (_texture) _texture.invalidateContent();
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
			if (_useTexture) {
				BitmapDataTextureCache.getInstance().freeTexture(_texture);
				_texture = null;
			}

			if (_specularGlossMap) _specularGlossMap.dispose();
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
			code += "add " + t+".xyz, " + lightDirReg+".xyz, " + _viewDirFragmentReg+".xyz\n" +
					"nrm " + t+".xyz, " + t+".xyz\n" +
					"dp3 " + t+".w, " + _normalFragmentReg+".xyz, " + t+".xyz\n" +
					"sat " + t+".w, " + t+".w\n";

			if (_useTexture) {
				code += "mul " + _specularTexData+".w, " + _specularTexData+".y, " + _specularDataRegister+".w\n" +
						"pow " + t+".w, " + t+".w, " + _specularTexData+".w\n";
			}
			else
				code += "pow " + t+".w, " + t+".w, " + _specularDataRegister+".w\n";

			// attenuate
			code += "mul " + t+".w, " + t+".w, " + lightDirReg+".w\n";

			if (_modulateMethod != null) code += _modulateMethod(t, regCache);

			code += "mul " + t+".xyz, " + lightColReg+".xyz, " + t+".w\n";

			if (lightIndex > 0) {
                code += "add " + _totalLightColorReg+".xyz, " + _totalLightColorReg+".xyz, " + t+".xyz\n";
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
				code += "mul " + _totalLightColorReg+".xyz, " + _totalLightColorReg+".xyz, " + _shadowRegister+".w\n";

			if (_useTexture) {
				code += "mul " + _totalLightColorReg+".xyz, " + _totalLightColorReg+".xyz, " + _specularTexData+".x\n";
				regCache.removeFragmentTempUsage(_specularTexData);
			}

			code += "mul " + _totalLightColorReg+".xyz, " + _totalLightColorReg+".xyz, " + _specularDataRegister+".xyz\n" +
					"add " + targetReg+".xyz, " + targetReg+".xyz, " + _totalLightColorReg+".xyz\n";
			regCache.removeFragmentTempUsage(_totalLightColorReg);

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(stage3DProxy : Stage3DProxy) : void
		{
			var context : Context3D = stage3DProxy._context3D;

			if (_specularGlossMapDirty) {
				updateSpecularGlossMap(context);
				_specularGlossMapDirty = false;
			}

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
			_specularData[0] = _specularR = ((_specularColor >> 16) & 0xff)/0xff*_specular;
			_specularData[1] = _specularG = ((_specularColor >> 8) & 0xff)/0xff*_specular;
			_specularData[2] = _specularB = (_specularColor & 0xff)/0xff*_specular;
		}

		public function set shadowRegister(shadowReg : ShaderRegisterElement) : void
		{
			_shadowRegister = shadowReg;
		}


		/**
		 * Updates the specular gloss map
		 */
		private function updateSpecularGlossMap(context : Context3D) : void
		{
			if (!_specularGlossMap) return;

			_specularGlossMap.fillRect(_specularGlossMap.rect, 0xffffff);

			if (_specularMap)
				_specularGlossMap.copyChannel(_specularMap, _specularGlossMap.rect, _specularGlossMap.rect.topLeft, BitmapDataChannel.BLUE, BitmapDataChannel.RED);

			if (_glossMap)
				_specularGlossMap.copyChannel(_glossMap, _specularGlossMap.rect, _specularGlossMap.rect.topLeft, BitmapDataChannel.GREEN, BitmapDataChannel.GREEN);

			bitmapData = _specularGlossMap;
		}
	}
}
