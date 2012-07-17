package away3d.entities
{

	import away3d.animators.IAnimator;
	import away3d.arcane;
	import away3d.bounds.BoundingSphere;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.RenderableNode;
	import away3d.materials.MaterialBase;
	import away3d.materials.SegmentMaterial;
	import away3d.primitives.LineSegment;
	import away3d.primitives.data.Segment;
	import flash.display3D.Context3D;

	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix;
	import flash.geom.Vector3D;

	use namespace arcane;

	public class SegmentSet extends Entity implements IRenderable
	{
		protected var _segments:Vector.<Segment>;

		private var _material:MaterialBase;
		private var _vertices:Vector.<Number>;
		private var _animator : IAnimator;
		
		private var _numVertices:uint;
		private var _indices:Vector.<uint>;
		private var _numIndices:uint;
		private var _vertexBufferDirty:Boolean;
		private var _indexBufferDirty:Boolean;
		
		private var _vertexContext3D:Context3D;
		private var _indexContext3D:Context3D;
		
		private var _vertexBuffer:VertexBuffer3D;
		private var _indexBuffer:IndexBuffer3D;
		private var _lineCount:uint;

		public function SegmentSet()
		{
			super();
			
			_vertices = new Vector.<Number>();
			_segments = new Vector.<Segment>();
			_numVertices = 0;
			_indices = new Vector.<uint>();

			material = new SegmentMaterial();
		}

		public function addSegment( segment:Segment ):void
		{
			segment.index = _vertices.length;
			segment.segmentsBase = this;
			_segments.push( segment );

			updateSegment( segment );

			var index:uint = _lineCount << 2;

			_indices.push( index, index + 1, index + 2, index + 3, index + 2, index + 1 );

			_numVertices = _vertices.length / 11;
			_numIndices = _indices.length;
			_vertexBufferDirty = true;
			_indexBufferDirty = true;
			_lineCount++;
		}

		arcane function updateSegment( segment:Segment ):void
		{
			//to do add support for curve segment
			var start:Vector3D = segment._start;
			var end:Vector3D = segment._end;
			var startX:Number = start.x, startY:Number = start.y, startZ:Number = start.z;
			var endX:Number = end.x, endY:Number = end.y, endZ:Number = end.z;
			var startR:Number = segment._startR, startG:Number = segment._startG, startB:Number = segment._startB;
			var endR:Number = segment._endR, endG:Number = segment._endG, endB:Number = segment._endB;
			var index:uint = segment.index;
			var t:Number = segment.thickness;


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

		private function removeSegmentByIndex( index:uint ):void
		{
			var indVert:uint = _indices[index] * 11;
			_indices.splice( index, 6 );
			_vertices.splice( indVert, 44 );

			_numVertices = _vertices.length / 11;
			_numIndices = _indices.length;
			_vertexBufferDirty = true;
			_indexBufferDirty = true;
		}

		public function removeSegment( segment:Segment ):void
		{
			//to do, add support curve indices/offset
			var index:uint;
			for( var i:uint = 0; i < _segments.length; ++i ) {
				if( _segments[i] == segment ) {
					segment.segmentsBase = null;
					_segments.splice( i, 1 );
					removeSegmentByIndex( segment.index );
					segment = null;
					_lineCount--;
					
				} else {
					_segments[i].index = index;
					index += 6;
				}
			}
			_vertexBufferDirty = true;
			_indexBufferDirty = true;
		}

		public function getSegment( index:uint ):Segment {
			return _segments[index];
		}

		public function removeAllSegments():void
		{
			_vertices.length = 0;
			_indices.length = 0;
			_segments.length = 0;
			_numVertices = 0;
			_numIndices = 0;
			_lineCount = 0;
			_vertexBufferDirty = true;
			_indexBufferDirty = true;
		}

		public function getIndexBuffer( stage3DProxy:Stage3DProxy ):IndexBuffer3D
		{
			if ( _indexContext3D != stage3DProxy.context3D || _indexBufferDirty ) {
				_indexBuffer = stage3DProxy._context3D.createIndexBuffer( _numIndices );
				_indexBuffer.uploadFromVector( _indices, 0, _numIndices );
				_indexBufferDirty = false;
				_indexContext3D = stage3DProxy.context3D;
			}
			return _indexBuffer;
		}

		public function getVertexBuffer( stage3DProxy:Stage3DProxy ):VertexBuffer3D
		{
			if( _numVertices == 0 )
				addSegment( new LineSegment( new Vector3D(0.0,0.0,0.0), new Vector3D(0.0,0.0,0.0) ) ); // buffers cannot be empty

			if ( _vertexContext3D != stage3DProxy.context3D || _vertexBufferDirty ) {
				_vertexBuffer = stage3DProxy._context3D.createVertexBuffer( _numVertices, 11 );
				_vertexBuffer.uploadFromVector( _vertices, 0, _numVertices );
				_vertexBufferDirty = false;
				_vertexContext3D = stage3DProxy.context3D;
			}
			return _vertexBuffer;
		}

		override public function dispose():void {
			super.dispose();
			if( _vertexBuffer ) _vertexBuffer.dispose();
			if( _indexBuffer ) _indexBuffer.dispose();
		}

		public function getUVBuffer( stage3DProxy:Stage3DProxy ):VertexBuffer3D {
			return null;
		}

		public function getVertexNormalBuffer( stage3DProxy:Stage3DProxy ):VertexBuffer3D {
			return null;
		}

		public function getVertexTangentBuffer( stage3DProxy:Stage3DProxy ):VertexBuffer3D {
			return null;
		}

		override public function get mouseEnabled():Boolean {
			return false;
		}

		public function get numTriangles():uint {
			return _numIndices / 3;
		}

		public function get sourceEntity():Entity {
			return this;
		}

		public function get castsShadows():Boolean {
			return false;
		}

		public function get material():MaterialBase {
			return _material;
		}

		public function get animator():IAnimator {
			return _animator;
		}

		public function set material( value:MaterialBase ):void {
			if( value == _material ) return;
			if( _material ) _material.removeOwner( this );
			_material = value;
			if( _material ) _material.addOwner( this );
		}

		override protected function getDefaultBoundingVolume():BoundingVolumeBase {
			return new BoundingSphere();
		}

		override protected function updateBounds():void {
			// todo: fix bounds
			_bounds.fromExtremes( -10000, -10000, 0, 10000, 10000, 0 );
			_boundsInvalid = false;
		}

		override protected function createEntityPartitionNode():EntityNode {
			return new RenderableNode( this );
		}

		public function get uvTransform():Matrix {
			return null;
		}

		public function getSecondaryUVBuffer( stage3DProxy:Stage3DProxy ):VertexBuffer3D {
			return null;
		}

		public function get vertexData():Vector.<Number> {
			return _vertices;
		}

		public function get indexData():Vector.<uint> {
			return _indices;
		}

		public function get UVData():Vector.<Number> {
			return null;
		}

		public function getCustomBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return null;
		}

		public function get vertexBufferOffset() : int
		{
			return 0;
		}

		public function get normalBufferOffset() : int
		{
			return 0;
		}

		public function get tangentBufferOffset() : int
		{
			return 0;
		}

		public function get UVBufferOffset() : int
		{
			return 0;
		}

		public function get secondaryUVBufferOffset() : int
		{
			return 0;
		}
	}
}