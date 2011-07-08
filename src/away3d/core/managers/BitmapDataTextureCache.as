/**
 *
 */
package away3d.core.managers
{
	import away3d.core.managers.Texture3DProxy;

	import flash.display.BitmapData;
	import flash.utils.Dictionary;

	public class BitmapDataTextureCache
	{
		private static var _instance : BitmapDataTextureCache;

		private var _textures : Dictionary;
		private var _usages : Dictionary;

		public function BitmapDataTextureCache(singletonEnforcer : SingletonEnforcer)
		{
			if (!singletonEnforcer) throw new Error("Cannot instantiate a singleton class. Use static getInstance instead.");

			_textures = new Dictionary();
			_usages = new Dictionary();
		}

		public static function getInstance() : BitmapDataTextureCache
		{
			return _instance ||= new BitmapDataTextureCache(new SingletonEnforcer());
		}

		public function getTexture(bitmapData : BitmapData) : Texture3DProxy
		{
			var texture : Texture3DProxy;
			if (!_textures[bitmapData]) {
				texture = new Texture3DProxy(bitmapData);
				_textures[bitmapData] = texture;
				_usages[texture] = 0;
			}
			_usages[texture]++;
			return _textures[bitmapData];
		}

		public function freeTexture(texture : Texture3DProxy) : void
		{
			_usages[texture]--;
			if (_usages[texture] == 0) {
				_textures[Texture3DProxy(texture).bitmapData] = null;
				texture.dispose(false);
			}
		}
	}
}

class SingletonEnforcer {}