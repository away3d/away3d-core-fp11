package away3d.materials
{
	import away3d.arcane;

	use namespace arcane;

	/**
	 * BitmapMaterial is a material that uses a flat colour as the surfaces diffuse.
	 */
	public class ColorMaterial extends DefaultMaterialBase
	{
		private var _diffuseAlpha : Number = 1;

		/**
		 * Creates a new ColorMaterial object.
		 * @param color The material's diffuse surface color.
		 * @param alpha The material's surface alpha.
		 */
		public function ColorMaterial(color : uint, alpha : Number = 1)
		{
			super();
			this.color = color;
			this.alpha = alpha;
		}

		/**
		 * The alpha of the surface.
		 */
		public function get alpha() : Number
		{
			return _screenPass.diffuseMethod.diffuseAlpha;
		}

		public function set alpha(value : Number) : void
		{
			if (value > 1) value = 1;
			else if (value < 0) value = 0;
			_screenPass.diffuseMethod.diffuseAlpha = _diffuseAlpha = value;
		}

		/**
		 * The diffuse color of the surface.
		 */
		public function get color() : uint
		{
			return _screenPass.diffuseMethod.diffuseColor;
		}

		public function set color(value : uint) : void
		{
			_screenPass.diffuseMethod.diffuseColor = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function get requiresBlending() : Boolean
		{
			return super.requiresBlending || _diffuseAlpha < 1;
		}
	}
}