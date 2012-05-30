package away3d.textures
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.errors.AbstractMethodError;
	import away3d.events.Stage3DEvent;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.library.assets.NamedAssetBase;
	import flash.utils.Dictionary;
	
	import flash.display3D.Context3D;
	import flash.display3D.textures.TextureBase;

	use namespace arcane;

	public class TextureProxyBase extends NamedAssetBase implements IAsset
	{
		protected var _textures : Dictionary;

		protected var _width : int;
		protected var _height : int;

		public function TextureProxyBase()
		{
			_textures = new Dictionary(true);
		}
		
		
		public function get assetType() : String
		{
			return AssetType.TEXTURE;
		}

		public function get width() : int
		{
			return _width;
		}

		public function get height() : int
		{
			return _height;
		}

		public function getTextureForStage3D(stage3DProxy : Stage3DProxy) : TextureBase
		{
			var tex : TextureBase = _textures[stage3DProxy];

			if (!tex) {
				_textures[stage3DProxy] = tex = createTexture(stage3DProxy._context3D);
				uploadContent(tex);
				stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onRecreated, false, 0, true);
			}

			return tex;
		}

		protected function uploadContent(texture : TextureBase) : void
		{
			throw new AbstractMethodError();
		}

		protected function setSize(width : int, height : int) : void
		{
			if (_width != width || _height != height)
				invalidateSize();

			_width = width;
			_height = height;
		}

		public function invalidateContent() : void
		{
			_textures = new Dictionary(true);
		}

		protected function invalidateSize() : void
		{
			_textures = new Dictionary(true);
		}

		protected function createTexture(context : Context3D) : TextureBase
		{
			throw new AbstractMethodError();
		}

		public function dispose() : void
		{
			for (var i : Object in _textures)
				_textures[i].dispose();
				delete _textures[i];
		}
		
		private function onRecreated(e:Stage3DEvent):void
		{
			var stage3Dproxy:Stage3DProxy = e.target as Stage3DProxy;
			delete _textures[stage3Dproxy];
		}
	}
}
