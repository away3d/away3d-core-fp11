/**
 */
package away3d.core.render
{
	import away3d.cameras.Camera3D;
	import away3d.core.managers.RTTBufferManager;
	import away3d.core.managers.Stage3DProxy;
	import away3d.filters.Filter3DBase;
	import away3d.filters.tasks.Filter3DTaskBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;

	public class Filter3DRenderer
	{
		private var _filters : Array;
		private var _tasks : Vector.<Filter3DTaskBase>;
		private var _filterTasksInvalid : Boolean;
		private var _mainInputTexture : Texture;

		private var _requireDepthRender : Boolean;

		private var _rttManager : RTTBufferManager;
		private var _stage3DProxy : Stage3DProxy;
		private var _filterSizesInvalid : Boolean = true;

		public function Filter3DRenderer(stage3DProxy : Stage3DProxy)
		{
			_stage3DProxy = stage3DProxy;
			_rttManager = RTTBufferManager.getInstance(stage3DProxy);
			_rttManager.addEventListener(Event.RESIZE, onRTTResize);
		}

		private function onRTTResize(event : Event) : void
		{
			_filterSizesInvalid = true;
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

			for (var i : int = 0; i < _filters.length; ++i)
				_requireDepthRender ||= _filters[i].requireDepthRender;


			_filterSizesInvalid = true;
		}

		private function updateFilterTasks(stage3DProxy : Stage3DProxy) : void
		{
			var len : uint;

			if (_filterSizesInvalid) updateFilterSizes();

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
			var i : int;
			var task : Filter3DTaskBase;
			var context : Context3D = stage3DProxy.context3D;
			var indexBuffer : IndexBuffer3D = _rttManager.indexBuffer;
			var vertexBuffer : VertexBuffer3D = _rttManager.renderToTextureVertexBuffer;

			if (!_filters) return;
			if (_filterSizesInvalid) updateFilterSizes();
			if (_filterTasksInvalid) updateFilterTasks(stage3DProxy);

			len = _filters.length;
			for (i = 0; i < len; ++i) _filters[i].update(stage3DProxy, camera3D);

			len = _tasks.length;

			if (len > 1) {
				context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
				context.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
			}

			for (i = 0; i < len; ++i) {
				task = _tasks[i];
				stage3DProxy.setRenderTarget(task.target);

				if (!task.target) {
					stage3DProxy.scissorRect = null;
					vertexBuffer = _rttManager.renderToScreenVertexBuffer;
					context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
					context.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
				}
				stage3DProxy.setTextureAt(0, task.getMainInputTexture(stage3DProxy));
				stage3DProxy.setProgram(task.getProgram3D(stage3DProxy));
				context.clear(0.0, 0.0, 0.0, 1.0);
				task.activate(stage3DProxy, camera3D, depthTexture);
				context.drawTriangles(indexBuffer, 0, 2);
				task.deactivate(stage3DProxy);
			}

			stage3DProxy.setTextureAt(0, null);
			stage3DProxy.setSimpleVertexBuffer(0, null, null, 0);
			stage3DProxy.setSimpleVertexBuffer(1, null, null, 0);
		}

		private function updateFilterSizes() : void
		{
			for (var i : int = 0; i < _filters.length; ++i) {
				_filters[i].textureWidth = _rttManager.textureWidth;
				_filters[i].textureHeight = _rttManager.textureHeight;
			}

			_filterSizesInvalid = true;
		}

		public function dispose() : void
		{
			_rttManager.removeEventListener(Event.RESIZE, onRTTResize);
			_rttManager = null;
			_stage3DProxy = null;
		}
	}
}
