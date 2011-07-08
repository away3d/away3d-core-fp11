package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.CubeTexture3DProxy;
	import away3d.core.managers.Stage3DProxy;

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
			_numUsedTextures = 1;
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
			return 	"tex ft0, v0, fs0 <cube,linear,clamp>	\n" +
					"mov oc, ft0							\n";
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			super.activate(stage3DProxy, camera);
			stage3DProxy.setTextureAt(0, _cubeTexture.getTextureForContext(stage3DProxy));
		}


//		arcane override function deactivate(stage3DProxy : Stage3DProxy) : void
//		{
//			stage3DProxy.setTextureAt(0, null);
//		}
	}

}