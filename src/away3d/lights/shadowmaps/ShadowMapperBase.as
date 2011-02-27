package away3d.lights.shadowmaps
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.core.render.DepthRenderer;
	import away3d.core.traverse.EntityCollector;
	import away3d.core.traverse.ShadowCasterCollector;
	import away3d.errors.AbstractMethodError;

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

		public function getDepthMap(contextIndex : uint) : TextureBase
		{
			return _depthMaps[contextIndex];
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
		}


		private function createDepthTexture(context : Context3D) : TextureBase
		{
			return context.createTexture(_depthMapSize, _depthMapSize, Context3DTextureFormat.BGRA, true);
		}


		/**
		 * Renders the depth map for this light.
		 * @param entityCollector The EntityCollector that contains the original scene data.
		 * @param renderer The DepthRenderer to render the depth map.
		 */
		arcane function renderDepthMap(context : Context3D, contextIndex : uint, entityCollector : EntityCollector, renderer : DepthRenderer) : void
		{
			if (!_depthMaps[contextIndex]) _depthMaps[contextIndex] = createDepthTexture(context);
			updateDepthProjection(entityCollector.camera);
			drawDepthMap(_depthMaps[contextIndex], entityCollector.scene, renderer);
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
