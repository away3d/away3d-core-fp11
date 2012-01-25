package away3d.raytracing.data
{

	import away3d.entities.Mesh;

	import flash.geom.Vector3D;

	public class CollisionVO
	{
		public var mesh:Mesh;
		public var t:Number;
		public var point:Vector3D;

		public function CollisionVO( mesh:Mesh, t:Number, point:Vector3D ) {
			this.mesh = mesh;
			this.t = t;
			this.point = point;
		}
	}
}
