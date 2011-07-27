package away3d.loaders.parsers.data
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class DefaultBitmapData {
		
		private static var _bitmapData:BitmapData;

		public static function get bitmapData() : BitmapData
		{
			if(!_bitmapData)
				build();
				
			return _bitmapData;
		}
		
		private static function build() : void
		{
			var size:uint = 256;
			_bitmapData = new BitmapData(size,size, false, 0xFFFFFF);
			var i:uint;
			var step:int = size/8;
			var rect:Rectangle = new Rectangle(0,0,step,step);
			for(i=0;i<4;++i){
				_bitmapData.fillRect(rect, 0x000000);
				rect.x += step*2;
			}
			rect.x = 0;
			rect.width = _bitmapData.width;
			var destpt:Point = new Point(0,0);
			
			for(i=1;i<8;++i){
				destpt.x = (i%2 == 0)? 0 : step;
				destpt.y = step*i;
				_bitmapData.copyPixels(_bitmapData,rect,destpt);
			}
		}
	}
}