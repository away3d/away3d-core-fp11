package away3d.core.base
{
	import away3d.core.base.data.ParticleData;
	
	/**
	 * ...
	 */
	public interface IParticleSubGeometry extends ISubGeometry
	{
		function get particles():Vector.<ParticleData>;
	}
	
}