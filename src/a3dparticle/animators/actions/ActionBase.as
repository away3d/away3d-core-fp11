package a3dparticle.animators.actions
{
	import a3dparticle.animators.AnimationRegistersManager;
	import a3dparticle.animators.ParticleAnimation;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.compilation.ShaderRegisterCache;

	/**
	 * ...
	 * @author ...
	 */
	public class ActionBase
	{
		public var _animation:ParticleAnimation;
		
		public var priority:int=1;
		
		public function ActionBase()
		{
			
		}
		
		public function reset(value:ParticleAnimation):void
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
			return _animation.animationRegistersManager.shaderRegisterCache;
		}
		
		protected function get animationRegistersManager():AnimationRegistersManager
		{
			return _animation.animationRegistersManager;
		}
		
		public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			return "";
		}
		
		public function getAGALFragmentCode(pass : MaterialPassBase) : String
		{
			return "";
		}
		
		public function getAGALUVCode(pass:MaterialPassBase):String
		{
			return "";
		}
		
		public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			
		}
		
		protected function saveRegisterIndex(registerName:String, index:int):void
		{
			animationRegistersManager.setRegisterIndex(this, registerName, index);
		}
		
		protected function getRegisterIndex(registerName:String):int
		{
			return animationRegistersManager.getRegisterIndex(this, registerName);
		}
		
	}

}