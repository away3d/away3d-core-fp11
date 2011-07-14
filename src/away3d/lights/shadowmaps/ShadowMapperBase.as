package away3d.lights.shadowmaps
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.render.DepthRenderer;
	import away3d.core.traverse.EntityCollector;
	import away3d.core.traverse.ShadowCasterCollector;
	import away3d.errors.AbstractMethodError;
	import away3d.events.Stage3DEvent;
	import away3d.lights.LightBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;

	use namespace arcane;

	public class ShadowMapperBase
	{
		protected var _casterCollector : ShadowCasterCollector;

		private var _depthMaps : Vector.<TextureBase>;
		private var _depthMapSize : uint = 2048;
		protected var _light : LightBase;
		private var _listeningForDisposal : Vector.<Stage3DProxy> = new Vector.<Stage3DProxy>(8, true);

		public function ShadowMapperBase(light : LightBase)
		{
			_light = light;
			_casterCollector = new ShadowCasterCollector();
			_depthMaps = new Vector.<TextureBase>(8);
		}

		/**
		 * Depth projection matrix that projects from scene space to depth map.
		 */
		arcane function get depthProjection() : Matrix3D
		{
			throw new AbstractMethodError();
			return null;
		}

		public function getDepthMap(stage3DProxy : Stage3DProxy) : TextureBase
		{
			return _depthMaps[stage3DProxy._stage3DIndex];
		}

		public function get depthMapSize() : uint
		{
			return _depthMapSize;
		}

		public function set depthMapSize(value : uint) : void
		{
			if (value == _depthMapSize) return;
			_depthMapSize = value;

			for (var i : int = 0; i < _depthMaps.length; ++i) {
				if (_depthMaps[i]) _depthMaps[i].dispose();
				_depthMaps[i] = null;
			}
		}

		public function dispose() : void
		{
			_casterCollector = null;
			for (var i : int = 0; i < _depthMaps.length; ++i) {
				if (_depthMaps[i]) _depthMaps[i].dispose();
			}
			_depthMaps = null;

			for (i = 0; i < 8; ++i) {
				if (_listeningForDisposal[i]) _listeningForDisposal[i].removeEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed);
			}
		}


		private function createDepthTexture(stage3DProxy : Stage3DProxy) : TextureBase
		{
			return stage3DProxy._context3D.createTexture(_depthMapSize, _depthMapSize, Context3DTextureFormat.BGRA, true);
		}


		/**
		 * Renders the depth map for this light.
		 * @param entityCollector The EntityCollector that contains the original scene data.
		 * @param renderer The DepthRenderer to render the depth map.
		 */
		arcane function renderDepthMap(stage3DProxy : Stage3DProxy, entityCollector : EntityCollector, renderer : DepthRenderer) : void
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;

			if (!_listeningForDisposal[contextIndex]) {
				_listeningForDisposal[contextIndex] = stage3DProxy;
				stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed);
			}

			if (!_depthMaps[contextIndex]) _depthMaps[contextIndex] = createDepthTexture(stage3DProxy);
			updateDepthProjection(entityCollector.camera);
			drawDepthMap(_depthMaps[contextIndex], entityCollector.scene, renderer);
		}

		private function onContext3DDisposed(event : Stage3DEvent) : void
		{
			var stage3DProxy : Stage3DProxy = Stage3DProxy(event.target);
			var contextIndex : int = stage3DProxy._stage3DIndex;
			stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed);
			_listeningForDisposal[contextIndex] = null;

			_depthMaps[contextIndex].dispose();
			_depthMaps[contextIndex] = null;
		}

		protected function updateDepthProjection(viewCamera : Camera3D) : void
		{
			throw new AbstractMethodError();
		}

		protected function drawDepthMap(target : TextureBase, scene : Scene3D, renderer : DepthRenderer) : void
		{
			throw new AbstractMethodError();
		}

	}
}
