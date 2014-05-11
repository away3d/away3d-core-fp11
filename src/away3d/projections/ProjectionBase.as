package away3d.projections
{
	import away3d.entities.Camera3D;
	import away3d.core.math.Matrix3DUtils;

	import flash.events.EventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	
	import away3d.arcane;
	import away3d.errors.AbstractMethodError;
	import away3d.events.ProjectionEvent;
	
	use namespace arcane;
	
	/**
	 * An abstract base class for all lens classes. Lens objects provides a projection matrix that transforms 3D geometry to normalized homogeneous coordinates.
	 */
	public class ProjectionBase extends EventDispatcher implements IProjection
	{
		protected var _matrix:Matrix3D;
		protected var _scissorRect:Rectangle = new Rectangle();
		protected var _viewPort:Rectangle = new Rectangle();
		protected var _near:Number = 20;
		protected var _far:Number = 3000;
		protected var _aspectRatio:Number = 1;
		
		protected var _matrixInvalid:Boolean = true;
		protected var _frustumCorners:Vector.<Number> = new Vector.<Number>(8*3, true);
		protected var _coordinateSystem:uint;
		protected var _originX:Number = 0.5;
		protected var _originY:Number = 0.5;

		private var _unprojection:Matrix3D;
		private var _unprojectionInvalid:Boolean = true;
		/**
		 * Creates a new LensBase object.
		 */
		public function ProjectionBase(coordinateSystem:uint = CoordinateSystem.LEFT_HANDED)
		{
			_matrix = new Matrix3D();
			this.coordinateSystem = coordinateSystem;
		}

		/**
		 * The handedness of the coordinate system projection. The default is LEFT_HANDED.
		 */
		public function get coordinateSystem():uint
		{
			return _coordinateSystem;
		}

		public function set coordinateSystem(value:uint):void
		{
			if (_coordinateSystem == value)
				return;

			_coordinateSystem = value;

			invalidateMatrix();
		}
		
		/**
		 * Retrieves the corner points of the lens frustum.
		 */
		public function get frustumCorners():Vector.<Number>
		{
			return _frustumCorners;
		}
		
		public function set frustumCorners(frustumCorners:Vector.<Number>):void
		{
			_frustumCorners = frustumCorners;
		}
		
		/**
		 * The projection matrix that transforms 3D geometry to normalized homogeneous coordinates.
		 */
		public function get matrix():Matrix3D
		{
			if (_matrixInvalid) {
				updateMatrix();
				_matrixInvalid = false;
			}
			return _matrix;
		}
		
		public function set matrix(value:Matrix3D):void
		{
			_matrix = value;
			invalidateMatrix();
		}
		
		/**
		 * The distance to the near plane of the frustum. Anything behind near plane will not be rendered.
		 */
		public function get near():Number
		{
			return _near;
		}
		
		public function set near(value:Number):void
		{
			if (value == _near)
				return;
			_near = value;
			invalidateMatrix();
		}
		
		/**
		 * The distance to the far plane of the frustum. Anything beyond the far plane will not be rendered.
		 */
		public function get far():Number
		{
			return _far;
		}
		
		public function set far(value:Number):void
		{
			if (value == _far)
				return;
			_far = value;
			invalidateMatrix();
		}
		
		/**
		 * Calculates the normalised position in screen space of the given scene position relative to the camera.
		 *
		 * @param point3d the position vector of the scene coordinates to be projected.
		 * @param v The destination Vector3D object
		 * @return The normalised screen position of the given scene coordinates relative to the camera.
		 */
		public function project(point3d:Vector3D, v:Vector3D = null):Vector3D
		{
			if(!v) v = new Vector3D();
			Matrix3DUtils.transformVector(matrix, point3d, v);
			v.x = v.x/v.w;
			v.y = -v.y/v.w;
			
			//z is unaffected by transform
			v.z = point3d.z;
			
			return v;
		}
		
		public function get unprojectionMatrix():Matrix3D
		{
			if (_unprojectionInvalid) {
				_unprojection ||= new Matrix3D();
				_unprojection.copyFrom(matrix);
				_unprojection.invert();
				_unprojectionInvalid = false;
			}
			
			return _unprojection;
		}
		
		/**
		 * Calculates the scene position relative to the camera of the given normalized coordinates in screen space.
		 *
		 * @param nX The normalised x coordinate in screen space, -1 corresponds to the left edge of the viewport, 1 to the right.
		 * @param nY The normalised y coordinate in screen space, -1 corresponds to the top edge of the viewport, 1 to the bottom.
		 * @param sZ The z coordinate in screen space, representing the distance into the screen.
		 * @param v The destination Vector3D object
		 * @return The scene position relative to the camera of the given screen coordinates.
		 */
		public function unproject(nX:Number, nY:Number, sZ:Number, v:Vector3D = null):Vector3D
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * Creates an exact duplicate of the lens
		 */
		public function clone():ProjectionBase
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * The aspect ratio (width/height) of the view. Set by the renderer.
		 */
		public function get aspectRatio():Number
		{
			return _aspectRatio;
		}

		public function set aspectRatio(value:Number):void
		{
			if (_aspectRatio == value)
				return;
			_aspectRatio = value;
			invalidateMatrix();
		}
		
		/**
		 * Invalidates the projection matrix, which will cause it to be updated on the next request.
		 */
		protected function invalidateMatrix():void
		{
			_matrixInvalid = true;
			_unprojectionInvalid = true;
			// notify the camera that the lens matrix is changing. this will mark the 
			// viewProjectionMatrix in the camera as invalid, and force the matrix to
			// be re-queried from the lens, and therefore rebuilt.
			dispatchEvent(new ProjectionEvent(ProjectionEvent.MATRIX_CHANGED, this));
		}

		/**
		 * Updates the projection matrix and frustum corners
		 */
		protected function updateMatrix():void
		{
			throw new AbstractMethodError();
		}

		public function updateScissorRect(x:Number, y:Number, width:Number, height:Number):void
		{
			_scissorRect.x = x;
			_scissorRect.y = y;
			_scissorRect.width = width;
			_scissorRect.height = height;
			invalidateMatrix();
		}

		public function updateViewport(x:Number, y:Number, width:Number, height:Number):void
		{
			_viewPort.x = x;
			_viewPort.y = y;
			_viewPort.width = width;
			_viewPort.height = height;
			invalidateMatrix();
		}

		public function get originY():Number {
			return _originY;
		}

		public function set originY(value:Number):void {
			_originY = value;
		}

		public function get originX():Number {
			return _originX;
		}

		public function set originX(value:Number):void {
			_originX = value;
		}
	}
}
