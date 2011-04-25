package away3d.filters{
	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Object3D;
	import away3d.debug.Debug;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	import flash.geom.Vector3D;

	public class DepthOfFieldFilter3D extends Filter3DBase
	{
		private var _program3d : Program3D;
		private var _maxBlurX : uint;
		private var _maxBlurY : uint;
		private var _data : Vector.<Number>;
		private var _stepX : Number = 1;
		private var _stepY : Number = 1;
		private var _numSamples : uint;
		private var _focusDistance : Number = 1;
		private var _focusTarget : ObjectContainer3D;
		private var _range : Number = 1000;

		public function DepthOfFieldFilter3D(maxBlurX : uint = 3, maxBlurY : uint = 3)
		{
			super(true);
			_maxBlurX = maxBlurX;
			_maxBlurY = maxBlurY;
			if (_maxBlurX > 7) _stepX = _maxBlurX/7;
			if (_maxBlurY > 7) _stepY = _maxBlurY/7;
			_data = Vector.<Number>([0, 0, 0, _focusDistance, 0, 0, 0, 0, _range, 0, 0, 0, 1.0, 1/255.0, 1/65025.0, 1/16581375.0]);
		}

		public function get focusTarget() : ObjectContainer3D
		{
			return _focusTarget;
		}

		public function set focusTarget(value : ObjectContainer3D) : void
		{
			_focusTarget = value;
		}

		public function get focusDistance() : Number
		{
			return _focusDistance;
		}

		public function set focusDistance(value : Number) : void
		{
			_focusDistance = value;
			_data[3] = value;
		}

		public function get range() : Number
		{
			return _range;
		}

		public function set range(value : Number) : void
		{
			_range = value;
			_data[8] = value
		}

// todo: provide focus on method

		public function get maxBlurX() : uint
		{
			return _maxBlurX;
		}

		public function set maxBlurX(value : uint) : void
		{
			invalidateProgram();
			_maxBlurX = value;
			if (_maxBlurX > 7) _stepX = _maxBlurX/7;
			else _stepX = 1;
		}

		public function get maxBlurY() : uint
		{
			return _maxBlurY;
		}

		public function set maxBlurY(value : uint) : void
		{
			invalidateProgram();
			_maxBlurY = value;
			if (_maxBlurY > 7) _stepY = _maxBlurY/7;
			else _stepY = 1;
		}

		private function invalidateProgram() : void
		{
			if (_program3d) {
				_program3d.dispose();
				_program3d = null;
			}
		}

		override public function render(context : Context3D, target : Texture, camera : Camera3D, depthRender : Texture = null) : void
		{
			var invW : Number = 1/_textureWidth;
			var invH : Number = 1/_textureHeight;
			var n : Number = camera.lens.near;
			var f : Number = camera.lens.far;

			super.render(context, target, camera);

			if (_focusTarget) {
				updateFocus(camera);
			}

			_data[0] = _maxBlurX*.5*invW;
			_data[1] = _maxBlurY*.5*invH;
			_data[4] = _stepX*invW;
			_data[5] = _stepY*invH;
			_data[6] = f/(f-n);
			_data[7] = -n*_data[6];

			if (!_program3d) initProgram(context);

			if (target)
				context.setRenderToTexture(target, false, 0, 0);
			else
				context.setRenderToBackBuffer();

			context.setProgram(_program3d);
			context.clear(0.0, 0.0, 0.0, 1.0);
			context.setVertexBufferAt(0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			context.setVertexBufferAt(1, _vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
			context.setTextureAt(0, _inputTexture);
			context.setTextureAt(1, depthRender);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 4);
			context.drawTriangles(_indexBuffer, 0, 2);
			context.setTextureAt(0, null);
			context.setTextureAt(1, null);
			context.setVertexBufferAt(0, null);
			context.setVertexBufferAt(1, null);
		}

		private function updateFocus(camera : Camera3D) : void
		{
			var target : Vector3D = camera.inverseSceneTransform.transformVector(_focusTarget.scenePosition);
			_data[3] = _focusDistance = target.z;
		}

		private function initProgram(context : Context3D) : void
		{
			_program3d = context.createProgram();
			_program3d.upload(	new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, getVertexCode()),
								new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, getFragmentCode())
							);
		}


		protected function getVertexCode() : String
		{
			return 	"mov op, va0\n"+
					"mov v0, va1";
		}

		protected function getFragmentCode() : String
		{
			var code : String;

			_numSamples = 0;

			// sample depth, unpack & get blur amount (offset point + step size)
			code = "tex ft0, v0, fs1 <2d, nearest>	\n" +
					"dp4 ft1.z, ft0, fc3				\n" +
					"sub ft1.z, ft1.z, fc1.z			\n" +	// d = d - f
					"div ft1.z, fc1.w, ft1.z			\n" +	// screenZ = -n*f/(d-f)
					"sub ft1.z, ft1.z, fc0.w			\n" +	// screenZ - dist
					"div ft1.z, ft1.z, fc2.x			\n" +	// (screenZ - dist)/range

					"abs ft1.z, ft1.z					\n" +	// abs(screenZ - dist)/range
					"sat ft1.z, ft1.z					\n" +	// sat(abs(screenZ - dist)/range)
					"mul ft6.xy, ft1.z, fc0.xy			\n" +
					"mul ft7.xy, ft1.z, fc1.xy			\n";


			code += 	"mov ft0, v0	\n" +
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

			_data[2] = 1/_numSamples;

			return code;
		}
	}
}
