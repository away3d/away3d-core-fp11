package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display.BitmapData;
	import flash.display3D.Context3D;

	use namespace arcane;

	/**
	 * WrapSpecularMethod provides a base class for specular methods that wrap a specular method to alter the strength
	 * of its calculated strength.
	 */
	public class WrapSpecularMethod extends BasicSpecularMethod
	{
		private var _baseSpecularMethod : BasicSpecularMethod;

		/**
		 * Creates a new WrapSpecularMethod object.
		 * @param modulateMethod The method which will add the code to alter the base method's strength. It needs to have the signature modSpecular(t : ShaderRegisterElement, regCache : ShaderRegisterCache) : String, in which t.w will contain the specular strength and t.xyz will contain the half-vector or the reflection vector.
		 * @param baseSpecularMethod The base specular method on which this method's shading is based.
		 */
		public function WrapSpecularMethod(modulateMethod : Function, baseSpecularMethod : BasicSpecularMethod = null)
		{
			super();
			_baseSpecularMethod = baseSpecularMethod || new BasicSpecularMethod();
			_baseSpecularMethod._modulateMethod = modulateMethod;
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
		override public function dispose(deep : Boolean) : void
		{
			_baseSpecularMethod.dispose(deep);
		}

		/**
		 * @inheritDoc
		 */
		override public function invalidateBitmapData() : void
		{
			_baseSpecularMethod.invalidateBitmapData();
		}

		/**
		 * @inheritDoc
		 */
		override public function get bitmapData() : BitmapData
		{
			return _baseSpecularMethod.bitmapData;
		}

		/**
		 * @inheritDoc
		 */
		override public function set bitmapData(value : BitmapData) : void
		{
			_baseSpecularMethod.bitmapData = value;
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
		override arcane function activate(context : Context3D, contextIndex : uint) : void
		{
			_baseSpecularMethod.activate(context, contextIndex);
		}

		arcane override function deactivate(context : Context3D) : void
		{
			_baseSpecularMethod.deactivate(context);
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
		override arcane function get specularDataRegister() : ShaderRegisterElement
		{
			return _baseSpecularMethod.specularDataRegister;
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
		override arcane function set globalPosVertexReg(value : ShaderRegisterElement) : void
		{
			_baseSpecularMethod.globalPosVertexReg = _globalPosVertexReg = value;
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
		override arcane function set viewDirFragmentReg(value : ShaderRegisterElement) : void
		{
			_viewDirFragmentReg = _baseSpecularMethod.viewDirFragmentReg = value;
		}

		arcane override function set projectionReg(value : ShaderRegisterElement) : void
		{
			_projectionReg = _baseSpecularMethod.projectionReg = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get specularTextureRegister() : ShaderRegisterElement
		{
			return _baseSpecularMethod.specularTextureRegister;
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

		override public function set shadowRegister(shadowReg : ShaderRegisterElement) : void
		{
			super.shadowRegister = shadowReg;
			_baseSpecularMethod.shadowRegister = shadowReg;
		}
	}
}
