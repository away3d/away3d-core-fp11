package away3d.tools.commands
{
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.data.Vertex;
	import away3d.entities.Mesh;
	
	import flash.geom.Vector3D;

	use namespace arcane;
	
	/**
	* Class Explode make all vertices and uv's of a mesh unic<code>Explode</code>
	*/
	public class Explode {
		
		private static var _added:uint;
		private static var _keepNormals:Boolean;
		private static const LIMIT:uint = 196605;

		/**
		*  Apply the explode code to a given ObjectContainer3D.
		* @param	 object				ObjectContainer3D. The target Object3d object.
		* @param	 keepNormals		Boolean. If the vertexNormals of the object are preserved. Default is true.
		*/
		public static function apply(object:ObjectContainer3D, keepNormals:Boolean = true):void
		{
			_added = 0;
			_keepNormals = keepNormals;
			parse(object);
		}
		
		/**
		* returns howmany vertices were added during the explode operation.
		*/
		public static function get verticesAdded():int
		{
			return _added;
		}
		
		/**
		* recursive parsing of a container.
		*/
		private static function parse(object:ObjectContainer3D):void
		{
			var child:ObjectContainer3D;
			if(object is Mesh && object.numChildren == 0)
				explode(Mesh(object));
				 
			for(var i:uint = 0;i<object.numChildren;++i){
				child = object.getChildAt(i);
				parse(child);
			}
		}
		
		/**
		* reset vertex normals
		*/
		private static function calcNormal(v0:Vertex,v1:Vertex,v2:Vertex, fNormal:Vector3D):Vector3D
		{
			var dx1:Number = v2.x-v0.x;
			var dy1:Number = v2.y-v0.y;
			var dz1:Number = v2.z-v0.z;
			var dx2:Number = v1.x-v0.x;
			var dy2:Number = v1.y-v0.y;
			var dz2:Number = v1.z-v0.z;
			
			var cx:Number = dz1*dy2 - dy1*dz2;
			var cy:Number = dx1*dz2 - dz1*dx2;
			var cz:Number = dy1*dx2 - dx1*dy2;
			var d:Number  = 1/Math.sqrt(cx*cx+cy*cy+cz*cz);
			 
			fNormal.x = cx*d;
			fNormal.y = cy*d;
			fNormal.z = cz*d; 
			
			return fNormal;
		}
		
		/**
		* makes all faces unique
		*/
		private static function explode(m:Mesh):void
		{
			var geometry:Geometry = m.geometry;
			var geometries:Vector.<SubGeometry> = geometry.subGeometries;
			var numSubGeoms:int = geometries.length;
			
			var vertices:Vector.<Number>;
			var indices:Vector.<uint>;
			var uvs:Vector.<Number>;
			var normals:Vector.<Number>;
			var tangents:Vector.<Number>;
			 
			var nvertices:Vector.<Number> = new Vector.<Number>();
			var nindices:Vector.<uint> = new Vector.<uint>();
			var nuvs:Vector.<Number> = new Vector.<Number>();
			var nnormals:Vector.<Number> = new Vector.<Number>();
			var ntangents:Vector.<Number> = new Vector.<Number>();
			
			var vectors:Array = [];
			vectors.push([nvertices,nindices,nuvs,nnormals,ntangents]);
			 
			var index:uint;
			var indexuv:uint;
			
			var nIndex:uint = 0;
			var nIndexuv:uint = 0;
			var nIndexind:uint = 0;
			 
			var j : uint;
			var i : uint;
			var vecLength : uint;
			var subGeom:SubGeometry;
			var oriCount:uint = 0;
			var destCount:uint = 0;
			
			for (i = 0; i < numSubGeoms; ++i){
				subGeom = SubGeometry(geometries[i]);
				vertices = subGeom.vertexData;
				indices = subGeom.indexData;
				uvs = subGeom.UVData;
				normals = subGeom.vertexNormalData;
				tangents = subGeom.vertexTangentData;
				if(!_keepNormals){
					subGeom.autoDeriveVertexTangents = true;
					subGeom.autoDeriveVertexNormals = false;
				}
				vecLength = indices.length;
				oriCount += vertices.length;
				 
				for (j = 0; j < vecLength;++j){
					index = indices[j]*3;
					indexuv = indices[j]*2;
					
					if(nvertices.length+3 > LIMIT){
						destCount+=nvertices.length;
						nIndexind = 0;
						nIndex = 0;
						nIndexuv = 0;
						nvertices = new Vector.<Number>();
						nindices = new Vector.<uint>();
						nuvs =new Vector.<Number>();
						nnormals = new Vector.<Number>();
						ntangents = new Vector.<Number>();
						vectors.push([nvertices,nindices,nuvs, nnormals,ntangents]);
						subGeom = new SubGeometry();
						geometry.addSubGeometry(subGeom);
					}
						
					nindices[nIndexind++] = nvertices.length/3;
					
					nvertices[nIndex] = vertices[index];
					nnormals[nIndex] = normals[index];
					if(_keepNormals)
						ntangents[nIndex] = tangents[index];
						
					nIndex++;
					
					index++;
					nvertices[nIndex] = vertices[index];
					nnormals[nIndex] = normals[index];
					if(_keepNormals)
						ntangents[nIndex] = tangents[index];

					nIndex++;
					
					index++;
					nvertices[nIndex] = vertices[index];
					nnormals[nIndex] = normals[index];
					if(_keepNormals)
						ntangents[nIndex] = tangents[index];
					
					nIndex++;
					
					nuvs[nIndexuv++] = uvs[indexuv];
					nuvs[nIndexuv++] = uvs[indexuv+1];
				}
			}
			
			destCount+=nvertices.length;
			_added = (destCount - oriCount)/3;
			
			geometries = geometry.subGeometries;
			numSubGeoms = geometries.length;
			
			var indv0:uint;
			var indv1:uint;
			var indv2:uint;
			var v0:Vertex = new Vertex();
			var v1:Vertex = new Vertex();
			var v2:Vertex = new Vertex();
			var fNormal:Vector3D = new Vector3D();
			
			for (i = 0; i < numSubGeoms; ++i){
				subGeom = SubGeometry(geometries[i]);
				vertices = vectors[i][0];
				subGeom.updateVertexData(vertices);
				indices = vectors[i][1];
				subGeom.updateIndexData(indices);
				subGeom.updateUVData(vectors[i][2]);
				normals = vectors[i][3];
				vecLength = indices.length;
				
				if(!_keepNormals){

					for (j = 0; j < vecLength;j+=3){
						
						indv0 = indices[j]*3;
						indv1 = indices[j+1]*3;
						indv2 = indices[j+2]*3;
						
						v0.x = vertices[indv0];
						v1.x = vertices[indv1];
						v2.x = vertices[indv2];
						
						v0.y = vertices[indv0+1];
						v1.y = vertices[indv1+1];
						v2.y = vertices[indv2+1];
						
						v0.z = vertices[indv0+2];
						v1.z = vertices[indv1+2];
						v2.z = vertices[indv2+2];
						
						fNormal = calcNormal(v0,v1,v2, fNormal);

						normals[indv0] = normals[indv1] = normals[indv2] = fNormal.x;
						normals[indv0+1] = normals[indv1+1] = normals[indv2+1] = fNormal.y;
						normals[indv0+2] = normals[indv1+2] = normals[indv2+2] = fNormal.z;
						 
					}
				}
				subGeom.updateVertexNormalData(normals);
				
				if(_keepNormals)
				 	subGeom.updateVertexTangentData(vectors[i][4]); 
			}
			 
			vectors = null;
		}
		 
	}
}