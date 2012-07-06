package away3d.lights.shadowmaps
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.OrthographicOffCenterLens;
	import away3d.containers.Scene3D;
	import away3d.core.math.Matrix3DUtils;
	import away3d.core.render.DepthRenderer;

	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;

	use namespace arcane;

	public class NearDirectionalShadowMapper extends DirectionalShadowMapper
	{
		private var _depthLens : OrthographicOffCenterLens;
		private var _localFrustum : Vector.<Number>;
		private var _frustumSegment : Vector.<Number>;
		private var _mtx : Matrix3D = new Matrix3D();
		private var _coverageRatio : Number;

		public function NearDirectionalShadowMapper(coverageRatio : Number = .5)
		{
			super();
			this.coverageRatio = coverageRatio;
			_depthCamera.lens = _depthLens = new OrthographicOffCenterLens(-10, 10, -10, 10);
			_frustumSegment = new Vector.<Number>(24, true);
			_localFrustum = new Vector.<Number>(24);
		}



		/**
		 * A value between 0 and 1 to indicate the ratio of the view frustum that needs to be covered by the shadow map.
		 */
		public function get coverageRatio() : Number
		{
			return _coverageRatio;
		}

		public function set coverageRatio(value : Number) : void
		{
			if (value > 1) value = 1;
			else if (value < 0) value = 0;

			_coverageRatio = value;
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

		override protected function updateDepthProjection(viewCamera : Camera3D) : void
		{
			var raw : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			var d : Number;
			var x2 : Number, y2 : Number;
			var xN : Number, yN : Number, zN : Number;
			var xF : Number, yF : Number, zF : Number;
			var minX : Number = Number.POSITIVE_INFINITY, minY : Number = Number.POSITIVE_INFINITY, minZ : Number = Number.POSITIVE_INFINITY;
			var maxX : Number = Number.NEGATIVE_INFINITY, maxY : Number = Number.NEGATIVE_INFINITY, maxZ : Number = Number.NEGATIVE_INFINITY;
			var scaleX : Number, scaleY : Number;
			var offsX : Number, offsY : Number;
			var halfSize : Number = depthMapSize*.5;
			var i : uint , j : uint;

			_mtx.copyFrom(_light.inverseSceneTransform);
			_mtx.prepend(viewCamera.sceneTransform);
			_mtx.transformVectors(viewCamera.lens.frustumCorners, _localFrustum);

			i = 0;
			j = 12;
			while (i < 12) {
				xN = _localFrustum[i++];
				yN = _localFrustum[i++];
				zN = _localFrustum[i++];
				x2 = _localFrustum[j++] - xN;
				y2 = _localFrustum[j++] - yN;
				zF = _localFrustum[j++];
				xF = xN + x2*_coverageRatio;
				yF = yN + y2*_coverageRatio;
				if (xN < minX) minX = xN;
				if (xN > maxX) maxX = xN;
				if (yN < minY) minY = yN;
				if (yN > maxY) maxY = yN;
				if (zN < minZ) minZ = zN;
				if (zN > maxZ) maxZ = zN;
				if (xF < minX) minX = xF;
				if (xF > maxX) maxX = xF;
				if (yF < minY) minY = yF;
				if (yF > maxY) maxY = yF;
				if (zF < minZ) minZ = zF;
				if (zF > maxZ) maxZ = zF;
			}

			_depthLens.near = minZ;
			_depthLens.far = maxZ;
			_depthLens.minX = minX-10;
			_depthLens.minY = minY-10;
			_depthLens.maxX = maxX+10;
			_depthLens.maxY = maxY+10;
			_depthCamera.transform = _light.sceneTransform;
		}
	}
}
