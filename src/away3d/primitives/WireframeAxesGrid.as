package away3d.primitives
{
	import away3d.entities.*;
	import flash.geom.Vector3D;

	/**
	* Class WireFrameGrid generates a grid of lines on a given plane<code>WireFrameGrid</code>
	* @param	subDivision		[optional] uint . Default is 10;
	* @param	gridSize				[optional] uint . Default is 100;
	* @param	color					[optional] uint . Default is 0xFFFFFF;
	* @param	thickness			[optional] Number . Default is 1;
	* @param	plane					[optional] String . Default is PLANE_XZ;
	* @param	worldPlanes		[optional] Boolean . Default is false.
	* If true, class displays the 3 world planes, at 0,0,0. with subDivision, thickness and and gridSize. Overrides color and plane settings.
	 *
	 * TODO: change this class to only show world planes, normal grid becomes WireframePlane
	*/

	public class WireframeAxesGrid extends SegmentSet
	{
		private static const PLANE_ZY:String = "zy";
		private static const PLANE_XY:String = "xy";
		private static const PLANE_XZ:String = "xz";

		public function WireframeAxesGrid(subDivision:uint = 10, gridSize:uint = 100, thickness:Number = 1, colorXY : int = 0x0000ff, colorZY : int = 0xff0000, colorXZ : int = 0x00ff00) {
			super();

			if(subDivision == 0) subDivision = 1;
			if(thickness <= 0) thickness = 1;
			if(gridSize ==  0) gridSize = 1;

			build(subDivision, gridSize, colorXY, thickness, PLANE_XY);
			build(subDivision, gridSize, colorZY, thickness, PLANE_ZY);
			build(subDivision, gridSize, colorXZ, thickness, PLANE_XZ);
		}

		private function build(subDivision:uint, gridSize:uint, color:uint, thickness:Number, plane:String):void
		{
			var bound:Number = gridSize *.5;
			var step:Number = gridSize/subDivision;
			var v0 : Vector3D = new Vector3D(0, 0, 0) ;
			var v1 : Vector3D = new Vector3D(0, 0, 0) ;
			var inc:Number = -bound;

			while(inc<=bound){

				switch(plane){
					case PLANE_ZY:
						v0.x = 0;
						v0.y = inc;
						v0.z = bound;
						v1.x = 0;
						v1.y = inc;
						v1.z = -bound;
						addSegment( new LineSegment(v0, v1, color, color, thickness));

						v0.z = inc;
						v0.x = 0;
						v0.y = bound;
						v1.x = 0;
						v1.y = -bound;
						v1.z = inc;
						addSegment(new LineSegment(v0, v1, color, color, thickness ));
						break;

					case PLANE_XY:
						v0.x = bound;
						v0.y = inc;
						v0.z = 0;
						v1.x = -bound;
						v1.y = inc;
						v1.z = 0;
						addSegment( new LineSegment(v0, v1, color, color, thickness));
						v0.x = inc;
						v0.y = bound;
						v0.z = 0;
						v1.x = inc;
						v1.y = -bound;
						v1.z = 0;
						addSegment(new LineSegment(v0, v1, color, color, thickness ));
						break;

					default:
						v0.x = bound;
						v0.y = 0;
						v0.z = inc;
						v1.x = -bound;
						v1.y = 0;
						v1.z = inc;
						addSegment( new LineSegment(v0, v1, color, color, thickness));

						v0.x = inc;
						v0.y = 0;
						v0.z = bound;
						v1.x = inc;
						v1.y = 0;
						v1.z = -bound;
						addSegment(new LineSegment(v0, v1, color, color, thickness ));
				}

				inc += step;
			}
		}

	}
}
