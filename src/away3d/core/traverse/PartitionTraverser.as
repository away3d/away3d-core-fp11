package away3d.core.traverse
{
	import away3d.containers.Scene3D;
	import away3d.core.base.IRenderable;
	import away3d.core.partition.NodeBase;
	import away3d.entities.Entity;
	import away3d.errors.AbstractMethodError;
	import away3d.lights.LightBase;

	/**
	 * IPartitionTraverser is a hierarchical visitor pattern that traverses through a Partition3D data structure.
	 *
	 * @see away3d.partition.Partition3D
	 */
	public class PartitionTraverser
	{
		/**
		 * The scene being traversed.
		 */
		public var scene : Scene3D;

		/**
		 * Called when the traversers enters a node. At minimum, it notifies the currently visited Partition3DNode whether or not further recursion is necessary.
		 * @param node The currently entered node.
		 * @return true if further recursion down children is necessary, false if not.
		 */
		public function enterNode(node : NodeBase) : Boolean { return true; }

		/**
		 * Called when the traverser leaves a node. This method is still called when enterNode returned false.
		 * @param node The node being left by the traverser.
		 */
		public function leaveNode(node : NodeBase) : void {}

		/**
		 * Passes a skybox to be processed by the traverser.
		 */
		public function applySkyBox(renderable : IRenderable) : void
		{
			throw new AbstractMethodError();
		}

		/**
		 * Passes an IRenderable object to be processed by the traverser.
		 */
		public function applyRenderable(renderable : IRenderable) : void
		{
			throw new AbstractMethodError();
		}

		/**
		 * Passes a light to be processed by the traverser.
		 */
		public function applyLight(light : LightBase) : void
		{
			throw new AbstractMethodError();
		}

		/**
		 * Registers an entity for use.
		 */
		public function applyEntity(entity : Entity) : void
		{
			throw new AbstractMethodError();
		}
	}
}