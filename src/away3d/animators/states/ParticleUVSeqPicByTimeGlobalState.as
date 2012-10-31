package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleUVSeqPicByTimeGlobalNode;
	import away3d.animators.ParticleAnimator;
	
	/**
	 * ...
	 */
	public class ParticleUVSeqPicByTimeGlobalState extends ParticleStateBase
	{
		
		private var _particleUVSeqPicByTimeGlobalNode:ParticleUVSeqPicByTimeGlobalNode;

		public function ParticleUVSeqPicByTimeGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleUVSeqPicByTimeGlobalNode = particleNode as ParticleUVSeqPicByTimeGlobalNode;
		}
		
		
		override public function setRenderState(parameter:ParticleRenderParameter):void
		{
			if (parameter.animationRegisterCache.needUVAnimation)
			{
				var index:int = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleUVSeqPicByTimeGlobalNode.UV_CONSTANT_REGISTER_0);
				var data:Vector.<Number> = _particleUVSeqPicByTimeGlobalNode.renderData;
				parameter.animationRegisterCache.setVertexConst(index, data[0], data[1], data[2], data[3]);
				parameter.animationRegisterCache.setVertexConst(index + 1, data[4], data[5]);
			}
		}
	
	}

}