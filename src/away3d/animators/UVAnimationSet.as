package away3d.animators
{
	import away3d.animators.IAnimationSet;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.core.managers.Stage3DProxy;

	/**
	 * The animation data set used by uv-based animators, containing uv animation state data.
	 * 
	 * @see away3d.animators.UVAnimator
	 * @see away3d.animators.UVAnimationState
	 */
	public class UVAnimationSet extends AnimationSetBase implements IAnimationSet
	{
		/**
		 * @inheritDoc
		 */
		public function getAGALVertexCode(pass:MaterialPassBase, sourceRegisters:Array, targetRegisters:Array):String
		{
			// TODO: Auto-generated method stub
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function activate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public function deactivate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public override function addState(stateName:String, animationState:IAnimationState):void
		{
			super.addState(stateName, animationState);
			
			animationState.addOwner(this, stateName);
		}
	}
}
