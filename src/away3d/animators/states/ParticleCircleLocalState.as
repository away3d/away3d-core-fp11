package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleCircleLocalNode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	/**
	 * ...
	 */
	public class ParticleCircleLocalState extends ParticleStateBase
	{
		private var _particleCircleLocalState:ParticleCircleLocalNode;
		
		public function ParticleCircleLocalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleCircleLocalState = particleNode as ParticleCircleLocalNode;
		}
		
		override public function setRenderState(parameter:ParticleRenderParameter) : void
		{
			var index:int = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleCircleLocalNode.CIRCLE_STREAM_REGISTER);
			parameter.animationSubGeometry.activateVertexBuffer(index, _particleCircleLocalState.dataOffset, parameter.stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			
			index = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleCircleLocalNode.EULERS_CONSTANT_REGISTER);
			parameter.animationRegisterCache.setVertexConstFromMatrix(index, _particleCircleLocalState.eulersMatrix);
		}
	}

}