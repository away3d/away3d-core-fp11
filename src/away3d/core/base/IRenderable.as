package away3d.core.base
{
	import away3d.entities.Entity;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;

	/**
	 * IRenderable provides an interface for objects that can be rendered in the rendering pipeline.
	 */
	public interface IRenderable extends IMaterialOwner, ISubGeometry
	{
		/**
		 * The transformation matrix that transforms from model to world space.
		 */
		function get sceneTransform() : Matrix3D;

		/**
		 * The inverse scene transform object that transforms from world to model space.
		 */
		function get inverseSceneTransform() : Matrix3D;

		/**
		 * The model-view-projection (MVP) matrix used to transform from model to homogeneous projection space.
		 */
		function get modelViewProjection() : Matrix3D;

		/**
		 * The model-view-projection (MVP) matrix used to transform from model to homogeneous projection space.
		 * NOT guarded, should never be called outside the render loop.
		 *
		 * @private
		 */
		function getModelViewProjectionUnsafe() : Matrix3D;

		/**
		 * The distance of the IRenderable object to the view, used to sort per object.
		 */
		function get zIndex() : Number;

		/**
		 * Indicates whether the IRenderable should trigger mouse events, and hence should be rendered for hit testing.
		 */
		function get mouseEnabled() : Boolean;

		/**
		 * The entity that that initially provided the IRenderable to the render pipeline.
		 */
		function get sourceEntity() : Entity;

		/**
		 * Indicates whether the renderable can cast shadows
		 */
		function get castsShadows() : Boolean;

		function get uvTransform() : Matrix;

		function get shaderPickingDetails() : Boolean;
	}
}