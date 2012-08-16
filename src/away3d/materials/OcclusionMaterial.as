package away3d.materials {
	import away3d.arcane;

	import flash.display3D.Context3D;

	use namespace arcane;

	/**
	 * OcclusionMaterial is a ColorMaterial for an object, that hides all other objects behind itself.
	 */
	public class OcclusionMaterial extends ColorMaterial
	{
		private var _occlude : Boolean = true;

		/**
		 * Creates a new OcclusionMaterial object.
		 * @param occlude Whether or not to occlude other objects.
		 * @param color The material's diffuse surface color.
		 * @param alpha The material's surface alpha.
		 */
		public function OcclusionMaterial(occlude : Boolean = true, color : uint = 0xcccccc, alpha : Number = 1)
		{
			super(color, alpha);
			this.occlude = occlude;
		}

		/**
		 * Whether or not an object with this material applied hides other objects.
		 */
		public function get occlude() : Boolean
		{
			return _occlude;
		}

		public function set occlude(value : Boolean) : void
		{
			_occlude = value;
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function updateMaterial(context : Context3D) : void
		{
			super.updateMaterial(context);
			if(occlude) {
				context.setColorMask(false, false, false, false);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function cleanMaterial(context : Context3D) : void
		{
			super.cleanMaterial(context);
			context.setColorMask(true, true, true, true);
		}
	}
}