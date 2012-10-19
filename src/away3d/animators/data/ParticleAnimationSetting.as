package away3d.animators.data
{
	/**
	 * ...
	 */
	public class ParticleAnimationSetting
	{
		//set true if has an node which will change UV
		public var hasUVNode:Boolean;
		//set true if has an node which will change color
		public var hasColorNode:Boolean;
		//set if the other nodes need to access the velocity
		public var needVelocity:Boolean;
	}

}