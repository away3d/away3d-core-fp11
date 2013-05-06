package away3d.filters.tasks
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.textures.Texture;

	use namespace arcane;

	public class Filter3DHDepthOfFFieldTask extends Filter3DTaskBase
	{
		private static var MAX_AUTO_SAMPLES : int = 10;
		private var _maxBlur : uint;
		private var _data : Vector.<Number>;
		private var _focusDistance : Number;
		private var _range : Number = 1000;
		private var _stepSize : int;
		private var _realStepSize : Number;

		/**
		 * Creates a new Filter3DHDepthOfFFieldTask
		 * @param amount The maximum amount of blur to apply in pixels at the most out-of-focus areas
		 * @param stepSize The distance between samples. Set to -1 to autodetect with acceptable quality.
		 */
		public function Filter3DHDepthOfFFieldTask(maxBlur : uint, stepSize : int = -1)
		{
			super(true);
			_maxBlur = maxBlur;
			_data = Vector.<Number>([0, 0, 0, _focusDistance, 0, 0, 0, 0, _range, 0, 0, 0, 1.0, 1 / 255.0, 1 / 65025.0, 1 / 16581375.0]);
			this.stepSize = stepSize;
		}

		public function get stepSize() : int
		{
			return _stepSize;
		}

		public function set stepSize(value : int) : void
		{
			if (value == _stepSize) return;
			_stepSize = value;
			calculateStepSize();
			invalidateProgram3D();
			updateBlurData();
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

		public function get maxBlur() : uint
		{
			return _maxBlur;
		}

		public function set maxBlur(value : uint) : void
		{
			if (_maxBlur == value) return;
			_maxBlur = value;

			invalidateProgram3D();
			updateBlurData();
			calculateStepSize();
		}

		override protected function getFragmentCode() : String
		{
			var code : String;
			var numSamples : uint = 1;

			// sample depth, unpack & get blur amount (offset point + step size)
			code = "tex ft0, v0, fs1 <2d, nearest>	\n" +
					"dp4 ft1.z, ft0, fc3				\n" +
					"sub ft1.z, ft1.z, fc1.z			\n" + // d = d - f
					"rcp ft1.z, ft1.z			\n" + // screenZ = -n*f/(d-f)
					"mul ft1.z, fc1.w, ft1.z			\n" + // screenZ = -n*f/(d-f)
					"sub ft1.z, ft1.z, fc0.w			\n" + // screenZ - dist
					"mul ft1.z, ft1.z, fc2.x			\n" + // (screenZ - dist)/range

					"abs ft1.z, ft1.z					\n" + // abs(screenZ - dist)/range
					"sat ft1.z, ft1.z					\n" + // sat(abs(screenZ - dist)/range)
					"mul ft6.xy, ft1.z, fc0.xy			\n";


			code += "mov ft0, v0	\n" +
					"sub ft0.x, ft0.x, ft6.x\n" +
					"tex ft1, ft0, fs0 <2d,linear,clamp>\n";

			for (var x : Number = _realStepSize; x <= _maxBlur; x += _realStepSize) {
				code += "add ft0.x, ft0.x, ft6.y	\n" +
						"tex ft2, ft0, fs0 <2d,linear,clamp>\n" +
						"add ft1, ft1, ft2 \n";

				++numSamples;
			}

			code += "mul oc, ft1, fc0.z";

			_data[2] = 1 / numSamples;

			return code;
		}

		override public function activate(stage3DProxy : Stage3DProxy, camera : Camera3D, depthTexture : Texture) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			var n : Number = camera.lens.near;
			var f : Number = camera.lens.far;

			_data[6] = f / (f - n);
			_data[7] = -n * _data[6];

			context.setTextureAt(1, depthTexture);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 4);
		}

		override public function deactivate(stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy._context3D.setTextureAt(1, null);
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

			_data[0] = _maxBlur * .5 * invW;
			_data[1] = _realStepSize* invW;
		}

		private function calculateStepSize() : void
		{
			_realStepSize = _stepSize > 0? 				_stepSize :
							_maxBlur > MAX_AUTO_SAMPLES? _maxBlur/MAX_AUTO_SAMPLES :
							1;
		}
	}
}
