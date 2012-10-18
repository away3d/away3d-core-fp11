package away3d.core.base
{
	import away3d.core.base.data.ParticleData;
	/**
	 * ...
	 */
	public class CompactParticleSubGeometry extends CompactSubGeometry implements IParticleSubGeometry
	{
		protected var _particles:Vector.<ParticleData>;
		
		
		public function set particles(value:Vector.<ParticleData>):void
		{
			_particles = value;
		}
		
		public function get particles():Vector.<ParticleData>
		{
			return _particles;
		}
		
		public function CompactParticleSubGeometry()
		{
			
		}
		
	}

}