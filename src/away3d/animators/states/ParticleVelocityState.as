package away3d.animators.states
{
	import flash.display3D.Context3DVertexBufferFormat;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleVelocityNode;
	import away3d.animators.ParticleAnimator;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleVelocityState extends ParticleStateBase
	{
		private var _particleVelocityNode:ParticleVelocityNode;
		
		public function ParticleVelocityState(animator:ParticleAnimator, particleVelocityNode:ParticleVelocityNode)
		{
			super(animator, particleVelocityNode);
			
			_particleVelocityNode = particleVelocityNode;
		}
		
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleVelocityNode.VELOCITY_INDEX);
			if (_particleVelocityNode.mode == ParticleVelocityNode.LOCAL) {
				animationSubGeometry.activateVertexBuffer(index, _particleVelocityNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			} else {
				var velocity:Vector3D = _particleVelocityNode.velocity;
				animationRegisterCache.setVertexConst(index, velocity.x, velocity.y, velocity.z);
			}
		}
		
	}

}