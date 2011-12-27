package away3d.core.partition
{
	import away3d.cameras.Camera3D;
	import away3d.core.traverse.PartitionTraverser;

	/**
	 * CameraNode is a space partitioning leaf node that contains a Camera3D object.
	 */
	public class CameraNode extends EntityNode
	{
		/**
		 * Creates a new CameraNode object.
		 * @param camera The camera to be contained in the node.
		 */
		public function CameraNode(camera : Camera3D)
		{
			super(camera);
		}

		/**
		 * @inheritDoc
		 */
		override public function acceptTraverser(traverser : PartitionTraverser) : void
		{
			// todo: dead end for now, if it has a debug mesh, then sure accept that
		}

		/**
		 * @inheritDoc
		 */
		override public function isInFrustum(camera : Camera3D) : Boolean
		{
			// TODO: not used
			camera = camera; 
			// todo: maybe test the debug mesh when present
			return true;
		}
	}
}