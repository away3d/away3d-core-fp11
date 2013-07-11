package away3d.paths
{
	import flash.geom.Vector3D;
	
	/**
	 * Defines a single segment of a cubic path
	 * @see away3d.paths.CubicPath
	 */
	public class CubicPathSegment implements IPathSegment
	{
		/**
		 * The first anchor point.
		 */
		public var start:Vector3D;
		
		/**
		 * The first control point.
		 */
		public var control1:Vector3D;
		
		/**
		 * The second control point.
		 */
		public var control2:Vector3D;
		
		/**
		 * The last anchor point.
		 */
		public var end:Vector3D;
		
		/**
		 *
		 * @param start The first anchor point.
		 * @param control1 The first control point.
		 * @param control2 The second control point.
		 * @param end The last anchor point.
		 */
		public function CubicPathSegment(start:Vector3D, control1:Vector3D, control2:Vector3D, end:Vector3D)
		{
			this.start = start;
			this.control1 = control1;
			this.control2 = control2;
			this.end = end;
		}
		
		public function toString():String
		{
			return start + ", " + control1 + ", " + control2 + ", " + end;
		}
		
		public function dispose():void
		{
			start = control1 = control2 = end = null;
		}
		
		public function getPointOnSegment(phase:Number, target:Vector3D = null):Vector3D
		{
			const td:Number = 1 - phase;
			const t_2:Number = phase*phase;
			const a:Number = td*td*td;
			const b:Number = 3*phase*td*td;
			const c:Number = 3*t_2*td;
			const t_3:Number = t_2*phase;
			
			target ||= new Vector3D();
			target.x = a*start.x + b*control1.x + c*control2.x + t_3*end.x;
			target.y = a*start.y + b*control1.y + c*control2.y + t_3*end.y;
			target.z = a*start.z + b*control1.z + c*control2.z + t_3*end.z;
			
			return target;
		}
	}
}
