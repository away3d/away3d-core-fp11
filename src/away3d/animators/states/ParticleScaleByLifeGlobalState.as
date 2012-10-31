package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleScaleByLifeGlobalNode;
	import away3d.animators.ParticleAnimator;
	/**
	 * ...
	 */
	public class ParticleScaleByLifeGlobalState extends ParticleStateBase
	{
		private var _particleScaleByLifeGlobalNode:ParticleScaleByLifeGlobalNode;
		
		public function ParticleScaleByLifeGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleScaleByLifeGlobalNode = particleNode as ParticleScaleByLifeGlobalNode;
		}
		
		override public function setRenderState(parameter:ParticleRenderParameter) : void
		{
			var index:int = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleScaleByLifeGlobalNode.SCALE_CONSTANT_REGISTER);
			parameter.animationRegisterCache.setVertexConst(index, _particleScaleByLifeGlobalNode.startScale, _particleScaleByLifeGlobalNode.delta);
		}
		
	}

}