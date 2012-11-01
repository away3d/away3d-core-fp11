package away3d.animators.states
{
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleAccelerateGlobalNode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	import flash.geom.Vector3D;
	/**
	 * ...
	 */
	public class ParticleAccelerateGlobalState extends ParticleStateBase
	{
		private var _particleAccelerateGlobalNode:ParticleAccelerateGlobalNode;
		
		public function ParticleAccelerateGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleAccelerateGlobalNode = particleNode as ParticleAccelerateGlobalNode;
		}
		
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			var index:int = animationRegisterCache.getRegisterIndex(particleNode, ParticleAccelerateGlobalNode.ACCELERATE_CONSTANT_REGISTER);
			var halfAccelerate:Vector3D = _particleAccelerateGlobalNode.halfAcceleration;
			animationRegisterCache.setVertexConst(index, halfAccelerate.x, halfAccelerate.y, halfAccelerate.z);
		}
		
	}

}