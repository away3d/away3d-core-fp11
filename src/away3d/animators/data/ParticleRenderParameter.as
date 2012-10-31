package away3d.animators.data
{
	import away3d.animators.utils.ParticleAnimationCompiler;
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
		public var streamManager : ParticleStreamManager;
		public var sharedSetting:ParticleAnimationSetting;
		public var activatedCompiler:ParticleAnimationCompiler;
		public var camera:Camera3D;
		public var constantData:ParticleConstantManager;
		public var renderable:IRenderable;
	}

}