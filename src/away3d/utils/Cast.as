package away3d.utils
{
	
	import away3d.errors.CastError;
	import away3d.textures.BitmapTexture;
	
	import flash.display.*;
	import flash.geom.Matrix;
	import flash.utils.*;
	
	/** Helper class for casting assets to usable objects */
	public class Cast
	{
		private static var _colorNames:Dictionary;
		private static var _hexChars:String = "0123456789abcdefABCDEF";
		
		private static var _notClasses:Dictionary = new Dictionary();
		private static var _classes:Dictionary = new Dictionary();
		
		public static function string(data:*):String
		{
			if (data is Class)
				data = new data;
			
			if (data is String)
				return data;
			
			return String(data);
		}
		
		public static function byteArray(data:*):ByteArray
		{
			//throw new Error(typeof(data));
			
			if (data is Class)
				data = new data;
			
			if (data is ByteArray)
				return data;
			
			return ByteArray(data);
		}
		
		public static function xml(data:*):XML
		{
			if (data is Class)
				data = new data;
			
			if (data is XML)
				return data;
			
			return XML(data);
		}
		
		private static function isHex(string:String):Boolean
		{
			var length:int = string.length;
			for (var i:int = 0; i < length; ++i) {
				if (_hexChars.indexOf(string.charAt(i)) == -1)
					return false;
			}
			
			return true;
		}
		
		public static function tryColor(data:*):uint
		{
			if (data is uint)
				return data as uint;
			
			if (data is int)
				return data as uint;
			
			if (data is String) {
				if (data == "random")
					return uint(Math.random()*0x1000000);
				
				if (_colorNames == null) {
					_colorNames = new Dictionary();
					_colorNames["steelblue"] = 0x4682B4;
					_colorNames["royalblue"] = 0x041690;
					_colorNames["cornflowerblue"] = 0x6495ED;
					_colorNames["lightsteelblue"] = 0xB0C4DE;
					_colorNames["mediumslateblue"] = 0x7B68EE;
					_colorNames["slateblue"] = 0x6A5ACD;
					_colorNames["darkslateblue"] = 0x483D8B;
					_colorNames["midnightblue"] = 0x191970;
					_colorNames["navy"] = 0x000080;
					_colorNames["darkblue"] = 0x00008B;
					_colorNames["mediumblue"] = 0x0000CD;
					_colorNames["blue"] = 0x0000FF;
					_colorNames["dodgerblue"] = 0x1E90FF;
					_colorNames["deepskyblue"] = 0x00BFFF;
					_colorNames["lightskyblue"] = 0x87CEFA;
					_colorNames["skyblue"] = 0x87CEEB;
					_colorNames["lightblue"] = 0xADD8E6;
					_colorNames["powderblue"] = 0xB0E0E6;
					_colorNames["azure"] = 0xF0FFFF;
					_colorNames["lightcyan"] = 0xE0FFFF;
					_colorNames["paleturquoise"] = 0xAFEEEE;
					_colorNames["mediumturquoise"] = 0x48D1CC;
					_colorNames["lightseagreen"] = 0x20B2AA;
					_colorNames["darkcyan"] = 0x008B8B;
					_colorNames["teal"] = 0x008080;
					_colorNames["cadetblue"] = 0x5F9EA0;
					_colorNames["darkturquoise"] = 0x00CED1;
					_colorNames["aqua"] = 0x00FFFF;
					_colorNames["cyan"] = 0x00FFFF;
					_colorNames["turquoise"] = 0x40E0D0;
					_colorNames["aquamarine"] = 0x7FFFD4;
					_colorNames["mediumaquamarine"] = 0x66CDAA;
					_colorNames["darkseagreen"] = 0x8FBC8F;
					_colorNames["mediumseagreen"] = 0x3CB371;
					_colorNames["seagreen"] = 0x2E8B57;
					_colorNames["darkgreen"] = 0x006400;
					_colorNames["green"] = 0x008000;
					_colorNames["forestgreen"] = 0x228B22;
					_colorNames["limegreen"] = 0x32CD32;
					_colorNames["lime"] = 0x00FF00;
					_colorNames["chartreuse"] = 0x7FFF00;
					_colorNames["lawngreen"] = 0x7CFC00;
					_colorNames["greenyellow"] = 0xADFF2F;
					_colorNames["yellowgreen"] = 0x9ACD32;
					_colorNames["palegreen"] = 0x98FB98;
					_colorNames["lightgreen"] = 0x90EE90;
					_colorNames["springgreen"] = 0x00FF7F;
					_colorNames["mediumspringgreen"] = 0x00FA9A;
					_colorNames["darkolivegreen"] = 0x556B2F;
					_colorNames["olivedrab"] = 0x6B8E23;
					_colorNames["olive"] = 0x808000;
					_colorNames["darkkhaki"] = 0xBDB76B;
					_colorNames["darkgoldenrod"] = 0xB8860B;
					_colorNames["goldenrod"] = 0xDAA520;
					_colorNames["gold"] = 0xFFD700;
					_colorNames["yellow"] = 0xFFFF00;
					_colorNames["khaki"] = 0xF0E68C;
					_colorNames["palegoldenrod"] = 0xEEE8AA;
					_colorNames["blanchedalmond"] = 0xFFEBCD;
					_colorNames["moccasin"] = 0xFFE4B5;
					_colorNames["wheat"] = 0xF5DEB3;
					_colorNames["navajowhite"] = 0xFFDEAD;
					_colorNames["burlywood"] = 0xDEB887;
					_colorNames["tan"] = 0xD2B48C;
					_colorNames["rosybrown"] = 0xBC8F8F;
					_colorNames["sienna"] = 0xA0522D;
					_colorNames["saddlebrown"] = 0x8B4513;
					_colorNames["chocolate"] = 0xD2691E;
					_colorNames["peru"] = 0xCD853F;
					_colorNames["sandybrown"] = 0xF4A460;
					_colorNames["darkred"] = 0x8B0000;
					_colorNames["maroon"] = 0x800000;
					_colorNames["brown"] = 0xA52A2A;
					_colorNames["firebrick"] = 0xB22222;
					_colorNames["indianred"] = 0xCD5C5C;
					_colorNames["lightcoral"] = 0xF08080;
					_colorNames["salmon"] = 0xFA8072;
					_colorNames["darksalmon"] = 0xE9967A;
					_colorNames["lightsalmon"] = 0xFFA07A;
					_colorNames["coral"] = 0xFF7F50;
					_colorNames["tomato"] = 0xFF6347;
					_colorNames["darkorange"] = 0xFF8C00;
					_colorNames["orange"] = 0xFFA500;
					_colorNames["orangered"] = 0xFF4500;
					_colorNames["crimson"] = 0xDC143C;
					_colorNames["red"] = 0xFF0000;
					_colorNames["deeppink"] = 0xFF1493;
					_colorNames["fuchsia"] = 0xFF00FF;
					_colorNames["magenta"] = 0xFF00FF;
					_colorNames["hotpink"] = 0xFF69B4;
					_colorNames["lightpink"] = 0xFFB6C1;
					_colorNames["pink"] = 0xFFC0CB;
					_colorNames["palevioletred"] = 0xDB7093;
					_colorNames["mediumvioletred"] = 0xC71585;
					_colorNames["purple"] = 0x800080;
					_colorNames["darkmagenta"] = 0x8B008B;
					_colorNames["mediumpurple"] = 0x9370DB;
					_colorNames["blueviolet"] = 0x8A2BE2;
					_colorNames["indigo"] = 0x4B0082;
					_colorNames["darkviolet"] = 0x9400D3;
					_colorNames["darkorchid"] = 0x9932CC;
					_colorNames["mediumorchid"] = 0xBA55D3;
					_colorNames["orchid"] = 0xDA70D6;
					_colorNames["violet"] = 0xEE82EE;
					_colorNames["plum"] = 0xDDA0DD;
					_colorNames["thistle"] = 0xD8BFD8;
					_colorNames["lavender"] = 0xE6E6FA;
					_colorNames["ghostwhite"] = 0xF8F8FF;
					_colorNames["aliceblue"] = 0xF0F8FF;
					_colorNames["mintcream"] = 0xF5FFFA;
					_colorNames["honeydew"] = 0xF0FFF0;
					_colorNames["lightgoldenrodyellow"] = 0xFAFAD2;
					_colorNames["lemonchiffon"] = 0xFFFACD;
					_colorNames["cornsilk"] = 0xFFF8DC;
					_colorNames["lightyellow"] = 0xFFFFE0;
					_colorNames["ivory"] = 0xFFFFF0;
					_colorNames["floralwhite"] = 0xFFFAF0;
					_colorNames["linen"] = 0xFAF0E6;
					_colorNames["oldlace"] = 0xFDF5E6;
					_colorNames["antiquewhite"] = 0xFAEBD7;
					_colorNames["bisque"] = 0xFFE4C4;
					_colorNames["peachpuff"] = 0xFFDAB9;
					_colorNames["papayawhip"] = 0xFFEFD5;
					_colorNames["beige"] = 0xF5F5DC;
					_colorNames["seashell"] = 0xFFF5EE;
					_colorNames["lavenderblush"] = 0xFFF0F5;
					_colorNames["mistyrose"] = 0xFFE4E1;
					_colorNames["snow"] = 0xFFFAFA;
					_colorNames["white"] = 0xFFFFFF;
					_colorNames["whitesmoke"] = 0xF5F5F5;
					_colorNames["gainsboro"] = 0xDCDCDC;
					_colorNames["lightgrey"] = 0xD3D3D3;
					_colorNames["silver"] = 0xC0C0C0;
					_colorNames["darkgrey"] = 0xA9A9A9;
					_colorNames["grey"] = 0x808080;
					_colorNames["lightslategrey"] = 0x778899;
					_colorNames["slategrey"] = 0x708090;
					_colorNames["dimgrey"] = 0x696969;
					_colorNames["darkslategrey"] = 0x2F4F4F;
					_colorNames["black"] = 0x000000;
					_colorNames["transparent"] = 0xFF000000;
				}
				
				if (_colorNames[data] != null)
					return _colorNames[data];
				
				if (((data as String).length == 6) && isHex(data))
					return parseInt("0x" + data);
			}
			
			return 0xFFFFFF;
		}
		
		public static function color(data:*):uint
		{
			var result:uint = tryColor(data);
			
			if (result == 0xFFFFFFFF)
				throw new CastError("Can't cast to color: " + data);
			
			return result;
		}
		
		public static function tryClass(name:String):Object
		{
			if (_notClasses[name])
				return name;
			
			var result:Class = _classes[name];
			
			if (result != null)
				return result;
			
			try {
				result = getDefinitionByName(name) as Class;
				_classes[name] = result;
				return result;
			} catch (error:ReferenceError) {
			}
			
			_notClasses[name] = true;
			
			return name;
		}
		
		public static function bitmapData(data:*):BitmapData
		{
			if (data == null)
				return null;
			
			if (data is String)
				data = tryClass(data);
			
			if (data is Class) {
				try {
					data = new data;
				} catch (bitmapError:ArgumentError) {
					data = new data(0, 0);
				}
			}
			
			if (data is BitmapData)
				return data;
			
			if (data is Bitmap) {
				if ((data as Bitmap).hasOwnProperty("bitmapData")) // if (data is BitmapAsset)
					return (data as Bitmap).bitmapData;
			}
			
			if (data is DisplayObject) {
				var ds:DisplayObject = data as DisplayObject;
				var bmd:BitmapData = new BitmapData(ds.width, ds.height, true, 0x00FFFFFF);
				var mat:Matrix = ds.transform.matrix.clone();
				mat.tx = 0;
				mat.ty = 0;
				bmd.draw(ds, mat, ds.transform.colorTransform, ds.blendMode, bmd.rect, true);
				return bmd;
			}
			
			throw new CastError("Can't cast to BitmapData: " + data);
		}
		
		public static function bitmapTexture(data:*):BitmapTexture
		{
			if (data == null)
				return null;
			
			if (data is String)
				data = tryClass(data);
			
			if (data is Class) {
				try {
					data = new data;
				} catch (materialError:ArgumentError) {
					data = new data(0, 0);
				}
			}
			
			if (data is BitmapTexture)
				return data;
			
			try {
				var bmd:BitmapData = Cast.bitmapData(data);
				return new BitmapTexture(bmd);
			} catch (error:CastError) {
			}
			
			throw new CastError("Can't cast to BitmapTexture: " + data);
		}
	}
}
