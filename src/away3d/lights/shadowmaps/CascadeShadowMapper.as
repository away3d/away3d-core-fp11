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
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;

	use namespace arcane;

	public class CascadeShadowMapper extends ShadowMapperBase
	{
		protected var _scissorRects : Vector.<Rectangle>;
		private var _scissorRectsInvalid : Boolean = true;
		private var _splitRatios : Vector.<Number>;

		private var _numCascades : int;
		private var _depthCameras : Vector.<Camera3D>;
		private var _depthLenses : Vector.<FreeMatrixLens>;

		private var _lightOffset : Number = 5000;
		private var _localFrustum : Vector.<Number>;
		private var _texOffsetsX : Vector.<Number>;
		private var _texOffsetsY : Vector.<Number>;

		private static var _calcMatrix : Matrix3D = new Matrix3D();

		public function CascadeShadowMapper(numCascades : uint = 3)
		{
			super();
			if (numCascades < 1 || numCascades > 4) throw new Error("numCascades must be an integer between 1 and 4");
			_numCascades = numCascades;
			init();
		}

		public function getSplitRatio(index : uint) : Number
		{
			return _splitRatios[index];
		}

		public function setSplitRatio(index : uint, value : Number) : void
		{
			if (value < 0) value = 0;
			else if (value > 1) value = 1;

			if (index >= _numCascades) throw new Error("index must be smaller than the number of cascades!");

			_splitRatios[index] = value;
		}

		public function getDepthProjections(partition : uint) : Matrix3D
		{
			return _depthCameras[partition].viewProjection;
		}

		private function init() : void
		{
			_localFrustum = new Vector.<Number>(8 * 3);
			_splitRatios = new Vector.<Number>(4, true);

			var s : Number = 1;
			for (var i : int = _numCascades-1; i >= 0; --i) {
				_splitRatios[i] = s;
				s *= .25;
			}

			_texOffsetsX = new <Number>[-1, 1, -1, 1];
			_texOffsetsY = new <Number>[1, 1, -1, -1];
			_scissorRects = new Vector.<Rectangle>(4, true);
			_depthLenses = new Vector.<FreeMatrixLens>();
			_depthCameras = new Vector.<Camera3D>();

			for (i = 0; i < _numCascades; ++i) {
				_depthLenses[i] = new FreeMatrixLens();
				_depthCameras[i] = new Camera3D(_depthLenses[i]);
			}
		}

		public function get lightOffset() : Number
		{
			return _lightOffset;
		}

		public function set lightOffset(value : Number) : void
		{
			_lightOffset = value;
		}

		// will not be allowed
		override public function set depthMapSize(value : uint) : void
		{
			if (value == _depthMapSize) return;
			super.depthMapSize = value;
			invalidateScissorRects();
		}

		private function invalidateScissorRects() : void
		{
			_scissorRectsInvalid = true;
		}

		public function get numCascades() : int
		{
			return _numCascades;
		}

		override protected function drawDepthMap(target : TextureBase, scene : Scene3D, renderer : DepthRenderer) : void
		{
			if (_scissorRectsInvalid) updateScissorRects();

			for (var i : int = 0; i < _numCascades; ++i) {
				_casterCollector.clear();
				_casterCollector.camera = _depthCameras[i];
				scene.traversePartitions(_casterCollector);
				// only clear buffer once
				renderer.clearOnRender = i == 0;
				renderer.render(_casterCollector, target, _scissorRects[i], 0);

				_casterCollector.cleanUp();
			}
			// be a gentleman and restore before returning
			renderer.clearOnRender = true;
		}

		private function updateScissorRects() : void
		{
			var half : Number = _depthMapSize*.5;

			_scissorRects[0] = new Rectangle(0, 0, half, half);
			_scissorRects[1] = new Rectangle(half, 0, _depthMapSize, half);
			_scissorRects[2] = new Rectangle(0, half, half, _depthMapSize);
			_scissorRects[3] = new Rectangle(half, half, _depthMapSize, _depthMapSize);

			_scissorRectsInvalid = false;
		}

		override protected function updateDepthProjection(viewCamera : Camera3D) : void
		{
			var matrix : Matrix3D;

			updateLocalFrustum(viewCamera);

			for (var i : int = 0; i < _numCascades; ++i) {
				matrix = _depthLenses[i].matrix;

				if (i == 0) {
					updateProjectionPartition(matrix, 0, _splitRatios[0], _texOffsetsX[i], _texOffsetsY[i]);
				}
				else {
					_depthCameras[i].transform = _depthCameras[0].transform;
					updateProjectionPartition(matrix, _splitRatios[i-1], _splitRatios[i], _texOffsetsX[i], _texOffsetsY[i]);
				}

				_depthLenses[i].matrix = matrix;
			}
		}

		private function updateLocalFrustum(viewCamera : Camera3D) : void
		{
			var corners : Vector.<Number> = viewCamera.lens.frustumCorners;
			var dir : Vector3D = DirectionalLight(_light).sceneDirection;
			var depthCam : Camera3D = _depthCameras[0];
			depthCam.transform = _light.sceneTransform;
			depthCam.x = viewCamera.x - dir.x * _lightOffset;
			depthCam.y = viewCamera.y - dir.y * _lightOffset;
			depthCam.z = viewCamera.z - dir.z * _lightOffset;

			_calcMatrix.copyFrom(depthCam.inverseSceneTransform);
			_calcMatrix.prepend(viewCamera.sceneTransform);
			_calcMatrix.transformVectors(corners, _localFrustum);

		}

		private function updateProjectionPartition(matrix : Matrix3D, minRatio : Number, maxRatio : Number, texOffsetX : Number, texOffsetY : Number) : void
		{
			var raw : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			var d : Number;
			var x1 : Number, y1 : Number, z1 : Number;
			var x2 : Number, y2 : Number, z2 : Number;
			var xN : Number, yN : Number, zN : Number;
			var xF : Number, yF : Number, zF : Number;
			var minX : Number = Number.POSITIVE_INFINITY, minY : Number = Number.POSITIVE_INFINITY, minZ : Number = Number.POSITIVE_INFINITY;
			var maxX : Number = Number.NEGATIVE_INFINITY, maxY : Number = Number.NEGATIVE_INFINITY, maxZ : Number = Number.NEGATIVE_INFINITY;
			var scaleX : Number, scaleY : Number;
			var offsX : Number, offsY : Number;
			var halfSize : Number = _depthMapSize*.5;
			var i : uint , j : uint;

			i = 0;
			j = 12;
			while (i < 12) {
				x1 = _localFrustum[i++];
				y1 = _localFrustum[i++];
				zN = _localFrustum[i++];
				x2 = _localFrustum[j++] - x1;
				y2 = _localFrustum[j++] - y1;
				zF = _localFrustum[j++];
				xN = x1 + x2*minRatio;
				xF = x1 + x2*maxRatio;
				yN = y1 + y2*minRatio;
				yF = y1 + y2*maxRatio;
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

			// todo: optimize this
			matrix.copyRawDataFrom(raw);
			matrix.prependTranslation(offsX, offsY, 0);
			matrix.prependScale(scaleX, scaleY, 1);
			// need some padding for filtering
			matrix.appendScale(.96, .96, 1);
			matrix.appendTranslation(texOffsetX, texOffsetY, 0);
			matrix.appendScale(.5, .5, 1);
		}
	}
}
