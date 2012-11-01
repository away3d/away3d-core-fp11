package away3d.animators.states
{
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	/**
	 * ...
	 */
	public class ParticleStateBase extends AnimationStateBase
	{
		protected var _needUpdateTime:Boolean;
		public function ParticleStateBase(animator:ParticleAnimator, particleNode:ParticleNodeBase, needUpdateTime:Boolean = false)
		{
			super(animator, particleNode);
			_needUpdateTime = needUpdateTime;
		}
		
		public function get needUpdateTime():Boolean
		{
			return _needUpdateTime;
		}
		
		public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):void
		{
			
		}
		
	}

}