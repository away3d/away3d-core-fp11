package away3d.filters.tasks
{
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;

	import flash.display3D.Context3DProgramType;

	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;

	public class Filter3DCompositeTask extends Filter3DTaskBase
	{
		private var _data : Vector.<Number>;
		private var _overlayTexture : TextureBase;
		private var _blendMode : String;

		public function Filter3DCompositeTask(blendMode : String, exposure : Number = 1)
		{
			super();
			_data = Vector.<Number>([ exposure, 0, 0, 0 ]);
			_blendMode = blendMode;
		}

		public function get overlayTexture() : TextureBase
		{
			return _overlayTexture;
		}

		public function set overlayTexture(value : TextureBase) : void
		{
			_overlayTexture = value;
		}

		public function get exposure() : Number
		{
			return _data[0];
		}

		public function set exposure(value : Number) : void
		{
			_data[0] = value;
		}


		override protected function getFragmentCode() : String
		{
			var code : String;
			var op : String;
			code = 	"tex ft0, v0, fs0 <2d,linear,clamp>	\n" +
					"tex ft1, v0, fs1 <2d,linear,clamp>	\n" +
					"mul ft1, ft1, fc0.x				\n";
			switch (_blendMode) {
				case "multiply":
					op = "mul";
					break;
				case "add":
					op = "add";
					break;
				case "subtract":
					op = "sub";
					break;
				case "normal":
						// for debugging purposes
					op = "mov";
					break;
				default:
					throw new Error("Unknown blend mode");
			}
			if (op != "mov")
				code += op + " oc, ft0, ft1					\n";
			else
				code += "mov oc, ft0						\n";
			return code;
		}

		override public function activate(stage3DProxy : Stage3DProxy, camera3D : Camera3D, depthTexture : Texture) : void
		{
			// TODO: not used
			camera3D = camera3D;
			depthTexture =  depthTexture;
			 
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 1);
			stage3DProxy.setTextureAt(1, _overlayTexture);
		}

		override public function deactivate(stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy.setTextureAt(1, null);
		}
	}
}
