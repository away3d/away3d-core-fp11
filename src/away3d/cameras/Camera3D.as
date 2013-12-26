package away3d.cameras
{
	import away3d.core.math.Matrix3DUtils;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import away3d.arcane;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.bounds.NullBounds;
	import away3d.cameras.lenses.LensBase;
	import away3d.cameras.lenses.PerspectiveLens;
	import away3d.core.math.Plane3D;
	import away3d.core.partition.CameraNode;
	import away3d.core.partition.EntityNode;
	import away3d.entities.Entity;
	import away3d.events.CameraEvent;
	import away3d.events.LensEvent;
	import away3d.library.assets.AssetType;
	
	use namespace arcane;
	
	/**
	 * A Camera3D object represents a virtual camera through which we view the scene.
	 */
	public class Camera3D extends Entity
	{
		private var _viewProjection:Matrix3D = new Matrix3D();
		private var _viewProjectionDirty:Boolean = true;
		private var _lens:LensBase;
		private var _frustumPlanes:Vector.<Plane3D>;
		private var _frustumPlanesDirty:Boolean = true;
		
		/**
		 * Creates a new Camera3D object
		 * @param lens An optional lens object that will perform the projection. Defaults to PerspectiveLens.
		 *
		 * @see away3d.cameras.lenses.PerspectiveLens
		 */
		public function Camera3D(lens:LensBase = null)
		{
			super();
			
			//setup default lens
			_lens = lens || new PerspectiveLens();
			_lens.addEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);
			
			//setup default frustum planes
			_frustumPlanes = new Vector.<Plane3D>(6, true);
			
			for (var i:int = 0; i < 6; ++i)
				_frustumPlanes[i] = new Plane3D();
			
			z = -1000;
		}
		
		override protected function getDefaultBoundingVolume():BoundingVolumeBase
		{
			return new NullBounds();
		}
		
		public override function get assetType():String
		{
			return AssetType.CAMERA;
		}
		
		private function onLensMatrixChanged(event:LensEvent):void
		{
			_viewProjectionDirty = true;
			_frustumPlanesDirty = true;
			
			dispatchEvent(event);
		}
		
		/**
		 *
		 */
		public function get frustumPlanes():Vector.<Plane3D>
		{
			if (_frustumPlanesDirty)
				updateFrustum();
			
			return _frustumPlanes;
		}
		
		private function updateFrustum():void
		{
			var a:Number, b:Number, c:Number;
			//var d : Number;
			var c11:Number, c12:Number, c13:Number, c14:Number;
			var c21:Number, c22:Number, c23:Number, c24:Number;
			var c31:Number, c32:Number, c33:Number, c34:Number;
			var c41:Number, c42:Number, c43:Number, c44:Number;
			var p:Plane3D;
			var raw:Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			var invLen:Number;
			viewProjection.copyRawDataTo(raw);
			
			c11 = raw[uint(0)];
			c12 = raw[uint(4)];
			c13 = raw[uint(8)];
			c14 = raw[uint(12)];
			c21 = raw[uint(1)];
			c22 = raw[uint(5)];
			c23 = raw[uint(9)];
			c24 = raw[uint(13)];
			c31 = raw[uint(2)];
			c32 = raw[uint(6)];
			c33 = raw[uint(10)];
			c34 = raw[uint(14)];
			c41 = raw[uint(3)];
			c42 = raw[uint(7)];
			c43 = raw[uint(11)];
			c44 = raw[uint(15)];
			
			// left plane
			p = _frustumPlanes[0];
			a = c41 + c11;
			b = c42 + c12;
			c = c43 + c13;
			invLen = 1/Math.sqrt(a*a + b*b + c*c);
			p.a = a*invLen;
			p.b = b*invLen;
			p.c = c*invLen;
			p.d = -(c44 + c14)*invLen;
			
			// right plane
			p = _frustumPlanes[1];
			a = c41 - c11;
			b = c42 - c12;
			c = c43 - c13;
			invLen = 1/Math.sqrt(a*a + b*b + c*c);
			p.a = a*invLen;
			p.b = b*invLen;
			p.c = c*invLen;
			p.d = (c14 - c44)*invLen;
			
			// bottom
			p = _frustumPlanes[2];
			a = c41 + c21;
			b = c42 + c22;
			c = c43 + c23;
			invLen = 1/Math.sqrt(a*a + b*b + c*c);
			p.a = a*invLen;
			p.b = b*invLen;
			p.c = c*invLen;
			p.d = -(c44 + c24)*invLen;
			
			// top
			p = _frustumPlanes[3];
			a = c41 - c21;
			b = c42 - c22;
			c = c43 - c23;
			invLen = 1/Math.sqrt(a*a + b*b + c*c);
			p.a = a*invLen;
			p.b = b*invLen;
			p.c = c*invLen;
			p.d = (c24 - c44)*invLen;
			
			// near
			p = _frustumPlanes[4];
			a = c31;
			b = c32;
			c = c33;
			invLen = 1/Math.sqrt(a*a + b*b + c*c);
			p.a = a*invLen;
			p.b = b*invLen;
			p.c = c*invLen;
			p.d = -c34*invLen;
			
			// far
			p = _frustumPlanes[5];
			a = c41 - c31;
			b = c42 - c32;
			c = c43 - c33;
			invLen = 1/Math.sqrt(a*a + b*b + c*c);
			p.a = a*invLen;
			p.b = b*invLen;
			p.c = c*invLen;
			p.d = (c34 - c44)*invLen;
			
			_frustumPlanesDirty = false;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function invalidateSceneTransform():void
		{
			super.invalidateSceneTransform();
			
			_viewProjectionDirty = true;
			_frustumPlanesDirty = true;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateBounds():void
		{
			_bounds.nullify();
			
			_boundsInvalid = false;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function createEntityPartitionNode():EntityNode
		{
			return new CameraNode(this);
		}
		
		/**
		 * The lens used by the camera to perform the projection;
		 */
		public function get lens():LensBase
		{
			return _lens;
		}
		
		public function set lens(value:LensBase):void
		{
			if (_lens == value)
				return;
			
			if (!value)
				throw new Error("Lens cannot be null!");

			_lens.removeEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);

			_lens = value;
			
			_lens.addEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);
			
			dispatchEvent(new CameraEvent(CameraEvent.LENS_CHANGED, this));
		}
		
		/**
		 * The view projection matrix of the camera.
		 */
		public function get viewProjection():Matrix3D
		{
			if (_viewProjectionDirty) {
				_viewProjection.copyFrom(inverseSceneTransform);
				_viewProjection.append(_lens.matrix);
				_viewProjectionDirty = false;
			}
			
			return _viewProjection;
		}
		
		/**
		 * Calculates the scene position of the given normalized coordinates in screen space.
		 *
		 * @param nX The normalised x coordinate in screen space, -1 corresponds to the left edge of the viewport, 1 to the right.
		 * @param nY The normalised y coordinate in screen space, -1 corresponds to the top edge of the viewport, 1 to the bottom.
		 * @param sZ The z coordinate in screen space, representing the distance into the screen.
		 * @param v The destination Vector3D object
		 * @return The scene position of the given screen coordinates.
		 */
		public function unproject(nX:Number, nY:Number, sZ:Number, v:Vector3D = null):Vector3D
		{
			return Matrix3DUtils.transformVector(sceneTransform, lens.unproject(nX, nY, sZ, v), v)
		}
		
		/**
		 * Calculates the ray in scene space from the camera to the given normalized coordinates in screen space.
		 *
		 * @param nX The normalised x coordinate in screen space, -1 corresponds to the left edge of the viewport, 1 to the right.
		 * @param nY The normalised y coordinate in screen space, -1 corresponds to the top edge of the viewport, 1 to the bottom.
		 * @param sZ The z coordinate in screen space, representing the distance into the screen.
		 * @param v The destination Vector3D object
		 * @return The ray from the camera to the scene space position of the given screen coordinates.
		 */
		public function getRay(nX:Number, nY:Number, sZ:Number, v:Vector3D = null):Vector3D
		{
			return Matrix3DUtils.deltaTransformVector(sceneTransform,lens.unproject(nX, nY, sZ, v), v);
		}
		
		/**
		 * Calculates the normalised position in screen space of the given scene position.
		 *
		 * @param point3d the position vector of the scene coordinates to be projected.
		 * @param v The destination Vector3D object
		 * @return The normalised screen position of the given scene coordinates.
		 */
		public function project(point3d:Vector3D, v:Vector3D = null):Vector3D
		{
			return lens.project(Matrix3DUtils.transformVector(inverseSceneTransform,point3d,v), v);
		}
	}
}
