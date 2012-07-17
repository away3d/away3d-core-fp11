package away3d.filters.tasks
{
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;

	import flash.display3D.Context3DProgramType;
	import flash.display3D.textures.Texture;

	public class Filter3DVBlurTask extends Filter3DTaskBase
	{
		private static var MAX_AUTO_SAMPLES : int = 15;
		private var _amount : uint;
		private var _data : Vector.<Number>;
		private var _stepSize : int = 1;
		private var _realStepSize : Number;

		/**
		 *
		 * @param amount
		 * @param stepSize The distance between samples. Set to -1 to autodetect with acceptable quality.
		 */
		public function Filter3DVBlurTask(amount : uint, stepSize : int = -1)
		{
			super();
			_amount = amount;
			_data = Vector.<Number>([0, 0, 0, 1]);
			this.stepSize = stepSize;
		}

		public function get amount() : uint
		{
			return _amount;
		}

		public function set amount(value : uint) : void
		{
			if (value == _amount) return;
			_amount = value;

			invalidateProgram3D();
			updateBlurData();
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

		override protected function getFragmentCode() : String
		{
			var code : String;
			var numSamples : int = 1;

			code = 		"mov ft0, v0	\n" +
						"sub ft0.y, v0.y, fc0.x\n";

			code += "tex ft1, ft0, fs0 <2d,nearest,clamp>\n";

			for (var x : Number = _realStepSize; x <= _amount; x += _realStepSize) {
				code += "add ft0.y, ft0.y, fc0.y	\n";
				code += "tex ft2, ft0, fs0 <2d,nearest,clamp>\n" +
						"add ft1, ft1, ft2 \n";
				++numSamples;
			}

			code += "mul oc, ft1, fc0.z";

			_data[2] = 1/numSamples;

			return code;
		}

		override public function activate(stage3DProxy : Stage3DProxy, camera3D : Camera3D, depthTexture : Texture) : void
		{
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 1);
		}

		override protected function updateTextures(stage : Stage3DProxy) : void
		{
			super.updateTextures(stage);

			updateBlurData();
		}

		private function updateBlurData() : void
		{
			// todo: must be normalized using view size ratio instead of texture
			var invH : Number = 1/_textureHeight;

			_data[0] = _amount*.5*invH;
			_data[1] = _realStepSize*invH;
		}

		private function calculateStepSize() : void
		{
				_realStepSize = _stepSize > 0? 				_stepSize :
								_amount > MAX_AUTO_SAMPLES? _amount/MAX_AUTO_SAMPLES :
															1;
		}
	}
}
