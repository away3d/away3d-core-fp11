/**
 * Author: David Lenaerts
 */
package away3d.lights.shadowmaps
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.OrthographicOffCenterLens;
	import away3d.containers.Scene3D;
	import away3d.core.render.DepthRenderer;

	import away3d.lights.DirectionalLight;

	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;

	use namespace arcane;

	public class DirectionalShadowMapper extends PlanarShadowMapper
	{
		private var _frustumSegment : Vector.<Number>;
		private var _depthLens : OrthographicOffCenterLens;
		private var _mtx : Matrix3D = new Matrix3D();
		private var _localFrustum : Vector.<Number>;

		public function DirectionalShadowMapper(light : DirectionalLight)
		{
			super(light);
			_depthCamera.lens = _depthLens = new OrthographicOffCenterLens(-10, -10, 10, 10)
			_localFrustum = new Vector.<Number>(8*3);
			_frustumSegment = new Vector.<Number>(8*3);
		}

		/**
		 * Depth projection matrix that projects from scene space to depth map.
		 */
		override arcane function get depthProjection() : Matrix3D
		{
			return _depthCamera.viewProjection;
		}

		override protected function drawDepthMap(target : TextureBase, scene : Scene3D, renderer : DepthRenderer) : void
		{
			_casterCollector.clear();
			_casterCollector.camera = _depthCamera;
			scene.traversePartitions(_casterCollector);
			renderer.render(_casterCollector, target);
			_casterCollector.cleanUp();
		}

		// todo: move to shadow mapper class
		override protected function updateDepthProjection(viewCamera : Camera3D) : void
		{
			// maybe try and fix this
			var corners : Vector.<Number> = viewCamera.lens.frustumCorners;
			var x : Number, y : Number, z : Number;
			var minX : Number = Number.POSITIVE_INFINITY, minY : Number = Number.POSITIVE_INFINITY, minZ : Number = Number.POSITIVE_INFINITY;
			var maxX : Number = Number.NEGATIVE_INFINITY, maxY : Number = Number.NEGATIVE_INFINITY, maxZ : Number = Number.NEGATIVE_INFINITY;
			var i : uint;
			_mtx.copyFrom(_light.inverseSceneTransform);
			_mtx.prepend(viewCamera.sceneTransform);
			_mtx.transformVectors(corners, _localFrustum);

			i = 0;
			while (i < 24) {
				x = _localFrustum[i++];
				y = _localFrustum[i++];
				z = _localFrustum[i++];
				if (x < minX) minX = x;
				if (x > maxX) maxX = x;
				if (y < minY) minY = y;
				if (y > maxY) maxY = y;
				if (z < minZ) minZ = z;
				if (z > maxZ) maxZ = z;
			}

			_depthLens.near = minZ;
			_depthLens.far = maxZ;
			_depthLens.minX = minX-10;
			_depthLens.maxX = maxX+10;
			_depthLens.minY = minY-10;
			_depthLens.maxY = maxY+10;
			_depthCamera.transform = _light.sceneTransform;
		}
	}
}
