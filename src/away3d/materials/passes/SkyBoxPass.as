package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.textures.CubeTextureBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	/**
	 * SkyBoxPass provides a material pass exclusively used to render sky boxes from a cube texture.
	 */
	public class SkyBoxPass extends MaterialPassBase
	{
		private var _cubeTexture : CubeTextureBase;

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
		public function get cubeTexture() : CubeTextureBase
		{
			return _cubeTexture;
		}

		public function set cubeTexture(value : CubeTextureBase) : void
		{
			_cubeTexture = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode() : String
		{
			return  "m44 vt7, va0, vc0		\n" +
					// fit within texture range
					"mul op, vt7, vc4\n" +
					"mov v0, va0\n";
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode() : String
		{
			return 	"tex ft0, v0, fs0 <cube,linear,clamp,miplinear>	\n" +
					"mov oc, ft0							\n";
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy, camera : Camera3D, textureRatioX : Number, textureRatioY : Number) : void
		{
			super.activate(stage3DProxy, camera, textureRatioX, textureRatioY);

			stage3DProxy.setTextureAt(0, _cubeTexture.getTextureForStage3D(stage3DProxy));
		}
	}
}