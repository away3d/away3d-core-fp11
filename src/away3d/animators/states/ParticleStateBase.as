package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	/**
	 * ...
	 */
	public class ParticleStateBase extends AnimationStateBase
	{
		protected var particleNode:ParticleNodeBase;
		public function ParticleStateBase(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			this.particleNode = particleNode;
		}
		
		public function setRenderState(parameter:ParticleRenderParameter):void
		{
			
		}
		
	}

}