package a3dparticle.animators.actions 
{
	import a3dparticle.animators.ParticleAnimation;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterCache;

	/**
	 * ...
	 * @author ...
	 */
	public class ActionBase 
	{
		public var _animation:ParticleAnimation
		
		public var priority:int=1;
		
		public function ActionBase() 
		{
			
		}
		
		public function set animation(value:ParticleAnimation):void
		{
			if (!_animation)
			{
				_animation = value;
			}
			else
			{
				if(_animation!=value)
					throw(new Error("can't change animation"));
			}
		}
		
		protected function get shaderRegisterCache():ShaderRegisterCache
		{
			return _animation.shaderRegisterCache;
		}
		
		public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			return "";
		}
		
		public function getAGALFragmentCode(pass : MaterialPassBase) : String
		{
			return "";
		}
		
		public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			
		}
		
	}

}