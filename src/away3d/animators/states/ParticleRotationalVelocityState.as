package away3d.animators.states
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleRotationalVelocityNode;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleRotationalVelocityState extends ParticleStateBase
	{
		private var _particleRotationalVelocityNode:ParticleRotationalVelocityNode;
		
		public function ParticleRotationalVelocityState(animator:ParticleAnimator, particleRotationNode:ParticleRotationalVelocityNode)
		{
			super(animator, particleRotationNode);
			
			_particleRotationalVelocityNode = particleRotationNode;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleRotationalVelocityNode.ROTATIONALVELOCITY_INDEX), _particleRotationalVelocityNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
		}
	}
}