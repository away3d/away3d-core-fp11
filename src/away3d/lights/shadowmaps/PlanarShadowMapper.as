/**
 * Author: David Lenaerts
 */
package away3d.lights.shadowmaps
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.core.render.DepthRenderer;
	import away3d.lights.LightBase;

	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;

	use namespace arcane;

	public class PlanarShadowMapper extends ShadowMapperBase
	{
		protected var _depthCamera : Camera3D;

		public function PlanarShadowMapper(light : LightBase)
		{
			super(light);
			_depthCamera = new Camera3D();
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
	}
}
