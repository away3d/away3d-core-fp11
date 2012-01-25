package away3d.raytracing.colliders
{

	import away3d.errors.AbstractMethodError;

	import flash.geom.Vector3D;

	public class RayCollider
	{
		protected var _collides:Boolean;
		protected var _rayPosition:Vector3D;
		protected var _rayDirection:Vector3D;

		public var rayPoint:Vector3D;

		public function RayCollider() {
			_rayPosition = new Vector3D();
			_rayDirection = new Vector3D();
			rayPoint = new Vector3D();
		}

		public function updateRay( position:Vector3D, direction:Vector3D ):void {
			_rayPosition = position;
			_rayDirection = direction;
		}

		public function evaluate( ...params ):Boolean {
			throw new AbstractMethodError();
		}

		public function get collides():Boolean {
			return _collides;
		}
	}
}
