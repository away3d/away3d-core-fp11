package away3d.entities
{
	import away3d.arcane;
	import away3d.bounds.BoundingSphere;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationBase;
	import away3d.animators.data.AnimationStateBase;
	import away3d.animators.data.NullAnimation;
	import away3d.core.base.IRenderable;
	import away3d.core.base.SubGeometry;
	import away3d.materials.MaterialBase;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.RenderableNode;

	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * Sprite3D is a 3D billboard, a renderable rectangular area that always faces the camera.
	 *
	 * todo: mvp generation can probably be optimized
	 */
	public class Sprite3D extends Entity implements IRenderable
	{
		private static var _geometry : SubGeometry;

		private static var _nullAnimation : NullAnimation;
		private var _mouseDetails : Boolean;
		private var _material : MaterialBase;
		private var _animationState : AnimationStateBase;
		private var _spriteMatrix : Matrix3D;

		private var _width : Number;
		private var _height : Number;
		private var _shadowCaster : Boolean = false;

		public function Sprite3D(material : MaterialBase, width : Number, height : Number)
		{
			super();
			_nullAnimation ||= new NullAnimation();
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

		public function get width() : Number
		{
			return _width;
		}

		public function set width(value : Number) : void
		{
			if (_width == value) return;
			_width = value;
			invalidateTransform();
		}

		public function get height() : Number
		{
			return _height;
		}

		public function set height(value : Number) : void
		{
			if (_height == value) return;
			_height = value;
			invalidateTransform();
		}

		/*override public function lookAt(target : Vector3D, upAxis : Vector3D = null) : void
		{
			super.lookAt(target, upAxis);
			_transform.appendScale(_width, _height, 1);
		}*/

		public function get mouseDetails() : Boolean
		{
			return _mouseDetails;
		}

		public function set mouseDetails(value : Boolean) : void
		{
			_mouseDetails = value;
		}

		public function getVertexBuffer(context : Context3D, contextIndex : uint) : VertexBuffer3D
		{
			return _geometry.getVertexBuffer(context, contextIndex);
		}

		public function getUVBuffer(context : Context3D, contextIndex : uint) : VertexBuffer3D
		{
			return _geometry.getUVBuffer(context, contextIndex);
		}

		public function getVertexNormalBuffer(context : Context3D, contextIndex : uint) : VertexBuffer3D
		{
			return _geometry.getVertexNormalBuffer(context, contextIndex);
		}

		public function getVertexTangentBuffer(context : Context3D, contextIndex : uint) : VertexBuffer3D
		{
			return _geometry.getVertexTangentBuffer(context, contextIndex);
		}

		public function getIndexBuffer(context : Context3D, contextIndex : uint) : IndexBuffer3D
		{
			return _geometry.getIndexBuffer(context, contextIndex);
		}

		override public function pushModelViewProjection(camera : Camera3D) : void
		{
			var comps : Vector.<Vector3D>;
			var rot : Vector3D;
			if (++_mvpIndex == _stackLen++)
				_mvpTransformStack[_mvpIndex] = new Matrix3D();

			var mvp : Matrix3D = _mvpTransformStack[_mvpIndex];
			mvp.copyFrom(sceneTransform);
			mvp.append(camera.inverseSceneTransform);
			comps = mvp.decompose();
			rot = comps[1];
			rot.x = rot.y = rot.z = 0;
			mvp.recompose(comps);
			mvp.append(camera.lens.matrix);
			mvp.copyRowTo(3, _pos);
			_zIndices[_mvpIndex] = -_pos.z;
		}

		public function get numTriangles() : uint
		{
			return 2;
		}

		public function get sourceEntity() : Entity
		{
			return this;
		}

		public function get material() : MaterialBase
		{
			return _material;
		}

		public function set material(value : MaterialBase) : void
		{
			if (value == _material) return;
			if (_material) _material.removeOwner(this);
			_material = value;
			if (_material) _material.addOwner(this);
		}

		public function get animation() : AnimationBase
		{
			return _nullAnimation;
		}

		public function get animationState() : AnimationStateBase
		{
			return _animationState;
		}

		public function get shadowCaster() : Boolean
		{
			return _shadowCaster;
		}

		override protected function getDefaultBoundingVolume() : BoundingVolumeBase
		{
			return new BoundingSphere();
		}

		override protected function updateBounds() : void
		{
			_bounds.fromExtremes(-.5, -.5, 0, .5, .5, 0);
			_boundsInvalid = false;
		}


		override protected function createEntityPartitionNode() : EntityNode
		{
			return new RenderableNode(this);
		}

		override protected function updateTransform() : void
		{
			super.updateTransform();
			_transform.prependScale(_width, _height, 1);
		}
	}
}
