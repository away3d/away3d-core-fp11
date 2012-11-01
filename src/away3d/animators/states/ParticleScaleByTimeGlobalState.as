package away3d.animators.states
{
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleScaleByTimeGlobalNode;
	import away3d.animators.ParticleAnimator;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleScaleByTimeGlobalState extends ParticleStateBase
	{
		private var _particleScaleByTimeGlobalNode:ParticleScaleByTimeGlobalNode;
		
		public function ParticleScaleByTimeGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleScaleByTimeGlobalNode = particleNode as ParticleScaleByTimeGlobalNode;
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleScaleByTimeGlobalNode.SCALE_CONSTANT_REGISTER);
			var data:Vector.<Number> = _particleScaleByTimeGlobalNode.data;
			animationRegisterCache.setVertexConst(index, data[0], data[1], data[2], data[3]);
		}
		
	}

}