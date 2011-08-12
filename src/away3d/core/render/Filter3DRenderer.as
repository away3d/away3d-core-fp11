/**
 */
package away3d.core.render
{
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.filters.Filter3DBase;
	import away3d.filters.tasks.Filter3DTaskBase;
	import away3d.tools.utils.TextureUtils;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.geom.Rectangle;

	public class Filter3DRenderer
	{
		private var _filters : Array;
		private var _tasks : Vector.<Filter3DTaskBase>
		private var _filterTasksInvalid : Boolean;
		private var _mainInputTexture : Texture;
		private var _viewWidth : Number;
		private var _viewHeight : Number;
		private var _textureSizeInvalid : Boolean;
		private var _textureWidth : int = -1;
		private var _textureHeight : int = -1;

		private var _vertexBufferInvalid : Boolean = true;
		private var _vertexBufferToTexture : VertexBuffer3D;
		private var _vertexBufferToScreen : VertexBuffer3D;
		private var _indexBuffer : IndexBuffer3D;
		private var _requireDepthRender : Boolean;

		private var _renderRect : Rectangle;

		public function Filter3DRenderer(viewWidth : int, viewHeight : int)
		{
			_renderRect = new Rectangle();
			this.viewWidth = viewWidth;
			this.viewHeight = viewHeight;
		}

		public function get requireDepthRender() : Boolean
		{
			return _requireDepthRender;
		}

		public function getMainInputTexture(stage3DProxy : Stage3DProxy) : Texture
		{
			if (_filterTasksInvalid) updateFilterTasks(stage3DProxy);
			return _mainInputTexture;
		}

		public function get filters() : Array
		{
			return _filters;
		}

		public function set filters(value : Array) : void
		{
			_filters = value;
			_filterTasksInvalid = true;

			_requireDepthRender = false;
			if (!_filters) return;

			for (var i : int = 0; i < _filters.length; ++i) {
				_requireDepthRender ||= _filters[i].requireDepthRender;
				_filters[i].textureWidth = _textureWidth;
				_filters[i].textureHeight = _textureHeight;
			}
		}

		private function updateFilterTasks(stage3DProxy : Stage3DProxy) : void
		{
			var len : uint;

			if (!_filters) {
				_tasks = null;
				return;
			}

			_tasks = new Vector.<Filter3DTaskBase>();

			len = _filters.length - 1;

			var filter : Filter3DBase;

			for (var i : uint = 0; i <= len; ++i) {
				// make sure all internal tasks are linked together
				filter = _filters[i];
				filter.setRenderTargets(i == len? null : Filter3DBase(_filters[i+1]).getMainInputTexture(stage3DProxy), stage3DProxy);
			   	_tasks = _tasks.concat(filter.tasks);
			}

			_mainInputTexture = _filters[0].getMainInputTexture(stage3DProxy);
		}

		public function render(stage3DProxy : Stage3DProxy, camera3D : Camera3D, depthTexture : Texture) : void
		{
			var len : int;
			var i : int
			var task : Filter3DTaskBase;
			var context : Context3D = stage3DProxy.context3D;

			if (!_filters) return;

			if (_filterTasksInvalid) updateFilterTasks(stage3DProxy);
			if (_vertexBufferInvalid) updateBuffers(stage3DProxy);

			len = _filters.length;
			for (i = 0; i < len; ++i) _filters[i].update(stage3DProxy, camera3D);

			len = _tasks.length;

			if (len > 1) {
				context.setVertexBufferAt(0, _vertexBufferToTexture, 0, Context3DVertexBufferFormat.FLOAT_2);
				context.setVertexBufferAt(1, _vertexBufferToTexture, 2, Context3DVertexBufferFormat.FLOAT_2);
			}

			for (i = 0; i < len; ++i) {
				task = _tasks[i];
				stage3DProxy.setRenderTarget(task.target);

				if (!task.target) {
					stage3DProxy.scissorRect = null;
					context.setVertexBufferAt(0, _vertexBufferToScreen, 0, Context3DVertexBufferFormat.FLOAT_2);
					context.setVertexBufferAt(1, _vertexBufferToScreen, 2, Context3DVertexBufferFormat.FLOAT_2);
				}
				stage3DProxy.setTextureAt(0, task.getMainInputTexture(stage3DProxy));
				stage3DProxy.setProgram(task.getProgram3D(stage3DProxy));
				context.clear(0.0, 0.0, 0.0, 1.0);
				task.activate(stage3DProxy, camera3D, depthTexture);
				context.drawTriangles(_indexBuffer, 0, 2);
				task.deactivate(stage3DProxy);
			}

			stage3DProxy.setTextureAt(0, null);
			stage3DProxy.setSimpleVertexBuffer(0, null);
			stage3DProxy.setSimpleVertexBuffer(1, null);
		}

		private function updateBuffers(stage3DProxy : Stage3DProxy) : void
		{
			var context : Context3D = stage3DProxy.context3D;
			var textureVerts : Vector.<Number>;
			var screenVerts : Vector.<Number>;
			var x : Number,  y : Number,  u : Number,  v : Number;
			// todo: will be diff for r2t and screen

			_vertexBufferToTexture ||= context.createVertexBuffer(4, 4);
			_vertexBufferToScreen ||= context.createVertexBuffer(4, 4);

			if (_viewWidth > _textureWidth) {
				x = 1;
				u = 0;
			}
			else {
				x = _viewWidth/_textureWidth;
				u = (_textureWidth - _viewWidth)*.5/_textureWidth;
			}
			if (_viewHeight > _textureHeight) {
				y = 1;
				v = 0;
			}
			else {
				y = _viewHeight/_textureHeight;
				v = (_textureHeight - _viewHeight)*.5/_textureHeight;
			}

			textureVerts = Vector.<Number>([	-x, -y, u, 1-v,
												x, -y, 1-u, 1-v,
												x,  y, 1-u, v,
												-x,  y, u, v ]);
			screenVerts = Vector.<Number>([		-1, -1, u, 1-v,
												1, -1, 1-u, 1-v,
												1,  1, 1-u, v,
												-1,  1, u, v ]);

			_vertexBufferToTexture.uploadFromVector(textureVerts, 0, 4);
			_vertexBufferToScreen.uploadFromVector(screenVerts, 0, 4);

			if (!_indexBuffer) {
				_indexBuffer = context.createIndexBuffer(6);
				_indexBuffer.uploadFromVector(Vector.<uint>([2, 1, 0, 3, 2, 0]), 0, 6);
			}
		}

		public function dispose() : void
		{
		}


		public function get viewWidth() : Number
		{
			return _viewWidth;
		}

		public function set viewWidth(value : Number) : void
		{
			_viewWidth = value;

			if (value > 0) {
				var w : int = TextureUtils.getBestPowerOf2(_viewWidth);
				if (_textureWidth != w) {
					_textureSizeInvalid = true;
					_textureWidth = w;
					if (_filters)
						for (var i : int = 0; i < _filters.length; ++i)
							_filters[i].textureWidth = w;
				}

				if (_textureWidth > _viewWidth) {
					_renderRect.x = (w-_viewWidth)*.5;
					_renderRect.width = _viewWidth;
				}
				else {
					_renderRect.x = 0;
					_renderRect.height = _textureHeight;
				}
			}
		}

		public function get viewHeight() : Number
		{
			return _viewHeight;
		}

		public function set viewHeight(value : Number) : void
		{
			_viewHeight = value;
			if (value > 0) {
				var h : int = TextureUtils.getBestPowerOf2(_viewHeight);
				if (_textureHeight != h) {
					_textureSizeInvalid = true;
					_textureHeight = h;
					if (_filters)
						for (var i : int = 0; i < _filters.length; ++i)
							_filters[i].textureHeight = h;
				}

				if (_textureHeight > _viewHeight) {
					_renderRect.y = (h-_viewHeight)*.5;
					_renderRect.height = _viewHeight;
				}
				else {
					_renderRect.y = 0;
					_renderRect.height = _textureHeight;
				}
			}
		}

		public function get renderRect() : Rectangle
		{
			return _renderRect;
		}

		public function get textureWidth() : int
		{
			return _textureWidth;
		}


		public function get textureHeight() : int
		{
			return _textureHeight;
		}
	}
}
