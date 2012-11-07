package away3d.animators.data
{
	/**
	 * @author robbateman
	 */
	public class ParticlePropertiesMode
	{
		/**
		 * Mode that defines the particle node as acting on global properties (ie. the properties of the node).
		 */
		public static const GLOBAL:uint = 1;
		
		/**
		 * Mode that defines the particle node as acting on local properties (ie. the properties of the particles).
		 */
		public static const LOCAL:uint = 0;
		
		/**
		 * Mode that defines the particle node as acting on local properties (ie. the properties of the particles).
		 */
		public static const LOCAL_DYNAMIC:uint = 2;
	}
}
