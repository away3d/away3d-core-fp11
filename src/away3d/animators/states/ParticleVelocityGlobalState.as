package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleVelocityGlobalNode;
	import away3d.animators.ParticleAnimator;
	import flash.geom.Vector3D;
	/**
	 * ...
	 */
	public class ParticleVelocityGlobalState extends ParticleStateBase
	{
		private var velocityNode:ParticleVelocityGlobalNode;
		public function ParticleVelocityGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			velocityNode = particleNode as ParticleVelocityGlobalNode;
		}
		
		
		override public function setRenderState(parameter:ParticleRenderParameter) : void
		{
			var index:int = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleVelocityGlobalNode.VELOCITY_STREAM_REGISTER);
			var velocity:Vector3D = velocityNode.velocity;
			parameter.animationRegisterCache.setVertexConst(index, velocity.x, velocity.y, velocity.z);
		}
		
	}

}