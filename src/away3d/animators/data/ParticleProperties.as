package away3d.animators.data
{
	
	/**
	 * Dynamic class for holding the local properties of a particle, used for processing the static properties
	 * of particles in the particle animation set before beginning upload to the GPU.
	 */
	dynamic public class ParticleProperties
	{
		/**
		 * The index of the current particle being set.
		 */
		public var index:uint;
		
		/**
		 * The total number of particles being processed by the particle animation set.
		 */
		public var total:uint;
		
		/**
		 * The start time of the particle.
		 */
		public var startTime:Number;
		
		/**
		 * The duration of the particle, an optional value used when the particle aniamtion set settings for <code>useDuration</code> are enabled in the constructor.
		 *
		 * @see away3d.animators.ParticleAnimationSet
		 */
		public var duration:Number;
		
		/**
		 * The delay between cycles of the particle, an optional value used when the particle aniamtion set settings for <code>useLooping</code> and  <code>useDelay</code> are enabled in the constructor.
		 *
		 * @see away3d.animators.ParticleAnimationSet
		 */
		public var delay:Number;
		
		public function ParticleProperties()
		{
		
		}
	}

}
