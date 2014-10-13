package away3d.materials
{
	import away3d.arcane;
    import away3d.core.pool.MaterialPassData;
    import away3d.entities.Camera3D;
	import away3d.managers.Stage3DProxy;
	
	use namespace arcane;
	
	/**
	 * OcclusionMaterial is a ColorMaterial for an object to prevents drawing anything that is placed behind it.
	 */
	public class OcclusionMaterial extends TriangleMethodMaterial
	{
		private var _occlude:Boolean = true;
		
		/**
		 * Creates a new OcclusionMaterial object.
		 * @param occlude Whether or not to occlude other objects.
		 * @param color The material's diffuse surface color.
		 * @param alpha The material's surface alpha.
		 */
		public function OcclusionMaterial(occlude:Boolean = true, color:uint = 0xcccccc, alpha:Number = 1)
		{
			super(null, false, false, false);
            this.occlude = occlude;
            this.color = color;
            this.alpha = alpha;
		}
		
		/**
		 * Whether or not an object with this material applied hides other objects.
		 */
		public function get occlude():Boolean
		{
			return _occlude;
		}
		
		public function set occlude(value:Boolean):void
		{
			_occlude = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function activatePass(pass:MaterialPassData, stage:Stage3DProxy, camera:Camera3D):void
		{
			if (occlude)
				stage._context3D.setColorMask(false, false, false, false);
			super.activatePass(pass, stage, camera);
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function deactivatePass(pass:MaterialPassData, stage:Stage3DProxy):void
		{
			super.deactivatePass(pass,stage);
			stage._context3D.setColorMask(true, true, true, true);
		}
	}
}
