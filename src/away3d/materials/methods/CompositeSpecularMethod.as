package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.events.ShadingMethodEvent;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	use namespace arcane;

	/**
	 * CompositeSpecularMethod provides a base class for specular methods that wrap a specular method to alter the strength
	 * of its calculated strength.
	 */
	public class CompositeSpecularMethod extends BasicSpecularMethod
	{
		private var _baseSpecularMethod : BasicSpecularMethod;

		/**
		 * Creates a new WrapSpecularMethod object.
		 * @param modulateMethod The method which will add the code to alter the base method's strength. It needs to have the signature modSpecular(t : ShaderRegisterElement, regCache : ShaderRegisterCache) : String, in which t.w will contain the specular strength and t.xyz will contain the half-vector or the reflection vector.
		 * @param baseSpecularMethod The base specular method on which this method's shading is based.
		 */
		public function CompositeSpecularMethod(modulateMethod : Function, baseSpecularMethod : BasicSpecularMethod = null)
		{
			super();
			_baseSpecularMethod = baseSpecularMethod || new BasicSpecularMethod();
			_baseSpecularMethod._modulateMethod = modulateMethod;
			_baseSpecularMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			_baseSpecularMethod.initVO(vo);
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			_baseSpecularMethod.initConstants(vo);
		}

		/**
		 * @inheritDoc
		 */
		override public function get gloss() : Number
		{
			return _baseSpecularMethod.gloss;
		}

		override public function set gloss(value : Number) : void
		{
			_baseSpecularMethod.gloss = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function get specular() : Number
		{
			return _baseSpecularMethod.specular;
		}

		override public function set specular(value : Number) : void
		{
			_baseSpecularMethod.specular = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get shadingModel() : String
		{
			return _baseSpecularMethod.shadingModel;
		}
		
		override public function set shadingModel(value : String) : void
		{
			_baseSpecularMethod.shadingModel = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get passes() : Vector.<MaterialPassBase>
		{
			return _baseSpecularMethod.passes;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose() : void
		{
			_baseSpecularMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_baseSpecularMethod.dispose();
		}

		/**
		 * @inheritDoc
		 */
		override public function get texture() : Texture2DBase
		{
			return _baseSpecularMethod.texture;
		}

		override public function set texture(value : Texture2DBase) : void
		{
			_baseSpecularMethod.texture = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			_baseSpecularMethod.activate(vo, stage3DProxy);
		}

		arcane override function deactivate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			_baseSpecularMethod.deactivate(vo, stage3DProxy);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get normalFragmentReg() : ShaderRegisterElement
		{
			return _baseSpecularMethod.normalFragmentReg;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set normalFragmentReg(value : ShaderRegisterElement) : void
		{
			_normalFragmentReg = _baseSpecularMethod.normalFragmentReg = value;
		}


		/**
		 * @inheritDoc
		 */
		override arcane function set globalPosReg(value : ShaderRegisterElement) : void
		{
			_baseSpecularMethod.globalPosReg = _globalPosReg = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set UVFragmentReg(value : ShaderRegisterElement) : void
		{
			_baseSpecularMethod.UVFragmentReg = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set secondaryUVFragmentReg(value : ShaderRegisterElement) : void
		{
			_baseSpecularMethod.secondaryUVFragmentReg = _secondaryUVFragmentReg = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set viewDirFragmentReg(value : ShaderRegisterElement) : void
		{
			_viewDirFragmentReg = _baseSpecularMethod.viewDirFragmentReg = value;
		}

		arcane override function set projectionReg(value : ShaderRegisterElement) : void
		{
			_projectionReg = _baseSpecularMethod.projectionReg = value;
		}

		override public function set viewDirVaryingReg(value : ShaderRegisterElement) : void
		{
			_viewDirVaryingReg = _baseSpecularMethod.viewDirVaryingReg = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getVertexCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			return _baseSpecularMethod.getVertexCode(vo, regCache);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPreLightingCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			return _baseSpecularMethod.getFragmentPreLightingCode(vo, regCache);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentCodePerLight(vo : MethodVO, lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			return _baseSpecularMethod.getFragmentCodePerLight(vo, lightIndex, lightDirReg, lightColReg, regCache);
		}

		/**
		 * @inheritDoc
		 * @return
		 */
		arcane override function getFragmentCodePerProbe(vo : MethodVO, lightIndex : int, cubeMapReg : ShaderRegisterElement, weightRegister : String, regCache : ShaderRegisterCache) : String
		{
			return _baseSpecularMethod.getFragmentCodePerProbe(vo, lightIndex, cubeMapReg, weightRegister, regCache);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			return _baseSpecularMethod.getFragmentPostLightingCode(vo, regCache, targetReg);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function reset() : void
		{
			_baseSpecularMethod.reset();
		}

		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_baseSpecularMethod.cleanCompilationData();
		}

		override arcane function set shadowRegister(value : ShaderRegisterElement) : void
		{
			super.shadowRegister = value;
			_baseSpecularMethod.shadowRegister = value;
		}

		override arcane function set tangentVaryingReg(value : ShaderRegisterElement) : void
		{
			super.tangentVaryingReg = value;
			_baseSpecularMethod.tangentVaryingReg = value;
		}

		private function onShaderInvalidated(event : ShadingMethodEvent) : void
		{
			invalidateShaderProgram();
		}
	}
}
