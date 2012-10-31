package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleBezierCurvelByLifelocalNode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	/**
	 * ...
	 */
	public class ParticleBezierCurvelByLifelocalState extends ParticleStateBase
	{
		
		public function ParticleBezierCurvelByLifelocalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
		}
		
		override public function setRenderState(parameter:ParticleRenderParameter) : void
		{
			var index:int = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleBezierCurvelByLifelocalNode.BEZIER_STREAM_REGISTER);
			parameter.streamManager.activateVertexBuffer(index, parameter.streamManager.getNodeDataOffset(particleNode), parameter.stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			parameter.streamManager.activateVertexBuffer(index + 1, parameter.streamManager.getNodeDataOffset(particleNode) + 3, parameter.stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		}
	}

}