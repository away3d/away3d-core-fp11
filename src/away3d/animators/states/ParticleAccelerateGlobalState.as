package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleAccelerateGlobalNode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	import flash.geom.Vector3D;
	/**
	 * ...
	 */
	public class ParticleAccelerateGlobalState extends ParticleStateBase
	{
		private var _particleAccelerateGlobalNode:ParticleAccelerateGlobalNode;
		
		public function ParticleAccelerateGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleAccelerateGlobalNode = particleNode as ParticleAccelerateGlobalNode;
		}
		
		
		override public function setRenderState(parameter:ParticleRenderParameter) : void
		{
			var index:int = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleAccelerateGlobalNode.ACCELERATE_CONSTANT_REGISTER);
			var halfAccelerate:Vector3D = _particleAccelerateGlobalNode.halfAcceleration;
			parameter.animationRegisterCache.setVertexConst(index, halfAccelerate.x, halfAccelerate.y, halfAccelerate.z);
		}
		
	}

}