package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
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
		override public function get passes() : Vector.<MaterialPassBase>
		{
			return _baseSpecularMethod.passes;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose() : void
		{
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
		override arcane function set parentPass(value : MaterialPassBase) : void
		{
			super.parentPass = value;
			_baseSpecularMethod.parentPass = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy) : void
		{
			_baseSpecularMethod.activate(stage3DProxy);
		}

		arcane override function deactivate(stage3DProxy : Stage3DProxy) : void
		{
			_baseSpecularMethod.deactivate(stage3DProxy);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get needsView() : Boolean
		{
			return _baseSpecularMethod.needsView;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get needsUV() : Boolean
		{
			return _baseSpecularMethod.needsUV;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get needsNormals() : Boolean
		{
			return _baseSpecularMethod.needsNormals;
		}

		arcane override function get needsProjection() : Boolean
		{
			return _baseSpecularMethod.needsProjection || _needsProjection;
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
		override arcane function get mipmap() : Boolean
		{
			return _baseSpecularMethod.mipmap;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set mipmap(value : Boolean) : void
		{
			_baseSpecularMethod.mipmap = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get smooth() : Boolean
		{
			return _baseSpecularMethod.smooth;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set smooth(value : Boolean) : void
		{
			_baseSpecularMethod.smooth = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get repeat() : Boolean
		{
			return _baseSpecularMethod.repeat;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set repeat(value : Boolean) : void
		{
			_baseSpecularMethod.repeat = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get numLights() : int
		{
			return _baseSpecularMethod.numLights;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set numLights(value : int) : void
		{
			_baseSpecularMethod.numLights = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get needsGlobalPos() : Boolean
		{
			return _baseSpecularMethod.needsGlobalPos || _needsGlobalPos;
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
		override arcane function getVertexCode(regCache : ShaderRegisterCache) : String
		{
			return _baseSpecularMethod.getVertexCode(regCache);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentAGALPreLightingCode(regCache : ShaderRegisterCache) : String
		{
			return _baseSpecularMethod.getFragmentAGALPreLightingCode(regCache);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentCodePerLight(lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			return _baseSpecularMethod.getFragmentCodePerLight(lightIndex, lightDirReg, lightColReg, regCache);
		}

		/**
		 * @inheritDoc
		 * @return
		 */
		arcane override function getFragmentCodePerProbe(lightIndex : int, cubeMapReg : ShaderRegisterElement, weightRegister : String, regCache : ShaderRegisterCache) : String
		{
			return _baseSpecularMethod.getFragmentCodePerProbe(lightIndex, cubeMapReg, weightRegister, regCache);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			return _baseSpecularMethod.getFragmentPostLightingCode(regCache, targetReg);
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

		override public function set shadowRegister(shadowReg : ShaderRegisterElement) : void
		{
			super.shadowRegister = shadowReg;
			_baseSpecularMethod.shadowRegister = shadowReg;
		}

		override public function set tangentVaryingReg(tangentVaryingReg : ShaderRegisterElement) : void
		{
			super.tangentVaryingReg = tangentVaryingReg;
			_baseSpecularMethod.shadowRegister = tangentVaryingReg;
		}

		arcane override function get needsSecondaryUV() : Boolean
		{
			return _needsSecondaryUV || _baseSpecularMethod.needsSecondaryUV;
		}

		arcane override function get needsTangents() : Boolean
		{
			return _needsTangents || _baseSpecularMethod.needsTangents;
		}
	}
}
