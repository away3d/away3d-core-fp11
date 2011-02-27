package away3d.materials
{
	import away3d.arcane;
	import away3d.core.managers.CubeTexture3DProxy;
	import away3d.materials.passes.SkyBoxPass;
	import away3d.materials.utils.CubeMap;

	use namespace arcane;

	/**
	 * SkyBoxMaterial is a material exclusively used to render skyboxes
	 *
	 * @see away3d.primitives.SkyBox
	 */
	public class SkyBoxMaterial extends MaterialBase
	{
		private var _cubeMap : CubeTexture3DProxy;
		private var _skyboxPass : SkyBoxPass;

		/**
		 * Creates a new SkyBoxMaterial object.
		 * @param cubeMap The CubeMap to use as the skybox.
		 */
		public function SkyBoxMaterial(cubeMap : CubeMap)
		{
			_cubeMap = new CubeTexture3DProxy();
			_cubeMap.cubeMap = cubeMap;
			addPass(_skyboxPass = new SkyBoxPass());
			_skyboxPass.cubeTexture = _cubeMap;
		}

		/**
		 * The CubeMap to use as the skybox.
		 */
		public function get cubeMap() : CubeMap
		{
			return _cubeMap.cubeMap;
		}

		public function set cubeMap(value : CubeMap) : void
		{
			_cubeMap.cubeMap = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose(deep : Boolean) : void
		{
			super.dispose(deep);
			_cubeMap.dispose(deep);
		}
	}
}
