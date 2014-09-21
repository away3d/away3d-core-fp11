package away3d.animators
{
	import away3d.core.pool.IRenderable;
	import away3d.core.base.SubGeometryBase;
	import away3d.entities.Mesh;
	import away3d.core.library.IAsset;

	/**
	 * Provides an interface for animator classes that control animation output from a data set subtype of <code>AnimationSetBase</code>.
	 *
	 * @see away3d.animators.IAnimationSet
	 */
	public interface IAnimator extends IAsset
	{
		/**
		 * Returns the animation data set in use by the animator.
		 */
		function get animationSet():IAnimationSet;

        /**
         * Returns animated
         * @param renderable
         * @param sourceSubGeometry
         * @return
         */
		function getRenderableSubGeometry(renderable:IRenderable, sourceSubGeometry:SubGeometryBase):SubGeometryBase;

		/**
		 * Used by the mesh object to which the animator is applied, registers the owner for internal use.
		 *
		 * @private
		 */
		function addOwner(mesh:Mesh):void
		
		/**
		 * Used by the mesh object from which the animator is removed, unregisters the owner for internal use.
		 *
		 * @private
		 */
		function removeOwner(mesh:Mesh):void

		/**
		 * Returns a shallow clone (re-using the same IAnimationSet) of this IAnimator.
		 */
		function clone():IAnimator;
	}
}
