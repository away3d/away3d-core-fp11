package away3d.entities {
	import away3d.animators.data.AnimationBase;
	import away3d.animators.data.AnimationStateBase;
	import away3d.animators.data.NullAnimation;
	import away3d.arcane;
	import away3d.bounds.BoundingSphere;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.core.base.IRenderable;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.RenderableNode;
	import away3d.materials.MaterialBase;
	import away3d.materials.WireframeMaterial;

	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Vector3D;




	/**
	 * @author jerome BIREMBAUT  Twitter: Seraf_NSS
	 */
	 use namespace arcane;
	public class Lines extends Entity implements IRenderable {
		
		private var _material : MaterialBase;
		private var _nullAnimation : NullAnimation;
		private var _animationState : AnimationStateBase;
		//private var _geometry : SubGeometry;
		private var _vertices : Vector.<Number>;
		private var _numVertices : Number;
		private var _indices : Vector.<uint>;
		private var _numIndices : uint;
		private var _vertexBufferDirty : Boolean= true;
		private var _indexBufferDirty : Boolean= true;
		private var _vertexBuffer : VertexBuffer3D;
		private var _indexBuffer : IndexBuffer3D;

		private var lineCount : int = 0;
		private var _index : Number;

		public function addLine(p0 : Vector3D, p1 : Vector3D,thickness:Number=1,r:Number=0,g:Number=0,b:Number=0,r2:Number=0,g2:Number=0,b2:Number=0):int{
			
			
			var t:Number = thickness / 2;
			_vertices.push(	p0.x, p0.y, p0.z,	p1.x, p1.y, p1.z,	 t,	r,g,b,1,
							p1.x, p1.y, p1.z,	p0.x, p0.y, p0.z,	-t,	r2,g2,b2,1,
							p0.x, p0.y, p0.z,	p1.x, p1.y, p1.z,	-t, r,g,b,1,
							p1.x, p1.y, p1.z,	p0.x, p0.y, p0.z,	 t,	r2,g2,b2,1);
			
			_index=lineCount*4;
			_indices.push(	_index, 	_index+1, _index+2,
							_index+3,	_index+2, _index+1);
						
						
			_numVertices=_vertices.length/11;
			_numIndices=_indices.length;
			_vertexBufferDirty=true;
			_indexBufferDirty=true;
			lineCount++;
			return lineCount;
		}
		
		public function Lines(material : WireframeMaterial = null){
			super();
		
			_nullAnimation ||= new NullAnimation();
			//_geometry = new SubGeometry();
			_vertices=new Vector.<Number>();
			_numVertices=0;
			_indices=new Vector.<uint>();
			_numIndices=0;
			
			this.material = material;//updateTransform();
			
		}
		public function getVertexBuffer(context : Context3D, contextIndex : uint) : VertexBuffer3D
		{
			if (_vertexBufferDirty ) {
			
				_vertexBuffer= context.createVertexBuffer(_numVertices, 11);
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
			if (_indexBufferDirty ) {
				_indexBuffer= context.createIndexBuffer(_numIndices);
				_indexBuffer.uploadFromVector(_indices, 0, _numIndices);
				_indexBufferDirty = false;
			}
				return _indexBuffer;
		}
		
		public function get mouseDetails() : Boolean {
			// TODO: Auto-generated method stub
			return false;
		}
		
		public function get numTriangles() : uint {
			// TODO: Auto-generated method stub
			return lineCount*2;
		}
		
		public function get sourceEntity() : Entity {
			// TODO: Auto-generated method stub
			return this;
		}
		
		public function get shadowCaster() : Boolean {
			// TODO: Auto-generated method stub
			return false;
		}
		
		public function get material() : MaterialBase {
				return _material;
		}
		
		public function get animation() : AnimationBase {
			// TODO: Auto-generated method stub
			return _nullAnimation;
		}
		
		public function get animationState() : AnimationStateBase {
			// TODO: Auto-generated method stub
			return _animationState;
		}
		
		public function set material(value : MaterialBase) : void {
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
			_bounds.fromExtremes(-100, -100, 0, 100, 100, 0);
			_boundsInvalid = false;
		}
		override protected function createEntityPartitionNode() : EntityNode
		{
			return new RenderableNode(this);
		}
	}
}
