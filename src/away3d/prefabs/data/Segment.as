package away3d.prefabs.data {
	import flash.geom.Vector3D;

	public class Segment {
		public var start:Vector3D;
		public var end:Vector3D;

		public var startR:Number;
		public var startG:Number;
		public var startB:Number;
		public var startAlpha:Number = 1;

		public var endR:uint;
		public var endG:uint;
		public var endB:uint;
		public var endAlpha:Number = 1;

		public var thickness:Number;

		public function Segment(start:Vector3D, end:Vector3D, thickness:Number = 1, startColor:uint = 0xffffff, endColor:uint = 0xffffff) {
			this.start = start;
			this.end = end;
			this.startColor = startColor;
			this.endColor = endColor;
			this.thickness = thickness;
		}

		public function set startColor(value:uint):void {
			startR = ((value >> 16) & 0xFF) / 0xFF;
			startG = ((value >> 8) & 0xFF) / 0xFF;
			startB = (value & 0xff) / 0xFF;
		}

		public function get startColor():uint {
			return (startR * 0xFF << 16) + (startG * 0xFF << 8) + startB * 0xFF;
		}

		public function set endColor(value:uint):void {
			endR = ((value >> 16) & 0xFF) / 0xFF;
			endG = ((value >> 8) & 0xFF) / 0xFF;
			endB = (value & 0xff) / 0xFF;
		}

		public function get endColor():uint {
			return (endR * 0xFF << 16) + (endG * 0xFF << 8) + endB * 0xFF;
		}
	}
}
