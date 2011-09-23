package away3d.materials {
	import away3d.arcane;
	import away3d.materials.passes.SegmentPass;

	/**
	 * @author jerome BIREMBAUT  Twitter: Seraf_NSS
	 */
	
	use namespace arcane;

	/**
	 * SegmentMaterial is a material exclusively used to render wireframe object
	 *
	 * @see away3d.entities.Lines
	 */
	public class SegmentMaterial extends MaterialBase
	{
		private var _screenPass : SegmentPass;

		/**
		 * Creates a new WireframeMaterial object.
		 */
		public function SegmentMaterial(thickness : Number = 1.25){
			super();

			bothSides = true;
			addPass(_screenPass = new SegmentPass(thickness));
			_screenPass.material = this;
		}
	}
}
