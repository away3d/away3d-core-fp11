package away3d.animators.states
{
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleColorByLifeGlobalNode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleColorByLifeGlobalState extends ParticleStateBase
	{
		private var _particleColorByLifeGlobalState:ParticleColorByLifeGlobalNode;
		
		public function ParticleColorByLifeGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleColorByLifeGlobalState = particleNode as ParticleColorByLifeGlobalNode;
			
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			if (animationRegisterCache.hasColorNode && animationRegisterCache.needFragmentAnimation)
			{
				var index:int;
				var data:Vector.<Number>;
				if (_particleColorByLifeGlobalState.needMultiple)
				{
					index = animationRegisterCache.getRegisterIndex(particleNode, ParticleColorByLifeGlobalNode.START_MULTIPLIER_CONSTANT_REGISTER);
					data = _particleColorByLifeGlobalState.startMultiplierData;
					animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
					index = animationRegisterCache.getRegisterIndex(particleNode, ParticleColorByLifeGlobalNode.DELTA_MULTIPLIER_CONSTANT_REGISTER);
					data = _particleColorByLifeGlobalState.deltaMultiplierData;
					animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
				}
				if (_particleColorByLifeGlobalState.needOffset)
				{
					index = animationRegisterCache.getRegisterIndex(particleNode, ParticleColorByLifeGlobalNode.START_OFFSET_CONSTANT_REGISTER);
					data = _particleColorByLifeGlobalState.startOffsetData;
					animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
					index = animationRegisterCache.getRegisterIndex(particleNode, ParticleColorByLifeGlobalNode.DELTA_OFFSET_CONSTANT_REGISTER);
					data = _particleColorByLifeGlobalState.deltaOffsetData;
					animationRegisterCache.setFragmentConst(index, data[0], data[1], data[2], data[3]);
				}
			}
		}
		
	}

}