package away3d.animators.data
{
	/**
	 * Options for setting the properties mode of a particle animation node.
	 */
	public class ParticlePropertiesMode
	{
		/**
		 * Mode that defines the particle node as acting on global properties (ie. the properties set in the node constructor or the corresponding animation state).
		 */
		public static const GLOBAL:uint = 0;
		
		/**
		 * Mode that defines the particle node as acting on local static properties (ie. the properties of particles set in the initialising function on the animation set).
		 */
		public static const LOCAL_STATIC:uint = 1;
		
		/**
		 * Mode that defines the particle node as acting on local dynamic properties (ie. the properties of the particles set in the corresponding animation state).
		 */
		public static const LOCAL_DYNAMIC:uint = 2;
	}
}