package away3d.animators.states
{
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleScaleByLifeGlobalNode;
	import away3d.animators.ParticleAnimator;
	/**
	 * ...
	 */
	public class ParticleScaleByLifeGlobalState extends ParticleStateBase
	{
		private var _particleScaleByLifeGlobalNode:ParticleScaleByLifeGlobalNode;
		
		public function ParticleScaleByLifeGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleScaleByLifeGlobalNode = particleNode as ParticleScaleByLifeGlobalNode;
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			var index:int = animationRegisterCache.getRegisterIndex(particleNode, ParticleScaleByLifeGlobalNode.SCALE_CONSTANT_REGISTER);
			animationRegisterCache.setVertexConst(index, _particleScaleByLifeGlobalNode.startScale, _particleScaleByLifeGlobalNode.delta);
		}
		
	}

}