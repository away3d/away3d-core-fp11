package away3d.core.pool
{
	import away3d.arcane;
	import away3d.managers.Stage3DProxy;
	import away3d.textures.TextureProxyBase;

	use namespace arcane;

	public class TextureDataPool
	{
		private var _pool:Object = {};
		private var _context:Stage3DProxy;

		public function TextureDataPool(context:Stage3DProxy)
		{
			_context = context;
		}

		public function getItem(textureProxy:TextureProxyBase):TextureData
		{
			return (_pool[textureProxy.id] || (_pool[textureProxy.id] = textureProxy.addTextureData(new TextureData(this, _context, textureProxy))))
		}

		public function disposeItem(textureProxy:TextureProxyBase):void
		{
			textureProxy.removeTextureData(_pool[textureProxy.id]);

			_pool[textureProxy.id] = null;
		}
	}
}