package away3d.entities
{
	import away3d.arcane;
	import away3d.animators.IAnimator;
	import away3d.bounds.BoundingSphere;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.RenderableNode;
	import away3d.materials.MaterialBase;
	import away3d.materials.SegmentMaterial;
	import away3d.primitives.LineSegment;
	import away3d.primitives.data.Segment;
	import away3d.library.assets.AssetType;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	use namespace arcane;
	
	public class SegmentSet extends Entity implements IRenderable
	{
		private const LIMIT:uint = 3*0xFFFF;
		private var _activeSubSet:SubSet;
		private var _subSets:Vector.<SubSet>;
		private var _subSetCount:uint;
		private var _numIndices:uint;
		private var _material:MaterialBase;
		private var _animator:IAnimator;
		private var _hasData:Boolean;
		
		protected var _segments:Dictionary;
		private var _indexSegments:uint;
		
		/**
		 * Creates a new SegmentSet object.
		 */
		public function SegmentSet()
		{
			super();
			
			_subSetCount = 0;
			_subSets = new Vector.<SubSet>();
			addSubSet();
			
			_segments = new Dictionary();
			material = new SegmentMaterial();
		}
		
		/**
		 * Adds a new segment to the SegmentSet.
		 *
		 * @param segment  the segment to add
		 */
		public function addSegment(segment:Segment):void
		{
			segment.segmentsBase = this;
			
			_hasData = true;
			
			var subSetIndex:uint = _subSets.length - 1;
			var subSet:SubSet = _subSets[subSetIndex];
			
			if (subSet.vertices.length + 44 > LIMIT) {
				subSet = addSubSet();
				subSetIndex++;
			}
			
			segment.index = subSet.vertices.length;
			segment.subSetIndex = subSetIndex;
			
			updateSegment(segment);
			
			var index:uint = subSet.lineCount << 2;
			
			subSet.indices.push(index, index + 1, index + 2, index + 3, index + 2, index + 1);
			subSet.numVertices = subSet.vertices.length/11;
			subSet.numIndices = subSet.indices.length;
			subSet.lineCount++;
			
			var segRef:SegRef = new SegRef();
			segRef.index = index;
			segRef.subSetIndex = subSetIndex;
			segRef.segment = segment;
			
			_segments[_indexSegments] = segRef;
			
			_indexSegments++;
		}
		
		/**
		 * Removes a segment from the SegmentSet by its index in the set.
		 *
		 * @param index        The index of the segment to remove
		 * @param dispose    If the segment must be disposed as well. Default is false;
		 *
		 *    Removing a Segment by an index when segment is unknown
		 *    index of the segment is relative to the order it was added to the segmentSet.
		 *    If a segment was removed from or added to the segmentSet, a segment index may have changed.
		 *    The index of each Segment is updated when one is added or removed.
		 *    If 2 segments are added, segment #1 has index 0, segment #2 has index 1
		 *    if segment #1 is removed, segment#2 will get index 0 instead of 1.
		 */
		public function removeSegmentByIndex(index:uint, dispose:Boolean = false):void
		{
			var segRef:SegRef;
			if (index >= _indexSegments)
				return;
			
			if (_segments[index])
				segRef = _segments[index];
			else
				return;
			
			var subSet:SubSet;
			if (!_subSets[segRef.subSetIndex])
				return;
			var subSetIndex:int = segRef.subSetIndex;
			subSet = _subSets[segRef.subSetIndex];
			
			var segment:Segment = segRef.segment;
			var indices:Vector.<uint> = subSet.indices;
			
			var ind:uint = index*6;
			for (var i:uint = ind; i < indices.length; ++i)
				indices[i] -= 4;
			
			subSet.indices.splice(index*6, 6);
			subSet.vertices.splice(index*44, 44);
			subSet.numVertices = subSet.vertices.length/11;
			subSet.numIndices = indices.length;
			subSet.vertexBufferDirty = true;
			subSet.indexBufferDirty = true;
			subSet.lineCount--;
			
			if (dispose) {
				segment.dispose();
				segment = null;
				
			} else {
				segment.index = -1;
				segment.segmentsBase = null;
			}
			
			if (subSet.lineCount == 0) {
				
				if (subSetIndex == 0)
					_hasData = false;
				
				else {
					subSet.dispose();
					_subSets[subSetIndex] = null;
					_subSets.splice(subSetIndex, 1);
				}
			}
			
			reOrderIndices(subSetIndex, index);
			
			segRef = null;
			_segments[_indexSegments] = null;
			_indexSegments--;
		}
		
		/**
		 * Removes a segment from the SegmentSet.
		 *
		 * @param segment        The segment to remove
		 * @param dispose        If the segment must be disposed as well. Default is false;
		 */
		public function removeSegment(segment:Segment, dispose:Boolean = false):void
		{
			if (segment.index == -1)
				return;
			removeSegmentByIndex(segment.index/44);
		}
		
		/**
		 * Empties the segmentSet from all its segments data
		 */
		public function removeAllSegments():void
		{
			var subSet:SubSet;
			for (var i:uint = 0; i < _subSetCount; ++i) {
				subSet = _subSets[i];
				subSet.vertices = null;
				subSet.indices = null;
				if (subSet.vertexBuffer)
					subSet.vertexBuffer.dispose();
				if (subSet.indexBuffer)
					subSet.indexBuffer.dispose();
				subSet = null;
			}
			
			for each (var segRef:SegRef in _segments)
				segRef = null;
			_segments = null;
			
			_subSetCount = 0;
			_activeSubSet = null;
			_indexSegments = 0;
			_subSets = new Vector.<SubSet>();
			_segments = new Dictionary();
			
			addSubSet();
			
			_hasData = false;
		}
		
		/**
		 * @returns a segment object from a given index.
		 */
		public function getSegment(index:uint):Segment
		{
			if (index > _indexSegments - 1)
				return null;
			
			return _segments[index].segment;
		}
		
		/**
		 * @returns howmany segments are in the SegmentSet
		 */
		public function get segmentCount():uint
		{
			return _indexSegments;
		}
		
		arcane function get subSetCount():uint
		{
			return _subSetCount;
		}
		
		arcane function updateSegment(segment:Segment):void
		{
			//to do: add support for curve segment
			var start:Vector3D = segment._start;
			var end:Vector3D = segment._end;
			var startX:Number = start.x, startY:Number = start.y, startZ:Number = start.z;
			var endX:Number = end.x, endY:Number = end.y, endZ:Number = end.z;
			var startR:Number = segment._startR, startG:Number = segment._startG, startB:Number = segment._startB;
			var endR:Number = segment._endR, endG:Number = segment._endG, endB:Number = segment._endB;
			var index:uint = segment.index;
			var t:Number = segment.thickness;
			
			var subSet:SubSet = _subSets[segment.subSetIndex];
			var vertices:Vector.<Number> = subSet.vertices;
			
			vertices[index++] = startX;
			vertices[index++] = startY;
			vertices[index++] = startZ;
			vertices[index++] = endX;
			vertices[index++] = endY;
			vertices[index++] = endZ;
			vertices[index++] = t;
			vertices[index++] = startR;
			vertices[index++] = startG;
			vertices[index++] = startB;
			vertices[index++] = 1;
			
			vertices[index++] = endX;
			vertices[index++] = endY;
			vertices[index++] = endZ;
			vertices[index++] = startX;
			vertices[index++] = startY;
			vertices[index++] = startZ;
			vertices[index++] = -t;
			vertices[index++] = endR;
			vertices[index++] = endG;
			vertices[index++] = endB;
			vertices[index++] = 1;
			
			vertices[index++] = startX;
			vertices[index++] = startY;
			vertices[index++] = startZ;
			vertices[index++] = endX;
			vertices[index++] = endY;
			vertices[index++] = endZ;
			vertices[index++] = -t;
			vertices[index++] = startR;
			vertices[index++] = startG;
			vertices[index++] = startB;
			vertices[index++] = 1;
			
			vertices[index++] = endX;
			vertices[index++] = endY;
			vertices[index++] = endZ;
			vertices[index++] = startX;
			vertices[index++] = startY;
			vertices[index++] = startZ;
			vertices[index++] = t;
			vertices[index++] = endR;
			vertices[index++] = endG;
			vertices[index++] = endB;
			vertices[index++] = 1;
			
			subSet.vertexBufferDirty = true;
			
			invalidateBounds();
		}
		
		arcane function get hasData():Boolean
		{
			return _hasData;
		}
		
		public function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D
		{
			if (_activeSubSet.indexContext3D != stage3DProxy.context3D || _activeSubSet.indexBufferDirty) {
				_activeSubSet.indexBuffer = stage3DProxy._context3D.createIndexBuffer(_activeSubSet.numIndices);
				_activeSubSet.indexBuffer.uploadFromVector(_activeSubSet.indices, 0, _activeSubSet.numIndices);
				_activeSubSet.indexBufferDirty = false;
				_activeSubSet.indexContext3D = stage3DProxy.context3D;
			}
			
			return _activeSubSet.indexBuffer;
		}
		
		public function activateVertexBuffer(index:int, stage3DProxy:Stage3DProxy):void
		{
			var subSet:SubSet = _subSets[index];
			
			_activeSubSet = subSet;
			_numIndices = subSet.numIndices;
			
			if (subSet.vertexContext3D != stage3DProxy.context3D || subSet.vertexBufferDirty) {
				subSet.vertexBuffer = stage3DProxy._context3D.createVertexBuffer(subSet.numVertices, 11);
				subSet.vertexBuffer.uploadFromVector(subSet.vertices, 0, subSet.numVertices);
				vertexBuffer = subSet.vertexBuffer;
				subSet.vertexBufferDirty = false;
				subSet.vertexContext3D = stage3DProxy.context3D;
			}
			
			var vertexBuffer:VertexBuffer3D = subSet.vertexBuffer;
			var context3d:Context3D = stage3DProxy._context3D;
			
			context3d.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context3d.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_3);
			context3d.setVertexBufferAt(2, vertexBuffer, 6, Context3DVertexBufferFormat.FLOAT_1);
			context3d.setVertexBufferAt(3, vertexBuffer, 7, Context3DVertexBufferFormat.FLOAT_4);
		}
		
		public function activateUVBuffer(index:int, stage3DProxy:Stage3DProxy):void
		{
		}
		
		public function activateVertexNormalBuffer(index:int, stage3DProxy:Stage3DProxy):void
		{
		}
		
		public function activateVertexTangentBuffer(index:int, stage3DProxy:Stage3DProxy):void
		{
		}
		
		public function activateSecondaryUVBuffer(index:int, stage3DProxy:Stage3DProxy):void
		{
		}
		
		private function reOrderIndices(subSetIndex:uint, index:int):void
		{
			var segRef:SegRef;
			
			for (var i:uint = index; i < _indexSegments - 1; ++i) {
				segRef = _segments[i + 1];
				segRef.index = i;
				if (segRef.subSetIndex == subSetIndex)
					segRef.segment.index -= 44;
				_segments[i] = segRef;
			}
		
		}
		
		private function addSubSet():SubSet
		{
			var subSet:SubSet = new SubSet();
			_subSets.push(subSet);
			
			subSet.vertices = new Vector.<Number>();
			subSet.numVertices = 0;
			subSet.indices = new Vector.<uint>();
			subSet.numIndices = 0;
			subSet.vertexBufferDirty = true;
			subSet.indexBufferDirty = true;
			subSet.lineCount = 0;
			
			_subSetCount++;
			
			return subSet;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			super.dispose();
			removeAllSegments();
			_segments = null
			_material = null;
			var subSet:SubSet = _subSets[0];
			subSet.vertices = null;
			subSet.indices = null;
			_subSets = null;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get mouseEnabled():Boolean
		{
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function getDefaultBoundingVolume():BoundingVolumeBase
		{
			return new BoundingSphere();
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateBounds():void
		{
			var subSet:SubSet;
			var len:uint;
			var v:Number;
			var index:uint;
			
			var minX:Number = Infinity;
			var minY:Number = Infinity;
			var minZ:Number = Infinity;
			var maxX:Number = -Infinity;
			var maxY:Number = -Infinity;
			var maxZ:Number = -Infinity;
			var vertices:Vector.<Number>;
			
			for (var i:uint = 0; i < _subSetCount; ++i) {
				subSet = _subSets[i];
				index = 0;
				vertices = subSet.vertices;
				len = vertices.length;
				
				if (len == 0)
					continue;
				
				while (index < len) {
					
					v = vertices[index++];
					if (v < minX)
						minX = v;
					else if (v > maxX)
						maxX = v;
					
					v = vertices[index++];
					if (v < minY)
						minY = v;
					else if (v > maxY)
						maxY = v;
					
					v = vertices[index++];
					if (v < minZ)
						minZ = v;
					else if (v > maxZ)
						maxZ = v;
					
					index += 8;
				}
			}
			
			if (minX != Infinity)
				_bounds.fromExtremes(minX, minY, minZ, maxX, maxY, maxZ);
			
			else {
				var min:Number = .5;
				_bounds.fromExtremes(-min, -min, -min, min, min, min);
			}
			
			_boundsInvalid = false;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function createEntityPartitionNode():EntityNode
		{
			return new RenderableNode(this);
		}
		
		public function get numTriangles():uint
		{
			return _numIndices/3;
		}
		
		public function get sourceEntity():Entity
		{
			return this;
		}
		
		public function get castsShadows():Boolean
		{
			return false;
		}
		
		public function get material():MaterialBase
		{
			return _material;
		}
		
		public function get animator():IAnimator
		{
			return _animator;
		}
		
		public function set material(value:MaterialBase):void
		{
			if (value == _material)
				return;
			if (_material)
				_material.removeOwner(this);
			_material = value;
			if (_material)
				_material.addOwner(this);
		}
		
		public function get uvTransform():Matrix
		{
			return null;
		}
		
		public function get vertexData():Vector.<Number>
		{
			return null;
		}
		
		public function get indexData():Vector.<uint>
		{
			return null;
		}
		
		public function get UVData():Vector.<Number>
		{
			return null;
		}
		
		public function get numVertices():uint
		{
			return null;
		}
		
		public function get vertexStride():uint
		{
			return 11;
		}
		
		public function get vertexNormalData():Vector.<Number>
		{
			return null;
		}
		
		public function get vertexTangentData():Vector.<Number>
		{
			return null;
		}
		
		public function get vertexOffset():int
		{
			return 0;
		}
		
		public function get vertexNormalOffset():int
		{
			return 0;
		}
		
		public function get vertexTangentOffset():int
		{
			return 0;
		}
		
		override public function get assetType():String
		{
			return AssetType.SEGMENT_SET;
		}
		
		public function getRenderSceneTransform(camera:Camera3D):Matrix3D
		{
			return _sceneTransform;
		}
	}
}

final class SegRef
{
	import away3d.primitives.data.Segment;
	
	public var index:uint;
	public var subSetIndex:uint;
	public var segment:Segment;
}

final class SubSet
{
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	
	public var vertices:Vector.<Number>;
	public var numVertices:uint;
	
	public var indices:Vector.<uint>;
	public var numIndices:uint;
	
	public var vertexBufferDirty:Boolean;
	public var indexBufferDirty:Boolean;
	
	public var vertexContext3D:Context3D;
	public var indexContext3D:Context3D;
	
	public var vertexBuffer:VertexBuffer3D;
	public var indexBuffer:IndexBuffer3D;
	public var lineCount:uint;
	
	public function dispose():void
	{
		vertices = null;
		if (vertexBuffer)
			vertexBuffer.dispose();
		if (indexBuffer)
			indexBuffer.dispose();
	}
}

