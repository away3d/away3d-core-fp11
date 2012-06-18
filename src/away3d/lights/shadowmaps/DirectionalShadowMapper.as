package away3d.lights.shadowmaps
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.FreeMatrixLens;
	import away3d.containers.Scene3D;
	import away3d.core.math.Matrix3DUtils;
	import away3d.core.render.DepthRenderer;
	import away3d.lights.DirectionalLight;

	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	public class DirectionalShadowMapper extends ShadowMapperBase
	{
		protected var _depthCamera : Camera3D;
		private var _localFrustum : Vector.<Number>;

		private var _lightOffset : Number = 10000;
		private var _matrix : Matrix3D;
		private var _depthLens : FreeMatrixLens;

		public function DirectionalShadowMapper()
		{
			super();
			_depthCamera = new Camera3D();
			_depthCamera.lens = _depthLens = new FreeMatrixLens();
			_localFrustum = new Vector.<Number>(8 * 3);
			_matrix = new Matrix3D();
		}

		public function get lightOffset() : Number
		{
			return _lightOffset;
		}

		public function set lightOffset(value : Number) : void
		{
			_lightOffset = value;
		}

		/**
		 * Depth projection matrix that projects from scene space to depth map.
		 */
		arcane function get depthProjection() : Matrix3D
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
			var dir : Vector3D;
			var d : Number;
			var corners : Vector.<Number> = viewCamera.lens.frustumCorners;
			var x : Number, y : Number, z : Number;
			var minX : Number = Number.POSITIVE_INFINITY, minY : Number = Number.POSITIVE_INFINITY, minZ : Number = Number.POSITIVE_INFINITY;
			var maxX : Number = Number.NEGATIVE_INFINITY, maxY : Number = Number.NEGATIVE_INFINITY, maxZ : Number = Number.NEGATIVE_INFINITY;
			var scaleX : Number, scaleY : Number;
			var offsX : Number, offsY : Number;
			var halfSize : Number = _depthMapSize*.5;
			var i : uint;

			_depthCamera.transform = _light.sceneTransform;
			dir = DirectionalLight(_light).sceneDirection;
			_depthCamera.x = viewCamera.x - dir.x * _lightOffset;
			_depthCamera.y = viewCamera.y - dir.y * _lightOffset;
			_depthCamera.z = viewCamera.z - dir.z * _lightOffset;

			_matrix.copyFrom(_depthCamera.inverseSceneTransform);
			_matrix.prepend(viewCamera.sceneTransform);
			_matrix.transformVectors(corners, _localFrustum);

			i = 0;
			while (i < 24) {
				x = _localFrustum[i++];
				y = _localFrustum[i++];
				z = _localFrustum[i++];
				if (x < minX) minX = x;
				if (x > maxX) maxX = x;
				if (y < minY) minY = y;
				if (y > maxY) maxY = y;
//				if (z < minZ) minZ = z;
				if (z > maxZ) maxZ = z;
			}

			// counter shadow map swimming
			scaleX = 64 / Math.ceil((maxX - minX)*32);
			scaleY = 64 / Math.ceil((maxY - minY)*32);

			offsX = Math.ceil(-.5*(maxX + minX)*scaleX*halfSize) / halfSize;
			offsY = Math.ceil(-.5*(maxY + minY)*scaleY*halfSize) / halfSize;

			minZ = 10;

			d = 1 / (maxZ - minZ);
			raw[0] = raw[5] = raw[15] = 1;
			raw[10] = d;
			raw[14] = -minZ * d;
			raw[1] = raw[2] = raw[3] = raw[4] = raw[6] = raw[7] = raw[8] = raw[9] = raw[11] = raw[12] = raw[13] = 0;

			_matrix.copyRawDataFrom(raw);
			_matrix.prependTranslation(offsX, offsY, 0);
			_matrix.prependScale(scaleX, scaleY, 1);

			_depthLens.matrix = _matrix;
		}
	}
}
