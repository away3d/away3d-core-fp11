package away3d.tools.commands
{
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.data.UV;
	import away3d.core.base.data.Vertex;
	import away3d.entities.Mesh;
	
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	use namespace arcane;
	
	/**
	* Class Weld removes the vertices that can be shared from one or more meshes (smoothes the mesh surface when lighted).
	*/
	public class Weld {
		
		private static var _delv:uint;
		
		/**
		*  Apply the welding code to a given ObjectContainer3D.
		* @param	 	obj				ObjectContainer3D. The target Object3d object.
		* @param	 	keepUVs		[otional]Boolean. If true the existing UV-mapping is not be altered by the welding operation, possibly adding extra data. Default is true.
		* @param	 	keepNormals	[otional]Boolean. If true normals of shared vertices will be averaged. If false autoDeriveVertexNormals will be set to true. Default is true.
		*/
		public static function apply(obj:ObjectContainer3D, keepUVs:Boolean = true, keepNormals:Boolean = true):void
		{
			_delv = 0;
			parse(obj, keepUVs, keepNormals);
		}
		
		/**
		* returns howmany vertices were deleted during the welding operation.
		*/
		public static function get verticesRemovedCount():uint
		{
			return _delv;
		}
		 
		private static function parse(obj:ObjectContainer3D, keepUVs:Boolean, keepNormals:Boolean):void
		{
			var child:ObjectContainer3D;
			if(obj is Mesh && obj.numChildren == 0)
				weld(Mesh(obj), keepUVs, keepNormals);
				 
			for(var i:uint = 0;i<obj.numChildren;++i){
				child = obj.getChildAt(i);
				parse(child, keepUVs, keepNormals);
			}
		}
	
		private static function weld(m:Mesh, keepUV:Boolean, keepNormals:Boolean):void
		{
			var geometry:Geometry = m.geometry;
			var geometries:Vector.<SubGeometry> = geometry.subGeometries;
			var numSubGeoms:int = geometries.length;
			
			var vertices:Vector.<Number>;
			var normals:Vector.<Number>;
			var indices:Vector.<uint>;
			var uvs:Vector.<Number>;
			
			var v:Vertex = new Vertex();
			var normal:Vertex = new Vertex();
			var uv:UV = new UV();
			
			var nvertices:Vector.<Number>;
			var nnormals:Vector.<Number>;
			var nindices:Vector.<uint>;
			var nuvs:Vector.<Number>;
			
			var vectors:Array = [];
			var index:uint;
			var indexuv:uint;
			
			var nIndex:uint;
			var nIndexind:uint;
			var checkIndex:int;
			
			var nInd:uint;
			
			var j : uint;
			var i : uint;
			var vecLength : uint;
			var subGeom:SubGeometry;
			
			var normalcalc:Vector3D=new Vector3D();
			var dic_key:String;
			var dic:Dictionary;
			
			for (i = 0; i < numSubGeoms; ++i){
				
				if(dic) dic = null;
				dic = new Dictionary();
				subGeom = SubGeometry(geometries[i]);
				vertices = subGeom.vertexData;
				indices = subGeom.indexData;
				uvs = subGeom.UVData;
				vecLength = indices.length;
				
				nvertices = new Vector.<Number>();
				nindices = new Vector.<uint>();
				nuvs = new Vector.<Number>();
				
				subGeom.autoDeriveVertexTangents = true;
				subGeom.autoDeriveVertexNormals = true;
				
				vectors.push([nvertices,nindices,nuvs]);
				
				nIndexind = nIndex = indexuv = nIndexind = checkIndex = 0;
				
				if (keepNormals){
					subGeom.autoDeriveVertexNormals = false;
					nnormals = new Vector.<Number>();
					normals = subGeom.vertexNormalData;
					vectors[i].push(nnormals);
				}
				 
				for (j = 0; j < vecLength;++j){
					index = indices[j]*3;
					
					v.x = vertices[index];
					v.y = vertices[index+1];
					v.z = vertices[index+2];
					
					if (keepNormals){			
						normal.x = normals[index];
						normal.y = normals[index+1];
						normal.z = normals[index+2];
					}
					
					dic_key=v.toString();
					
					if( keepUV ){	
						indexuv = indices[j]*2;
						uv.u = uvs[indexuv];
						uv.v = uvs[indexuv+1];
						dic_key+="#"+uv.toString();
					}
					
					checkIndex=-1;
					
					if ( dic[dic_key] != undefined){
						checkIndex=dic[dic_key];
					}
					
					if (checkIndex==-1){

						if(keepUV==false){
							indexuv = indices[j]*2;
							uv.u = uvs[indexuv];
							uv.v = uvs[indexuv+1];
						}
							
						dic[dic_key] = nvertices.length/3;
						
						nindices.push(nvertices.length/3);
						nvertices.push(v.x);
						nvertices.push(v.y);
						
						if (keepNormals) nnormals.push(normal.x, normal.y, normal.z);
						
						
						nvertices.push(v.z);
						nuvs.push(uv.u);
						nuvs.push(uv.v);
						
					} else {
						
						if (keepNormals == true){
							nInd = checkIndex*3;
							normalcalc.x= (nnormals[nInd]+normal.x)*.5;
							normalcalc.y = (nnormals[nInd+1]+normal.y)*.5;
							normalcalc.z = (nnormals[nInd+2]+normal.z)*.5;
							normalcalc = normalizeNormalVector(normalcalc);
							nnormals[nInd] = normalcalc.x;
							nnormals[nInd+1] = normalcalc.y;
							nnormals[nInd+2] = normalcalc.z;
						}
						
						nindices.push(checkIndex);
					}
				}
				
				_delv += (vertices.length - nvertices.length)/3;
			}
			
			for (i = 0; i<vectors.length; ++i){
				subGeom = SubGeometry(geometries[i]); 
				
				subGeom.updateVertexData(vectors[i][0]);
				subGeom.updateIndexData(vectors[i][1]);
				subGeom.updateUVData(vectors[i][2]);
				
				if(keepNormals && vectors[i][3] && vectors[i][3].length>0 )
					subGeom.updateVertexNormalData(vectors[i][3]);
			}
			
			dic = null;
			vectors = null;
		}
		
		private static function normalizeNormalVector(v:Vector3D):Vector3D
		{
			var c:Number = 0;
			
			if((v.x*v.x>=v.y*v.y)&&(v.x*v.x>=v.z*v.z)){
				c = 1/Math.sqrt(v.x*v.x);
			} else if((v.y*v.y>=v.x*v.x)&&(v.y*v.y>=v.z*v.z)){
				c = 1/Math.sqrt(v.y*v.y);
			} else if((v.z*v.z>=v.y*v.y)&&(v.z*v.z>=v.x*v.x)){
				c = 1/Math.sqrt(v.z*v.z);
			}
			
			v.x *= c;
			v.y *= c;
			v.z *= c;
			
			return v;
		}
		 
	}
}