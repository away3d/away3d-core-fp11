/**
 * Author: David Lenaerts
 */
package away3d.core.managers
{
	import away3d.arcane;
	import away3d.materials.utils.CubeMap;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.CubeTexture;

	use namespace arcane;

	public class CubeTexture3DProxy
	{
		private var _cubeMap : CubeMap;
		private var _textures : Vector.<CubeTexture>;
		private var _dirty : Vector.<Boolean>;
		private var _maxIndex : int = -1;

		public function CubeTexture3DProxy()
		{
			_textures = new Vector.<CubeTexture>(8);
			_dirty = new Vector.<Boolean>(8);
		}

		public function get cubeMap() : CubeMap
		{
			return _cubeMap;
		}

		public function set cubeMap(value : CubeMap) : void
		{
			if (value == _cubeMap) return;

			if (_cubeMap) {
				if (value.size != _cubeMap.size)
					invalidateSize();
				else
					invalidateContent();
			}

			_cubeMap = value;
		}

		public function invalidateContent() : void
		{
			for (var i : int = 0; i <= _maxIndex; ++i) {
				_dirty[i] = true;
			}
		}

		private function invalidateSize() : void
		{
			var tex : CubeTexture;
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
				if (_cubeMap) _cubeMap.dispose();
				_cubeMap = null;
			}

			for (var i : int = 0; i <= _maxIndex; ++i)
				if (_textures[i]) _textures[i].dispose();
		}

		public function getTextureForContext(context : Context3D, contextIndex : int) : CubeTexture
		{
			if (contextIndex > _maxIndex) _maxIndex = contextIndex;
			var tex : CubeTexture = _textures[contextIndex];

			if (!tex || _dirty[contextIndex]) {
				if (!tex) _textures[contextIndex] = tex = context.createCubeTexture(_cubeMap.size, Context3DTextureFormat.BGRA, false);
				_cubeMap.upload(_textures[contextIndex]);
				_dirty[contextIndex] = false;
			}

			return tex;
		}
	}
}
