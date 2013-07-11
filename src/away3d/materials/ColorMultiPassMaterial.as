package away3d.materials
{
	import away3d.arcane;
	
	use namespace arcane;
	
	/**
	 * ColorMultiPassMaterial is a multi-pass material that uses a flat color as the surface's diffuse reflection value.
	 */
	public class ColorMultiPassMaterial extends MultiPassMaterialBase
	{
		/**
		 * Creates a new ColorMultiPassMaterial object.
		 *
		 * @param color The material's diffuse surface color.
		 */
		public function ColorMultiPassMaterial(color:uint = 0xcccccc)
		{
			super();
			this.color = color;
		}
		
		/**
		 * The diffuse reflectivity color of the surface.
		 */
		public function get color():uint
		{
			return diffuseMethod.diffuseColor;
		}
		
		public function set color(value:uint):void
		{
			diffuseMethod.diffuseColor = value;
		}
	}
}
