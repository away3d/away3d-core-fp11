package away3d.textures
{
	import away3d.arcane;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.TextureBase;

	use namespace arcane;

	public class Texture2DProxyBase extends TextureProxyBase
	{
		public function Texture2DProxyBase()
		{
			super();
		}

		override final protected function createTexture(context : Context3D) : TextureBase
		{
			return context.createTexture(width, height, Context3DTextureFormat.BGRA, false);
		}
	}
}
