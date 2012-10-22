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
		
		public function ParticleAccelerateLocalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
		}
		
		override public function setRenderState(parameter:ParticleRenderParameter) : void
		{
			var index:int = parameter.activatedCompiler.getRegisterIndex(particleNode, ParticleAccelerateLocalNode.ACCELERATELOCAL_STREAM_REGISTER);
			parameter.streamManager.activateVertexBuffer(index, parameter.streamManager.getNodeDataOffset(particleNode), parameter.stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		}
	}

}