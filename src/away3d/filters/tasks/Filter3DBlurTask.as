package away3d.filters.tasks
{
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;

	import flash.display3D.Context3DProgramType;

	import flash.display3D.textures.Texture;

	public class Filter3DBlurTask extends Filter3DTaskBase
	{
		private static const MAX_BLUR : int = 6;
		private var _blurX : uint;
		private var _blurY : uint;
		private var _data : Vector.<Number>;
		private var _stepX : Number = 1;
		private var _stepY : Number = 1;
		private var _numSamples : uint;

		public function Filter3DBlurTask(blurX : uint = 3, blurY : uint = 3)
		{
			super();
			_blurX = blurX;
			_blurY = blurY;
			_data = Vector.<Number>([0, 0, 0, 1, 0, 0, 0, 0]);
		}

		public function get blurX() : uint
		{
			return _blurX;
		}

		public function set blurX(value : uint) : void
		{
			_blurX = value;

			if (_blurX > MAX_BLUR) _stepX = _blurX/MAX_BLUR;
			else _stepX = 1;

			invalidateProgram3D();
			updateBlurData();
		}

		public function get blurY() : uint
		{
			return _blurY;
		}

		public function set blurY(value : uint) : void
		{
			_blurY = value;

			invalidateProgram3D();
			updateBlurData();
		}

		override protected function getFragmentCode() : String
		{
			var code : String;

			_numSamples = 0;

			code = 		"mov ft0, v0	\n" +
						"sub ft0.y, v0.y, fc0.y\n";

			for (var y : Number = 0; y <= _blurY; y += _stepY) {
				if (y > 0) code += "sub ft0.x, v0.x, fc0.x\n";
				for (var x : Number = 0; x <= _blurX; x += _stepX) {
					++_numSamples;
					if (x == 0 && y == 0)
						code += "tex ft1, ft0, fs0 <2d,nearest,clamp>\n";
					else
						code += "tex ft2, ft0, fs0 <2d,nearest,clamp>\n" +
								"add ft1, ft1, ft2 \n";

					if (x < _blurX)
						code += "add ft0.x, ft0.x, fc1.x	\n";
				}
				if (y < _blurY) code += "add ft0.y, ft0.y, fc1.y	\n";
			}

			code += "mul oc, ft1, fc0.z";

			_data[2] = 1/_numSamples;

			return code;
		}

		override public function activate(stage3DProxy : Stage3DProxy, camera3D : Camera3D, depthTexture : Texture) : void
		{
			// TODO: not used
			camera3D = camera3D; 
			depthTexture = depthTexture;
			
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 2);
		}

		override protected function updateTextures(stage : Stage3DProxy) : void
		{
			super.updateTextures(stage);

			updateBlurData();
		}

		private function updateBlurData() : void
		{
			// todo: must be normalized using view size ratio
			var invW : Number = 1/_textureWidth;
			var invH : Number = 1/_textureHeight;

			if (_blurX > MAX_BLUR) _stepX = _blurX/MAX_BLUR;
			else _stepX = 1;

			if (_blurY > MAX_BLUR) _stepY = _blurY/MAX_BLUR;
			else _stepY = 1;

			_data[0] = _blurX*.5*invW;
			_data[1] = _blurY*.5*invH;
			_data[4] = _stepX*invW;
			_data[5] = _stepY*invH;
		}
	}
}
