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
		
		public function get time():Number
		{
			return _target.time;
		}
		
		public function set time(value:Number):void
		{
			_target.time = value;
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