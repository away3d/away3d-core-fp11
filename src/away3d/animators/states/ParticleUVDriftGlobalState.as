package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleUVDriftGlobalNode;
	import away3d.animators.ParticleAnimator;
	
	/**
	 * ...
	 */
	public class ParticleUVDriftGlobalState extends ParticleStateBase
	{
		
		private var _particleUVDriftGlobalNode:ParticleUVDriftGlobalNode;

		public function ParticleUVDriftGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleUVDriftGlobalNode = particleNode as ParticleUVDriftGlobalNode;
		}
		
		
		override public function setRenderState(parameter:ParticleRenderParameter):void
		{
			if (parameter.animationRegisterCache.needUVAnimation)
			{
				var index:int = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleUVDriftGlobalNode.UV_CONSTANT_REGISTER);
				var data:Vector.<Number> = _particleUVDriftGlobalNode.renderData;
				parameter.animationRegisterCache.setVertexConst(index, data[0], data[1]);
			}
		}
	
	}

}