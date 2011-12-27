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
	import away3d.lights.LightBase;
	import away3d.textures.RenderTexture;
	import away3d.textures.TextureProxyBase;

	import flash.display3D.textures.TextureBase;

	use namespace arcane;

	// todo: deferred renderers can support a shared depth map for several lights. Allow an external depth map to be set.
	public class ShadowMapperBase
	{
		protected var _casterCollector : ShadowCasterCollector;

		private var _depthMap : TextureProxyBase;
		protected var _depthMapSize : uint = 2048;
		protected var _light : LightBase;
		private var _explicitDepthMap : Boolean;

		public function ShadowMapperBase()
		{
			_casterCollector = new ShadowCasterCollector();
		}

		/**
		 * This is used by renderers that can support depth maps to be shared across instances
		 * @param depthMap
		 */
		arcane function setDepthMap(depthMap : TextureProxyBase) : void
		{
			if (_depthMap == depthMap) return;
			if (_depthMap && !_explicitDepthMap) _depthMap.dispose();
			_depthMap = depthMap;
			_explicitDepthMap = depthMap? true : false;
		}

		public function get light() : LightBase
		{
			return _light;
		}

		public function set light(value : LightBase) : void
		{
			_light = value;
		}

		public function get depthMap() : TextureProxyBase
		{
			return _depthMap ||= createDepthTexture();
		}

		public function get depthMapSize() : uint
		{
			return _depthMapSize;
		}

		public function set depthMapSize(value : uint) : void
		{
			if (value == _depthMapSize) return;
			_depthMapSize = value;

			if (_explicitDepthMap) {
				throw Error("Cannot set depth map size for the current renderer.");
			}
			else if (_depthMap) {
				_depthMap.dispose();
				_depthMap = null;
			}
		}

		public function dispose() : void
		{
			_casterCollector = null;
			if (_depthMap && !_explicitDepthMap) _depthMap.dispose();
			_depthMap = null;
		}


		protected function createDepthTexture() : TextureProxyBase
		{
			return new RenderTexture(_depthMapSize, _depthMapSize);
		}


		/**
		 * Renders the depth map for this light.
		 * @param entityCollector The EntityCollector that contains the original scene data.
		 * @param renderer The DepthRenderer to render the depth map.
		 */
		arcane function renderDepthMap(stage3DProxy : Stage3DProxy, entityCollector : EntityCollector, renderer : DepthRenderer) : void
		{
			updateDepthProjection(entityCollector.camera);
			_depthMap ||= createDepthTexture();
			drawDepthMap(_depthMap.getTextureForStage3D(stage3DProxy), entityCollector.scene, renderer);
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