package away3d.materials {
	import away3d.arcane;
	import away3d.materials.passes.WireframePass;

	/**
	 * @author jerome BIREMBAUT  Twitter: Seraf_NSS
	 */
	
	use namespace arcane;

	/**
	 * WireframeMaterial is a material exclusively used to render wireframe object
	 *
	 * @see away3d.entities.Lines
	 */
	public class WireframeMaterial extends MaterialBase
	{
		//private var _screenPass : DefaultScreenPass;
		private var _screenPass1 : WireframePass;

		/**
		 * Creates a new WireframeMaterial object.
		  * @param color The material's diffuse surface color.
		 * @param alpha The material's surface alpha.
		 */
		public function WireframeMaterial(w:int=1000,h:int=700){
			super();
			/*super(color,alpha);
			_wirePass = new WireFramePass();
			
			addPass(_wirePass);	
			Logger.log("1");
			_wirePass.material = this;
			Logger.log("2");*/
			this.bothSides=true;
			
			
			addPass(_screenPass1 = new WireframePass(w,h));
			_screenPass1.material = this;
			//addPass(_screenPass = new DefaultScreenPass());
			//_screenPass.material = this;
			
			
			//this.color = color;
		}
		/*	
		public function get color() : uint
		{
			return _screenPass.diffuseMethod.diffuseColor;
		}

		public function set color(value : uint) : void
		{
			_screenPass.diffuseMethod.diffuseColor = value;
		}
		*/

		
	}
}
