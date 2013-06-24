package away3d.debug.data
{
	import away3d.entities.SegmentSet;
	import away3d.primitives.LineSegment;
	
	import flash.geom.Vector3D;
	
	public class TridentLines extends SegmentSet
	{
		public function TridentLines(vectors:Vector.<Vector.<Vector3D>>, colors:Vector.<uint>):void
		{
			super();
			build(vectors, colors);
		}
		
		private function build(vectors:Vector.<Vector.<Vector3D>>, colors:Vector.<uint>):void
		{
			var letter:Vector.<Vector3D>;
			var v0:Vector3D;
			var v1:Vector3D;
			var color:uint;
			var j:uint;
			
			for (var i:uint = 0; i < vectors.length; ++i) {
				color = colors[i];
				letter = vectors[i];
				
				for (j = 0; j < letter.length; j += 2) {
					v0 = letter[j];
					v1 = letter[j + 1];
					addSegment(new LineSegment(v0, v1, color, color, 1));
				}
			}
		}
	
	}
}

