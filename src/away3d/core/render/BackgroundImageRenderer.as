package away3d.core.render
{
	import away3d.core.managers.Stage3DProxy;
	import away3d.debug.Debug;
	import away3d.tools.utils.TextureUtils;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;

	public class BackgroundImageRenderer
	{
		private var _bitmapData : BitmapData;
		private var _program3d : Program3D;
		private var _texture : Texture;
		private var _texWidth : Number = -1;
		private var _texHeight : Number = -1;
		private var _indexBuffer : IndexBuffer3D;
		private var _vertexBuffer : VertexBuffer3D;
		private var _stage3DProxy : Stage3DProxy;
		private var _textureInvalid : Boolean = true;
		private var _fitToViewPort:Boolean = true;
		private var _viewWidth:Number;
		private var _viewHeight:Number;

		public function BackgroundImageRenderer(stage3DProxy : Stage3DProxy)
		{
			this.stage3DProxy = stage3DProxy;
		}

		public function get stage3DProxy() : Stage3DProxy
		{
			return _stage3DProxy;
		}

		public function set stage3DProxy(value : Stage3DProxy) : void
		{
			if (value == _stage3DProxy) return;
			_stage3DProxy = value;

			if (_vertexBuffer) {
				_vertexBuffer.dispose();
				_vertexBuffer = null;
				_program3d.dispose();
				_program3d = null;
				_indexBuffer.dispose();
				_indexBuffer = null;
			}

			if (_texture) {
				_texture.dispose();
				_texture = null;
				_textureInvalid = true;
			}

		}

		private function getVertexCode() : String
		{
			return 	"mov op, va0\n"+
					"mov v0, va1";
		}

		private function getFragmentCode() : String
		{
			return	"tex ft0, v0, fs0 <2d, linear>	\n" +
					"mov oc, ft0";
		}

		public function dispose() : void
		{
			if (_vertexBuffer) _vertexBuffer.dispose();
			if (_program3d) _program3d.dispose();
			if (_texture) _texture.dispose();
		}

		public function render() : void
		{
			var context : Context3D = _stage3DProxy.context3D;

			if (!context) return;

			if (!_vertexBuffer) initBuffers(context);
			if (_textureInvalid) updateTexture(context);

			_stage3DProxy.setProgram(_program3d);
			_stage3DProxy.setTextureAt(0, _texture);
			context.setVertexBufferAt(0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			context.setVertexBufferAt(1, _vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
			context.drawTriangles(_indexBuffer, 0, 2);
			_stage3DProxy.setSimpleVertexBuffer(0, null);
			_stage3DProxy.setSimpleVertexBuffer(1, null);
			_stage3DProxy.setTextureAt(0, null);
		}

		private function initBuffers(context : Context3D) : void
		{
			_vertexBuffer = context.createVertexBuffer(4, 4);
			_program3d = context.createProgram();
			_indexBuffer = context.createIndexBuffer(6);
			_indexBuffer.uploadFromVector(Vector.<uint>([2, 1, 0, 3, 2, 0]), 0, 6);
			_program3d.upload(	new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, getVertexCode()),
								new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, getFragmentCode())
							);
		}

		private function updateTexture(context : Context3D) : void
		{
			(_texture ||= context.createTexture(_texWidth, _texHeight, Context3DTextureFormat.BGRA, true)).uploadFromBitmapData(_bitmapData);

			var ratioX : Number = _bitmapData.width/_texWidth;
			var ratioY : Number = _bitmapData.height/_texHeight;
			var w:Number = _fitToViewPort ? 1 : _bitmapData.width / _viewWidth;
			var h:Number = _fitToViewPort ? 1 : _bitmapData.height / _viewHeight;
			_vertexBuffer.uploadFromVector(Vector.<Number>([	-w, -h,   0,      ratioY,
																 w, -h,   ratioX, ratioY,
																 w,  h,   ratioX, 0,
																-w,  h,   0,      0
														   ]), 0, 4);
		}

		public function get bitmapData() : BitmapData
		{
			return _bitmapData;
		}

		public function set bitmapData(value : BitmapData) : void
		{
			var w : Number = TextureUtils.getBestPowerOf2(value.width);
			var h : Number = TextureUtils.getBestPowerOf2(value.height);

			if (w != _texWidth || h != _texHeight) {
				if (_texture) {
					_texture.dispose();
					_texture = null;
				}
				_texWidth = w;
				_texHeight = h;
			}

			_textureInvalid = true;

			_bitmapData = value;
		}

		public function get viewWidth():Number
		{
			return _viewWidth;
		}

		public function set viewWidth(value:Number):void
		{
			_viewWidth = value;
		}

		public function get viewHeight():Number
		{
			return _viewHeight;
		}

		public function set viewHeight(value:Number):void
		{
			_viewHeight = value;
		}

		public function set fitToViewPort(value:Boolean):void
		{
			_fitToViewPort = value;
		}
	}
}
