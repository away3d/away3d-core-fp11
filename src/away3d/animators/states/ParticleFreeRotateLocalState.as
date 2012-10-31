package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleFreeRotateLocalNode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;

	/**
	 * ...
	 */
	public class ParticleFreeRotateLocalState extends ParticleStateBase
	{
		private var _particleFreeRotateLocalNode:ParticleFreeRotateLocalNode;
		
		public function ParticleFreeRotateLocalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleFreeRotateLocalNode = particleNode as ParticleFreeRotateLocalNode;
		}
			
		override public function setRenderState(parameter:ParticleRenderParameter) : void
		{
			var index:int = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleFreeRotateLocalNode.ROTATE_STREAM_REGISTER);
			parameter.animationSubGeometry.activateVertexBuffer(index, _particleFreeRotateLocalNode.dataOffset, parameter.stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
		}
		
	}

}