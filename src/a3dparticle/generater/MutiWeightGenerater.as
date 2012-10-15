package a3dparticle.generater 
{
	import a3dparticle.particle.ParticleSample;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class MutiWeightGenerater extends GeneraterBase
	{
		private var _vec:Vector.<ParticleSample>;
		
		public function MutiWeightGenerater(samples:Array,weights:Array,count:uint) 
		{
			var total:int = 0;
			var i:uint;
			var j:uint;
			var current:Number;
			var _weights:Array = [];
			_vec = new  Vector.<ParticleSample>();
			
			for (i = 0; i < samples.length; i++)
			{
				total += weights[i];
				_weights.push(total);
			}
			for (j = 0; j < count; j++)
			{
				current = Math.random() * total;
				for (i = 0; i < samples.length; i++)
				{
					if (current < _weights[i]) break;
				}
				_vec.push(samples[i]);
			}
			
		}
		override public function get particlesSamples():Vector.<ParticleSample>
		{
			return _vec;
		}
		
	}

}