package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleTimeNode;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	/**
	 * ...
	 */
	public class ParticleTimeState extends ParticleStateBase
	{
		
		public function ParticleTimeState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode, true);
		}
		
		override public function setRenderState(parameter:ParticleRenderParameter):void
		{
			var index:int = parameter.activatedCompiler.getRegisterIndex(particleNode, ParticleTimeNode.TIME_STREAM_REGISTER);
			parameter.streamManager.activateVertexBuffer(index, parameter.streamManager.getNodeDataOffset(particleNode), parameter.stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
			
			var particleTime:Number = _time / 1000;
			index = parameter.activatedCompiler.getRegisterIndex(particleNode, ParticleTimeNode.TIME_CONSTANT_REGISTER);
			parameter.constantData.setVertexConst(index, particleTime, particleTime, particleTime, 0);
		}
		
	}

}