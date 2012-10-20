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
		
		public function ParticleFreeRotateLocalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
		}
			
		override public function setRenderState(parameter:ParticleRenderParameter) : void
		{
			var index:int = parameter.activatedCompiler.getRegisterIndex(particleNode, ParticleFreeRotateLocalNode.ROTATE_STREAM_REGISTER);
			parameter.streamManager.activateVertexBuffer(index, parameter.streamManager.getNodeDataOffset(particleNode), parameter.stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
		}
		
	}

}