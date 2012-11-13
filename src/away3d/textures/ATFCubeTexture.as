package away3d.textures {
	import away3d.arcane;

	import flash.display3D.Context3D;
	import flash.display3D.textures.CubeTexture;
	import flash.display3D.textures.TextureBase;
	import flash.utils.ByteArray;

	use namespace arcane;

	public class ATFCubeTexture extends CubeTextureBase
	{
		private var _atfdata : ATFData;
		
		public function ATFCubeTexture(data : ByteArray)
		{
			super();

			_atfdata = new ATFData(data);
			this.textureFormat = atfdata.format;
			this.hasMipmaps = _atfdata.numTextures > 1;
		}

		public function get atfdata() : ATFData
		{
			return _atfdata;
		}

		public function set atfdata(value : ATFData) : void
		{
			_atfdata = value;
			
			invalidateContent();
			
			setSize(value.width, value.height);
		}	
		
		override protected function uploadContent(texture : TextureBase) : void
		{
			CubeTexture(texture).uploadCompressedTextureFromByteArray(_atfdata.data, 0, false);
		}
		
		override protected function createTexture(context : Context3D) : TextureBase
		{
			//return context.createTexture(_width, _height, atfdata.format, false);
			return context.createCubeTexture(512, atfdata.format, false);
		}
		
	}
}
