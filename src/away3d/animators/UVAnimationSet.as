package away3d.animators
{
	import away3d.animators.IAnimationSet;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.core.managers.Stage3DProxy;

	/**
	 * @author robbateman
	 */
	public class UVAnimationSet extends AnimationSetBase implements IAnimationSet
	{
		public function getAGALVertexCode(pass:MaterialPassBase, sourceRegisters:Array, targetRegisters:Array):String
		{
			// TODO: Auto-generated method stub
			return null;
		}

		public function activate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):void
		{
		}

		public function deactivate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):void
		{
		}
	}
}
