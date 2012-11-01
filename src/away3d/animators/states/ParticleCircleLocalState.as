package away3d.animators.states
{
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleCircleLocalNode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	/**
	 * ...
	 */
	public class ParticleCircleLocalState extends ParticleStateBase
	{
		private var _particleCircleLocalNode:ParticleCircleLocalNode;
		
		public function ParticleCircleLocalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleCircleLocalNode = particleNode as ParticleCircleLocalNode;
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleCircleLocalNode.CIRCLE_STREAM_REGISTER);
			animationSubGeometry.activateVertexBuffer(index, _particleCircleLocalNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			
			index = animationRegisterCache.getRegisterIndex(_animationNode, ParticleCircleLocalNode.EULERS_CONSTANT_REGISTER);
			animationRegisterCache.setVertexConstFromMatrix(index, _particleCircleLocalNode.eulersMatrix);
		}
	}

}