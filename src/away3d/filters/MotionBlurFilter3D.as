package away3d.filters{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.containers.View3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.debug.Debug;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;

	use namespace arcane;

	public class MotionBlurFilter3D extends Filter3DBase
	{
		private var _blurFilter : Program3D;
		private var _copyProgram3D : Program3D;
		private var _data : Vector.<Number>;
		private var _strength : Number;
		private var _accumTexture1 : Texture;
		private var _accumTexture2 : Texture;
		private var _sourceAccum : Texture;
		private var _dstAccum : Texture;

		public function MotionBlurFilter3D(strength : Number = .65)
		{
			super(false);
			_data = new Vector.<Number>(4, true);
			this.strength = strength;
		}

		override protected function initTextures(context : Context3D, view : View3D) : void
		{
			var w : int = _textureWidth;
			var h : int = _textureHeight;
			var dummy : BitmapData;

			super.initTextures(context, view);

			if (w == _textureWidth && h == _textureHeight) return;

			if (_accumTexture1) {
				_accumTexture1.dispose();
				_accumTexture2.dispose();
			}
			_accumTexture1 = context.createTexture(_textureWidth, _textureHeight, Context3DTextureFormat.BGRA, true);
			_accumTexture2 = context.createTexture(_textureWidth, _textureHeight, Context3DTextureFormat.BGRA, true);
			_sourceAccum = _accumTexture1;
			_dstAccum = _accumTexture2;

			dummy = new BitmapData(_textureWidth, _textureHeight, false, 0);
			_accumTexture1.uploadFromBitmapData(dummy);
			_accumTexture2.uploadFromBitmapData(dummy);
			dummy.dispose();
		}

		public function get strength() : Number
		{
			return _strength;
		}

		public function set strength(value : Number) : void
		{
			_strength = value;
			_data[0] = _strength;
		}

		override public function render(stage3DProxy : Stage3DProxy, target : Texture, camera : Camera3D, depthRender : Texture = null) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			super.render(stage3DProxy, target, camera);

			if (!_blurFilter) initPrograms(context);

			context.setRenderToTexture(_dstAccum, false, 0, 0);
			stage3DProxy.setProgram(_blurFilter);
			context.clear(0.0, 0.0, 0.0, 1.0);
			context.setVertexBufferAt(0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			context.setVertexBufferAt(1, _vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
			stage3DProxy.setTextureAt(0, _inputTexture);
			stage3DProxy.setTextureAt(1, _sourceAccum);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 1);
			context.drawTriangles(_indexBuffer, 0, 2);

			var temp : Texture = _dstAccum;
			_dstAccum = _sourceAccum;
			_sourceAccum = temp;

			if (target)
				context.setRenderToTexture(target, false, 0, 0);
			else
				context.setRenderToBackBuffer();

			stage3DProxy.setProgram(_copyProgram3D);
			context.clear(0.0, 0.0, 0.0, 1.0);
			stage3DProxy.setTextureAt(0, _sourceAccum);
			stage3DProxy.setTextureAt(1, null);
			context.drawTriangles(_indexBuffer, 0, 2);

			stage3DProxy.setTextureAt(0, null);
			stage3DProxy.setSimpleVertexBuffer(0, null);
			stage3DProxy.setSimpleVertexBuffer(1, null);
		}

		private function initPrograms(context : Context3D) : void
		{
			_blurFilter = context.createProgram();
			_blurFilter.upload(	new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, getVertexCode()),
								new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, getBlurFragmentCode())
							);
			_copyProgram3D = context.createProgram();
			_copyProgram3D.upload(	new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, getVertexCode()),
								new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, getCopyFragmentCode())
							);
		}


		protected function getVertexCode() : String
		{
			return 	"mov op, va0\n"+
					"mov v0, va1";
		}

		protected function getBlurFragmentCode() : String
		{
			var code : String = "";

			code += "tex ft0, v0, fs0 <2d,nearest>	\n";
			code += "tex ft1, v0, fs1 <2d,nearest>	\n";
			code += "sub ft1, ft1, ft0				\n";
			code += "mul ft1, ft1, fc0.x			\n";
			code += "add oc, ft1, ft0				\n";

			return code;
		}

		protected function getCopyFragmentCode() : String
		{
			var code : String = "";

			code += "tex oc, v0, fs0 <2d,nearest,clamp>\n";

			return code;
		}
	}
}
