package away3d.materials.utils
{
	import flash.display.*;
	import flash.display3D.textures.CubeTexture;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.geom.*;

	/**
	 * MipmapGenerator is a helper class that uploads BitmapData to a Texture including mipmap levels.
	 */
	public class MipmapGenerator
	{
		private static var _matrix : Matrix = new Matrix();
		private static var _rect : Rectangle = new Rectangle();

		/**
		 * Uploads a BitmapData with mip maps to a target Texture object.
		 * @param source The source BitmapData to upload.
		 * @param target The target Texture to upload to.
		 * @param mipmap An optional mip map holder to avoids creating new instances for fe animated materials.
		 * @param alpha Indicate whether or not the uploaded bitmapData is transparent.
		 */
		public static function generateMipMaps(source : BitmapData, target : TextureBase, mipmap : BitmapData = null, alpha : Boolean = false, side : int = -1) : void
		{
			var w : uint = source.width,
				h : uint = source.height;
			var i : uint;
			var regen : Boolean = mipmap != null;
			mipmap ||= new BitmapData(w, h, alpha);

			_rect.width = w;
			_rect.height = h;
			               
			while (w >= 1 || h >= 1) {
				if (alpha) mipmap.fillRect(_rect, 0);

				_matrix.a = _rect.width/source.width;
				_matrix.d = _rect.height/source.height;

				mipmap.draw(source, _matrix, null, null, null, true);

				if (target is Texture)
					Texture(target).uploadFromBitmapData(mipmap, i++);
				else
					CubeTexture(target).uploadFromBitmapData(mipmap, side, i++);

				w >>= 1;
				h >>= 1;

				_rect.width = w > 1? w : 1;
				_rect.height = h > 1? h : 1;
			}

			if (!regen)
				mipmap.dispose();
		}
	}
}