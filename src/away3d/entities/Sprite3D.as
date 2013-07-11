package away3d.entities
{
	import away3d.animators.IAnimator;
	import away3d.arcane;
	import away3d.bounds.AxisAlignedBoundingBox;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.SubMesh;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.math.Matrix3DUtils;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.RenderableNode;
	import away3d.core.pick.IPickingCollider;
	import away3d.materials.MaterialBase;
	
	import flash.display3D.IndexBuffer3D;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * Sprite3D is a 3D billboard, a renderable rectangular area that is always aligned with the projection plane.
	 * As a result, no perspective transformation occurs on a Sprite3D object.
	 *
	 * todo: mvp generation or vertex shader code can be optimized
	 */
	public class Sprite3D extends Entity implements IRenderable
	{
		// TODO: Replace with CompactSubGeometry
		private static var _geometry:SubGeometry;
		//private static var _pickingSubMesh:SubGeometry;
		
		private var _material:MaterialBase;
		private var _spriteMatrix:Matrix3D;
		private var _animator:IAnimator;
		
		private var _pickingSubMesh:SubMesh;
		private var _pickingTransform:Matrix3D;
		private var _camera:Camera3D;
		
		private var _width:Number;
		private var _height:Number;
		private var _shadowCaster:Boolean = false;
		
		public function Sprite3D(material:MaterialBase, width:Number, height:Number)
		{
			super();
			this.material = material;
			_width = width;
			_height = height;
			_spriteMatrix = new Matrix3D();
			if (!_geometry) {
				_geometry = new SubGeometry();
				_geometry.updateVertexData(Vector.<Number>([-.5, .5, .0, .5, .5, .0, .5, -.5, .0, -.5, -.5, .0]));
				_geometry.updateUVData(Vector.<Number>([.0, .0, 1.0, .0, 1.0, 1.0, .0, 1.0]));
				_geometry.updateIndexData(Vector.<uint>([0, 1, 2, 0, 2, 3]));
				_geometry.updateVertexTangentData(Vector.<Number>([1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0]));
				_geometry.updateVertexNormalData(Vector.<Number>([.0, .0, -1.0, .0, .0, -1.0, .0, .0, -1.0, .0, .0, -1.0]));
			}
		}
		
		override public function set pickingCollider(value:IPickingCollider):void
		{
			super.pickingCollider = value;
			if (value) { // bounds collider is the only null value
				_pickingSubMesh = new SubMesh(_geometry, null);
				_pickingTransform = new Matrix3D();
			}
		}
		
		public function get width():Number
		{
			return _width;
		}
		
		public function set width(value:Number):void
		{
			if (_width == value)
				return;
			_width = value;
			invalidateTransform();
		}
		
		public function get height():Number
		{
			return _height;
		}
		
		public function set height(value:Number):void
		{
			if (_height == value)
				return;
			_height = value;
			invalidateTransform();
		}
		
		public function activateVertexBuffer(index:int, stage3DProxy:Stage3DProxy):void
		{
			_geometry.activateVertexBuffer(index, stage3DProxy);
		}
		
		public function activateUVBuffer(index:int, stage3DProxy:Stage3DProxy):void
		{
			_geometry.activateUVBuffer(index, stage3DProxy);
		}
		
		public function activateSecondaryUVBuffer(index:int, stage3DProxy:Stage3DProxy):void
		{
			_geometry.activateSecondaryUVBuffer(index, stage3DProxy);
		}
		
		public function activateVertexNormalBuffer(index:int, stage3DProxy:Stage3DProxy):void
		{
			_geometry.activateVertexNormalBuffer(index, stage3DProxy);
		}
		
		public function activateVertexTangentBuffer(index:int, stage3DProxy:Stage3DProxy):void
		{
			_geometry.activateVertexTangentBuffer(index, stage3DProxy);
		}
		
		public function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D
		{
			return _geometry.getIndexBuffer(stage3DProxy);
		}
		
		public function get numTriangles():uint
		{
			return 2;
		}
		
		public function get sourceEntity():Entity
		{
			return this;
		}
		
		public function get material():MaterialBase
		{
			return _material;
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
		
		/**
		 * Defines the animator of the mesh. Act on the mesh's geometry. Defaults to null
		 */
		public function get animator():IAnimator
		{
			return _animator;
		}
		
		public function get castsShadows():Boolean
		{
			return _shadowCaster;
		}
		
		override protected function getDefaultBoundingVolume():BoundingVolumeBase
		{
			return new AxisAlignedBoundingBox();
		}
		
		override protected function updateBounds():void
		{
			_bounds.fromExtremes(-.5*_scaleX, -.5*_scaleY, -.5*_scaleZ, .5*_scaleX, .5*_scaleY, .5*_scaleZ);
			_boundsInvalid = false;
		}
		
		override protected function createEntityPartitionNode():EntityNode
		{
			return new RenderableNode(this);
		}
		
		override protected function updateTransform():void
		{
			super.updateTransform();
			_transform.prependScale(_width, _height, Math.max(_width, _height));
		}
		
		public function get uvTransform():Matrix
		{
			return null;
		}
		
		public function get vertexData():Vector.<Number>
		{
			return _geometry.vertexData;
		}
		
		public function get indexData():Vector.<uint>
		{
			return _geometry.indexData;
		}
		
		public function get UVData():Vector.<Number>
		{
			return _geometry.UVData;
		}
		
		public function get numVertices():uint
		{
			return _geometry.numVertices;
		}
		
		public function get vertexStride():uint
		{
			return _geometry.vertexStride;
		}
		
		public function get vertexNormalData():Vector.<Number>
		{
			return _geometry.vertexNormalData;
		}
		
		public function get vertexTangentData():Vector.<Number>
		{
			return _geometry.vertexTangentData;
		}
		
		public function get vertexOffset():int
		{
			return _geometry.vertexOffset;
		}
		
		public function get vertexNormalOffset():int
		{
			return _geometry.vertexNormalOffset;
		}
		
		public function get vertexTangentOffset():int
		{
			return _geometry.vertexTangentOffset;
		}
		
		override arcane function collidesBefore(shortestCollisionDistance:Number, findClosest:Boolean):Boolean
		{
			findClosest = findClosest;
			var viewTransform:Matrix3D = _camera.inverseSceneTransform.clone();
			viewTransform.transpose();
			var rawViewTransform:Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			viewTransform.copyRawDataTo(rawViewTransform);
			rawViewTransform[ 3  ] = 0;
			rawViewTransform[ 7  ] = 0;
			rawViewTransform[ 11 ] = 0;
			rawViewTransform[ 12 ] = 0;
			rawViewTransform[ 13 ] = 0;
			rawViewTransform[ 14 ] = 0;
			
			_pickingTransform.copyRawDataFrom(rawViewTransform);
			_pickingTransform.prependScale(_width, _height, Math.max(_width, _height));
			_pickingTransform.appendTranslation(scenePosition.x, scenePosition.y, scenePosition.z);
			_pickingTransform.invert();
			
			var localRayPosition:Vector3D = _pickingTransform.transformVector(_pickingCollisionVO.rayPosition);
			var localRayDirection:Vector3D = _pickingTransform.deltaTransformVector(_pickingCollisionVO.rayDirection);
			
			_pickingCollider.setLocalRay(localRayPosition, localRayDirection);
			
			_pickingCollisionVO.renderable = null;
			if (_pickingCollider.testSubMeshCollision(_pickingSubMesh, _pickingCollisionVO, shortestCollisionDistance))
				_pickingCollisionVO.renderable = _pickingSubMesh;
			
			return _pickingCollisionVO.renderable != null;
		}
		
		public function getRenderSceneTransform(camera:Camera3D):Matrix3D
		{
			var comps:Vector.<Vector3D> = camera.sceneTransform.decompose();
			var scale:Vector3D = comps[2];
			comps[0] = scenePosition;
			scale.x = _width*_scaleX;
			scale.y = _height*_scaleY;
			_spriteMatrix.recompose(comps);
			return _spriteMatrix;
		}
	}
}
