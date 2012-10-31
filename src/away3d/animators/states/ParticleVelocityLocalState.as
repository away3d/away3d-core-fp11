package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleVelocityLocalNode;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	/**
	 * ...
	 */
	public class ParticleVelocityLocalState extends ParticleStateBase
	{
		private var _particleVelocityGlobalNode:ParticleVelocityLocalNode;
		
		public function ParticleVelocityLocalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleVelocityGlobalNode = particleNode as ParticleVelocityLocalNode;
		}
		
		override public function setRenderState(parameter:ParticleRenderParameter) : void
		{
			var index:int = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleVelocityLocalNode.VELOCITY_STREAM_REGISTER);
			parameter.animationSubGeometry.activateVertexBuffer(index, _particleVelocityGlobalNode.dataOffset, parameter.stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		}
	}
}