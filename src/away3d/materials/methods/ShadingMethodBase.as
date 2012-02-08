package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	use namespace arcane;

	/**
	 * ShadingMethodBase provides an abstract base method for shading methods, used by DefaultScreenPass to compile
	 * the final shading program.
	 */
	public class ShadingMethodBase
	{
		protected var _needsProjection : Boolean;
		protected var _needsView : Boolean;
		protected var _needsNormals : Boolean;
		protected var _needsTangents : Boolean;
		protected var _needsUV : Boolean;
		protected var _needsSecondaryUV : Boolean;
		protected var _needsGlobalPos : Boolean;

		protected var _viewDirVaryingReg : ShaderRegisterElement;
		protected var _viewDirFragmentReg : ShaderRegisterElement;
		protected var _normalFragmentReg : ShaderRegisterElement;
		protected var _uvFragmentReg : ShaderRegisterElement;
		protected var _secondaryUVFragmentReg : ShaderRegisterElement;
		protected var _tangentVaryingReg : ShaderRegisterElement;
		protected var _globalPosReg : ShaderRegisterElement;
		protected var _projectionReg : ShaderRegisterElement;

		protected var _mipmap : Boolean = true;
		protected var _smooth : Boolean = true;

		protected var _repeat : Boolean;
		protected var _passes : Vector.<MaterialPassBase>;

		private var _parentPass : MaterialPassBase;
		protected var _numLights : int;



		/**
		 * Create a new ShadingMethodBase object.
		 * @param needsNormals Defines whether or not the method requires normals.
		 * @param needsView Defines whether or not the method requires the view direction.
		 */
		public function ShadingMethodBase(needsNormals : Boolean, needsView : Boolean, needsGlobalPos : Boolean)
		{
			_needsNormals = needsNormals;
			_needsView = needsView;
			_needsGlobalPos = needsGlobalPos;
		}

		/**
		 * Any passes required that render to a texture used by this method.
		 */
		public function get passes() : Vector.<MaterialPassBase>
		{
			return _passes;
		}

		/**
		 * Cleans up any resources used by the current object.
		 * @param deep Indicates whether other resources should be cleaned up, that could potentially be shared across different instances.
		 */
		public function dispose() : void
		{

		}

		/**
		 * The amount of lights the method needs to support.
		 * @private
		 */
		arcane function get numLights() : int
		{
			return _numLights;
		}

		arcane function set numLights(value : int) : void
		{
			_numLights = value;
		}


		/**
		 * The pass for which this method is used.
		 * @private
		 */
		arcane function get parentPass() : MaterialPassBase
		{
			return _parentPass;
		}

		arcane function set parentPass(value : MaterialPassBase) : void
		{
			_parentPass = value;
		}

		arcane function reset() : void
		{
			cleanCompilationData();
		}

		/**
		 * Resets the method's state for compilation.
		 * @private
		 */
		arcane function cleanCompilationData() : void
		{
			_viewDirVaryingReg = null;
			_viewDirFragmentReg = null;
			_normalFragmentReg = null;
			_uvFragmentReg = null;
			_globalPosReg = null;
			_projectionReg = null;
		}

		/**
		 * Defines whether any used textures should use mipmapping.
		 * @private
		 */
		arcane function get mipmap() : Boolean
		{
			return _mipmap;
		}

		arcane function set mipmap(value : Boolean) : void
		{
			_mipmap = value;
		}

		/**
		 * Defines whether smoothing should be applied to any used textures.
		 * @private
		 */
		arcane function get smooth() : Boolean
		{
			return _smooth;
		}

		arcane function set smooth(value : Boolean) : void
		{
			_smooth = value;
		}

		/**
		 * Defines whether textures should be tiled.
		 * @private
		 */
		arcane function get repeat() : Boolean
		{
			return _repeat;
		}

		arcane function set repeat(value : Boolean) : void
		{
			_repeat = value;
		}

		/**
		 * Indicates whether the material requires uv coordinates.
		 * @private
		 */
		arcane function get needsUV() : Boolean
		{
			return _needsUV;
		}

		/**
		 * Indicates whether the material requires uv coordinates.
		 * @private
		 */
		arcane function get needsSecondaryUV() : Boolean
		{
			return _needsSecondaryUV;
		}

		/**
		 * Indicates whether the material requires the view direction.
		 * @private
		 */
		arcane function get needsView() : Boolean
		{
			return _needsView;
		}

		/**
		 * Indicates whether the material requires normals.
		 * @private
		 */
		arcane function get needsNormals() : Boolean
		{
			return _needsNormals;
		}

		arcane function get needsTangents() : Boolean
		{
			return _needsTangents;
		}

		arcane function get needsGlobalPos() : Boolean
		{
			return _needsGlobalPos;
		}

		arcane function get needsProjection() : Boolean
		{
			return _needsProjection;
		}

		/**
		 * The fragment register in which the uv coordinates are stored.
		 * @private
		 */
		arcane function get globalPosReg() : ShaderRegisterElement
		{
			return _globalPosReg;
		}

		arcane function set globalPosReg(value : ShaderRegisterElement) : void
		{
			_globalPosReg = value;
		}

		arcane function get projectionReg() : ShaderRegisterElement
		{
			return _projectionReg;
		}

		arcane function set projectionReg(value : ShaderRegisterElement) : void
		{
			_projectionReg = value;
		}

		/**
		 * The fragment register in which the uv coordinates are stored.
		 * @private
		 */
		arcane function get UVFragmentReg() : ShaderRegisterElement
		{
			return _uvFragmentReg;
		}

		arcane function set UVFragmentReg(value : ShaderRegisterElement) : void
		{
			_uvFragmentReg = value;
		}

		/**
		 * The fragment register in which the uv coordinates are stored.
		 * @private
		 */
		arcane function get secondaryUVFragmentReg() : ShaderRegisterElement
		{
			return _secondaryUVFragmentReg;
		}

		arcane function set secondaryUVFragmentReg(value : ShaderRegisterElement) : void
		{
			_secondaryUVFragmentReg = value;
		}

		/**
		 * The fragment register in which the view direction is stored.
		 * @private
		 */
		arcane function get viewDirFragmentReg() : ShaderRegisterElement
		{
			return _viewDirFragmentReg;
		}

		arcane function set viewDirFragmentReg(value : ShaderRegisterElement) : void
		{
			_viewDirFragmentReg = value;
		}

		public function get viewDirVaryingReg() : ShaderRegisterElement
		{
			return _viewDirVaryingReg;
		}

		public function set viewDirVaryingReg(value : ShaderRegisterElement) : void
		{
			_viewDirVaryingReg = value;
		}

		/**
		 * The fragment register in which the normal is stored.
		 * @private
		 */
		arcane function get normalFragmentReg() : ShaderRegisterElement
		{
			return _normalFragmentReg;
		}

		arcane function set normalFragmentReg(value : ShaderRegisterElement) : void
		{
			_normalFragmentReg = value;
		}

		/**
		 * Get the vertex shader code for this method.
		 * @param regCache The register cache used during the compilation.
		 * @private
		 */
		arcane function getVertexCode(regCache : ShaderRegisterCache) : String
		{
			// TODO: not used
			regCache = regCache;			
			return "";
		}

		/**
		 * Get the fragment shader code that should be added after all per-light code. Usually composits everything to the target register.
		 * @param regCache The register cache used during the compilation.
		 * @private
		 */
		arcane function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			// TODO: not used
			regCache = regCache;
			targetReg = targetReg;			
			return "";
		}

		/**
		 * Sets the render state for this method.
		 * @param context The Context3D currently used for rendering.
		 * @private
		 */
		arcane function activate(stage3DProxy : Stage3DProxy) : void
		{

		}

		/**
		 * Sets the render state for a single renderable.
		 */
		arcane function setRenderState(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{

		}

		/**
		 * Clears the render state for this method.
		 * @param context The Context3D currently used for rendering.
		 * @private
		 */
		arcane function deactivate(stage3DProxy : Stage3DProxy) : void
		{

		}

		/**
		 * A helper method that generates standard code for sampling from a texture using the normal uv coordinates.
		 * @param targetReg The register in which to store the sampled colour.
		 * @param inputReg The texture stream register.
		 * @return The fragment code that performs the sampling.
		 */
		protected function getTexSampleCode(targetReg : ShaderRegisterElement, inputReg : ShaderRegisterElement, uvReg : ShaderRegisterElement = null, forceWrap : String = null) : String
		{
			var wrap : String = forceWrap || (_repeat ? "wrap" : "clamp");
			var filter : String;

			if (_smooth) filter = _mipmap ? "linear,miplinear" : "linear";
			else filter = _mipmap ? "nearest,mipnearest" : "nearest";

            uvReg ||= _uvFragmentReg;
            return "tex "+targetReg.toString()+", "+uvReg.toString()+", "+inputReg.toString()+" <2d,"+filter+","+wrap+">\n";
		}

		/**
		 * Marks the shader program as invalid, so it will be recompiled before the next render.
		 */
		protected function invalidateShaderProgram() : void
		{
			if (_parentPass)
				_parentPass.invalidateShaderProgram();
		}

		/**
		 * Copies the state from a ShadingMethodBase object into the current object.
		 */
		public function copyFrom(method : ShadingMethodBase) : void
		{
		}

		public function get tangentVaryingReg() : ShaderRegisterElement
		{
			return _tangentVaryingReg;
		}


		public function set tangentVaryingReg(tangentVaryingReg : ShaderRegisterElement) : void
		{
			_tangentVaryingReg = tangentVaryingReg;
		}
	}
}
