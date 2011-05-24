package away3d.core.partition
{
	import away3d.arcane;
	import away3d.core.traverse.PartitionTraverser;
	import away3d.entities.Entity;

	use namespace arcane;

	public class Octree extends Partition3D
	{
		public function Octree(maxDepth : int, size : Number)
		{
			super(new OctreeNode(maxDepth, size));
		}
	}
}