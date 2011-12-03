package away3d.filters.tasks
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.textures.Texture;

	use namespace arcane;

	public class Filter3DDepthOfFFieldTask extends Filter3DTaskBase
	{
		private static const MAX_BLUR : int = 6;
		private var _maxBlurX : uint;
		private var _maxBlurY : uint;
		private var _data : Vector.<Number>;
		private var _stepX : Number = 1;
		private var _stepY : Number = 1;
		private var _numSamples : uint;
		private var _focusDistance : Number;
		private var _range : Number = 1000;

		public function Filter3DDepthOfFFieldTask(maxBlurX : uint = 3, maxBlurY : uint = 3)
		{
			super(true);
			_maxBlurX = maxBlurX;
			_maxBlurY = maxBlurY;
			_data = Vector.<Number>([0, 0, 0, _focusDistance, 0, 0, 0, 0, _range, 0, 0, 0, 1.0, 1 / 255.0, 1 / 65025.0, 1 / 16581375.0]);
		}

		public function get range() : Number
		{
			return _range;
		}

		public function set range(value : Number) : void
		{
			_range = value;
			_data[8] = value;
		}


		public function get focusDistance() : Number
		{
			return _focusDistance;
		}

		public function set focusDistance(value : Number) : void
		{
			_data[3] = _focusDistance = value;
		}

		public function get maxBlurX() : uint
		{
			return _maxBlurX;
		}

		public function set maxBlurX(value : uint) : void
		{
			if (_maxBlurX == value) return;
			_maxBlurX = value;

			if (_maxBlurX > MAX_BLUR) _stepX = _maxBlurX / MAX_BLUR;
			else _stepX = 1;

			invalidateProgram3D();
			updateBlurData();
		}

		public function get maxBlurY() : uint
		{
			return _maxBlurY;
		}

		public function set maxBlurY(value : uint) : void
		{
			if (_maxBlurY == value) return;
			_maxBlurY = value;

			invalidateProgram3D();
			updateBlurData();
		}

		override protected function getFragmentCode() : String
		{
			var code : String;

			_numSamples = 0;

			// sample depth, unpack & get blur amount (offset point + step size)
			code = "tex ft0, v0, fs1 <2d, nearest>	\n" +
					"dp4 ft1.z, ft0, fc3				\n" +
					"sub ft1.z, ft1.z, fc1.z			\n" + // d = d - f
					"div ft1.z, fc1.w, ft1.z			\n" + // screenZ = -n*f/(d-f)
					"sub ft1.z, ft1.z, fc0.w			\n" + // screenZ - dist
					"div ft1.z, ft1.z, fc2.x			\n" + // (screenZ - dist)/range

					"abs ft1.z, ft1.z					\n" + // abs(screenZ - dist)/range
					"sat ft1.z, ft1.z					\n" + // sat(abs(screenZ - dist)/range)
					"mul ft6.xy, ft1.z, fc0.xy			\n" +
					"mul ft7.xy, ft1.z, fc1.xy			\n";


			code += "mov ft0, v0	\n" +
					"sub ft0.y, v0.y, ft6.y\n";

			for (var y : Number = 0; y <= _maxBlurY; y += _stepY) {
				if (y > 0) code += "sub ft0.x, v0.x, ft6.x\n";
				for (var x : Number = 0; x <= _maxBlurX; x += _stepX) {
					++_numSamples;
					if (x == 0 && y == 0)
						code += "tex ft1, ft0, fs0 <2d,linear,clamp>\n";
					else
						code += "tex ft2, ft0, fs0 <2d,linear,clamp>\n" +
								"add ft1, ft1, ft2 \n";

					if (x < _maxBlurX) code += "add ft0.x, ft0.x, ft7.x	\n";
				}
				if (y < _maxBlurY) code += "add ft0.y, ft0.y, ft7.y		\n";
			}

			code += "mul oc, ft1, fc0.z";

			_data[2] = 1 / _numSamples;

			return code;
		}

		override public function activate(stage3DProxy : Stage3DProxy, camera : Camera3D, depthTexture : Texture) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			var n : Number = camera.lens.near;
			var f : Number = camera.lens.far;

			_data[6] = f / (f - n);
			_data[7] = -n * _data[6];

			stage3DProxy.setTextureAt(1, depthTexture);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 4);
		}

		override public function deactivate(stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy.setTextureAt(1, null);
		}

		override protected function updateTextures(stage : Stage3DProxy) : void
		{
			super.updateTextures(stage);

			updateBlurData();
		}

		private function updateBlurData() : void
		{
			// todo: replace with view width once texture rendering is scissored?
			var invW : Number = 1 / _textureWidth;
			var invH : Number = 1 / _textureHeight;

			if (_maxBlurX > MAX_BLUR) _stepX = _maxBlurX / MAX_BLUR;
			else _stepX = 1;

			if (_maxBlurY > MAX_BLUR) _stepY = _maxBlurY / MAX_BLUR;
			else _stepY = 1;


			_data[0] = _maxBlurX * .5 * invW;
			_data[1] = _maxBlurY * .5 * invH;
			_data[4] = _stepX * invW;
			_data[5] = _stepY * invH;
		}
	}
}
