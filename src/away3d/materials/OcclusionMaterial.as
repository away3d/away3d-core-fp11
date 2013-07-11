package away3d.materials
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	
	use namespace arcane;
	
	/**
	 * OcclusionMaterial is a ColorMaterial for an object to prevents drawing anything that is placed behind it.
	 */
	public class OcclusionMaterial extends ColorMaterial
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
			super(color, alpha);
			this.occlude = occlude;
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
		override arcane function activatePass(index:uint, stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			if (occlude)
				stage3DProxy._context3D.setColorMask(false, false, false, false);
			super.activatePass(index, stage3DProxy, camera);
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function deactivatePass(index:uint, stage3DProxy:Stage3DProxy):void
		{
			super.deactivatePass(index, stage3DProxy);
			stage3DProxy._context3D.setColorMask(true, true, true, true);
		}
	}
}
