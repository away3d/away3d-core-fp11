package away3d.core.partition
{
	import away3d.arcane;
	
	use namespace arcane;
	
	public class QuadTree extends Partition3D
	{
		public function QuadTree(maxDepth:int, size:Number, height:Number = 1000000)
		{
			super(new QuadTreeNode(maxDepth, size, height));
		}
	}
}
