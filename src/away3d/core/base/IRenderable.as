package away3d.core.base
{

	import away3d.bounds.BoundingVolumeBase;
	import away3d.core.managers.Stage3DProxy;
	import away3d.entities.Entity;

	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;

	/**
	 * IRenderable provides an interface for objects that can be rendered in the rendering pipeline.
	 */
	public interface IRenderable extends IMaterialOwner
	{
		/**
		 * The transformation matrix that transforms from model to world space.
		 */
		function get sceneTransform():Matrix3D;

		/**
		 * The inverse scene transform object that transforms from world to model space.
		 */
		function get inverseSceneTransform():Matrix3D;

		/**
		 * The model-view-projection (MVP) matrix used to transform from model to homogeneous projection space.
		 */
		function get modelViewProjection():Matrix3D;

		/**
		 * The model-view-projection (MVP) matrix used to transform from model to homogeneous projection space.
		 * NOT guarded, should never be called outside the render loop.
		 *
		 * @private
		 */
		function getModelViewProjectionUnsafe():Matrix3D;

		/**
		 * The distance of the IRenderable object to the view, used to sort per object.
		 */
		function get zIndex():Number;

		/**
		 * Indicates whether the IRenderable should trigger mouse events, and hence should be rendered for hit testing.
		 */
		function get mouseEnabled():Boolean;

		/**
		 * Retrieves the VertexBuffer3D object that contains vertex positions.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains vertex positions.
		 */
		function getVertexBuffer( stage3DProxy:Stage3DProxy ):VertexBuffer3D;

		/**
		 * Retrieves a custom buffer that can contain any per-vertex data
		 * @param stage3DProxy
		 * @return The VertexBuffer3D object containing the data?
		 */
		function getCustomBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D;

		/**
		 * Retrieves the VertexBuffer3D object that contains texture coordinates.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains texture coordinates.
		 */
		function getUVBuffer( stage3DProxy:Stage3DProxy ):VertexBuffer3D;


		function getSecondaryUVBuffer( stage3DProxy:Stage3DProxy ):VertexBuffer3D;

		/**
		 * Retrieves the VertexBuffer3D object that contains vertex normals.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains vertex normals.
		 */
		function getVertexNormalBuffer( stage3DProxy:Stage3DProxy ):VertexBuffer3D;

		/**
		 * Retrieves the VertexBuffer3D object that contains vertex tangents.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains vertex tangents.
		 */
		function getVertexTangentBuffer( stage3DProxy:Stage3DProxy ):VertexBuffer3D;

		/**
		 * Retrieves the VertexBuffer3D object that contains triangle indices.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains triangle indices.
		 */
		function getIndexBuffer( stage3DProxy:Stage3DProxy ):IndexBuffer3D;

		/**
		 * The amount of triangles that comprise the IRenderable geometry.
		 */
		function get numTriangles():uint;

		/**
		 * The entity that that initially provided the IRenderable to the render pipeline.
		 */
		function get sourceEntity():Entity;

		/**
		 * Indicates whether the renderable can cast shadows
		 */
		function get castsShadows():Boolean;

		/**
		 * Retrieves the object's vertices as a Number array.
		 */
		function get vertexData():Vector.<Number>;

		/**
		 * Retrieves the object's indices as a uint array.
		 */
		function get indexData():Vector.<uint>;

		/**
		 * Retrieves the object's uvs as a Number array.
		 */
		function get UVData():Vector.<Number>;

		function get uvTransform():Matrix;

		function get vertexBufferOffset() : int;
		function get normalBufferOffset() : int;
		function get tangentBufferOffset() : int;
		function get UVBufferOffset() : int;
		function get secondaryUVBufferOffset() : int;

		function get shaderPickingDetails():Boolean;
	}
}