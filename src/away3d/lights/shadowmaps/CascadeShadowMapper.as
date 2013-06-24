package away3d.lights.shadowmaps
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.FreeMatrixLens;
	import away3d.cameras.lenses.LensBase;
	import away3d.containers.Scene3D;
	import away3d.core.math.Matrix3DUtils;
	import away3d.core.render.DepthRenderer;
	
	import flash.display3D.textures.TextureBase;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	
	use namespace arcane;
	
	public class CascadeShadowMapper extends DirectionalShadowMapper implements IEventDispatcher
	{
		protected var _scissorRects:Vector.<Rectangle>;
		private var _scissorRectsInvalid:Boolean = true;
		private var _splitRatios:Vector.<Number>;
		
		private var _numCascades:int;
		private var _depthCameras:Vector.<Camera3D>;
		private var _depthLenses:Vector.<FreeMatrixLens>;
		
		private var _texOffsetsX:Vector.<Number>;
		private var _texOffsetsY:Vector.<Number>;
		
		private var _changeDispatcher:EventDispatcher;
		private var _nearPlaneDistances:Vector.<Number>;
		
		public function CascadeShadowMapper(numCascades:uint = 3)
		{
			super();
			if (numCascades < 1 || numCascades > 4)
				throw new Error("numCascades must be an integer between 1 and 4");
			_numCascades = numCascades;
			_changeDispatcher = new EventDispatcher(this);
			init();
		}
		
		public function getSplitRatio(index:uint):Number
		{
			return _splitRatios[index];
		}
		
		public function setSplitRatio(index:uint, value:Number):void
		{
			if (value < 0)
				value = 0;
			else if (value > 1)
				value = 1;
			
			if (index >= _numCascades)
				throw new Error("index must be smaller than the number of cascades!");
			
			_splitRatios[index] = value;
		}
		
		public function getDepthProjections(partition:uint):Matrix3D
		{
			return _depthCameras[partition].viewProjection;
		}
		
		private function init():void
		{
			_splitRatios = new Vector.<Number>(_numCascades, true);
			_nearPlaneDistances = new Vector.<Number>(_numCascades, true);
			
			var s:Number = 1;
			for (var i:int = _numCascades - 1; i >= 0; --i) {
				_splitRatios[i] = s;
				s *= .4;
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
		
		// will not be allowed
		override public function set depthMapSize(value:uint):void
		{
			if (value == _depthMapSize)
				return;
			super.depthMapSize = value;
			invalidateScissorRects();
		}
		
		private function invalidateScissorRects():void
		{
			_scissorRectsInvalid = true;
		}
		
		public function get numCascades():int
		{
			return _numCascades;
		}
		
		public function set numCascades(value:int):void
		{
			if (value == _numCascades)
				return;
			if (value < 1 || value > 4)
				throw new Error("numCascades must be an integer between 1 and 4");
			_numCascades = value;
			invalidateScissorRects();
			init();
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		override protected function drawDepthMap(target:TextureBase, scene:Scene3D, renderer:DepthRenderer):void
		{
			if (_scissorRectsInvalid)
				updateScissorRects();
			
			_casterCollector.cullPlanes = _cullPlanes;
			_casterCollector.camera = _overallDepthCamera;
			_casterCollector.clear();
			scene.traversePartitions(_casterCollector);
			
			renderer.renderCascades(_casterCollector, target, _numCascades, _scissorRects, _depthCameras);
			
			_casterCollector.cleanUp();
		}
		
		private function updateScissorRects():void
		{
			var half:Number = _depthMapSize*.5;
			
			_scissorRects[0] = new Rectangle(0, 0, half, half);
			_scissorRects[1] = new Rectangle(half, 0, half, half);
			_scissorRects[2] = new Rectangle(0, half, half, half);
			_scissorRects[3] = new Rectangle(half, half, half, half);
			
			_scissorRectsInvalid = false;
		}
		
		override protected function updateDepthProjection(viewCamera:Camera3D):void
		{
			var matrix:Matrix3D;
			var lens:LensBase = viewCamera.lens;
			var lensNear:Number = lens.near;
			var lensRange:Number = lens.far - lensNear;
			
			updateProjectionFromFrustumCorners(viewCamera, viewCamera.lens.frustumCorners, _matrix);
			_matrix.appendScale(.96, .96, 1);
			_overallDepthLens.matrix = _matrix;
			updateCullPlanes(viewCamera);
			
			for (var i:int = 0; i < _numCascades; ++i) {
				matrix = _depthLenses[i].matrix;
				
				_nearPlaneDistances[i] = lensNear + _splitRatios[i]*lensRange;
				_depthCameras[i].transform = _overallDepthCamera.transform;
				
				updateProjectionPartition(matrix, _splitRatios[i], _texOffsetsX[i], _texOffsetsY[i]);
				
				_depthLenses[i].matrix = matrix;
			}
		}
		
		private function updateProjectionPartition(matrix:Matrix3D, splitRatio:Number, texOffsetX:Number, texOffsetY:Number):void
		{
			var raw:Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			var xN:Number, yN:Number, zN:Number;
			var xF:Number, yF:Number, zF:Number;
			var minX:Number = Number.POSITIVE_INFINITY, minY:Number = Number.POSITIVE_INFINITY, minZ:Number;
			var maxX:Number = Number.NEGATIVE_INFINITY, maxY:Number = Number.NEGATIVE_INFINITY, maxZ:Number = Number.NEGATIVE_INFINITY;
			var i:uint = 0;
			
			while (i < 12) {
				xN = _localFrustum[i];
				yN = _localFrustum[uint(i + 1)];
				zN = _localFrustum[uint(i + 2)];
				xF = xN + (_localFrustum[uint(i + 12)] - xN)*splitRatio;
				yF = yN + (_localFrustum[uint(i + 13)] - yN)*splitRatio;
				zF = zN + (_localFrustum[uint(i + 14)] - zN)*splitRatio;
				if (xN < minX)
					minX = xN;
				if (xN > maxX)
					maxX = xN;
				if (yN < minY)
					minY = yN;
				if (yN > maxY)
					maxY = yN;
				if (zN > maxZ)
					maxZ = zN;
				if (xF < minX)
					minX = xF;
				if (xF > maxX)
					maxX = xF;
				if (yF < minY)
					minY = yF;
				if (yF > maxY)
					maxY = yF;
				if (zF > maxZ)
					maxZ = zF;
				i += 3;
			}
			
			minZ = 1;
			
			var w:Number = (maxX - minX);
			var h:Number = (maxY - minY);
			var d:Number = 1/(maxZ - minZ);
			
			if (minX < 0)
				minX -= _snap; // because int() rounds up for < 0
			if (minY < 0)
				minY -= _snap;
			minX = int(minX/_snap)*_snap;
			minY = int(minY/_snap)*_snap;
			
			var snap2:Number = 2*_snap;
			w = int(w/snap2 + 1)*snap2;
			h = int(h/snap2 + 1)*snap2;
			
			maxX = minX + w;
			maxY = minY + h;
			
			w = 1/w;
			h = 1/h;
			
			raw[0] = 2*w;
			raw[5] = 2*h;
			raw[10] = d;
			raw[12] = -(maxX + minX)*w;
			raw[13] = -(maxY + minY)*h;
			raw[14] = -minZ*d;
			raw[15] = 1;
			raw[1] = raw[2] = raw[3] = raw[4] = raw[6] = raw[7] = raw[8] = raw[9] = raw[11] = 0;
			
			matrix.copyRawDataFrom(raw);
			matrix.appendScale(.96, .96, 1);
			matrix.appendTranslation(texOffsetX, texOffsetY, 0);
			matrix.appendScale(.5, .5, 1);
		}
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
		{
			_changeDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void
		{
			_changeDispatcher.removeEventListener(type, listener, useCapture);
		}
		
		public function dispatchEvent(event:Event):Boolean
		{
			return _changeDispatcher.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean
		{
			return _changeDispatcher.hasEventListener(type);
		}
		
		public function willTrigger(type:String):Boolean
		{
			return _changeDispatcher.willTrigger(type);
		}
		
		arcane function get nearPlaneDistances():Vector.<Number>
		{
			return _nearPlaneDistances;
		}
	}
}
