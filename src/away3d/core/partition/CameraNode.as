package away3d.core.partition
{
	import away3d.core.traverse.ICollector;
	import away3d.entities.Camera3D;

	/**
	 * CameraNode is a space partitioning leaf node that contains a Camera3D object.
	 */
	public class CameraNode extends EntityNode
	{
		/**
		 * Creates a new CameraNode object.
		 * @param camera The camera to be contained in the node.
		 */
		public function CameraNode(camera:Camera3D)
		{
			super(camera);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function acceptTraverser(traverser:ICollector):void
		{
			// todo: dead end for now, if it has a debug mesh, then sure accept that
		}
	}
}
