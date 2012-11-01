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
		private var _particleFlickerByTimeGlobalNode:ParticleFlickerByTimeGlobalNode;
		
		public function ParticleFlickerByTimeGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleFlickerByTimeGlobalNode = particleNode as ParticleFlickerByTimeGlobalNode;
			
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			if (animationRegisterCache.needFragmentAnimation)
			{
				var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleFlickerByTimeGlobalNode.CYCLE_CONSTANT_REGISTER);;
				var data:Vector.<Number> = _particleFlickerByTimeGlobalNode.cycleData;
				animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
				
				if (_particleFlickerByTimeGlobalNode.needMultiple)
				{
					index = animationRegisterCache.getRegisterIndex(_animationNode, ParticleFlickerByTimeGlobalNode.START_MULTIPLIER_CONSTANT_REGISTER);
					data = _particleFlickerByTimeGlobalNode.startMultiplierData;
					animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
					index = animationRegisterCache.getRegisterIndex(_animationNode, ParticleFlickerByTimeGlobalNode.DELTA_MULTIPLIER_CONSTANT_REGISTER);
					data = _particleFlickerByTimeGlobalNode.deltaMultiplierData;
					animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
				}
				if (_particleFlickerByTimeGlobalNode.needOffset)
				{
					index = animationRegisterCache.getRegisterIndex(_animationNode, ParticleFlickerByTimeGlobalNode.START_OFFSET_CONSTANT_REGISTER);
					data = _particleFlickerByTimeGlobalNode.startOffsetData;
					animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
					index = animationRegisterCache.getRegisterIndex(_animationNode, ParticleFlickerByTimeGlobalNode.DELTA_OFFSET_CONSTANT_REGISTER);
					data = _particleFlickerByTimeGlobalNode.deltaOffsetData;
					animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
				}
			}
		}
		
	}

}