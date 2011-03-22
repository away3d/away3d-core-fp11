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
	 * WrapDiffuseMethod provides a base class for diffuse methods that wrap a diffuse method to alter the strength
	 * of its calculated strength.
	 */
	public class WrapDiffuseMethod extends BasicDiffuseMethod
	{
		private var _baseDiffuseMethod : BasicDiffuseMethod;

		/**
		 * Creates a new WrapDiffuseMethod object.
		 * @param modulateMethod The method which will add the code to alter the base method's strength. It needs to have the signature clampDiffuse(t : ShaderRegisterElement, regCache : ShaderRegisterCache) : String, in which t.w will contain the diffuse strength.
		 * @param baseDiffuseMethod The base diffuse method on which this method's shading is based.
		 */
		public function WrapDiffuseMethod(modulateMethod : Function = null, baseDiffuseMethod : BasicDiffuseMethod = null)
		{
			_baseDiffuseMethod = baseDiffuseMethod || new BasicDiffuseMethod();
			_baseDiffuseMethod._modulateMethod = modulateMethod;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose(deep : Boolean) : void
		{
			_baseDiffuseMethod.dispose(deep);
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
		override public function invalidateBitmapData() : void
		{
			_baseDiffuseMethod.invalidateBitmapData();
		}

		/**
		 * @inheritDoc
		 */
		override public function get bitmapData() : BitmapData
		{
			return _baseDiffuseMethod.bitmapData;
		}

		/**
		 * @inheritDoc
		 */
		override public function set bitmapData(value : BitmapData) : void
		{
			_baseDiffuseMethod.bitmapData = value;
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
		override arcane function set parentPass(value : MaterialPassBase) : void
		{
			super.parentPass = value;
			_baseDiffuseMethod.parentPass = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentAGALPreLightingCode(regCache : ShaderRegisterCache) : String
		{
			return _baseDiffuseMethod.getFragmentAGALPreLightingCode(regCache);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentCodePerLight(lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			var code : String = _baseDiffuseMethod.getFragmentCodePerLight(lightIndex, lightDirReg, lightColReg, regCache);
			_totalLightColorReg = _baseDiffuseMethod._totalLightColorReg;
			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(context : Context3D, contextIndex : uint) : void
		{
			_baseDiffuseMethod.activate(context, contextIndex);
		}

		arcane override function deactivate(context : Context3D) : void
		{
			_baseDiffuseMethod.deactivate(context);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get needsUV() : Boolean
		{
			return _baseDiffuseMethod.needsUV;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getVertexCode(regCache : ShaderRegisterCache) : String
		{
			return _baseDiffuseMethod.getVertexCode(regCache);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			return _baseDiffuseMethod.getFragmentPostLightingCode(regCache, targetReg);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function reset() : void
		{
			_baseDiffuseMethod.reset();
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get mipmap() : Boolean
		{
			return _mipmap;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set mipmap(value : Boolean) : void
		{
			_baseDiffuseMethod.mipmap = _mipmap = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get smooth() : Boolean
		{
			return _smooth;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set smooth(value : Boolean) : void
		{
			_baseDiffuseMethod.smooth = _smooth = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get repeat() : Boolean
		{
			return _repeat;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set repeat(value : Boolean) : void
		{
			_baseDiffuseMethod.repeat = _repeat = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get numLights() : int
		{
			return _numLights;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set numLights(value : int) : void
		{
			_numLights = _baseDiffuseMethod.numLights = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get needsGlobalPos() : Boolean
		{
			return _baseDiffuseMethod.needsGlobalPos || _needsGlobalPos;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get needsView() : Boolean
		{
			return _baseDiffuseMethod.needsView || _needsView;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get needsNormals() : Boolean
		{
			return _baseDiffuseMethod.needsNormals || _needsNormals;
		}

		arcane override function get needsProjection() : Boolean
		{
			return _baseDiffuseMethod.needsProjection || _needsProjection;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get globalPosVertexReg() : ShaderRegisterElement
		{
			return _globalPosVertexReg;
		}

		override arcane function set globalPosVertexReg(value : ShaderRegisterElement) : void
		{
			_baseDiffuseMethod.globalPosVertexReg = _globalPosVertexReg = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get UVFragmentReg() : ShaderRegisterElement
		{
			return _uvFragmentReg;
		}

		override arcane function set UVFragmentReg(value : ShaderRegisterElement) : void
		{
			_baseDiffuseMethod.UVFragmentReg = _uvFragmentReg = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get viewDirFragmentReg() : ShaderRegisterElement
		{
			return _viewDirFragmentReg;
		}

		override arcane function set viewDirFragmentReg(value : ShaderRegisterElement) : void
		{
			_baseDiffuseMethod.viewDirFragmentReg = _viewDirFragmentReg = value;
		}

		override public function set viewDirVaryingReg(value : ShaderRegisterElement) : void
		{
			_viewDirVaryingReg = _baseDiffuseMethod.viewDirVaryingReg = value;
		}


		arcane override function set projectionReg(value : ShaderRegisterElement) : void
		{
			_projectionReg = _baseDiffuseMethod.projectionReg = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get normalFragmentReg() : ShaderRegisterElement
		{
			return _normalFragmentReg;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set normalFragmentReg(value : ShaderRegisterElement) : void
		{
			_baseDiffuseMethod.normalFragmentReg = _normalFragmentReg = value;
		}

		override public function set shadowRegister(shadowReg : ShaderRegisterElement) : void
		{

			super.shadowRegister = shadowReg;
			_baseDiffuseMethod.shadowRegister = shadowReg;
		}
	}
}
