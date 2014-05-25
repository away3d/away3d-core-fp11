package away3d.materials.methods {
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	use namespace arcane;

	public class OpacityMapMethod extends EffectMethodBase {

		private var _texture:Texture2DBase;
		private var _useSecondaryUV:Boolean;
		private var _alphaThreshold:Number = 1;

		/**
		 * Creates a new OpacityMapMethod object
		 * @param texture The texture to use as the alpha mask.
		 * @param useSecondaryUV Indicated whether or not the secondary uv set for the mask. This allows mapping alpha independently.
		 */
		public function OpacityMapMethod(texture:Texture2DBase, alphaThreshold:Number = 1, useSecondaryUV:Boolean = false) {
			super();
			_texture = texture;
			_alphaThreshold = alphaThreshold;
			_useSecondaryUV = useSecondaryUV;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(vo:MethodVO):void {
			vo.needsSecondaryUV = _useSecondaryUV;
			vo.needsUV = !_useSecondaryUV;

		}

		/**
		 * Indicated whether or not the secondary uv set for the mask. This allows mapping alpha independently, for
		 * instance to tile the main texture and normal map while providing untiled alpha, for example to define the
		 * transparency over a tiled water surface.
		 */
		public function get useSecondaryUV():Boolean {
			return _useSecondaryUV;
		}

		public function set useSecondaryUV(value:Boolean):void {
			if (_useSecondaryUV == value)
				return;
			_useSecondaryUV = value;
			invalidateShaderProgram();
		}

		/**
		 * The texture to use as the alpha mask.
		 */
		public function get texture():Texture2DBase {
			return _texture;
		}

		public function set texture(value:Texture2DBase):void {
			_texture = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void {
			vo.fragmentData[vo.fragmentConstantsIndex] = _alphaThreshold;
			stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String {
			var dataRegister:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var textureReg:ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var uvReg:ShaderRegisterElement = _useSecondaryUV ? _sharedRegisters.secondaryUVVarying : _sharedRegisters.uvVarying;
			vo.texturesIndex = textureReg.index;
			vo.fragmentConstantsIndex = dataRegister.index * 4;

			return getTex2DSampleCode(vo, temp, textureReg, _texture, uvReg) +
					"sub " + temp + ".x, " + temp + ".x, " + dataRegister + ".x\n" +
					"kil " + temp + ".x\n"
		}
	}
}
