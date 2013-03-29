package away3d.animators.data
{
	import flash.geom.ColorTransform;

	
	public class ColorSegmentPoint
	{
		private var _color:ColorTransform;
		private var _life:Number;
		
		public function ColorSegmentPoint(life:Number,color:ColorTransform)
		{
			//0<life<1
			if (life<=0||life>=1)
				throw(new Error("life exceeds range (0,1)"));
			_life = life;
			_color = color;
		}
		
		public function get color():ColorTransform
		{
			return _color;
		}
		
		public function get life():Number
		{
			return _life;
		}
		
	}

}