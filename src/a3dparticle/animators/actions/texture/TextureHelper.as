package a3dparticle.animators.actions.texture
{
	import flash.display.BitmapData;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class TextureHelper
	{
		
		public static function hori2tilt(_startColor:uint, _endColor:uint, turnPoint:Number, precision:uint = 512):BitmapData
		{
			var startColor:Array = [];
			startColor[0] = (_startColor >> 24) & 0xff;
			startColor[1] = (_startColor >> 16) & 0xff;
			startColor[2] = (_startColor >> 8) & 0xff;
			startColor[3] = _startColor & 0xff;
			var endColor:Array = [];
			endColor[0] = (_endColor >> 24) & 0xff;
			endColor[1] = (_endColor >> 16) & 0xff;
			endColor[2] = (_endColor >> 8) & 0xff;
			endColor[3] = _endColor & 0xff;
			var deltaColor:Array = [];
			deltaColor[0] = endColor[0] - startColor[0];
			deltaColor[1] = endColor[1] - startColor[1];
			deltaColor[2] = endColor[2] - startColor[2];
			deltaColor[3] = endColor[3] - startColor[3];
			
			var genFun:Function = function(u:Number):uint
			{
				if (u <= turnPoint)
				{
					return _startColor;
				}
				else
				{
					var delta:Number = (u - turnPoint) / (1 - turnPoint);
					var result:Array = [];
					result[0] = startColor[0] + delta * deltaColor[0];
					result[1] = startColor[1] + delta * deltaColor[1];
					result[2] = startColor[2] + delta * deltaColor[2];
					result[3] = startColor[3] + delta * deltaColor[3];
					return (result[0] << 24) + (result[1] << 16) + (result[2] << 8) + result[3];
				}
			}
			return genPixels(precision, genFun);
		}
		
		public static function hori2jump(_startColor:uint, jump:uint, _endColor:uint, turnPoint:Number, precision:uint = 512):BitmapData
		{
			var startColor:Array = [];
			startColor[0] = (jump >> 24) & 0xff;
			startColor[1] = (jump >> 16) & 0xff;
			startColor[2] = (jump >> 8) & 0xff;
			startColor[3] = jump & 0xff;
			var endColor:Array = [];
			endColor[0] = (_endColor >> 24) & 0xff;
			endColor[1] = _endColor & 0xff;
			endColor[2] = (_endColor >> 8) & 0xff;
			endColor[3] = _endColor & 0xff;
			var deltaColor:Array = [];
			deltaColor[0] = endColor[0] - startColor[0];
			deltaColor[1] = endColor[1] - startColor[1];
			deltaColor[2] = endColor[2] - startColor[2];
			deltaColor[3] = endColor[3] - startColor[3];
			
			var genFun:Function = function(u:Number):uint
			{
				if (u <= turnPoint)
				{
					return _startColor;
				}
				else
				{
					var delta:Number = (u - turnPoint) / (1 - turnPoint);
					var result:Array = [];
					result[0] = startColor[0] + delta * deltaColor[0];
					result[1] = startColor[1] + delta * deltaColor[1];
					result[2] = startColor[2] + delta * deltaColor[2];
					result[3] = startColor[3] + delta * deltaColor[3];
					return (result[0] << 24) + (result[1] << 16) + (result[2] << 8) + result[3];
				}
			}
			return genPixels(precision, genFun);
		}
		
		
		public static function genPixels(precision:uint,genFun:Function):BitmapData
		{
			var bitmap:BitmapData = new BitmapData(precision, 2, true);
			var step:Number = 1 / precision;
			for (var i:int = 0; i < precision; i++)
			{
				var color:uint = genFun(step * i);
				bitmap.setPixel32(i, 0, genFun(step * i));
				bitmap.setPixel32(i, 1, genFun(step * i));
			}
			return bitmap;
		}
		
	}

}