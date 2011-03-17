package away3d.entities {
	import away3d.containers.View3D;
	import away3d.primitives.LineSegment;

	import flash.geom.Vector3D;


	public class WireFrameGrid extends SegmentsBase {
		public function WireFrameGrid(_view : View3D,ceil:uint=10,size:uint=1000, color:uint = 0xCCCCCC, thickness:Number = 1) {
			
			
			super(_view);
			
			var ceilSize:uint = size/ ceil;
			var v0 : Vector3D = new Vector3D(0, 0, 0) ;
			var v1 : Vector3D = new Vector3D(0, 0, 0) ;
			for ( var i:int = -ceil; i <= ceil; i++ ){
				
				
				v0.x=size;
				v0.y=0;
				v0.z=i*ceilSize;
				
				v1.x=-size;
				v1.y=0;
				v1.z=i*ceilSize;
					addSegment( new LineSegment(v0 , v1,color,color,thickness));
				v0.x=i*ceilSize;
				v0.y=0;
				v0.z=size;
				
				v1.x=i*ceilSize;
				v1.y=0;
				v1.z=-size;
					addSegment(new LineSegment(v0 , v1,color,color,thickness ));
			}
		}
	}
}
