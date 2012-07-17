package away3d.tools.helpers
{
	import away3d.arcane;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.data.UV;
	import away3d.core.base.data.Vertex;
	import away3d.entities.Mesh;

	use namespace arcane;
	
	/**
	* Helper Class for face manipulation<code>FaceHelper</code>
	*/
	 
	public class FaceHelper {
		
		private static const LIMIT:uint = 196605;
		private static const SPLIT:uint = 2;
		private static const TRI:uint = 3;
		private static const QUARTER:uint = 4;
		
		public static function addFace(mesh:Mesh, v0:Vertex, v1:Vertex, v2:Vertex, uv0:UV, uv1:UV, uv2:UV, subGeomIndice:uint):void
		{
			var subGeom:SubGeometry;
			if(mesh.geometry.subGeometries.length == 0){
				subGeom = new SubGeometry();
				mesh.geometry.addSubGeometry(subGeom);
			}

			if(mesh.geometry.subGeometries.length-1 < subGeomIndice)
				throw new Error("no subGeometry at index provided:"+subGeomIndice);
			
			subGeom = mesh.geometry.subGeometries[subGeomIndice];
			 
			var vertices:Vector.<Number> = subGeom.vertexData || new Vector.<Number>();
			var indices:Vector.<uint>;
			var uvs:Vector.<Number>;

			var lengthVertices:uint = vertices.length;

			if(lengthVertices+9 > LIMIT){
				indices = Vector.<uint>([0,1,2]);
				vertices = Vector.<Number>([v0.x, v0.y, v0.z, v1.x, v1.y, v1.z, v2.x, v2.y, v2.z]);
				uvs = Vector.<Number>([uv0.u, uv0.v, uv1.u, uv1.v, uv2.u, uv2.v]);
				subGeom = new SubGeometry();
				mesh.geometry.addSubGeometry(subGeom);

			} else {

				indices = subGeom.indexData || new Vector.<uint>();
				uvs = subGeom.UVData || new Vector.<Number>();
				vertices.fixed = indices.fixed = uvs.fixed = false;
				var ind:uint = lengthVertices/3;
				var nind:uint = indices.length;
				indices[nind++] = ind++;
				indices[nind++] = ind++;
				indices[nind++] = ind++;
				vertices.push(v0.x, v0.y, v0.z, v1.x, v1.y, v1.z, v2.x, v2.y, v2.z);
				uvs.push(uv0.u, uv0.v, uv1.u, uv1.v, uv2.u, uv2.v);
			}
			
			updateSubGeometryData(subGeom, vertices, indices, uvs);
		}
		
		/**
		* Remove a face from a mesh
		* @param mesh						Mesh. The mesh to remove a face from
		* @param index						uint. Index of the face in vertices. The value represents the position in indices vector divided by 3.
		* For instance, to edit face [1], the parameter indice will be 1. The x value of the v0 at position 3 in vertice vector is then extracted from vertices[indices[indice]]
		* @param subGeomIndice		uint. Index of vertex 1 of the face
		*/
		
		//todo return the remove Face as face to ease some manipulations
		public static function removeFace(mesh:Mesh, index:uint, subGeomIndice:uint):void
		{
			var pointer:uint = index*3;
			var subGeom:SubGeometry = getSubGeometry(mesh, subGeomIndice);
			
			var indices:Vector.<uint> = subGeom.indexData.concat();
			
			if(pointer >  indices.length -3)
				throw new Error("ERROR >> face index out of range! Use the location in indice vector /3. For example, pass 1 if you want edit face 1, not 3!");
			
			var vertices:Vector.<Number> = subGeom.vertexData.concat();
			var uvs:Vector.<Number> = subGeom.UVData.concat();
		 
			var pointerEnd:uint = pointer+2;
			subGeom.dispose();
			  
			var oInd:uint;
			var oVInd:uint;
			var oUVInd:uint;
			var indInd:uint;
			var uvInd:uint;
			var vInd:uint;
			var i:uint;
			 
			var nvertices:Vector.<Number> = new Vector.<Number>();
			var nindices:Vector.<uint> = new Vector.<uint>();
			var nuvs:Vector.<Number> = new Vector.<Number>();
			
			//Check for shared vectors
			if(vertices.length/3 != indices.length){

				var sharedIndice:int;
				
				for(i = 0; i<indices.length;++i){
					
					if(i >= pointer && i <= pointerEnd)
						continue;
					
					oInd = indices[i];
					oVInd = oInd*3;
					oUVInd = oInd*2;
					 
					sharedIndice = getUsedIndice(nvertices, vertices[oVInd], vertices[oVInd+1], vertices[oVInd+2]);
					
					if(sharedIndice != -1){
						nindices[indInd++] = sharedIndice;
						continue;
					}
						
					nindices[indInd++] = nvertices.length/3;
					
					nvertices[vInd] = vertices[oVInd];
					vInd++;
					
					oVInd++;
					nvertices[vInd] = vertices[oVInd];
					vInd++;
					
					oVInd++;
					nvertices[vInd] = vertices[oVInd];
					vInd++;
					
					nuvs[uvInd++] = uvs[oUVInd];
					nuvs[uvInd++] = uvs[oUVInd+1];
				}
				 
			} else {
				
				for(i = 0; i<indices.length;++i){
					
					if(i < pointer || i > pointerEnd){
						oInd = indices[i];
						oVInd = oInd*3;
						oUVInd = oInd*2;
						
						nindices[indInd++] = vInd/3;
						 
						nvertices[vInd] = vertices[oVInd];
						vInd++;
						
						oVInd++;
						nvertices[vInd] = vertices[oVInd];
						vInd++;
						
						oVInd++;
						nvertices[vInd] = vertices[oVInd];
						vInd++;
						 
						nuvs[uvInd++] = uvs[oUVInd];
						nuvs[uvInd++] = uvs[oUVInd+1];
					} 
				}
			}
			
			updateSubGeometryData(subGeom, nvertices, nindices, nuvs);
		}
		
		/**
		* Remove a series of faces from a mesh. Indices and geomIndices must have the same length.
		* Meshes with less that 20k faces and single material, will generally only have one single subgeometry.
		* The geomIndices vector will then contain only zeros.
		* IMPORTANT: the code considers the indices as location in the mesh subgemeometry indices vector, not the value at the pointer location.
		* 
		* @param mesh				Mesh. The mesh to remove a face from
		* @param indices			A vector with a series of uints indices: the indices of the faces to be removed. 
		* @param subGeomIndices		A vector with a series of uints indices representing the subgeometries of the faces to be removed.
		*/
		public static function removeFaces(mesh:Mesh, indices:Vector.<uint>, subGeomIndices:Vector.<uint>):void
		{
			for(var i:uint = 0; i<indices.length;++i)
				removeFace(mesh, indices[i], subGeomIndices[i]);
		}
		
		/**
		* Adds a series of faces from a mesh. All vectors must have the same length.
		* @param mesh	Mesh. The mesh to remove a face from
		* @param v0s	A vector with a series of Vertex Objects representing the v0 of a face. 
		* @param v1s	A vector with a series of Vertex Objects representing the v1 of a face. 
		* @param v2s	A vector with a series of Vertex Objects representing the v2 of a face. 
		* @param uv0s	A vector with a series of UV Objects representing the uv0 of a face.
		* @param uv1s	A vector with a series of UV Objects representing the uv1 of a face. 
		* @param uv2s	A vector with a series of UV Objects representing the uv2 of a face. 
		*/
		public static function addFaces(mesh:Mesh, v0s:Vector.<Vertex>, v1s:Vector.<Vertex>, v2s:Vector.<Vertex>, uv0s:Vector.<UV>, uv1s:Vector.<UV>, uv2s:Vector.<UV>, subGeomIndices:Vector.<uint>):void
		{
			for(var i:uint = 0; i<v0s.length;++i)
				addFace(mesh, v0s[i], v1s[i], v2s[i], uv0s[i], uv1s[i], uv2s[i], subGeomIndices[i]);
		}
		
		/**
		* Divides a face into 2 faces.
		* @param	mesh			The mesh holding the face to split in 2
		* @param	indice			The face index. The value represents the position in indices vector divided by 3.
		* For instance, to edit face [1], the parameter indice will be 1. The x value of the v0 at position 9 in vertices vector is then extracted from vertices[indices[indice*3]]
		* @param	subGeomIndice	The index of the subgeometry holder this face.
		* @param	side			[optional] The side of the face to split in two. 0 , 1 or 2. (clockwize).
		*/
		public static function splitFace(mesh:Mesh, indice:uint, subGeomIndice:uint, side:uint = 0):void
		{
			var pointer:uint = indice*3;
			var subGeom:SubGeometry = getSubGeometry(mesh, subGeomIndice);
			var indices:Vector.<uint> = subGeom.indexData.concat();

			if(pointer >  indices.length -3)
				throw new Error("ERROR >> face index out of range! Use the location in indice vector /3. For example, pass 1 if you want edit face 1, not 3!");
			
			 
			var vertices:Vector.<Number> = subGeom.vertexData.concat();
			
			if(indices.length + 3 > LIMIT || vertices.length + 9 > LIMIT){
				trace("splitFace cannot take place, not enough room in target subGeometry");
				return;
			}
			
			var uvs:Vector.<Number> = subGeom.UVData.concat();
			var normals:Vector.<Number> = subGeom.vertexNormalData.concat();
			var tangents:Vector.<Number> = subGeom.vertexTangentData.concat();
			
			indices = subGeom.indexData.concat();
			uvs = subGeom.UVData.concat();
			normals = subGeom.vertexNormalData.concat();
			tangents = subGeom.vertexTangentData.concat();
			
			var pointerverts:uint = indices[pointer]*3;
			var v0:Vertex = new Vertex(vertices[pointerverts], vertices[pointerverts+1], vertices[pointerverts+2]);
			pointerverts = indices[pointer+1]*3;
			var v1:Vertex = new Vertex(vertices[pointerverts], vertices[pointerverts+1], vertices[pointerverts+2]);
			pointerverts = indices[pointer+2]*3;
			var v2:Vertex = new Vertex(vertices[pointerverts], vertices[pointerverts+1], vertices[pointerverts+2]);
			 
			var pointeruv:uint = indices[pointer]*2;
			var uv0:UV = new UV(uvs[pointeruv], uvs[pointeruv+1]);
			pointeruv =  indices[pointer+1]*2;
			var uv1:UV = new UV(uvs[pointeruv], uvs[pointeruv+1]);
			pointeruv = indices[pointer+2]*2;
			var uv2:UV = new UV(uvs[pointeruv], uvs[pointeruv+1]);
			
			var vlength:uint = indices.length;
			indices[vlength] = vlength/3;
			var targetIndice:uint;
			
			switch(side){
				case 0:
					vertices.push((v0.x+v1.x)*.5, (v0.y+v1.y)*.5,  (v0.z+v1.z)*.5);
					uvs.push((uv0.u+uv1.u)*.5, (uv0.v+uv1.v)*.5);
					targetIndice = indices[(indice*3)+1];
					indices[(indice*3)+1] = (vertices.length-1)/3;
					indices[vlength++] = indices[pointer+1];
					indices[vlength++] = targetIndice;
					indices[vlength++] = indices[pointer+2];
					break;
					
				case 1:
					vertices.push((v1.x+v2.x)*.5, (v1.y+v2.y)*.5, (v1.z+v2.z)*.5);
					uvs.push((uv1.u+uv2.u)*.5, (uv1.v+uv2.v)*.5);
					targetIndice = indices[(indice*3)+2];
					indices[(indice*3)+2] = targetIndice;
					indices[vlength++] = (vertices.length-1)/3;
					indices[vlength++] = indices[pointer+2];
					indices[vlength++] = indices[pointer];
					break;
					
				default:
					vertices.push((v2.x+v0.x)*.5, (v2.y+v0.y)*.5, (v2.z+v0.z)*.5);
					uvs.push((uv2.u+uv0.u)*.5, (uv2.v+uv0.v)*.5);
					targetIndice = indices[indice*3];
					indices[indice*3] = targetIndice;
					indices[vlength++] = (vertices.length-1)/3;
					indices[vlength++] = indices[pointer];
					indices[vlength++] = indices[pointer+1];
			}
			
			v0 = v1 = v2 =  null;
			uv0 = uv1 = uv2 = null;
			
			updateSubGeometryData(subGeom, vertices, indices, uvs, normals, tangents);
		}
		
		/**
		* Divides a face into 3 faces.
		* @param	mesh			The mesh holding the face to split in 3.
		* @param	indice		The face index. The value represents the position in indices vector divided by 3.
		* For instance, to edit face [1], the parameter indice will be 1. The x value of the v0 at position 9 in vertices vector is then extracted from vertices[indices[indice*3]]
		* @param	subGeomIndice			The index of the subgeometry holder this face.
		*/
		public static function triFace(mesh:Mesh, indice:uint, subGeomIndice:uint):void
		{
			var pointer:uint = indice*3;
			var subGeom:SubGeometry = getSubGeometry(mesh, subGeomIndice);
			var indices:Vector.<uint> = subGeom.indexData.concat();

			if(pointer >  indices.length -3)
				throw new Error("ERROR >> face index out of range! Use the location in indice vector /3. For example, pass 1 if you want edit face 1, not 3!");
			
			var vertices:Vector.<Number> = subGeom.vertexData.concat();
			
			if(indices.length + 6 > LIMIT || vertices.length + 18 > LIMIT){
				trace("triFace cannot take place, not enough room in target subGeometry");
				return;
			}
			
			var uvs:Vector.<Number> = subGeom.UVData.concat();
			var normals:Vector.<Number> = subGeom.vertexNormalData.concat();
			var tangents:Vector.<Number> = subGeom.vertexTangentData.concat();
			
			indices = subGeom.indexData.concat();
			uvs = subGeom.UVData.concat();
			normals = subGeom.vertexNormalData.concat();
			tangents = subGeom.vertexTangentData.concat();
			
			var pointerverts:uint = indices[pointer]*3;
			var v0:Vertex = new Vertex(vertices[pointerverts], vertices[pointerverts+1], vertices[pointerverts+2]);
			pointerverts = indices[pointer+1]*3;
			var v1:Vertex = new Vertex(vertices[pointerverts], vertices[pointerverts+1], vertices[pointerverts+2]);
			pointerverts = indices[pointer+2]*3;
			var v2:Vertex = new Vertex(vertices[pointerverts], vertices[pointerverts+1], vertices[pointerverts+2]);
			 
			var pointeruv:uint = indices[pointer]*2;
			var uv0:UV = new UV(uvs[pointeruv], uvs[pointeruv+1]);
			pointeruv =  indices[pointer+1]*2;
			var uv1:UV = new UV(uvs[pointeruv], uvs[pointeruv+1]);
			pointeruv = indices[pointer+2]*2;
			var uv2:UV = new UV(uvs[pointeruv], uvs[pointeruv+1]);
			 
			vertices.push((v0.x+v1.x+v2.x)/3, (v0.y+v1.y+v2.y)/3,  (v0.z+v1.z+v2.z)/3);
			uvs.push((uv0.u+uv1.u+uv2.u)/3, (uv0.v+uv1.v+uv2.v)/3);
			
			var vlength:uint = indices.length;
			var ind:uint = vlength/3;
			
			indices[(indice*3)+2] =  (vertices.length-1)/3;
			indices[vlength++] = ind;
			indices[vlength++] = indices[pointer];
			indices[vlength++] = indices[pointer+2];
			
			indices[vlength++] = indices[pointer+1];
			indices[vlength++] = ind;
			indices[vlength++] = indices[pointer+2];
			 
			v0 = v1 = v2 =  null;
			uv0 = uv1 = uv2 = null;

			updateSubGeometryData(subGeom, vertices, indices, uvs, normals, tangents);
		}
		
		/**
		* Divides a face into 4 faces.
		* @param	mesh			The mesh holding the face to split in 4.
		* @param	indice		The face index. The value represents the position in indices vector divided by 3.
		* For instance, to edit face [1], the parameter indice will be 1. The x value of the v0 at position 9 in vertices vector is then extracted from vertices[indices[indice*3]]
		* @param	subGeomIndice			The index of the subgeometry holder this face.
		*/
		public static function quarterFace(mesh:Mesh, indice:uint, subGeomIndice:uint):void
		{
			var pointer:uint = indice*3;
			var subGeom:SubGeometry = getSubGeometry(mesh, subGeomIndice);
			var indices:Vector.<uint> = subGeom.indexData.concat();

			if(pointer >  indices.length -3)
				throw new Error("ERROR >> face index out of range! Use the location in indice vector /3. For example, pass 1 if you want edit face 1, not 3!");
			
			var vertices:Vector.<Number> = subGeom.vertexData.concat();
			
			if(indices.length + 9 > LIMIT || vertices.length + 27 > LIMIT){
				trace("quarterFace cannot take place, not enough room in target subGeometry");
				return;
			}
			
			var uvs:Vector.<Number> = subGeom.UVData.concat();
			var normals:Vector.<Number> = subGeom.vertexNormalData.concat();
			var tangents:Vector.<Number> = subGeom.vertexTangentData.concat();
			
			indices = subGeom.indexData.concat();
			uvs = subGeom.UVData.concat();
			normals = subGeom.vertexNormalData.concat();
			tangents = subGeom.vertexTangentData.concat();
			 
			var pointerverts:uint = indices[pointer]*3;
			var v0:Vertex = new Vertex(vertices[pointerverts], vertices[pointerverts+1], vertices[pointerverts+2]);
			pointerverts = indices[pointer+1]*3;
			var v1:Vertex = new Vertex(vertices[pointerverts], vertices[pointerverts+1], vertices[pointerverts+2]);
			pointerverts = indices[pointer+2]*3;
			var v2:Vertex = new Vertex(vertices[pointerverts], vertices[pointerverts+1], vertices[pointerverts+2]);
			 
			var pointeruv:uint = indices[pointer]*2;
			var uv0:UV = new UV(uvs[pointeruv], uvs[pointeruv+1]);
			pointeruv =  indices[pointer+1]*2;
			var uv1:UV = new UV(uvs[pointeruv], uvs[pointeruv+1]);
			pointeruv = indices[pointer+2]*2;
			var uv2:UV = new UV(uvs[pointeruv], uvs[pointeruv+1]);
			
			var vind1:uint = vertices.length/3;
			vertices.push((v0.x+v1.x)*.5, (v0.y+v1.y)*.5,  (v0.z+v1.z)*.5);
			uvs.push((uv0.u+uv1.u)*.5, (uv0.v+uv1.v)*.5);
			
			var vind2:uint = vertices.length/3;
			vertices.push((v1.x+v2.x)*.5, (v1.y+v2.y)*.5, (v1.z+v2.z)*.5);
			uvs.push((uv1.u+uv2.u)*.5, (uv1.v+uv2.v)*.5);
			
			var vind3:uint = vertices.length/3;
			vertices.push((v2.x+v0.x)*.5, (v2.y+v0.y)*.5, (v2.z+v0.z)*.5);
			uvs.push((uv2.u+uv0.u)*.5, (uv2.v+uv0.v)*.5);
			
			var vlength:uint = indices.length;
			
			indices[vlength++] =  vind2;
			indices[vlength++] = indices[pointer+2];
			indices[vlength++] =  vind3;
			
			indices[vlength++] = vind2;
			indices[vlength++] = vind3;
			indices[vlength++] = vind1;
			
			indices[vlength++] = vind2;
			indices[vlength++] = vind1;
			indices[vlength++] = indices[pointer+1];
			
			indices[(indice*3)+1] =  vind1;
			indices[(indice*3)+2] =  vind3;
			
			v0 = v1 = v2 =  null;
			uv0 = uv1 = uv2 = null;

			updateSubGeometryData(subGeom, vertices, indices, uvs, normals, tangents);
		}
		
		/**
		* Divides all the faces of a mesh in 2 faces.
		* @param	mesh		The mesh holding the faces to split in 2
		* @param	face		The face index. The value represents the position in indices vector divided by 3.
		* @param	side		The side of the face to split in two. 0 , 1 or 2. (clockwize).
		* At this time of dev, splitFaces method will abort if a subgeometry reaches max buffer limit of 65k 
		*/
		public static function splitFaces(mesh:Mesh):void
		{
			applyMethod(SPLIT, mesh);
		}
		
		/**
		* Divides all the faces of a mesh in 3 faces.
		* @param	mesh		The mesh holding the faces to split in 3
		* At this time of dev, triFaces method will abort if a subgeometry reaches max buffer limit of 65k 
		*/
		public static function triFaces(mesh:Mesh):void
		{
			applyMethod(TRI, mesh);
		}
		/**
		* Divides all the faces of a mesh in 4 faces.
		* @param	mesh		The mesh holding the faces to split in 4
		* At this time of dev, quarterFaces method will abort if a subgeometry reaches max buffer limit of 65k 
		*/
		public static function quarterFaces(mesh:Mesh):void
		{
			applyMethod(QUARTER, mesh);
		}
		
		private static function applyMethod(methodID:uint, mesh:Mesh, value:Number = 0):void
		{
			var subGeoms:Vector.<SubGeometry> = mesh.geometry.subGeometries;
			var indices:Vector.<uint>;
			var faceNumber:uint;
			var j:uint;
			for(var i:uint = 0;i<subGeoms.length;++i){
				indices = subGeoms[i].indexData;
				faceNumber = 0;
				for(j = 0; j< indices.length; j+=3){
					switch(methodID){
						case 2:
							splitFace(mesh, faceNumber, i, 0);
							break;
						case 3:
							triFace(mesh, faceNumber, i);
							break;
						case 4:
							quarterFace(mesh, faceNumber, i);
							break;
						default:
							throw new Error("unknown method reference");
					}
					faceNumber++;
				}
			}
		}
		
		private static function updateSubGeometryData(subGeometry:SubGeometry, vertices:Vector.<Number>, indices:Vector.<uint>, uvs:Vector.<Number>, normals:Vector.<Number> = null, tangents:Vector.<Number> = null):void
		{
			subGeometry.updateVertexData(vertices);
			subGeometry.updateIndexData(indices);
			subGeometry.updateUVData(uvs);
			if(normals)
				subGeometry.updateVertexNormalData(normals);
			if(tangents)
				subGeometry.updateVertexTangentData(tangents);
		}
		
		private static function getSubGeometry(mesh:Mesh, subGeomIndice:uint):SubGeometry
		{
			var subGeoms:Vector.<SubGeometry> = mesh.geometry.subGeometries;
			
			if(subGeomIndice>subGeoms.length-1)
				throw new Error("ERROR >> subGeomIndice is out of range!");
			
			return subGeoms[subGeomIndice];
		}
		
		private static function getUsedIndice(vertices:Vector.<Number>, x:Number, y:Number, z:Number):int
		{
			for(var i:uint = 0; i<vertices.length;i+=3){
				if(vertices[i] == x && vertices[i+1] == y && vertices[i+1] == z)
					return i/3;
			}
			return -1;
		}
	}
}