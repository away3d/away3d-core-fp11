package away3d.primitives
{
	import flash.geom.Vector3D;
	import away3d.primitives.data.Segment;
	
	public class LineSegment extends Segment {
		
		private var _index:uint;
		public const TYPE:String = "line";
		
		public function LineSegment(v0:Vector3D, v1:Vector3D, color0:uint = 0x333333, color1:uint = 0x333333, thickness:Number = 1):void
		{
			super(v0, v1, null, color0, color1, thickness);
		}
		 
	}
}
