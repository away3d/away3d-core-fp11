package away3d.animators.data
{
	import away3d.arcane;
	import away3d.core.base.IRenderable;
	import away3d.entities.Mesh;
	import away3d.errors.AbstractMethodError;
	import away3d.materials.passes.MaterialPassBase;

	import flash.display3D.Context3D;

	/**
	 * AnimationStateBase provides an abstract base class for all animation states. This defines the actual state of the
	 * animation data (such as the matrices to be used for skinning) for an entire Mesh. The AnimationController is the
	 * class that inputs the values.
	 */
	public class AnimationStateBase
	{
		protected var _animation : AnimationBase;
		protected var _stateInvalid : Boolean;

		protected var _owners : Vector.<Mesh>;

		/**
		 * Creates a new AnimationStateBase object
		 * @param animation The animation on which this AnimationStateBase object is based.
		 */
		public function AnimationStateBase(animation : AnimationBase)
		{
			_owners = new Vector.<Mesh>();
			_animation = animation;
		}

		/**
		 * Invalidates the state, so it needs to be updated next time it is requested.
		 */
		public function invalidateState() : void
		{
			_stateInvalid = true;
		}

		/**
		 * The animation on which this AnimationStateBase object is based.
		 */
		public function get animation() : AnimationBase
		{
			return _animation;
		}

		/**
		 * Sets the GPU render state required by the animation that is dependent of the rendered object.
		 * @param context The context which is currently performing the rendering.
		 * @param pass The material pass which is currently used to render the geometry.
		 * @param renderable The object currently being rendered.
		 */
		public function setRenderState(context : Context3D, contextIndex : uint, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			throw new AbstractMethodError();
		}

		/**
		 * Clones the current object.
		 * @return An exact duplicate of the current object.
		 */
		public function clone() : AnimationStateBase
		{
			throw new AbstractMethodError();
		}

		arcane function addOwner(mesh : Mesh) : void
		{
			_owners.push(mesh);
		}

		arcane function removeOwner(mesh : Mesh) : void
		{
			_owners.splice(_owners.indexOf(mesh), 1);
		}
	}
}