package away3d.lights.shadowmaps
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.FreeMatrixLens;
	import away3d.cameras.lenses.LensBase;
	import away3d.cameras.lenses.OrthographicOffCenterLens;
	import away3d.containers.Scene3D;
	import away3d.core.math.Matrix3DUtils;
	import away3d.core.math.Plane3D;
	import away3d.core.render.DepthRenderer;
	import away3d.lights.DirectionalLight;
	import flash.display3D.textures.TextureBase;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;

	use namespace arcane;

	public class CascadeShadowMapper extends ShadowMapperBase implements IEventDispatcher
	{
		protected var _scissorRects : Vector.<Rectangle>;
		private var _scissorRectsInvalid : Boolean = true;
		private var _splitRatios : Vector.<Number>;

		private var _numCascades : int;
		private var _overallCamera : Camera3D;
		private var _overallLens : OrthographicOffCenterLens;
		private var _depthCameras : Vector.<Camera3D>;
		private var _depthLenses : Vector.<FreeMatrixLens>;

		private var _lightOffset : Number = 5000;
		private var _localFrustum : Vector.<Number>;
		private var _texOffsetsX : Vector.<Number>;
		private var _texOffsetsY : Vector.<Number>;

		private static var _calcMatrix : Matrix3D = new Matrix3D();
		private static var _calcVector : Vector3D = new Vector3D();

		private var _changeDispatcher : EventDispatcher;
		private var _nearPlaneDistances : Vector.<Number>;
		private var _splitPlanes : Vector.<Plane3D>;

		public function CascadeShadowMapper(numCascades : uint = 3)
		{
			super();
			if (numCascades < 1 || numCascades > 4) throw new Error("numCascades must be an integer between 1 and 4");
			_numCascades = numCascades;
			_changeDispatcher = new EventDispatcher(this);
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
			_splitRatios = new Vector.<Number>(_numCascades, true);
			_nearPlaneDistances = new Vector.<Number>(_numCascades, true);
			_splitPlanes = new Vector.<Plane3D>(_numCascades, true);

			var s : Number = 1;
			for (var i : int = _numCascades-1; i >= 0; --i) {
				_splitRatios[i] = s;
				s *= .3333;
			}

			_texOffsetsX = new <Number>[-1, 1, -1, 1];
			_texOffsetsY = new <Number>[1, 1, -1, -1];
			_scissorRects = new Vector.<Rectangle>(4, true);
			_depthLenses = new Vector.<FreeMatrixLens>();
			_depthCameras = new Vector.<Camera3D>();

			_overallLens = new OrthographicOffCenterLens(-1, 1, -1, 1);
			_overallCamera = new Camera3D(_overallLens);

			for (i = 0; i < _numCascades; ++i) {
				_splitPlanes[i] = new Plane3D();
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

		public function set numCascades(value : int) : void
		{
			if (value == _numCascades) return;
			if (value < 1 || value > 4) throw new Error("numCascades must be an integer between 1 and 4");
			_numCascades = value;
			invalidateScissorRects();
			init();
			dispatchEvent(new Event(Event.CHANGE));
		}

		override protected function drawDepthMap(target : TextureBase, scene : Scene3D, renderer : DepthRenderer) : void
		{
			if (_scissorRectsInvalid) updateScissorRects();

			_casterCollector.clear();
			_casterCollector.camera = _overallCamera;
			scene.traversePartitions(_casterCollector);

			renderer.renderCascades(_casterCollector, target, _numCascades, _scissorRects, _splitPlanes, _depthCameras);

			_casterCollector.cleanUp();
		}

		private function updateScissorRects() : void
		{
			var half : Number = _depthMapSize*.5;

			_scissorRects[0] = new Rectangle(0, 0, half, half);
			_scissorRects[1] = new Rectangle(half, 0, half, half);
			_scissorRects[2] = new Rectangle(0, half, half, half);
			_scissorRects[3] = new Rectangle(half, half, half, half);

			_scissorRectsInvalid = false;
		}

		override protected function updateDepthProjection(viewCamera : Camera3D) : void
		{
			var matrix : Matrix3D;

			updateLocalFrustum(viewCamera);
			updateOverallMatrix();

			for (var i : int = 0; i < _numCascades; ++i) {
				matrix = _depthLenses[i].matrix;

				_depthCameras[i].transform = _overallCamera.transform;

				updateProjectionPartition(matrix, i == 0? 0 : _splitRatios[i-1], _splitRatios[i], _texOffsetsX[i], _texOffsetsY[i]);

				_depthLenses[i].matrix = matrix;
			}
		}

		private function updateLocalFrustum(viewCamera : Camera3D) : void
		{
			var corners : Vector.<Number> = viewCamera.lens.frustumCorners;
			var dir : Vector3D = DirectionalLight(_light).sceneDirection;

			_overallCamera.transform = _light.sceneTransform;
			_overallCamera.x = viewCamera.x-dir.x * _lightOffset;
			_overallCamera.y = viewCamera.y-dir.y * _lightOffset;
			_overallCamera.z = viewCamera.z-dir.z * _lightOffset;

			_calcMatrix.copyFrom(_overallCamera.inverseSceneTransform);
			_calcMatrix.prepend(viewCamera.sceneTransform);
			_calcMatrix.transformVectors(corners, _localFrustum);

			viewCamera.sceneTransform.copyColumnTo(2, _calcVector);
			var point : Vector3D = viewCamera.scenePosition;
			var a : Number = -_calcVector.x;
			var b : Number = -_calcVector.y;
			var c : Number = -_calcVector.z;
			var len : Number = Math.sqrt(a*a + b*b + c*c);
			var d : Number = a*point.x + b*point.y + c*point.z;
			var lens : LensBase = viewCamera.lens;
			var near : Number = lens.near;
			var frustumDepth : Number = lens.far - near;

			for (var i : uint = 0; i < _numCascades; ++i) {
				var dist : Number = near + _splitRatios[i]*frustumDepth;
				var plane : Plane3D = _splitPlanes[i];
				plane.a = a;
				plane.b = b;
				plane.c = c;
				plane.d = d - dist * len;
				_nearPlaneDistances[i] = dist;
			}
		}

		private function updateOverallMatrix() : void
		{
			var i : uint;
			var xN : Number, yN : Number, zN : Number;
			var minX : Number = Number.POSITIVE_INFINITY, minY : Number = Number.POSITIVE_INFINITY;
			var maxX : Number = Number.NEGATIVE_INFINITY, maxY : Number = Number.NEGATIVE_INFINITY, maxZ : Number = Number.NEGATIVE_INFINITY;

			while (i < 24) {
				xN = _localFrustum[i];
				yN = _localFrustum[uint(i+1)];
				zN = _localFrustum[uint(i+2)];
				if (xN < minX) minX = xN;
				if (xN > maxX) maxX = xN;
				if (yN < minY) minY = yN;
				if (yN > maxY) maxY = yN;
				if (zN > maxZ) maxZ = zN;
				i += 3;
			}

			_overallLens.minX = minX;
			_overallLens.minY = minY;
			_overallLens.near = 1;
			_overallLens.maxX = maxX;
			_overallLens.maxY = maxY;
			_overallLens.far = maxZ;
		}

		private function updateProjectionPartition(matrix : Matrix3D, minRatio : Number, maxRatio : Number, texOffsetX : Number, texOffsetY : Number) : void
		{
			var raw : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			var x1 : Number, y1 : Number, z1 : Number;
			var x2 : Number, y2 : Number, z2 : Number;
			var xN : Number, yN : Number, zN : Number;
			var xF : Number, yF : Number, zF : Number;
			var minX : Number = Number.POSITIVE_INFINITY, minY : Number = Number.POSITIVE_INFINITY, minZ : Number;
			var maxX : Number = Number.NEGATIVE_INFINITY, maxY : Number = Number.NEGATIVE_INFINITY, maxZ : Number = Number.NEGATIVE_INFINITY;
			var scaleX : Number, scaleY : Number;
			var offsX : Number, offsY : Number;
			var halfSize : Number = _depthMapSize*.5;
			var i : uint;

			i = 0;
			while (i < 12) {
				x1 = _localFrustum[i];
				y1 = _localFrustum[uint(i+1)];
				z1 = _localFrustum[uint(i+2)];
				x2 = _localFrustum[uint(i+12)] - x1;
				y2 = _localFrustum[uint(i+13)] - y1;
				z2 = _localFrustum[uint(i+14)] - z1;
				xN = x1 + x2*minRatio;
				yN = y1 + y2*minRatio;
				zN = z1 + z2*maxRatio;
				xF = x1 + x2*maxRatio;
				yF = y1 + y2*maxRatio;
				zF = z1 + z2*maxRatio;
				if (xN < minX) minX = xN;
				if (xN > maxX) maxX = xN;
				if (yN < minY) minY = yN;
				if (yN > maxY) maxY = yN;
				if (zN > maxZ) maxZ = zN;
				if (xF < minX) minX = xF;
				if (xF > maxX) maxX = xF;
				if (yF < minY) minY = yF;
				if (yF > maxY) maxY = yF;
				if (zF > maxZ) maxZ = zF;
				i += 3;
			}

			minZ = 10;

			var quantizeFactor : Number = 128;
			var invQuantizeFactor : Number = 1/quantizeFactor;

			scaleX = 2*invQuantizeFactor/Math.ceil((maxX - minX)*invQuantizeFactor);
			scaleY = 2*invQuantizeFactor/Math.ceil((maxY - minY)*invQuantizeFactor);

			offsX = Math.ceil(-.5*(maxX + minX)*scaleX*halfSize) / halfSize;
			offsY = Math.ceil(-.5*(maxY + minY)*scaleY*halfSize) / halfSize;

			var d : Number = 1/(maxZ - minZ);

			raw[0] = scaleX;
			raw[5] = scaleY;
			raw[10] = d;
			raw[12] = offsX;
			raw[13] = offsY;
			raw[14] = -minZ * d;
			raw[15] = 1;
			raw[1] = raw[2] = raw[3] = raw[4] = raw[6] = raw[7] = raw[8] = raw[9] = raw[11] = 0;

			matrix.copyRawDataFrom(raw);
			matrix.appendScale(.96, .96, 1);
			matrix.appendTranslation(texOffsetX, texOffsetY, 0);
			matrix.appendScale(.5, .5, 1);
		}

		public function addEventListener(type : String, listener : Function, useCapture : Boolean = false, priority : int = 0, useWeakReference : Boolean = false) : void
		{
			_changeDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}

		public function removeEventListener(type : String, listener : Function, useCapture : Boolean = false) : void
		{
			_changeDispatcher.removeEventListener(type, listener, useCapture);
		}

		public function dispatchEvent(event : Event) : Boolean
		{
			return _changeDispatcher.dispatchEvent(event);
		}

		public function hasEventListener(type : String) : Boolean
		{
			return _changeDispatcher.hasEventListener(type);
		}

		public function willTrigger(type : String) : Boolean
		{
			return _changeDispatcher.willTrigger(type);
		}

		arcane function get nearPlaneDistances() : Vector.<Number>
		{
			return _nearPlaneDistances;
		}
	}
}
