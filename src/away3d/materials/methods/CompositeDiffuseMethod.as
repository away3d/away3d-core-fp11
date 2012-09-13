package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.events.ShadingMethodEvent;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterData;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	use namespace arcane;

	/**
	 * CompositeDiffuseMethod provides a base class for diffuse methods that wrap a diffuse method to alter the strength
	 * of its calculated strength.
	 */
	public class CompositeDiffuseMethod extends BasicDiffuseMethod
	{
		protected var _baseDiffuseMethod : BasicDiffuseMethod;

		/**
		 * Creates a new WrapDiffuseMethod object.
		 * @param modulateMethod The method which will add the code to alter the base method's strength. It needs to have the signature clampDiffuse(t : ShaderRegisterElement, regCache : ShaderRegisterCache) : String, in which t.w will contain the diffuse strength.
		 * @param baseDiffuseMethod The base diffuse method on which this method's shading is based.
		 */
		public function CompositeDiffuseMethod(modulateMethod : Function = null, baseDiffuseMethod : BasicDiffuseMethod = null)
		{
			_baseDiffuseMethod = baseDiffuseMethod || new BasicDiffuseMethod();
			_baseDiffuseMethod._modulateMethod = modulateMethod;
			_baseDiffuseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			_baseDiffuseMethod.initVO(vo);
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			_baseDiffuseMethod.initConstants(vo);
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose() : void
		{
			_baseDiffuseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_baseDiffuseMethod.dispose();
		}

        override public function get alphaThreshold() : Number
        {
            return _baseDiffuseMethod.alphaThreshold;
        }

        override public function set alphaThreshold(value : Number) : void
        {
            _baseDiffuseMethod.alphaThreshold = value;
        }

		/**
		 * @inheritDoc
		 */
		override public function get texture() : Texture2DBase
		{
			return _baseDiffuseMethod.texture;
		}

		/**
		 * @inheritDoc
		 */
		override public function set texture(value : Texture2DBase) : void
		{
			_baseDiffuseMethod.texture = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function get diffuseAlpha() : Number
		{
			return _baseDiffuseMethod.diffuseAlpha;
		}

		/**
		 * @inheritDoc
		 */
		override public function get diffuseColor() : uint
		{
			return _baseDiffuseMethod.diffuseColor;
		}

		/**
		 * @inheritDoc
		 */
		override public function set diffuseColor(diffuseColor : uint) : void
		{
			_baseDiffuseMethod.diffuseColor = diffuseColor;
		}

		/**
		 * @inheritDoc
		 */
		override public function set diffuseAlpha(value : Number) : void
		{
			_baseDiffuseMethod.diffuseAlpha = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPreLightingCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			return _baseDiffuseMethod.getFragmentPreLightingCode(vo, regCache);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentCodePerLight(vo : MethodVO, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			var code : String = _baseDiffuseMethod.getFragmentCodePerLight(vo, lightDirReg, lightColReg, regCache);
			_totalLightColorReg = _baseDiffuseMethod._totalLightColorReg;
			return code;
		}


		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCodePerProbe(vo : MethodVO, cubeMapReg : ShaderRegisterElement, weightRegister : String, regCache : ShaderRegisterCache) : String
		{
			var code : String = _baseDiffuseMethod.getFragmentCodePerProbe(vo, cubeMapReg, weightRegister, regCache);
			_totalLightColorReg = _baseDiffuseMethod._totalLightColorReg;
			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			_baseDiffuseMethod.activate(vo, stage3DProxy);
		}

		arcane override function deactivate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			_baseDiffuseMethod.deactivate(vo, stage3DProxy);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getVertexCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			return _baseDiffuseMethod.getVertexCode(vo, regCache);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			return _baseDiffuseMethod.getFragmentPostLightingCode(vo, regCache, targetReg);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function reset() : void
		{
			_baseDiffuseMethod.reset();
		}


		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_baseDiffuseMethod.cleanCompilationData();
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set sharedRegisters(value : ShaderRegisterData) : void
		{
			super.sharedRegisters = _baseDiffuseMethod.sharedRegisters = value;
		}

		override arcane function set shadowRegister(value : ShaderRegisterElement) : void
		{
			super.shadowRegister = value;
			_baseDiffuseMethod.shadowRegister = value;
		}

		private function onShaderInvalidated(event : ShadingMethodEvent) : void
		{
			invalidateShaderProgram();
		}
	}
}
