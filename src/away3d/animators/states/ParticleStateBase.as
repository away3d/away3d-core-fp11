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
		protected var _needUpdateTime:Boolean;
		public function ParticleStateBase(animator:ParticleAnimator, particleNode:ParticleNodeBase, needUpdateTime:Boolean = false)
		{
			super(animator, particleNode);
			this.particleNode = particleNode;
			this._needUpdateTime = needUpdateTime;
		}
		
		public function get needUpdateTime():Boolean
		{
			return _needUpdateTime;
		}
		
		public function setRenderState(parameter:ParticleRenderParameter):void
		{
			
		}
		
	}

}