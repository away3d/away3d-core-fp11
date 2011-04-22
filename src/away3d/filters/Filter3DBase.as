package away3d.filters
{
	import away3d.cameras.Camera3D;
	import away3d.containers.View3D;

//	import away3d.filters.Filter3DBase.requireDepthRender;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;

	public class Filter3DBase
	{
		protected var _inputTexture : Texture;
		private var _viewWidth : Number = -1;
		private var _viewHeight : Number = -1;
		private var _requireDepthBuffer : Boolean;
		protected var _textureWidth : int = -1;
		protected var _textureHeight : int = -1;
		protected var _vertexBuffer : VertexBuffer3D;	// contains the screen-tris	and uvs
		protected var _indexBuffer : IndexBuffer3D;

		public function Filter3DBase(requireDepthBuffer : Boolean)
		{
			_requireDepthBuffer = requireDepthBuffer;
		}

		public function get requireDepthRender() : Boolean
		{
			return _requireDepthBuffer;
		}

		public function getInputTexture(context : Context3D, view : View3D) : Texture
		{
			if (_viewWidth != view.width || _viewHeight != view.height)
				initTextures(context, view);

			return _inputTexture;
		}

		public function render(context : Context3D, target : Texture, camera : Camera3D, depthRender : Texture = null) : void
		{
			if (!_vertexBuffer)
				initBuffers(context);
		}

		private function initBuffers(context : Context3D) : void
		{
			_vertexBuffer = context.createVertexBuffer(4, 4);
			_vertexBuffer.uploadFromVector(Vector.<Number>([	-1, -1, 0, 1,
																1, -1, 1, 1,
																1,  1, 1, 0,
																-1,  1, 0, 0 ]), 0, 4);
			_indexBuffer = context.createIndexBuffer(6);
			_indexBuffer.uploadFromVector(Vector.<uint>([2, 1, 0, 3, 2, 0]), 0, 6);
		}

		public function dispose() : void
		{
			if (_inputTexture) _inputTexture.dispose();
		}

		protected function initTextures(context : Context3D, view : View3D) : void
		{
			var w : int = getPowerOf2Exceeding(view.width);
			var h : int = getPowerOf2Exceeding(view.height);

			if (w == _textureWidth && h == _textureHeight) return;

			_textureWidth = w;
			_textureHeight = h;

			if (_inputTexture) _inputTexture.dispose();

			_inputTexture = context.createTexture(w, h, Context3DTextureFormat.BGRA, true);
		}

		private function getPowerOf2Exceeding(value : int) : Number
		{
			var p : int = 1;

			while (p < value)
				p <<= 1;

			return p;
		}
	}
}
