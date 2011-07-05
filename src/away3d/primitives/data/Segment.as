package away3d.primitives.data
{
	import away3d.arcane;
	import away3d.entities.SegmentSet;

	import flash.geom.Vector3D;

	use namespace arcane;
	
	public class Segment
	{
		arcane var _segmentsBase:SegmentSet;
		arcane var _thickness:Number;
		private var _index:uint;
		arcane var _start : Vector3D;
		arcane var _end : Vector3D;
		private var _startColor : uint;
		private var _endColor : uint;
		arcane var _startR : Number;
		arcane var _startG : Number;
		arcane var _startB : Number;
		arcane var _endR : Number;
		arcane var _endG : Number;
		arcane var _endB : Number;

		public function Segment(start:Vector3D, end:Vector3D, anchor:Vector3D, color0:uint = 0x333333, color1:uint = 0x333333, thickness:Number = 1):void
		{
			_thickness = thickness *.5;
			// TODO: add support for curve using anchor v1
			// Prefer removing v1 from this, and make Curve a separate class extending Segment? (- David)
			_start = start;
			_end = end;
			startColor 	= color0;
			endColor 	= color1;
		}

		public function updateSegment(start:Vector3D, end:Vector3D, anchor:Vector3D, startColor:uint = 0x333333, endColor:uint = 0x333333, thickness:Number = 1) : void
		{
			_start = start;
			_end = end;
			_startColor = startColor;
			_endColor = endColor;
			_thickness = thickness;
			update();
		}

		/**
		 * Defines the starting vertex.
		 */
        public function get start():Vector3D
        {
            return _start;
        }

        public function set start(value:Vector3D):void
        {
			_start = value;

			update();
        }
		
		/**
		 * Defines the ending vertex.
		 */
        public function get end():Vector3D
        {
            return _end;
        }
		
        public function set end(value:Vector3D):void
        {
         	_end = value;

			update();
        }
		
		/**
		 * Defines the ending vertex.
		 */
        public function get thickness():Number
        {
            return _thickness;
        }
		
        public function set thickness(value:Number):void
        {
         	_thickness = value*.5;

			update();
        }
		/**
		 * Defines the startColor
		 */
        public function get startColor():uint
        {
            return  _startColor;
        }
		
        public function set startColor(color:uint):void
        {
         	_startR =  ( ( color >> 16 ) & 0xff ) / 255;
			_startG =  ( ( color >> 8 ) & 0xff ) / 255;
			_startB =  ( color & 0xff ) / 255;

			update();
        }
		
		/**
		 * Defines the endColor
		 */
        public function get endColor():uint
        {
             return  _endColor;
        }
		
        public function set endColor(color:uint):void
        {
         	_endR =  ( ( color >> 16 ) & 0xff ) / 255;
			_endG =  ( ( color >> 8 ) & 0xff ) / 255;
			_endB =  ( color & 0xff ) / 255;

			update();
        }
		
		arcane function get index():uint
        {
			return _index;
		}
		
		arcane function set index(ind:uint):void
        {
			_index = ind;
		}
		
		arcane function set segmentsBase(segBase:SegmentSet):void
        {
			_segmentsBase = segBase;
		}

		private function update():void
		{
			if(!_segmentsBase) return;
			_segmentsBase.updateSegment(this);
		}

	}
}
