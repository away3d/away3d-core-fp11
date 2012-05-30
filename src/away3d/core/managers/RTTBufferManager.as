package away3d.core.managers
{
	import away3d.events.Stage3DEvent;
	import away3d.tools.utils.TextureUtils;

	import flash.display3D.Context3D;

	import flash.display3D.IndexBuffer3D;

	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;

	import flash.utils.Dictionary;

	public class RTTBufferManager extends EventDispatcher
	{
		private var _renderToTextureVertexBuffer : VertexBuffer3D;
		private var _renderToScreenVertexBuffer : VertexBuffer3D;

		private var _indexBuffer : IndexBuffer3D;
		private var _stage3DProxy : Stage3DProxy;
		private var _viewWidth : int = -1;
		private var _viewHeight : int = -1;
		private var _textureWidth : int = -1;
		private var _textureHeight : int = -1;
		private var _renderToTextureRect : Rectangle;
		private var _buffersInvalid : Boolean = true;

		private var _textureRatioX : Number;
		private var _textureRatioY : Number;

		public function RTTBufferManager(stage3DProxy : Stage3DProxy)
		{
			_renderToTextureRect = new Rectangle();
			_stage3DProxy = stage3DProxy;
			_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onRecreated, false, 0, true);
		}


		public function get textureRatioX() : Number
		{
			return _textureRatioX;
		}

		public function get textureRatioY() : Number
		{
			return _textureRatioY;
		}

		public function get viewWidth() : int
		{
			return _viewWidth;
		}

		public function set viewWidth(value : int) : void
		{
			if (value == _viewWidth) return;
			_viewWidth = value;

			_buffersInvalid = true;

			_textureWidth = TextureUtils.getBestPowerOf2(_viewWidth);

			if (_textureWidth > _viewWidth) {
				_renderToTextureRect.x = uint((_textureWidth-_viewWidth)*.5);
				_renderToTextureRect.width = _viewWidth;
			}
			else {
				_renderToTextureRect.x = 0;
				_renderToTextureRect.height = _textureHeight;
			}

			dispatchEvent(new Event(Event.RESIZE));
		}

		public function get viewHeight() : int
		{
			return _viewHeight;
		}

		public function set viewHeight(value : int) : void
		{
			if (value == _viewHeight) return;
			_viewHeight = value;

			_buffersInvalid = true;

			_textureHeight = TextureUtils.getBestPowerOf2(_viewHeight);

			if (_textureHeight > _viewHeight) {
				_renderToTextureRect.y = uint((_textureHeight-_viewHeight)*.5);
				_renderToTextureRect.height = _viewHeight;
			}
			else {
				_renderToTextureRect.y = 0;
				_renderToTextureRect.height = _textureHeight;
			}

			dispatchEvent(new Event(Event.RESIZE));
		}

		public function get renderToTextureVertexBuffer() : VertexBuffer3D
		{
			if (_buffersInvalid) updateRTTBuffers();
			return _renderToTextureVertexBuffer;
		}

		public function get renderToScreenVertexBuffer() : VertexBuffer3D
		{
			if (_buffersInvalid) updateRTTBuffers();
			return _renderToScreenVertexBuffer;
		}

		public function get indexBuffer() : IndexBuffer3D
		{
			return _indexBuffer;
		}

		public function get renderToTextureRect() : Rectangle
		{
			if (_buffersInvalid) updateRTTBuffers();
			return _renderToTextureRect;
		}

		public function get textureWidth() : int
		{
			return _textureWidth;
		}

		public function get textureHeight() : int
		{
			return _textureHeight;
		}

		public function dispose() : void
		{
			if (_indexBuffer) {
				_indexBuffer.dispose();
				_renderToScreenVertexBuffer.dispose();
				_renderToTextureVertexBuffer.dispose();
				_renderToScreenVertexBuffer = null;
				_renderToTextureVertexBuffer = null;
				_indexBuffer = null;
			}
			_stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onRecreated);
		}

		// todo: place all this in a separate model, since it's used all over the place
		// maybe it even has a place in the core (together with screenRect etc)?
		// needs to be stored per view of course
		private function updateRTTBuffers() : void
		{
			var context : Context3D = _stage3DProxy.context3D;
			var textureVerts : Vector.<Number>;
			var screenVerts : Vector.<Number>;
			var x : Number,  y : Number,  u : Number,  v : Number;

			_renderToTextureVertexBuffer ||= context.createVertexBuffer(4, 5);
			_renderToScreenVertexBuffer ||= context.createVertexBuffer(4, 5);

			if (!_indexBuffer) {
				_indexBuffer = context.createIndexBuffer(6);
				_indexBuffer.uploadFromVector(new <uint>[2, 1, 0, 3, 2, 0], 0, 6);
			}

			if (_viewWidth > _textureWidth) {
				x = 1;
				u = 0;
			}
			else {
				x = _viewWidth/_textureWidth;
				u = _renderToTextureRect.x/_textureWidth;
			}
			if (_viewHeight > _textureHeight) {
				y = 1;
				v = 0;
			}
			else {
				y = _viewHeight/_textureHeight;
				v = _renderToTextureRect.y/_textureHeight;
			}

			_textureRatioX = x;
			_textureRatioY = y;

			// last element contains indices for data per vertex that can be passed to the vertex shader if necessary (ie: frustum corners for deferred rendering)
			textureVerts = new <Number>[	-x, -y, u,   1-v, 0,
											 x, -y, 1-u, 1-v, 1,
											 x,  y, 1-u, v,   2,
											-x,  y, u,   v,   3 ];
			screenVerts = new <Number>[		-1, -1,   u, 1-v, 0,
											 1, -1, 1-u, 1-v, 1,
											 1,  1, 1-u,   v, 2,
											-1,  1,   u,   v, 3 ];

			_renderToTextureVertexBuffer.uploadFromVector(textureVerts, 0, 4);
			_renderToScreenVertexBuffer.uploadFromVector(screenVerts, 0, 4);

			_buffersInvalid = false;
		}
		
		private function onRecreated(e:Event):void
		{
			_buffersInvalid = true;
			_renderToTextureVertexBuffer = null;
			_renderToScreenVertexBuffer = null;
			_indexBuffer = null;
		}
	}
}
