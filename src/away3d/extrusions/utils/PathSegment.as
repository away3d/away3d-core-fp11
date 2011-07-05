package away3d.extrusions.utils
{
	import flash.geom.Vector3D;

	/**
    * Creates a curved line segment definition required for the Path class.
    */ 
	
	public class PathSegment
	{
		/**
		* Defines the first vector of the PathSegment
		*/
		public var pStart:Vector3D;
		
		/**
		* Defines the control vector of the PathSegment
		*/
		public var pControl:Vector3D;
		
		/**
		* Defines the control vector of the PathSegment
		*/
		public var pEnd:Vector3D;
		 
		
		public function PathSegment(pStart:Vector3D, pControl:Vector3D, pEnd:Vector3D)
		{
			this.pStart = pStart;
			this.pControl = pControl;
			this.pEnd = pEnd;
		}
		
		public function toString():String
		{
			return pStart + ", " + pControl + ", " + pEnd;
		}
		
	}
}