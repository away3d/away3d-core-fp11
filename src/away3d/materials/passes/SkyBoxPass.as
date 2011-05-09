package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.CubeTexture3DProxy;
	import away3d.materials.SkyBoxMaterial;
	import away3d.materials.utils.AGAL;

	import flash.display3D.Context3D;

	use namespace arcane;

	/**
	 * SkyBoxPass provides a material pass exclusively used to render sky boxes from a cube texture.
	 */
	public class SkyBoxPass extends MaterialPassBase
	{
		private var _cubeTexture : CubeTexture3DProxy;

		/**
		 * Creates a new SkyBoxPass object.
		 */
		public function SkyBoxPass()
		{
			super();
			mipmap = false;
		}
		/**
		 * The cube texture to use as the skybox.
		 */
		public function get cubeTexture() : CubeTexture3DProxy
		{
			return _cubeTexture;
		}

		public function set cubeTexture(value : CubeTexture3DProxy) : void
		{
			_cubeTexture = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode() : String
		{
			return "mov v0, vt0\n";
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode() : String
		{
			return 	AGAL.sample("ft0", "v0", "cube", "fs0", "bilinear", "clamp") +
					AGAL.mov("oc", "ft0");
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(context : Context3D, contextIndex : uint, camera : Camera3D) : void
		{
			super.activate(context, contextIndex, camera);
			context.setTextureAt(0, _cubeTexture.getTextureForContext(context, contextIndex));
		}


		arcane override function deactivate(context : Context3D) : void
		{
			context.setTextureAt(0, null);
		}
	}

}