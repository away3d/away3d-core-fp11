package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleScaleByTimeGlobalNode;
	import away3d.animators.ParticleAnimator;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleScaleByTimeGlobalState extends ParticleStateBase
	{
		private var _particleScaleByTimeGlobalState:ParticleScaleByTimeGlobalNode;
		
		public function ParticleScaleByTimeGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleScaleByTimeGlobalState = particleNode as ParticleScaleByTimeGlobalNode;
		}
		
		override public function setRenderState(parameter:ParticleRenderParameter) : void
		{
			var index:int = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleScaleByTimeGlobalNode.SCALE_CONSTANT_REGISTER);
			var data:Vector.<Number> = _particleScaleByTimeGlobalState.data;
			parameter.animationRegisterCache.setVertexConst(index, data[0], data[1], data[2], data[3]);
		}
		
	}

}