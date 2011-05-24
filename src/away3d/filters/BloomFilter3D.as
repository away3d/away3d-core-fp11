package away3d.filters{
	import away3d.cameras.Camera3D;
	import away3d.containers.View3D;
	import away3d.debug.Debug;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;

	public class BloomFilter3D extends Filter3DBase
	{
		private var _brightpassProgram3D : Program3D;
		private var _blurProgram3D : Program3D;
		private var _compositeProgram3D : Program3D;
		private var _blurX : uint;
		private var _blurY : uint;
		private var _stepX : Number = 1;
		private var _stepY : Number = 1;
		private var _blurData : Vector.<Number>;
		private var _brightPassData : Vector.<Number>;
		private var _numSamples : uint;
		private var _brightPassTexture : Texture;
		private var _blurTexture : Texture;
		private var _brightWidth : int = -1;
		private var _brightHeight : int = -1;
		private var _threshold : Number;
		private var _exposure : Number;
		private var _quality : int;

		public function BloomFilter3D(blurX : uint = 15, blurY : uint = 15, threshold : Number = .75, exposure : Number = 3, quality : int = 1)
		{
			super(false);
			_blurX = blurX;
			_blurY = blurY;
			_stepX = _blurX > 8? _blurX/8 : 1;
			_stepY = _blurY > 8? _blurY/8 : 1;
			_threshold = threshold;
			_exposure = exposure;
			if (quality > 4) quality = 4;
			else if (quality < 0) quality = 0;
			_quality = quality;
			_blurData = Vector.<Number>([0, 0, 0, 1, 0, 0, 0, 0]);
			_brightPassData = Vector.<Number>([threshold, 1/(1-threshold), 0, 0]);
		}

		public function get blurX() : uint
		{
			return _blurX;
		}

		public function set blurX(value : uint) : void
		{
			invalidateBlurProgram();
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
			invalidateBlurProgram();
			_blurY = value;
			if (_blurY > 7) _stepY = _blurY/7;
			else _stepY = 1;
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

		public function get exposure() : Number
		{
			return _exposure;
		}

		public function set exposure(value : Number) : void
		{
			_exposure = value;
			_blurData[2] = value/_numSamples;
		}

		private function invalidateBlurProgram() : void
		{
			if (_blurProgram3D) {
				_blurProgram3D.dispose();
				_blurProgram3D = null;
			}
		}

		override public function render(context : Context3D, target : Texture, camera : Camera3D, depthRender : Texture = null) : void
		{
			var invW : Number = 1/_textureWidth;
			var invH : Number = 1/_textureHeight;

			super.render(context, target, camera);

			_blurData[0] = _blurX*.5*invW;
			_blurData[1] = _blurY*.5*invH;
			_blurData[4] = _stepX*invW;
			_blurData[5] = _stepY*invH;

			if (!_blurProgram3D) initPrograms(context);

			context.setRenderToTexture(_brightPassTexture, false, 0, 0);
			context.clear(0.0, 0.0, 0.0, 1.0);
			context.setVertexBufferAt(0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			context.setVertexBufferAt(1, _vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
			context.setProgram(_brightpassProgram3D);
			context.setTextureAt(0, _inputTexture);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _brightPassData, 1);
			context.drawTriangles(_indexBuffer, 0, 2);


			context.setRenderToTexture(_blurTexture, false, 0, 0);
			context.setProgram(_blurProgram3D);
			context.setTextureAt(0, _brightPassTexture);
			context.clear(0.0, 0.0, 0.0, 1.0);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _blurData, 2);
			context.drawTriangles(_indexBuffer, 0, 2);

			if (target)
				context.setRenderToTexture(target, false, 0, 0);
			else
				context.setRenderToBackBuffer();

			context.setProgram(_compositeProgram3D);
			context.setTextureAt(0, _blurTexture);
			context.setTextureAt(1, _inputTexture);
			context.clear(0.0, 0.0, 0.0, 1.0);
			context.drawTriangles(_indexBuffer, 0, 2);


			context.setTextureAt(0, null);
			context.setTextureAt(1, null);
			context.setVertexBufferAt(0, null);
			context.setVertexBufferAt(1, null);
		}

		override protected function initTextures(context : Context3D, view : View3D) : void
		{
			var w : int;
			var h : int;

			super.initTextures(context, view);

			w = _textureWidth >> (4-_quality);
			h = _textureHeight >> (4-_quality);
			if (w < 1) w = 1;
			if (h < 1) h = 1;

			if (w == _brightWidth && h == _brightHeight) return;

			if (_brightPassTexture) {
				_brightPassTexture.dispose();
				_blurTexture.dispose();
			}

			_brightPassTexture = context.createTexture(w, h, Context3DTextureFormat.BGRA, true);
			_blurTexture = context.createTexture(w, h, Context3DTextureFormat.BGRA, true);

			_brightWidth = w;
			_brightHeight = h;
		}

		private function initPrograms(context : Context3D) : void
		{
			_blurProgram3D = context.createProgram();
			_blurProgram3D.upload(	new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, getVertexCode()),
									new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, getBlurFragmentCode())
								);
			_brightpassProgram3D = context.createProgram();
			_brightpassProgram3D.upload(	new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, getVertexCode()),
											new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, getBrightPassFragmentCode())
										);
			_compositeProgram3D = context.createProgram();
			_compositeProgram3D.upload(	new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, getVertexCode()),
										new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, getCompositeFragmentCode())
										);
		}

		protected function getVertexCode() : String
		{
			return 	"mov op, va0\n"+
					"mov v0, va1";
		}


		protected function getBlurFragmentCode() : String
		{
			var code : String;

			code = 		"mov ft0, v0	\n" +
						"sub ft0.y, v0.y, fc0.y\n";

			for (var y : Number = 0; y <= _blurY; y += _stepY) {
				if (y > 0) code += "sub ft0.x, v0.x, fc0.x\n";
				for (var x : Number = 0; x <= _blurX; x += _stepX) {
					++_numSamples;
					if (x == 0 && y == 0) {
						code += "tex ft1, ft0, fs0 <2d,linear,clamp>\n";
					}
					else
						code += "tex ft2, ft0, fs0 <2d,linear,clamp>\n" +
								"add ft1, ft1, ft2 \n";

					if (x < _blurX)
						code += "add ft0.x, ft0.x, fc1.x	\n";
				}
				if (y < _blurY) code += "add ft0.y, ft0.y, fc1.y	\n";
			}

			code += "mul oc, ft1, fc0.z				\n";
			_blurData[2] = _exposure/_numSamples;

			return code;
		}

		private function getBrightPassFragmentCode() : String
		{
			var code : String;

			code = 	"tex ft0, v0, fs0 <2d,linear,clamp>	\n" +
					// maybe there's a more weighted by to calculate brightness?
					"dp3 ft1.x, ft0.xyz, ft0.xyz	\n" +
					"sqt ft1.x, ft1.x				\n" +
//					"sge ft1.y, ft1.x, fc0.x		\n" +
					"sub ft1.y, ft1.x, fc0.x		\n" +
					"mul ft1.y, ft1.y, fc0.y		\n" +
					"sat ft1.y, ft1.y				\n" +
					"mul ft0.xyz, ft0.xyz, ft1.y	\n" +
					"mov oc, ft0						\n";

			return code;
		}

		private function getCompositeFragmentCode() : String
		{
			var code : String;

			code = 	"tex ft0, v0, fs0 <2d,linear,clamp>	\n" +
					"tex ft1, v0, fs1 <2d,linear,clamp>	\n" +
					"add oc, ft0, ft1				\n";
//			code +=	"mov oc, ft0					\n";
			return code;
		}

	}
}