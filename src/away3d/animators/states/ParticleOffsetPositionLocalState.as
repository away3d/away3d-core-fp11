package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleOffsetPositionLocalNode;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleOffsetPositionLocalState extends ParticleStateBase
	{
		private var _particleOffsetPositionLocalNode:ParticleOffsetPositionLocalNode;
		
		public function ParticleOffsetPositionLocalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleOffsetPositionLocalNode = particleNode as ParticleOffsetPositionLocalNode;
		}
		
		
		override public function setRenderState(parameter:ParticleRenderParameter) : void
		{
			var index:int = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleOffsetPositionLocalNode.OFFSET_STREAM_REGISTER);
			parameter.animationSubGeometry.activateVertexBuffer(index, _particleOffsetPositionLocalNode.dataOffset, parameter.stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		}
		
	}

}