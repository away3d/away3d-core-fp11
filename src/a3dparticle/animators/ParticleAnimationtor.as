package a3dparticle.animators 
{
	import away3d.animators.AnimatorBase;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleAnimationtor extends AnimatorBase
	{
		private var _target:ParticleAnimationState;
		
		public function ParticleAnimationtor(target : ParticleAnimationState) 
		{
			super();
			_target = target;
		}
		
		override protected function updateAnimation(realDT : Number, scaledDT : Number) : void
		{
			_target.time += scaledDT / 1000;
		}
		
		public function play():void
		{
			start();
		}
	}

}