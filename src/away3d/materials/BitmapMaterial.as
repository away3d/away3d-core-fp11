package away3d.materials
{
	import away3d.textures.BitmapTexture;
	import away3d.arcane;
	import away3d.errors.DeprecationError;
	import away3d.textures.BitmapTextureCache;

	import flash.display.BitmapData;

	use namespace arcane;

	/**
	 * BitmapMaterial is a material that uses a BitmapData texture as the surface's diffuse colour.
	 */
	[Deprecated(message="Use texture composition instead of inheritance", replacement="TextureMaterial", since="4.0a")]
	public class BitmapMaterial extends TextureMaterial
	{
		private var _alphaBlending : Boolean;
		private var _diffuseBMD : BitmapData;

		/**
		 * Creates a new BitmapMaterial.
		 * @param bitmapData The BitmapData object to use as the texture.
		 * @param smooth Indicates whether or not the texture should use smoothing.
		 * @param repeat Indicates whether or not the texture should be tiled.
		 * @param mipmap Indicates whether or not the texture should use mipmapping.
		 */
		public function BitmapMaterial(bitmapData : BitmapData = null, smooth : Boolean = true, repeat : Boolean = false, mipmap : Boolean = true)
		{
			super(null, smooth, repeat, mipmap);
			throw new DeprecationError("BitmapMaterial", "4.0a", "Please use new TextureMaterial(new BitmapTexture(bitmapData)) instead.");
			this.bitmapData = bitmapData;
		}

		/**
		 * The BitmapData object to use as the texture.
		 */
		public function get bitmapData() : BitmapData
		{
			return _diffuseBMD;
		}

		public function set bitmapData(value : BitmapData) : void
		{
			if (value == _diffuseBMD) return;
			if (_diffuseBMD) BitmapTextureCache.getInstance().freeTexture(BitmapTexture(texture));
			texture = BitmapTextureCache.getInstance().getTexture(value);
			_diffuseBMD = value;
		}

		public function updateBitmapData() : void
		{
			texture.invalidateContent();
		}

		override public function get requiresBlending() : Boolean
		{
			return super.requiresBlending || _alphaBlending;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose() : void
		{
			super.dispose();

			BitmapTextureCache.getInstance().freeTexture(BitmapTexture(texture));
		}
	}
}