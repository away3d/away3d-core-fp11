package away3d.textures {
	import away3d.arcane;

	import flash.display3D.Context3D;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.utils.ByteArray;

	use namespace arcane;

	public class ATFTexture extends Texture2DBase
	{
		private var _atfData : ATFData;
		
		public function ATFTexture(byteArray : ByteArray)
		{
			super();
			
			atfData = new ATFData(byteArray);
			_format = atfData.format;
			_hasMipmaps = _atfData.numTextures > 1;
		}

		public function get atfData() : ATFData
		{
			return _atfData;
		}

		public function set atfData(value : ATFData) : void
		{
			_atfData = value;
			
			invalidateContent();
			
			setSize(value.width, value.height);
		}								
		
		override protected function uploadContent(texture : TextureBase) : void
		{
			Texture(texture).uploadCompressedTextureFromByteArray(_atfData.data, 0, false);
		}
		
		override protected function createTexture(context : Context3D) : TextureBase
		{
			return context.createTexture(_width, _height, atfData.format, false);
		}
	}
}
