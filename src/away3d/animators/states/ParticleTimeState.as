package away3d.animators.states
{
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleTimeNode;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	/**
	 * ...
	 */
	public class ParticleTimeState extends ParticleStateBase
	{
		private var _particleTimeNode:ParticleTimeNode;
		
		public function ParticleTimeState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode, true);
			_particleTimeNode = particleNode as ParticleTimeNode;
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleTimeNode.TIME_STREAM_REGISTER);
			animationSubGeometry.activateVertexBuffer(index, _particleTimeNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
			
			var particleTime:Number = _time / 1000;
			index = animationRegisterCache.getRegisterIndex(_animationNode, ParticleTimeNode.TIME_CONSTANT_REGISTER);
			animationRegisterCache.setVertexConst(index, particleTime, particleTime, particleTime, 0);
		}
		
	}

}