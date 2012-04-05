package a3dparticle.generater 
{
	import a3dparticle.particle.ParticleSample;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class SingleGenerater extends GeneraterBase
	{
		private var _vec:Vector.<ParticleSample>;
		
		public function SingleGenerater(particleSample:ParticleSample,count:uint)
		{
			_vec = new Vector.<ParticleSample>;
			for (var i:uint = 0; i < count; i++)
			{
				_vec.push(particleSample);
			}
		}
		
		override public function get particlesSamples():Vector.<ParticleSample>
		{
			return _vec;
		}
		
	}

}