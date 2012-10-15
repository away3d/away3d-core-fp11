package a3dparticle.particle
{
	import away3d.core.base.SubGeometry;
	import away3d.materials.MaterialBase;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class ParticleSample
	{
		public var subGem:SubGeometry;
		public var material:MaterialBase;
		
		public function ParticleSample(subGem:SubGeometry,material:MaterialBase)
		{
			this.subGem = subGem;
			this.material = material;
		}
		
	}

}