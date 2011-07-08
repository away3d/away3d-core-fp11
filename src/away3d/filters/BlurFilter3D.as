package away3d.filters{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.debug.Debug;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;

	use namespace arcane;

	public class BlurFilter3D extends Filter3DBase
	{
		private var _program3d : Program3D;
		private var _blurX : uint;
		private var _blurY : uint;
		private var _data : Vector.<Number>;
		private var _stepX : Number = 1;
		private var _stepY : Number = 1;
		private var _numSamples : uint;

		public function BlurFilter3D(blurX : uint = 3, blurY : uint = 3)
		{
			super(false);
			_blurX = blurX;
			_blurY = blurY;
			if (_blurX > 7) _stepX = _blurX/7;
			if (_blurY > 7) _stepY = _blurY/7;
			_data = Vector.<Number>([0, 0, 0, 1, 0, 0, 0, 0]);
		}

		public function get blurX() : uint
		{
			return _blurX;
		}

		public function set blurX(value : uint) : void
		{
			invalidateProgram();
			_blurX = value;
			if (_blurX > 7) _stepX = _blurX/7;
			else _stepX = 1;
		}

		public function get blurY() : uint
		{
			return _blurY;
		}

		public function set blurY(value : uint) : void
		{
			invalidateProgram();
			_blurY = value;
			if (_blurY > 7) _stepY = _blurY/7;
			else _stepY = 1;
		}

		private function invalidateProgram() : void
		{
			if (_program3d) {
				_program3d.dispose();
				_program3d = null;
			}
		}

		override public function render(stage3DProxy : Stage3DProxy, target : Texture, camera : Camera3D, depthRender : Texture = null) : void
		{
			var context : Context3D =  stage3DProxy._context3D;
			var invW : Number = 1/_textureWidth;
			var invH : Number = 1/_textureHeight;

			super.render(stage3DProxy, target, camera);

			_data[0] = _blurX*.5*invW;
			_data[1] = _blurY*.5*invH;
			_data[4] = _stepX*invW;
			_data[5] = _stepY*invH;

			if (!_program3d) initProgram(context);

			if (target)
				context.setRenderToTexture(target, false, 0, 0);
			else
				context.setRenderToBackBuffer();

			stage3DProxy.setProgram(_program3d);
			context.clear(0.0, 0.0, 0.0, 1.0);
			context.setVertexBufferAt(0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			context.setVertexBufferAt(1, _vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
			stage3DProxy.setTextureAt(0, _inputTexture);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 2);
			context.drawTriangles(_indexBuffer, 0, 2);
			stage3DProxy.setTextureAt(0, null);
			stage3DProxy.setSimpleVertexBuffer(0, null);
			stage3DProxy.setSimpleVertexBuffer(1, null);
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
	}
}
