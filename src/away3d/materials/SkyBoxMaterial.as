package away3d.materials
{
	import away3d.arcane;
	import away3d.materials.passes.SkyBoxPass;
	import away3d.textures.CubeTextureBase;

	use namespace arcane;

	/**
	 * SkyBoxMaterial is a material exclusively used to render skyboxes
	 *
	 * @see away3d.primitives.SkyBox
	 */
	public class SkyBoxMaterial extends MaterialBase
	{
		private var _cubeMap : CubeTextureBase;
		private var _skyboxPass : SkyBoxPass;

		/**
		 * Creates a new SkyBoxMaterial object.
		 * @param cubeMap The CubeMap to use as the skybox.
		 */
		public function SkyBoxMaterial(cubeMap : CubeTextureBase)
		{
			_cubeMap = cubeMap;
			addPass(_skyboxPass = new SkyBoxPass());
			_skyboxPass.cubeTexture = _cubeMap;
		}

		/**
		 * The CubeMap to use as the skybox.
		 */
		public function get cubeMap() : CubeTextureBase
		{
			return _cubeMap;
		}

		public function set cubeMap(value : CubeTextureBase) : void
		{
			if (value && _cubeMap && (value.hasMipMaps != _cubeMap.hasMipMaps || value.format != _cubeMap.format))
				invalidatePasses(null);
			
			_cubeMap = value;
			
			_skyboxPass.cubeTexture = _cubeMap;
		}
	}
}
