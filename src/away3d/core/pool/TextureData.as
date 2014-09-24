package away3d.core.pool
{
	import away3d.managers.Stage3DProxy;
	import away3d.textures.TextureProxyBase;

	import flash.display3D.textures.TextureBase;

	public class TextureData implements ITextureData
	{
		private var _pool:TextureDataPool;

		public var context:Stage3DProxy;

		public var texture:TextureBase;

		public var textureProxy:TextureProxyBase;

		public var invalid:Boolean;

		public function TextureData(pool:TextureDataPool, context:Stage3DProxy, textureProxy:TextureProxyBase)
		{
			_pool = pool;
			this.context = context;
			this.textureProxy = textureProxy;
		}

		public function dispose():void
		{
			_pool.disposeItem(textureProxy);

			texture.dispose();
			texture = null;
		}

		public function invalidate():void
		{
			invalid = true;
		}
	}
}
