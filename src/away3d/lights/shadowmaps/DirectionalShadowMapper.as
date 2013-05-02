package away3d.lights.shadowmaps
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.FreeMatrixLens;
	import away3d.containers.Scene3D;
	import away3d.core.math.Matrix3DUtils;
	import away3d.core.math.Plane3D;
	import away3d.core.render.DepthRenderer;
	import away3d.lights.DirectionalLight;

	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	public class DirectionalShadowMapper extends ShadowMapperBase
	{
		protected var _depthCamera : Camera3D;
		protected var _localFrustum : Vector.<Number>;

		protected var _lightOffset : Number = 10000;
		protected var _matrix : Matrix3D;
		protected var _depthLens : FreeMatrixLens;
		private var _snap : Number = 64;

		private var _cullPlanes : Vector.<Plane3D>;

		public function DirectionalShadowMapper()
		{
			super();
			_cullPlanes = new Vector.<Plane3D>();
			_depthCamera = new Camera3D();
			_depthCamera.lens = _depthLens = new FreeMatrixLens();
			_localFrustum = new Vector.<Number>(8 * 3);
			_matrix = new Matrix3D();
		}

		public function get snap() : Number
		{
			return _snap;
		}

		public function set snap(value : Number) : void
		{
			_snap = value;
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
			_casterCollector.camera = _depthCamera;
			_casterCollector.cullPlanes = _cullPlanes;
			_casterCollector.clear();
			scene.traversePartitions(_casterCollector);
			renderer.render(_casterCollector, target);
			_casterCollector.cleanUp();
		}

		private function updateCullPlanes(viewCamera : Camera3D) : void
		{
			var lightFrustumPlanes : Vector.<Plane3D> = _depthCamera.frustumPlanes;
			var viewFrustumPlanes : Vector.<Plane3D> = viewCamera.frustumPlanes;
			_cullPlanes.length = 4;

			_cullPlanes[0] = lightFrustumPlanes[0];
			_cullPlanes[1] = lightFrustumPlanes[1];
			_cullPlanes[2] = lightFrustumPlanes[2];
			_cullPlanes[3] = lightFrustumPlanes[3];

			var dir : Vector3D = DirectionalLight(_light).sceneDirection;
			var dirX : Number = dir.x;
			var dirY : Number = dir.y;
			var dirZ : Number = dir.z;
			var j : int = 4;
			for (var i : int = 0; i < 6; ++i) {
				var plane : Plane3D = viewFrustumPlanes[i];
				if (plane.a * dirX + plane.b * dirY + plane.c * dirZ < 0)
					_cullPlanes[j++] = plane;
			}
		}

		override protected function updateDepthProjection(viewCamera : Camera3D) : void
		{
			updateProjectionFromFrustumCorners(viewCamera, viewCamera.lens.frustumCorners, _matrix);
			_depthLens.matrix = _matrix;
			updateCullPlanes(viewCamera);
		}

		protected function updateProjectionFromFrustumCorners(viewCamera : Camera3D, corners : Vector.<Number>, matrix : Matrix3D) : void
		{
			var raw : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			var dir : Vector3D;
			var x : Number, y : Number, z : Number;
			var minX : Number, minY : Number, minZ : Number;
			var maxX : Number, maxY : Number, maxZ : Number;
			var i : uint;

			dir = DirectionalLight(_light).sceneDirection;
			_depthCamera.transform = _light.sceneTransform;
			x = int((viewCamera.x-dir.x * _lightOffset)/_snap)*_snap;
			y = int((viewCamera.y-dir.y * _lightOffset)/_snap)*_snap;
			z = int((viewCamera.z-dir.z * _lightOffset)/_snap)*_snap;
			_depthCamera.x = x;
			_depthCamera.y = y;
			_depthCamera.z = z;

			_matrix.copyFrom(_depthCamera.inverseSceneTransform);
			_matrix.prepend(viewCamera.sceneTransform);
			_matrix.transformVectors(corners, _localFrustum);

			minX = maxX = _localFrustum[0];
			minY = maxY = _localFrustum[1];
			maxZ = _localFrustum[2];

			i = 3;
			while (i < 24) {
				x = _localFrustum[i];
				y = _localFrustum[uint(i+1)];
				z = _localFrustum[uint(i+2)];
				if (x < minX) minX = x;
				if (x > maxX) maxX = x;
				if (y < minY) minY = y;
				if (y > maxY) maxY = y;
				if (z > maxZ) maxZ = z;
				i += 3;
			}
			minZ = 1;

			var w : Number = maxX - minX;
			var h : Number = maxY - minY;
			var d : Number = 1/(maxZ - minZ);

			if (minX < 0) minX -= _snap;	// because int() rounds up for < 0
			if (minY < 0) minY -= _snap;
			minX = int(minX / _snap) * _snap;
			minY = int(minY / _snap) * _snap;

			var snap2 : Number = 2*_snap;
			w = int(w/snap2 + 2)*snap2;
			h = int(h/snap2 + 2)*snap2;

			maxX = minX + w;
			maxY = minY + h;

			w = 1/w;
			h = 1/h;

			raw[0] = 2*w;
			raw[5] = 2*h;
			raw[10] = d;
			raw[12] = -(maxX + minX)*w;
			raw[13] = -(maxY + minY)*h;
			raw[14] = -minZ * d;
			raw[15] = 1;
			raw[1] = raw[2] = raw[3] = raw[4] = raw[6] = raw[7] = raw[8] = raw[9] = raw[11] = 0;

			matrix.copyRawDataFrom(raw);
		}
	}
}
