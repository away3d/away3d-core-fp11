/**
 * Author: David Lenaerts
 */
package away3d.core.managers
{
	import away3d.materials.utils.MipmapGenerator;

	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;

	public class Texture3DProxy
	{
		private var _bitmapData : BitmapData;
		private var _textures : Vector.<Texture>;
		private var _dirty : Vector.<Boolean>;
		private var _maxIndex : int = -1;
		private var _mipMapTex : BitmapData;

		public function Texture3DProxy(mipMapTex : BitmapData = null)
		{
			_mipMapTex = mipMapTex;
			_textures = new Vector.<Texture>(8);
			_dirty = new Vector.<Boolean>(8);
		}

		public function get bitmapData() : BitmapData
		{
			return _bitmapData;
		}

		public function set bitmapData(value : BitmapData) : void
		{
			if (value == _bitmapData) return;

			if (_bitmapData) {
				if (value.width != _bitmapData.width || value.height != _bitmapData.height)
					invalidateSize();
				else
					invalidateContent();
			}

			_bitmapData = value;
		}

		public function invalidateContent() : void
		{
			for (var i : int = 0; i <= _maxIndex; ++i) {
				_dirty[i] = true;
			}
		}

		private function invalidateSize() : void
		{
			var tex : Texture;
			for (var i : int = 0; i <= _maxIndex; ++i) {
				tex = _textures[i];
				if (tex) {
					tex.dispose();
					_textures[i] = null;
				    _dirty[i] = false;
				}
			}
		}

		public function dispose(deep : Boolean) : void
		{
			if (deep) {
				if (_bitmapData) _bitmapData.dispose();
				_bitmapData = null;
			}

			for (var i : int = 0; i <= _maxIndex; ++i)
				if (_textures[i]) _textures[i].dispose();
		}

		public function getTextureForContext(context : Context3D, contextIndex : uint) : Texture
		{
			if (contextIndex > _maxIndex) _maxIndex = contextIndex;
			var tex : Texture = _textures[contextIndex];

			if (!tex || _dirty[contextIndex]) {
				if (!tex) _textures[contextIndex] = tex = context.createTexture(_bitmapData.width, _bitmapData.height, Context3DTextureFormat.BGRA, false);
				MipmapGenerator.generateMipMaps(_bitmapData, tex, _mipMapTex, true);
				_dirty[contextIndex] = false;
			}

			return tex;
		}
	}
}
