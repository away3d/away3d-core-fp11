package away3d.animators.states
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleCircleNode;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleCircleState extends ParticleStateBase
	{
		private var _particleCircleNode:ParticleCircleNode;
		
		public function ParticleCircleState(animator:ParticleAnimator, particleCircleNode:ParticleCircleNode)
		{
			super(animator, particleCircleNode);
			
			_particleCircleNode = particleCircleNode;
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleCircleNode.CIRCLE_INDEX);
			animationSubGeometry.activateVertexBuffer(index, _particleCircleNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			
			index = animationRegisterCache.getRegisterIndex(_animationNode, ParticleCircleNode.EULERS_INDEX);
			animationRegisterCache.setVertexConstFromMatrix(index, _particleCircleNode.eulersMatrix);
		}
	}

}