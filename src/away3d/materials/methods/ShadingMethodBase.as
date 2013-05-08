package away3d.materials.methods {
	import away3d.*;
	import away3d.cameras.*;
	import away3d.core.base.*;
	import away3d.core.managers.*;
	import away3d.events.*;
	import away3d.library.assets.*;
	import away3d.materials.compilation.*;
	import away3d.materials.passes.*;
	import away3d.textures.*;

	import flash.display3D.*;

	use namespace arcane;

	/**
	 * ShadingMethodBase provides an abstract base method for shading methods, used by DefaultScreenPass to compile
	 * the final shading program.
	 */
	public class ShadingMethodBase extends NamedAssetBase
	{
		protected var _sharedRegisters : ShaderRegisterData;
		protected var _passes : Vector.<MaterialPassBase>;

		/**
		 * Create a new ShadingMethodBase object.
		 * @param needsNormals Defines whether or not the method requires normals.
		 * @param needsView Defines whether or not the method requires the view direction.
		 */
		public function ShadingMethodBase()  // needsNormals : Boolean, needsView : Boolean, needsGlobalPos : Boolean
		{
		}

		arcane function initVO(vo : MethodVO) : void
		{

		}

		arcane function initConstants(vo : MethodVO) : void
		{

		}

		arcane function get sharedRegisters() : ShaderRegisterData
		{
			return _sharedRegisters;
		}

		arcane function set sharedRegisters(value : ShaderRegisterData) : void
		{
			_sharedRegisters = value;
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
		 * Creates a data container that contains material-dependent data. Provided as a factory method so a custom subtype can be overridden when needed.
		 */
		arcane function createMethodVO() : MethodVO
		{
			return new MethodVO();
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
		}

		/**
		 * Get the vertex shader code for this method.
		 * @param regCache The register cache used during the compilation.
		 * @private
		 */
		arcane function getVertexCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			return "";
		}

		/**
		 * Sets the render state for this method.
		 * @param context The Context3D currently used for rendering.
		 * @private
		 */
		arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{

		}

		/**
		 * Sets the render state for a single renderable.
		 */
		arcane function setRenderState(vo : MethodVO, renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{

		}

		/**
		 * Clears the render state for this method.
		 * @param context The Context3D currently used for rendering.
		 * @private
		 */
		arcane function deactivate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{

		}

		/**
		 * A helper method that generates standard code for sampling from a texture using the normal uv coordinates.
		 * @param targetReg The register in which to store the sampled colour.
		 * @param inputReg The texture stream register.
		 * @return The fragment code that performs the sampling.
		 */
		protected function getTex2DSampleCode(vo : MethodVO, targetReg : ShaderRegisterElement, inputReg : ShaderRegisterElement, texture : TextureProxyBase, uvReg : ShaderRegisterElement = null, forceWrap : String = null) : String
		{
			var wrap : String = forceWrap || (vo.repeatTextures ? "wrap" : "clamp");
			var filter : String;
			var format : String = getFormatStringForTexture(texture);
			var enableMipMaps : Boolean = vo.useMipmapping && texture.hasMipMaps;

			if (vo.useSmoothTextures) {
				filter = enableMipMaps? "linear,miplinear" : "linear";
			}else{
				filter = enableMipMaps? "nearest,mipnearest" : "nearest";
			}

			uvReg ||= _sharedRegisters.uvVarying;
            return "tex " + targetReg + ", " + uvReg + ", " + inputReg + " <2d,"+filter+","+format+wrap+">\n";
		}

		protected function getTexCubeSampleCode(vo : MethodVO, targetReg : ShaderRegisterElement, inputReg : ShaderRegisterElement, texture : TextureProxyBase, uvReg : ShaderRegisterElement) : String
		{
			var filter : String;
			var format : String = getFormatStringForTexture(texture);
			var enableMipMaps : Boolean = vo.useMipmapping && texture.hasMipMaps;

			if (vo.useSmoothTextures) {
				filter = enableMipMaps? "linear,miplinear" : "linear";
			}else{
				filter = enableMipMaps? "nearest,mipnearest" : "nearest";
			}

			return "tex " + targetReg + ", " + uvReg + ", " + inputReg + " <cube,"+format+filter+">\n";
		}

		private function getFormatStringForTexture(texture : TextureProxyBase) : String
		{
			switch (texture.format) {
				case Context3DTextureFormat.COMPRESSED:
					return "dxt1,";
					break;
				case "compressedAlpha":
					return "dxt5,";
					break;
				default:
					return "";
			}
		}

		/**
		 * Marks the shader program as invalid, so it will be recompiled before the next render.
		 */
		protected function invalidateShaderProgram() : void
		{
			dispatchEvent(new ShadingMethodEvent(ShadingMethodEvent.SHADER_INVALIDATED));
		}

		/**
		 * Copies the state from a ShadingMethodBase object into the current object.
		 */
		public function copyFrom(method : ShadingMethodBase) : void
		{
		}
	}
}
