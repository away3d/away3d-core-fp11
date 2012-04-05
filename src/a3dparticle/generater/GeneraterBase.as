package a3dparticle.generater 
{
	import a3dparticle.particle.ParticleSample;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class GeneraterBase 
	{
		
		
		public function get particlesSamples():Vector.<ParticleSample>
		{
			throw(new Error("this is a abstract function!"));
		}
		
	}

}