package away3d.tools.commands
{
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.SubGeometry;
	import away3d.entities.Mesh;
	import away3d.materials.MaterialBase;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	/**
	*  Class Merge merges two or more static meshes into one.<code>Merge</code>
	*/
	public class Merge{
		
		private const LIMIT:uint = 196605;
		private var _baseReceiver:Mesh;
		private var _objectSpace:Boolean;
		private var _keepMaterial:Boolean;
		private var _disposeSources:Boolean;
		private var _holder:Vector3D;
		private var _v:Vector3D;
		private var _vn:Vector3D;
		private var _vectorsSource:Vector.<DataSubGeometry>;
		   
		/**
		* @param	 keepMaterial		[optional] Boolean. Defines if the merged object uses the mesh1 material information or keeps its material(s). Default is false.
		* If set to false and receiver object has multiple materials, the last material found in mesh1 submeshes is applied to mesh2 submeshes. 
		* @param	 disposeSources	[optional] Boolean. Defines if mesh2 (or sources meshes in case applyToContainer is used) are kept untouched or disposed. Default is false.
		* If keepMaterial is true, only geometry and eventual ObjectContainers3D are cleared from memory.
		* @param	 objectSpace		[optional] Boolean. Defines if mesh2 is merge using its objectSpace or worldspace. Default is false.
		*/
		
		function Merge(keepMaterial:Boolean = false, disposeSources:Boolean = false, objectSpace:Boolean = false ):void
		{
			_keepMaterial = keepMaterial;
			_disposeSources = disposeSources;
			_objectSpace = objectSpace;
		}
		
		/**
		* Defines if the mesh(es) sources used for the merging are kept or disposed.
		*/
		public function set disposeSources(b:Boolean):void
		{
			_disposeSources = b;
		}
		
		public function get disposeSources():Boolean
		{
			return _disposeSources;
		}
		/**
		* Defines if mesh2 will be merged using its own material information.
		*/
		public function set keepMaterial(b:Boolean):void
		{
			_keepMaterial = b;
		}
		
		public function get keepMaterial():Boolean
		{
			return _keepMaterial;
		}
		
		/**
		* Defines if mesh2 is merged using its objectSpace.
		*/
		public function set objectSpace(b:Boolean):void
		{
			_objectSpace = b;
		}
		
		public function get objectSpace():Boolean
		{
			return _objectSpace;
		}
		
		/**
		*  Merges all the children of a container as one single Mesh.
		* 	The first Mesh child encountered becomes the receiver. This is mesh that is returned.
		* 	If no Mesh object is found, class returns null.
		* @param	 objectContainer The ObjectContainer3D holding meshes to merge as one mesh.
		* @param	 name [optional]  As the class picks the first mesh it finds, the name is applied to the merged mesh.
		*
		* @return The merged Mesh instance renamed to the name parameter if one was provided.
		*/
		public function applyToContainer(object:ObjectContainer3D, name:String = ""):Mesh
		{
			initHolders();
			_baseReceiver = new Mesh(new Geometry(), null);
			_baseReceiver.position = object.position;
			
			parseContainer(object);
			merge(_baseReceiver);
			if(name != "") _baseReceiver.name = name;
			
			if(_disposeSources){

				if(object is Mesh && Mesh(object).geometry)
					Mesh(object).geometry.dispose();
				
				object = null;
			}
				
			
			return _baseReceiver;
		}
		
		/**
		*  Merges all the meshes found into the Vector.&lt;Mesh&gt; parameter with the receiver Mesh.
		* @param	 receiver 	Mesh. The Mesh receiver.
		* @param	 meshes		Vector.&lt;Mesh&gt;. A series of Meshes to be merged with the reciever mesh.
		*
		* @return The merged receiver Mesh instance.
		*/
		public function applyToMeshes(receiver:Mesh, meshes:Vector.<Mesh>):Mesh
		{
			initHolders();
			
			for(var i:uint = 0;i<meshes.length;i++)
				collect(meshes[i]);
			 
			merge(receiver);

			if(_disposeSources){
				for(i = 0;i<meshes.length;i++){
					meshes[i].geometry.dispose();
					meshes[i] = null;
				}
			}

			return receiver;
		}
		 
		/**
		*  Merge 2 meshes into one. It is recommand to use apply when 2 meshes are to be merged. If more need to be merged, use either applyToMeshes or applyToContainer methods.
		* @param	 mesh1				Mesh. The receiver object that will hold both meshes information.
		* @param	 mesh2				Mesh. The Mesh object to be merge with mesh1.
		*/
		public function apply(mesh1:Mesh, mesh2:Mesh):void
		{
			initHolders();
			collect(mesh2);
			merge(mesh1);
		}
		
		private function initHolders():void
		{
			_vectorsSource= new Vector.<DataSubGeometry>();
			_baseReceiver = null;
			if(!_objectSpace && !_v){
				_holder = new Vector3D();
				_v = new Vector3D();
				_vn = new Vector3D();
			}
		}
		
		private function merge(destMesh:Mesh):void
		{
			var j : uint;
			var i : uint;
			var vecLength : uint;
			var subGeom : SubGeometry;
			var ds:DataSubGeometry;
			
			var geometry:Geometry = destMesh.geometry;
			var geometries:Vector.<SubGeometry> = geometry.subGeometries;
			var numSubGeoms:uint = geometries.length;
			
			var vertices:Vector.<Number>;
			var normals:Vector.<Number>;
			var indices:Vector.<uint>;
			var uvs:Vector.<Number>;
			var vectors:Vector.<DataSubGeometry> = new Vector.<DataSubGeometry>();
			
			//empty mesh receiver case
			if(numSubGeoms == 0){
				subGeom = new SubGeometry();
				subGeom.autoDeriveVertexNormals = true;
				subGeom.autoDeriveVertexTangents = false;
				vertices = new Vector.<Number>();
				normals = new Vector.<Number>();
				indices = new Vector.<uint>();
				uvs = new Vector.<Number>();
						
				subGeom.updateVertexData(vertices);
				subGeom.updateIndexData(indices);
				subGeom.updateUVData(uvs);
				subGeom.updateVertexNormalData(normals);
				geometry.addSubGeometry(subGeom);
				numSubGeoms = 1;
			}
			
			for (i = 0; i<numSubGeoms; ++i){					 
				vertices = geometries[i].vertexData;
				normals = geometries[i].vertexNormalData;
				indices = geometries[i].indexData;
				uvs = geometries[i].UVData;
				
				vertices.fixed = false;
				normals.fixed = false;
				indices.fixed = false;
				uvs.fixed = false;
				
				ds = new DataSubGeometry();
				ds.vertices = vertices;
				ds.indices = indices;
				ds.uvs = uvs;
				ds.normals = normals;
				ds.material = (destMesh.subMeshes[i].material)? destMesh.subMeshes[i].material : destMesh.material; 
				
				ds.subGeometry = SubGeometry(geometries[i]);
				
				vectors.push(ds);
			}
			
			var nvertices:Vector.<Number>;
			var nindices:Vector.<uint>;
			var nuvs:Vector.<Number>;
			var nnormals:Vector.<Number>;
			nvertices = ds.vertices;
			nindices = ds.indices;
			nuvs = ds.uvs;
			nnormals = ds.normals;
			
			var activeMaterial:MaterialBase = ds.material;
			
			numSubGeoms = _vectorsSource.length;
			 
			var index:uint;
			var indexY:uint;
			var indexZ:uint;
			var indexuv:uint;
			
			var destDs:DataSubGeometry;
			var rotate:Boolean;
			var scale:Boolean = (destMesh.scaleX != 1 || destMesh.scaleY != 1 || destMesh.scaleZ != 1);
			 
			for (i = 0; i < numSubGeoms; ++i){
				ds = _vectorsSource[i];
				subGeom = ds.subGeometry;
				vertices = ds.vertices;
				normals = ds.normals;
				indices = ds.indices;
				uvs = ds.uvs;
				
				if(_keepMaterial && ds.material){
					destDs = getDestSubgeom(vectors, ds);
					if(!destDs){
						destDs = _vectorsSource[i];
						subGeom = new SubGeometry();
						destDs.subGeometry = subGeom;
						
						if(!_objectSpace){
						 	vecLength = destDs.vertices.length;
							rotate = ( destDs.mesh.rotationX != 0 || destDs.mesh.rotationY != 0 || destDs.mesh.rotationZ != 0);
							 
							for (j = 0; j < vecLength;j+=3){
								indexY = j+1;
								indexZ = indexY+1;
								_v.x = destDs.vertices[j];
								_v.y = destDs.vertices[indexY];
								_v.z = destDs.vertices[indexZ];
								 
								if(rotate){
									_vn.x = destDs.normals[j];
									_vn.y = destDs.normals[indexY];
									_vn.z = destDs.normals[indexZ];
									_vn = applyRotations(_vn, destDs.transform);
									destDs.normals[j] = _vn.x;
									destDs.normals[indexY] = _vn.y;
									destDs.normals[indexZ] = _vn.z;
								}
								
								_v = destDs.transform.transformVector(_v);
								
								if(scale){
									destDs.vertices[j] = _v.x/destMesh.scaleX;
									destDs.vertices[indexY] = _v.y/destMesh.scaleY;
									destDs.vertices[indexZ] = _v.z/destMesh.scaleZ;
								 
								} else {
									destDs.vertices[j] = _v.x;
									destDs.vertices[indexY] = _v.y;
									destDs.vertices[indexZ] = _v.z;
								}
									
							}
						}
						vectors.push(destDs);
						continue;
					}
					
					activeMaterial = destDs.material;
					nvertices = destDs.vertices;
					nnormals = destDs.normals;
					nindices = destDs.indices;
					nuvs = destDs.uvs;
				}

				vecLength = indices.length;
				
				rotate = (ds.mesh.rotationX != 0 || ds.mesh.rotationY != 0 || ds.mesh.rotationZ != 0);
				 
				for (j = 0; j < vecLength;++j){
					 
					if(nvertices.length+9 > LIMIT && nindices.length % 3 == 0){

						destDs = new DataSubGeometry();
						
						nvertices = destDs.vertices = new Vector.<Number>();
						nnormals = destDs.normals = new Vector.<Number>();
						nindices = destDs.indices = new Vector.<uint>();
						nuvs = destDs.uvs = new Vector.<Number>();
 
						destDs.material = activeMaterial; 
						destDs.subGeometry = new SubGeometry();
						destDs.transform = ds.transform;
						destDs.mesh = ds.mesh;
						ds = destDs;
						ds.addSub = true;
						vectors.push(ds);
					}
					
					index = indices[j]*3;
					indexuv = indices[j]*2;
					nindices.push(nvertices.length/3);
					indexY = index+1;
					indexZ = indexY+1;
					
					if(_objectSpace){
						
						nvertices.push(vertices[index], vertices[indexY], vertices[indexZ]);
						 
					} else {

						_v.x = vertices[index];
						_v.y = vertices[indexY];
						_v.z = vertices[indexZ];
						
						if(rotate) {
							_vn.x = normals[index];
							_vn.y = normals[indexY];
							_vn.z = normals[indexZ];
							_vn = applyRotations(_vn, ds.transform);
							nnormals.push(_vn.x, _vn.y, _vn.z);
						}
						 
						_v = ds.transform.transformVector(_v);
						
						if(scale){
							nvertices.push(_v.x/destMesh.scaleX, _v.y/destMesh.scaleY, _v.z/destMesh.scaleZ);
						} else{
							nvertices.push(_v.x, _v.y, _v.z);
						}
					}
					
					if(_objectSpace || !rotate)
						nnormals.push(normals[index], normals[indexY], normals[indexZ]);
					
					nuvs.push(uvs[indexuv], uvs[indexuv+1]);
				} 
			}
			
			for (i = 0; i < vectors.length; ++i){
				ds = vectors[i];
				if(ds.vertices.length == 0) continue;
				subGeom = ds.subGeometry;

				if(ds.normals && ds.normals.length>0 && ds.normals.length == ds.vertices.length){
					subGeom.autoDeriveVertexNormals = false;
					subGeom.updateVertexNormalData(ds.normals);
				} else {
					subGeom.autoDeriveVertexNormals = true;
				}
				
				subGeom.updateVertexData(ds.vertices);
				subGeom.updateIndexData(ds.indices);
				subGeom.updateUVData(ds.uvs);
				 
				if(ds.addSub || !isSubGeomAdded(geometry.subGeometries, subGeom))
					geometry.addSubGeometry(subGeom);
				
				if(destMesh.material != ds.material)
					destMesh.subMeshes[destMesh.subMeshes.length-1].material = ds.material;
				
				if(_disposeSources && ds.mesh){
					if(_keepMaterial){
						ds.mesh.geometry.dispose();
					} else if(ds.material != destMesh.material){
						ds.mesh.dispose();
						if (ds.material) ds.material.dispose();
					}
					ds.mesh = null;
				}
				ds = null;
			}
			
			for (i = 0; i < _vectorsSource.length; ++i)
				_vectorsSource[i] = null;
				
			vectors = _vectorsSource = null;
			
			if(geometry.subGeometries[0].vertexData.length == 0 && geometry.subGeometries[0].indexData.length == 0)
				geometry.removeSubGeometry(geometry.subGeometries[0]);
		}
		
		private function isSubGeomAdded(subGeometries:Vector.<SubGeometry>, subGeom:SubGeometry):Boolean
		{
			for (var i:uint = 0; i<subGeometries.length; ++i)
				if(subGeometries[i] == subGeom) return true;
				
			return false;
		}
		 
		private function collect(m:Mesh):void
		{
			var ds:DataSubGeometry;
			var geom:Geometry = m.geometry;
			var geoms:Vector.<SubGeometry> = geom.subGeometries;
			
			if(geoms.length == 0) return;
			 
			for (var i:uint = 0; i<geoms.length; ++i){					 
				ds = new DataSubGeometry();
				ds.vertices = SubGeometry(geoms[i]).vertexData.concat();
				ds.indices = SubGeometry(geoms[i]).indexData.concat();
				ds.uvs = SubGeometry(geoms[i]).UVData.concat();
				ds.normals = SubGeometry(geoms[i]).vertexNormalData.concat();
				ds.vertices.fixed = false;
				ds.normals.fixed = false;
				ds.indices.fixed = false;
				ds.uvs.fixed = false;
				ds.material = (m.subMeshes[i].material)? m.subMeshes[i].material : m.material;
				ds.subGeometry = SubGeometry(geoms[i]);
				ds.transform = m.transform;
				ds.mesh = m;
				
				_vectorsSource.push(ds);
			}
		}
		
		private function getDestSubgeom(v:Vector.<DataSubGeometry>, ds:DataSubGeometry):DataSubGeometry
		{
			var targetDs:DataSubGeometry;
			var len:uint = v.length-1;
			for (var i:int = len; i>-1; --i){
				if(v[i].material == ds.material){
					targetDs = v[i];
					return targetDs;
				}
			}
			
			return null;
		}
		
		private function parseContainer(object:ObjectContainer3D):void
		{
			var child:ObjectContainer3D;
			var i:uint;
			
			if(object is Mesh && object.numChildren == 0)
				collect(Mesh(object));
			
			for(i = 0;i<object.numChildren;++i){
				child = object.getChildAt(i);
				if(child!=_baseReceiver)
					parseContainer(child);
			}
		}
		
		private function applyRotations(v:Vector3D, t:Matrix3D):Vector3D
		{
			_holder.x = v.x;
			_holder.y = v.y;
			_holder.z = v.z;
			
			_holder = t.deltaTransformVector(_holder);
			
			v.x = _holder.x;
			v.y = _holder.y;
			v.z = _holder.z;
			
			return v;
		}
		 
	}
}

import away3d.core.base.SubGeometry;
import away3d.entities.Mesh;
import away3d.materials.MaterialBase;

import flash.geom.Matrix3D;

class DataSubGeometry {
	public var uvs:Vector.<Number>;
	public var vertices:Vector.<Number>;
	public var normals:Vector.<Number>;
	public var indices:Vector.<uint>;
	public var subGeometry:SubGeometry;
	public var material:MaterialBase;
	public var transform:Matrix3D;
	public var mesh:Mesh;
	public var addSub:Boolean;
}