package away3d.core.render
{
	import away3d.core.managers.Stage3DProxy;
	import away3d.debug.Debug;
	import away3d.textures.Texture2DBase;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;

	public class BackgroundImageRenderer
	{
		private var _program3d : Program3D;
		private var _texture : Texture2DBase;
		private var _indexBuffer : IndexBuffer3D;
		private var _vertexBuffer : VertexBuffer3D;
		private var _stage3DProxy : Stage3DProxy;

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
		}

		private function getVertexCode() : String
		{
			return	 "mov op, va0\n" +
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
		}

		public function render() : void
		{
			var context : Context3D = _stage3DProxy.context3D;

			if (!context) return;

			if (!_vertexBuffer) initBuffers(context);

			_stage3DProxy.setProgram(_program3d);
			_stage3DProxy.setTextureAt(0, _texture.getTextureForStage3D(_stage3DProxy));
			context.setVertexBufferAt(0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			context.setVertexBufferAt(1, _vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
			context.drawTriangles(_indexBuffer, 0, 2);
			_stage3DProxy.setSimpleVertexBuffer(0, null, null, 0);
			_stage3DProxy.setSimpleVertexBuffer(1, null, null, 0);
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

			_vertexBuffer.uploadFromVector(Vector.<Number>([	-1, -1, 0, 1,
																1, -1, 1, 1,
																1,  1, 1, 0,
																-1,  1, 0, 0
															]), 0, 4);
		}

		public function get texture() : Texture2DBase
		{
			return _texture;
		}

		public function set texture(value : Texture2DBase) : void
		{
			_texture = value;
		}
	}
}
