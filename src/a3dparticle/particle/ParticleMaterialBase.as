package a3dparticle.particle 
{
	import a3dparticle.animators.ParticleAnimation;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class ParticleMaterialBase 
	{
		//use for SimpleParticlePas clean the texture.
		public var numUsedTextures:int = 0;
		
		private var _bothSides:Boolean;
		
		/**
		 * init the particleAnimation state.set the needUV for example.
		 * @param	particleAnimation ParticleAnimation.
		 * @return
		 */
		public function initAnimation(particleAnimation:ParticleAnimation):void
		{
			
		}
		
		public function get bothSides() : Boolean
		{
			return _bothSides;
		}

		public function set bothSides(value : Boolean) : void
		{
			_bothSides = value;
		}
		
		/**
		 * generating the init color of a fragment.
		 * @param	particleAnimation ParticleAnimation.
		 * @return
		 */
		public function getFragmentCode(particleAnimation:ParticleAnimation):String
		{
			throw(new Error("abstract function"));
			return "";
		}
		
		public function render(_particleAnimation:ParticleAnimation, renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			
		}
	}

}