package away3d.paths
{
	import flash.geom.Vector3D;
	
	/**
	 * Creates a curved line segment definition required for the Path class.
	 */
	
	public class QuadraticPathSegment implements IPathSegment
	{
		/**
		 * Defines the first vector of the PathSegment
		 */
		public var start:Vector3D;
		
		/**
		 * Defines the control vector of the PathSegment
		 */
		public var control:Vector3D;
		
		/**
		 * Defines the control vector of the PathSegment
		 */
		public var end:Vector3D;
		
		public function QuadraticPathSegment(pStart:Vector3D, pControl:Vector3D, pEnd:Vector3D)
		{
			this.start = pStart;
			this.control = pControl;
			this.end = pEnd;
		}
		
		public function toString():String
		{
			return start + ", " + control + ", " + end;
		}
		
		/**
		 * nulls the 3 vectors
		 */
		public function dispose():void
		{
			start = control = end = null;
		}
		
		public function getPointOnSegment(t:Number, target:Vector3D = null):Vector3D
		{
			const sx:Number = start.x;
			const sy:Number = start.y;
			const sz:Number = start.z;
			const t2Inv:Number = 2*(1 - t);
			
			target ||= new Vector3D();
			
			target.x = sx + t*(t2Inv*(control.x - sx) + t*(end.x - sx));
			target.y = sy + t*(t2Inv*(control.y - sy) + t*(end.y - sy));
			target.z = sz + t*(t2Inv*(control.z - sz) + t*(end.z - sz));
			
			return target;
		}
	}
}
