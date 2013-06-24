package away3d.core.partition
{
	import away3d.arcane;
	
	use namespace arcane;
	
	public class Octree extends Partition3D
	{
		public function Octree(maxDepth:int, size:Number)
		{
			super(new OctreeNode(maxDepth, size));
		}
	}
}
