package away3d.materials.passes
{
	import away3d.animators.IAnimator;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.textures.CubeTextureBase;

	import flash.display3D.Context3D;

	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;

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

		override arcane function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, camera.viewProjection, true);
			renderable.activateVertexBuffer(0, stage3DProxy);
			context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(animationCode:String) : String
		{
			var format : String;
			switch (_cubeTexture.format) {
				case Context3DTextureFormat.COMPRESSED:
					format = "dxt1,";
					break;
				case "compressedAlpha":
					format ="dxt5,";
					break;
				default:
					format = "";
			}
			var mip : String = ",mipnone";
			if(_cubeTexture.hasMipMaps)
			{
				mip = ",miplinear";
			}
			return 	"tex ft0, v0, fs0 <cube,"+format+"linear,clamp"+mip+">	\n" +
					"mov oc, ft0							\n";
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy, camera : Camera3D, textureRatioX : Number, textureRatioY : Number) : void
		{
			super.activate(stage3DProxy, camera, textureRatioX, textureRatioY);

			stage3DProxy._context3D.setDepthTest(false, Context3DCompareMode.LESS);
			stage3DProxy.setTextureAt(0, _cubeTexture.getTextureForStage3D(stage3DProxy));
		}
	}
}
