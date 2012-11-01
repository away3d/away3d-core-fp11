package away3d.animators.states
{
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleUVSeqPicByTimeGlobalNode;
	import away3d.animators.ParticleAnimator;
	
	/**
	 * ...
	 */
	public class ParticleUVSeqPicByTimeGlobalState extends ParticleStateBase
	{
		
		private var _particleUVSeqPicByTimeGlobalNode:ParticleUVSeqPicByTimeGlobalNode;

		public function ParticleUVSeqPicByTimeGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleUVSeqPicByTimeGlobalNode = particleNode as ParticleUVSeqPicByTimeGlobalNode;
		}
		
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):void
		{
			if (animationRegisterCache.needUVAnimation)
			{
				var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleUVSeqPicByTimeGlobalNode.UV_CONSTANT_REGISTER_0);
				var data:Vector.<Number> = _particleUVSeqPicByTimeGlobalNode.renderData;
				animationRegisterCache.setVertexConst(index, data[0], data[1], data[2], data[3]);
				animationRegisterCache.setVertexConst(index + 1, data[4], data[5]);
			}
		}
	
	}

}