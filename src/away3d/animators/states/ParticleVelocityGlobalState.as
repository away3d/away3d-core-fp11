package away3d.animators.states
{
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleVelocityGlobalNode;
	import away3d.animators.ParticleAnimator;
	import flash.geom.Vector3D;
	/**
	 * ...
	 */
	public class ParticleVelocityGlobalState extends ParticleStateBase
	{
		private var _particleVelocityGlobalNode:ParticleVelocityGlobalNode;
		
		public function ParticleVelocityGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleVelocityGlobalNode = particleNode as ParticleVelocityGlobalNode;
		}
		
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleVelocityGlobalNode.VELOCITY_STREAM_REGISTER);
			var velocity:Vector3D = _particleVelocityGlobalNode.velocity;
			animationRegisterCache.setVertexConst(index, velocity.x, velocity.y, velocity.z);
		}
		
	}

}