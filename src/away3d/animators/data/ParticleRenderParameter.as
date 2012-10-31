package away3d.animators.data
{
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	/**
	 * ...
	 * @author
	 */
	public class ParticleRenderParameter
	{
		public var stage3DProxy : Stage3DProxy;
		public var animationSubGeometry : AnimationSubGeometry;
		public var sharedSetting:ParticleAnimationSetting;
		public var animationRegisterCache:AnimationRegisterCache;
		public var camera:Camera3D;
		public var renderable:IRenderable;
	}

}