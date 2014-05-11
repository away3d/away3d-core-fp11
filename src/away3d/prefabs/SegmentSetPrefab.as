package away3d.prefabs {
	import away3d.arcane;
	import away3d.core.base.Geometry;
	import away3d.core.base.LineSubGeometry;
	import away3d.core.base.Object3D;
	import away3d.entities.Mesh;
	import away3d.library.assets.AssetType;
	import away3d.prefabs.data.Segment;

	use namespace arcane;

	public class SegmentSetPrefab extends PrefabBase {
		private const segments:Vector.<Segment> = new Vector.<Segment>();
		private var segmentsLength:uint = 0;
		private var lineSubGeometry:LineSubGeometry;
		private var _geomDirty:Boolean = true;
		private var _geometry:Geometry;

		/**
		 * Create segment set
		 */
		public function SegmentSetPrefab() {
			lineSubGeometry = new LineSubGeometry();
			_geometry = new Geometry();
			_geometry.addSubGeometry(lineSubGeometry);
		}

		public function addSegment(segment:Segment):void {
			var index:int = segments.indexOf(segment);
			if (index != -1) return;
			segments[segmentsLength++] = segment;
			invalidate();
		}

		public function removeSegment(segment:Segment):void {
			var index:int = segments.indexOf(segment);
			if (index == -1) return;
			segments.splice(index, 1);
			segmentsLength--;
			invalidate();
		}

		public function removeSegmentAt(index:int):void {
			if (index < 0 || index >= segmentsLength) return;
			segments.splice(index, 1);
			segmentsLength--;
			invalidate();
		}

		public function removeAllSegments():void {
			segments.length = 0;
			segmentsLength = 0;
			invalidate();
		}

		public function invalidate():void {
			_geomDirty = true;
		}

		override arcane function validate():void {
			if (_geomDirty) {
				updateGeometry();
			}
		}

		private function updateGeometry():void {
			var startPositions:Vector.<Number> = lineSubGeometry.startPositions;
			if(!startPositions) startPositions = new Vector.<Number>();
			startPositions.length = 0;

			var endPositions:Vector.<Number> = lineSubGeometry.endPositions;
			if(!endPositions) endPositions = new Vector.<Number>();
			endPositions.length = 0;

			var startColors:Vector.<Number> = lineSubGeometry.startColors;
			if(!startColors) startColors = new Vector.<Number>();
			startColors.length = 0;

			var endColors:Vector.<Number> = lineSubGeometry.endColors;
			if(!endColors) endColors = new Vector.<Number>();
			endColors.length = 0;

			var thickness:Vector.<Number> = lineSubGeometry.thickness;
			if(!thickness) thickness = new Vector.<Number>();
			thickness.length = 0;

			for (var i:uint = 0; i < segmentsLength; i++) {
				var segment:Segment = segments[i];
				startPositions.push(segment.start.x, segment.start.y, segment.start.z);
				endPositions.push(segment.end.x, segment.end.y, segment.end.z);
				startColors.push(segment.startR,segment.startG,segment.startB, segment.startAlpha);
				endColors.push(segment.endR,segment.endG,segment.endB, segment.endAlpha);
				thickness.push(segment.thickness);
			}

			lineSubGeometry.updatePositions(startPositions, endPositions);
			lineSubGeometry.updateColors(startColors, endColors);
			lineSubGeometry.updateThickness(thickness);

			_geomDirty = false;
		}

		override protected function createObject():Object3D {
			var mesh:Mesh = new Mesh(_geometry);
			mesh.sourcePrefab = this;
			return mesh;
		}

		override public function dispose():void {
			super.dispose();
			if (_geometry) _geometry.dispose();
			removeAllSegments();
		}

		override public function get assetType():String {
			return AssetType.LINE_SEGMENT;
		}
	}
}
