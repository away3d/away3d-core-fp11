package away3d.filters.tasks
{
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;

	import flash.display3D.Context3DProgramType;

	import flash.display3D.textures.Texture;

	public class Filter3DBrightPassTask extends Filter3DTaskBase
	{
		private var _brightPassData : Vector.<Number>;
		private var _threshold : Number;

		public function Filter3DBrightPassTask(threshold : Number = .75)
		{
			super();
			_threshold = threshold;
			_brightPassData = Vector.<Number>([threshold, 1/(1-threshold), 0, 0]);
		}

		public function get threshold() : Number
		{
			return _threshold;
		}

		public function set threshold(value : Number) : void
		{
			_threshold = value;
			_brightPassData[0] = value;
			_brightPassData[1] = 1/(1-value);
		}

		override protected function getFragmentCode() : String
		{
			return 	"tex ft0, v0, fs0 <2d,linear,clamp>	\n" +
					"dp3 ft1.x, ft0.xyz, ft0.xyz	\n" +
					"sqt ft1.x, ft1.x				\n" +
					"sub ft1.y, ft1.x, fc0.x		\n" +
					"mul ft1.y, ft1.y, fc0.y		\n" +
					"sat ft1.y, ft1.y				\n" +
					"mul ft0.xyz, ft0.xyz, ft1.y	\n" +
					"mov oc, ft0					\n";
		}

		override public function activate(stage3DProxy : Stage3DProxy, camera3D : Camera3D, depthTexture : Texture) : void
		{
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _brightPassData, 1);
		}
	}
}
