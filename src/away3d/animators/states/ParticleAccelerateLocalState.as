package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleAccelerateLocalNode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	/**
	 * ...
	 */
	public class ParticleAccelerateLocalState extends ParticleStateBase
	{
		private var _particleAccelerateLocalNode:ParticleAccelerateLocalNode;
		
		public function ParticleAccelerateLocalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			
			_particleAccelerateLocalNode = particleNode as ParticleAccelerateLocalNode;
		}
		
		override public function setRenderState(parameter:ParticleRenderParameter) : void
		{
			var index:int = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleAccelerateLocalNode.ACCELERATELOCAL_STREAM_REGISTER);
			parameter.animationSubGeometry.activateVertexBuffer(index, _particleAccelerateLocalNode.dataOffset, parameter.stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		}
	}

}