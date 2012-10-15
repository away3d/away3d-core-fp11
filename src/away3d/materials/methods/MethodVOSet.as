package away3d.materials.methods
{
	import away3d.arcane;

	public class MethodVOSet
	{
		use namespace arcane;

		public var method : EffectMethodBase;
		public var data : MethodVO;

		public function MethodVOSet(method : EffectMethodBase)
		{
			this.method = method;
			data = method.createMethodVO();
		}
	}
}
