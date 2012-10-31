package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleFlickerByTimeGlobalNode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	/**
	 * ...
	 */
	public class ParticleFlickerByTimeGlobalState extends ParticleStateBase
	{
		private var _particleFlickerByTimeGlobalState:ParticleFlickerByTimeGlobalNode;
		
		public function ParticleFlickerByTimeGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleFlickerByTimeGlobalState = particleNode as ParticleFlickerByTimeGlobalNode;
			
		}
		
		override public function setRenderState(parameter:ParticleRenderParameter) : void
		{
			if (parameter.animationRegisterCache.needFragmentAnimation)
			{
				var index:int = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleFlickerByTimeGlobalNode.CYCLE_CONSTANT_REGISTER);;
				var data:Vector.<Number> = _particleFlickerByTimeGlobalState.cycleData;
				parameter.animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
				
				if (_particleFlickerByTimeGlobalState.needMultiple)
				{
					index = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleFlickerByTimeGlobalNode.START_MULTIPLIER_CONSTANT_REGISTER);
					data = _particleFlickerByTimeGlobalState.startMultiplierData;
					parameter.animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
					index = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleFlickerByTimeGlobalNode.DELTA_MULTIPLIER_CONSTANT_REGISTER);
					data = _particleFlickerByTimeGlobalState.deltaMultiplierData;
					parameter.animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
				}
				if (_particleFlickerByTimeGlobalState.needOffset)
				{
					index = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleFlickerByTimeGlobalNode.START_OFFSET_CONSTANT_REGISTER);
					data = _particleFlickerByTimeGlobalState.startOffsetData;
					parameter.animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
					index = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleFlickerByTimeGlobalNode.DELTA_OFFSET_CONSTANT_REGISTER);
					data = _particleFlickerByTimeGlobalState.deltaOffsetData;
					parameter.animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
				}
			}
		}
		
	}

}