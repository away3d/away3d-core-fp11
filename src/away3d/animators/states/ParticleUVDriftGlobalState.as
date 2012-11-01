package away3d.animators.states
{
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleUVDriftGlobalNode;
	import away3d.animators.ParticleAnimator;
	
	/**
	 * ...
	 */
	public class ParticleUVDriftGlobalState extends ParticleStateBase
	{
		
		private var _particleUVDriftGlobalNode:ParticleUVDriftGlobalNode;

		public function ParticleUVDriftGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleUVDriftGlobalNode = particleNode as ParticleUVDriftGlobalNode;
		}
		
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):void
		{
			if (animationRegisterCache.needUVAnimation)
			{
				var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleUVDriftGlobalNode.UV_CONSTANT_REGISTER);
				var data:Vector.<Number> = _particleUVDriftGlobalNode.renderData;
				animationRegisterCache.setVertexConst(index, data[0], data[1]);
			}
		}
	
	}

}