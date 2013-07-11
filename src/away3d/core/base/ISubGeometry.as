package away3d.core.base
{
	import away3d.core.managers.Stage3DProxy;
	
	import flash.display3D.IndexBuffer3D;
	import flash.geom.Matrix3D;
	
	public interface ISubGeometry
	{
		/**
		 * The total amount of vertices in the SubGeometry.
		 */
		function get numVertices():uint;
		
		/**
		 * The amount of triangles that comprise the IRenderable geometry.
		 */
		function get numTriangles():uint;
		
		/**
		 * The distance between two consecutive vertex, normal or tangent elements
		 * This always applies to vertices, normals and tangents.
		 */
		function get vertexStride():uint;
		
		/**
		 * The distance between two consecutive normal elements
		 * This always applies to vertices, normals and tangents.
		 */
		function get vertexNormalStride():uint;
		
		/**
		 * The distance between two consecutive tangent elements
		 * This always applies to vertices, normals and tangents.
		 */
		function get vertexTangentStride():uint;
		
		/**
		 * The distance between two consecutive UV elements
		 */
		function get UVStride():uint;
		
		/**
		 * The distance between two secondary UV elements
		 */
		function get secondaryUVStride():uint;
		
		/**
		 * Assigns the attribute stream for vertex positions.
		 * @param index The attribute stream index for the vertex shader
		 * @param stage3DProxy The Stage3DProxy to assign the stream to
		 */
		function activateVertexBuffer(index:int, stage3DProxy:Stage3DProxy):void;
		
		/**
		 * Assigns the attribute stream for UV coordinates
		 * @param index The attribute stream index for the vertex shader
		 * @param stage3DProxy The Stage3DProxy to assign the stream to
		 */
		function activateUVBuffer(index:int, stage3DProxy:Stage3DProxy):void;
		
		/**
		 * Assigns the attribute stream for a secondary set of UV coordinates
		 * @param index The attribute stream index for the vertex shader
		 * @param stage3DProxy The Stage3DProxy to assign the stream to
		 */
		function activateSecondaryUVBuffer(index:int, stage3DProxy:Stage3DProxy):void;
		
		/**
		 * Assigns the attribute stream for vertex normals
		 * @param index The attribute stream index for the vertex shader
		 * @param stage3DProxy The Stage3DProxy to assign the stream to
		 */
		function activateVertexNormalBuffer(index:int, stage3DProxy:Stage3DProxy):void;
		
		/**
		 * Assigns the attribute stream for vertex tangents
		 * @param index The attribute stream index for the vertex shader
		 * @param stage3DProxy The Stage3DProxy to assign the stream to
		 */
		function activateVertexTangentBuffer(index:int, stage3DProxy:Stage3DProxy):void;
		
		/**
		 * Retrieves the IndexBuffer3D object that contains triangle indices.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains triangle indices.
		 */
		function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D;
		
		/**
		 * Retrieves the object's vertices as a Number array.
		 */
		function get vertexData():Vector.<Number>;
		
		/**
		 * Retrieves the object's normals as a Number array.
		 */
		function get vertexNormalData():Vector.<Number>;
		
		/**
		 * Retrieves the object's tangents as a Number array.
		 */
		function get vertexTangentData():Vector.<Number>;
		
		/**
		 * The offset into vertexData where the vertices are placed
		 */
		function get vertexOffset():int;
		
		/**
		 * The offset into vertexNormalData where the normals are placed
		 */
		function get vertexNormalOffset():int;
		
		/**
		 * The offset into vertexTangentData where the tangents are placed
		 */
		function get vertexTangentOffset():int;
		
		/**
		 * The offset into UVData vector where the UVs are placed
		 */
		function get UVOffset():int;
		
		/**
		 * The offset into SecondaryUVData vector where the UVs are placed
		 */
		function get secondaryUVOffset():int;
		
		/**
		 * Retrieves the object's indices as a uint array.
		 */
		function get indexData():Vector.<uint>;
		
		/**
		 * Retrieves the object's uvs as a Number array.
		 */
		function get UVData():Vector.<Number>;
		
		function applyTransformation(transform:Matrix3D):void;
		
		function scale(scale:Number):void;
		
		function dispose():void;
		
		function clone():ISubGeometry;
		
		function get scaleU():Number;
		
		function get scaleV():Number;
		
		function scaleUV(scaleU:Number = 1, scaleV:Number = 1):void;
		
		function get parentGeometry():Geometry;
		
		function set parentGeometry(value:Geometry):void;
		
		function get faceNormals():Vector.<Number>;
		
		function cloneWithSeperateBuffers():SubGeometry;
		
		function get autoDeriveVertexNormals():Boolean;
		
		function set autoDeriveVertexNormals(value:Boolean):void;
		
		function get autoDeriveVertexTangents():Boolean;
		
		function set autoDeriveVertexTangents(value:Boolean):void;
		
		function fromVectors(vertices:Vector.<Number>, uvs:Vector.<Number>, normals:Vector.<Number>, tangents:Vector.<Number>):void;
		
		function get vertexPositionData():Vector.<Number>;
	}
}
