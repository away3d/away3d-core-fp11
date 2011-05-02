package away3d.entities
{
	import away3d.animators.data.AnimationBase;
	import away3d.animators.data.AnimationStateBase;
	import away3d.animators.data.NullAnimation;
	import away3d.arcane;
	import away3d.bounds.BoundingSphere;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.containers.View3D;
	import away3d.core.base.IRenderable;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.RenderableNode;
	import away3d.materials.MaterialBase;
	import away3d.materials.SegmentMaterial;
	import away3d.primitives.data.Segment;

	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	public class SegmentSet extends Entity implements IRenderable
	{
		private var _material : MaterialBase;
		private var _nullAnimation : NullAnimation;
		private var _animationState : AnimationStateBase;
		private var _vertices : Vector.<Number>;
		protected var _segments : Vector.<Segment>;

		private var _numVertices : uint;
		private var _indices : Vector.<uint>;
		private var _numIndices : uint;
		private var _vertexBufferDirty : Boolean;
		private var _indexBufferDirty : Boolean;
		private var _vertexBuffer : VertexBuffer3D;
		private var _indexBuffer : IndexBuffer3D;
		private var _lineCount : uint;

		public function SegmentSet()
		{
			super();

			_nullAnimation ||= new NullAnimation();
			_vertices = new Vector.<Number>();
			_segments = new Vector.<Segment>();
			_numVertices = 0;
			_indices = new Vector.<uint>();

			material = new SegmentMaterial();
		}

		public function addSegment(segment : Segment) : void
		{
			segment.index = _vertices.length;
			segment.segmentsBase = this;
			_segments.push(segment);

			updateSegment(segment);

			var index : uint = _lineCount << 2;

			_indices.push(index, index + 1, index + 2, index + 3, index + 2, index + 1);

			_numVertices = _vertices.length / 11;
			_numIndices = _indices.length;
			_vertexBufferDirty = true;
			_indexBufferDirty = true;
			_lineCount++;
		}

		arcane function updateSegment(segment : Segment) : void
		{
			//to do add support for curve segment
			var start : Vector3D = segment._start;
			var end : Vector3D = segment._end;
			var startX : Number = start.x, startY : Number = start.y, startZ : Number = start.z;
			var endX : Number = end.x, endY : Number = end.y, endZ : Number = end.z;
			var startR : Number = segment._startR, startG : Number = segment._startG, startB : Number = segment._startB;
			var endR : Number = segment._endR, endG : Number = segment._endG, endB : Number = segment._endB;
			var index : uint = segment.index;
			var t : Number = segment.thickness;


			_vertices[index++] = startX;
			_vertices[index++] = startY;
			_vertices[index++] = startZ;
			_vertices[index++] = endX;
			_vertices[index++] = endY;
			_vertices[index++] = endZ;
			_vertices[index++] = t;
			_vertices[index++] = startR;
			_vertices[index++] = startG;
			_vertices[index++] = startB;
			_vertices[index++] = 1;

			_vertices[index++] = endX;
			_vertices[index++] = endY;
			_vertices[index++] = endZ;
			_vertices[index++] = startX;
			_vertices[index++] = startY;
			_vertices[index++] = startZ;
			_vertices[index++] = -t;
			_vertices[index++] = endR;
			_vertices[index++] = endG;
			_vertices[index++] = endB;
			_vertices[index++] = 1;

			_vertices[index++] = startX;
			_vertices[index++] = startY;
			_vertices[index++] = startZ;
			_vertices[index++] = endX;
			_vertices[index++] = endY;
			_vertices[index++] = endZ;
			_vertices[index++] = -t;
			_vertices[index++] = startR;
			_vertices[index++] = startG;
			_vertices[index++] = startB;
			_vertices[index++] = 1;

			_vertices[index++] = endX;
			_vertices[index++] = endY;
			_vertices[index++] = endZ;
			_vertices[index++] = startX;
			_vertices[index++] = startY;
			_vertices[index++] = startZ;
			_vertices[index++] = t;
			_vertices[index++] = endR;
			_vertices[index++] = endG;
			_vertices[index++] = endB;
			_vertices[index++] = 1;

			_vertexBufferDirty = true;
		}


		private function remove(index : uint) : void
		{
			var indVert : uint = _indices[index] * 11;
			_indices.splice(index, 6);
			_vertices.splice(indVert, 44);

			_numVertices = _vertices.length / 11;
			_numIndices = _indices.length;
			_vertexBufferDirty = true;
			_indexBufferDirty = true;
		}

		public function removeSegment(segment : Segment) : void
		{
			//to do, add support curve indices/offset
			var index : uint;
			for (var i : uint = 0; i < _segments.length; ++i) {
				if (_segments[i] == segment) {
					_segments.splice(i, 1);
					remove(segment.index);
					_lineCount--;
				} else {
					_segments[i].index = index;
					index += 6;
				}
			}
			_vertexBufferDirty = true;
			_indexBufferDirty = true;
		}

		protected function clearSegments() : void
		{
			_vertices.length = 0;
			_indices.length = 0;
			_segments.length = 0;
			_vertexBufferDirty = true;
			_indexBufferDirty = true;
		}

		public function getVertexBuffer(context : Context3D, contextIndex : uint) : VertexBuffer3D
		{
			if (_vertexBufferDirty) {
				_vertexBuffer = context.createVertexBuffer(_numVertices, 11);
				_vertexBuffer.uploadFromVector(_vertices, 0, _numVertices);
				_vertexBufferDirty = false;
			}
			return _vertexBuffer;
		}

		public function getUVBuffer(context : Context3D, contextIndex : uint) : VertexBuffer3D
		{
			return null;
		}

		public function getVertexNormalBuffer(context : Context3D, contextIndex : uint) : VertexBuffer3D
		{
			return null;
		}

		public function getVertexTangentBuffer(context : Context3D, contextIndex : uint) : VertexBuffer3D
		{
			return null;
		}

		public function getIndexBuffer(context : Context3D, contextIndex : uint) : IndexBuffer3D
		{
			if (_indexBufferDirty) {
				_indexBuffer = context.createIndexBuffer(_numIndices);
				_indexBuffer.uploadFromVector(_indices, 0, _numIndices);
				_indexBufferDirty = false;
			}
			return _indexBuffer;
		}

		public function get mouseDetails() : Boolean
		{
			return false;
		}

		public function get numTriangles() : uint
		{
			return _numIndices / 3;
		}

		public function get sourceEntity() : Entity
		{
			return this;
		}

		public function get castsShadows() : Boolean
		{
			return false;
		}

		public function get material() : MaterialBase
		{
			return _material;
		}

		public function get animation() : AnimationBase
		{
			return _nullAnimation;
		}

		public function get animationState() : AnimationStateBase
		{
			return _animationState;
		}

		public function set material(value : MaterialBase) : void
		{
			if (value == _material) return;
			if (_material) _material.removeOwner(this);
			_material = value;
			if (_material) _material.addOwner(this);
		}

		override protected function getDefaultBoundingVolume() : BoundingVolumeBase
		{
			return new BoundingSphere();
		}

		override protected function updateBounds() : void
		{
			// todo: fix bounds
			_bounds.fromExtremes(-100, -100, 0, 100, 100, 0);
			_boundsInvalid = false;
		}

		override protected function createEntityPartitionNode() : EntityNode
		{
			return new RenderableNode(this);
		}
	}
}
