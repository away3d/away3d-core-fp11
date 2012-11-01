package away3d.animators.states
{
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
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
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			if (animationRegisterCache.needFragmentAnimation)
			{
				var index:int = animationRegisterCache.getRegisterIndex(particleNode, ParticleFlickerByTimeGlobalNode.CYCLE_CONSTANT_REGISTER);;
				var data:Vector.<Number> = _particleFlickerByTimeGlobalState.cycleData;
				animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
				
				if (_particleFlickerByTimeGlobalState.needMultiple)
				{
					index = animationRegisterCache.getRegisterIndex(particleNode, ParticleFlickerByTimeGlobalNode.START_MULTIPLIER_CONSTANT_REGISTER);
					data = _particleFlickerByTimeGlobalState.startMultiplierData;
					animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
					index = animationRegisterCache.getRegisterIndex(particleNode, ParticleFlickerByTimeGlobalNode.DELTA_MULTIPLIER_CONSTANT_REGISTER);
					data = _particleFlickerByTimeGlobalState.deltaMultiplierData;
					animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
				}
				if (_particleFlickerByTimeGlobalState.needOffset)
				{
					index = animationRegisterCache.getRegisterIndex(particleNode, ParticleFlickerByTimeGlobalNode.START_OFFSET_CONSTANT_REGISTER);
					data = _particleFlickerByTimeGlobalState.startOffsetData;
					animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
					index = animationRegisterCache.getRegisterIndex(particleNode, ParticleFlickerByTimeGlobalNode.DELTA_OFFSET_CONSTANT_REGISTER);
					data = _particleFlickerByTimeGlobalState.deltaOffsetData;
					animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
				}
			}
		}
		
	}

}