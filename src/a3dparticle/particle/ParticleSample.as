package a3dparticle.particle 
{
	import away3d.core.base.SubGeometry;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class ParticleSample 
	{
		public var subGem:SubGeometry;
		public var material:ParticleMaterialBase;
		
		public function ParticleSample(subGem:SubGeometry,material:ParticleMaterialBase) 
		{
			this.subGem = subGem;
			this.material = material;
		}
		
	}

}