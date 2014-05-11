package away3d.debug.data {
	import away3d.containers.ObjectContainer3D;
	import away3d.entities.Mesh;
	import away3d.prefabs.SegmentSetPrefab;
	import away3d.prefabs.data.Segment;

	import flash.geom.Vector3D;

	public class TridentLines extends ObjectContainer3D {
		private var segmentSet:SegmentSetPrefab;

		public function TridentLines(vectors:Vector.<Vector.<Vector3D>>, colors:Vector.<uint>):void {
			super();
			build(vectors, colors);
		}

		private function build(vectors:Vector.<Vector.<Vector3D>>, colors:Vector.<uint>):void {
			var letter:Vector.<Vector3D>;
			var v0:Vector3D;
			var v1:Vector3D;
			var color:uint;
			var j:uint;

			segmentSet = new SegmentSetPrefab();

			for (var i:uint = 0; i < vectors.length; ++i) {
				color = colors[i];
				letter = vectors[i];

				for (j = 0; j < letter.length; j += 2) {
					v0 = letter[j];
					v1 = letter[j + 1];
					segmentSet.addSegment(new Segment(v0, v1, 1, colors[i], colors[i]));
				}
			}
			addChild(segmentSet.getNewObject() as Mesh);
		}
	}
}