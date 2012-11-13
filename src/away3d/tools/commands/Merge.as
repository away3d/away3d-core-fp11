package away3d.tools.commands
{
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.CompactSubGeometry;
	import away3d.core.base.Geometry;
	import away3d.core.base.ISubGeometry;
	import away3d.core.base.SubGeometry;
	import away3d.entities.Mesh;
	import away3d.materials.MaterialBase;
	import away3d.tools.utils.GeomUtil;

	/**
	*  Class Merge merges two or more static meshes into one.<code>Merge</code>
	*/
	public class Merge{
		
		private const LIMIT:uint = 196605;
		private var _objectSpace:Boolean;
		private var _keepMaterial:Boolean;
		private var _disposeSources:Boolean;
		private var _geomVOs:Vector.<GeometryVO>;
		   
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
			var receiver : Mesh;
			
			reset();
			
			receiver = new Mesh(new Geometry(), null);
			receiver.position = object.position;
			
			parseContainer(object);
			merge(receiver);
			if(name != "") receiver.name = name;
			
			return receiver;
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
			reset();
			
			for(var i:uint = 0;i<meshes.length;i++)
				collect(meshes[i]);
			 
			merge(receiver);

			return receiver;
		}
		 
		/**
		*  Merge 2 meshes into one. It is recommand to use apply when 2 meshes are to be merged. If more need to be merged, use either applyToMeshes or applyToContainer methods.
		* @param	 mesh1				Mesh. The receiver object that will hold both meshes information.
		* @param	 mesh2				Mesh. The Mesh object to be merge with mesh1.
		*/
		public function apply(mesh1:Mesh, mesh2:Mesh):void
		{
			reset();
			collect(mesh2);
			merge(mesh1);
		}
		
		private function reset():void
		{
			_geomVOs= new Vector.<GeometryVO>();
		}
		
		
		private function merge(destMesh:Mesh):void
		{
			var i : uint;
			var subIdx : uint;
			var destGeom : Geometry;
			var useSubMaterials : Boolean;
			
			destGeom = destMesh.geometry;
			subIdx = destMesh.subMeshes.length;
			
			// Only apply materials directly to sub-meshes if necessary,
			// i.e. if there is more than one material available.
			useSubMaterials = (_geomVOs.length > 0);
			
			for (i=0; i<_geomVOs.length; i++) {
				var s : uint;
				var data : GeometryVO;
				var subs : Vector.<ISubGeometry>;
				
				data = _geomVOs[i];
				subs = GeomUtil.fromVectors(data.vertices, data.indices, data.uvs, data.normals, null, null, null);
				
				for (s=0; s<subs.length; s++) {
					destGeom.addSubGeometry(subs[s]);
					
					if (_keepMaterial && useSubMaterials)
						destMesh.subMeshes[subIdx].material = data.material;
					
					subIdx++;
				}
			}
			
			if (_keepMaterial && !useSubMaterials && _geomVOs.length)
				destMesh.material = _geomVOs[0].material;
		}
		
		private function collect(mesh:Mesh):void
		{
			if (mesh.geometry) {
				var subIdx : uint;
				var subGeometries : Vector.<ISubGeometry> = mesh.geometry.subGeometries;
				 
				for (subIdx = 0; subIdx<subGeometries.length; subIdx++){					 
					var i : uint;
					var len : uint;
					var iIdx : uint, vIdx : uint, nIdx : uint, uIdx : uint;
					var indexOffset : uint;
					var subGeom : ISubGeometry;
					var vo : GeometryVO;
					var vertices : Vector.<Number>;
					var normals : Vector.<Number>;
					
					var vStride : uint, nStride : uint, uStride : uint;
					var vOffs : uint, nOffs : uint, uOffs : uint;
					var vd : Vector.<Number>, nd : Vector.<Number>, ud : Vector.<Number>;
					
					subGeom = subGeometries[subIdx];
					vd = subGeom.vertexData;
					vStride = subGeom.vertexStride;
					vOffs = subGeom.vertexOffset;
					nd = subGeom.vertexNormalData;
					nStride = subGeom.vertexNormalStride;
					nOffs = subGeom.vertexNormalOffset;
					ud = subGeom.UVData;
					uStride = subGeom.UVStride;
					uOffs = subGeom.UVOffset;
					
					// Get (or create) a VO for this material
					vo = getSubGeomData(mesh.subMeshes[subIdx].material || mesh.material);
					
					// Vertices and normals are copied to temporary vectors, to be transformed
					// before concatenated onto those of the data. This is unnecessary if no
					// transformation will be performed, i.e. for object space merging.
					vertices = (_objectSpace)? vo.vertices : new Vector.<Number>();
					normals = (_objectSpace)? vo.normals : new Vector.<Number>();
					
					// Copy over vertex attributes
					vIdx = vertices.length;
					nIdx = normals.length;
					uIdx = vo.uvs.length;
					len = subGeom.numVertices;
					for (i=0; i<len; i++) {
						// Position
						vertices[vIdx++] = vd[vOffs + i*vStride + 0];
						vertices[vIdx++] = vd[vOffs + i*vStride + 1];
						vertices[vIdx++] = vd[vOffs + i*vStride + 2];
						
						// Normal
						normals[nIdx++] = nd[nOffs + i*nStride + 0];
						normals[nIdx++] = nd[nOffs + i*nStride + 1];
						normals[nIdx++] = nd[nOffs + i*nStride + 2];
						
						// UV
						vo.uvs[uIdx++] = ud[uOffs + i*uStride + 0];
						vo.uvs[uIdx++] = ud[uOffs + i*uStride + 1];
					}
					
					// Copy over triangle indices
					indexOffset = vo.vertices.length/3;
					iIdx = vo.indices.length;
					len = subGeom.numTriangles;
					for (i=0; i<len; i++) {
						vo.indices[iIdx++] = subGeom.indexData[i*3+0] + indexOffset;
						vo.indices[iIdx++] = subGeom.indexData[i*3+1] + indexOffset;
						vo.indices[iIdx++] = subGeom.indexData[i*3+2] + indexOffset;
					}
					
					if (!_objectSpace) {
						mesh.sceneTransform.transformVectors(vertices, vertices);
						mesh.sceneTransform.transformVectors(normals, normals);
						
						// Copy vertex data from temporary (transformed) vectors
						vIdx = vo.vertices.length;
						nIdx = vo.normals.length;
						len = vertices.length;
						for (i=0; i<len; i++) {
							vo.vertices[vIdx++] = vertices[i];
							vo.normals[nIdx++] = normals[i];
						}
					}
					
					_geomVOs.push(vo);
				}
				
				if (_disposeSources) {
					mesh.geometry.dispose();
				}
			}
		}
		
		
		private function getSubGeomData(material : MaterialBase) : GeometryVO
		{
			var data : GeometryVO;
			
			if (_keepMaterial) {
				var i : uint;
				var len : uint;
				
				len = _geomVOs.length;
				for (i=0; i<len; i++) {
					if (_geomVOs[i].material == material) {
						data = _geomVOs[i];
						break;
					}
				}
			}
			else if (_geomVOs.length) {
				// If materials are not to be kept, all data can be
				// put into a single VO, so return that one.
				data = _geomVOs[0];
			}
			
			// No data (for this material) found, create new.
			if (!data) {
				data = new GeometryVO();
				data.vertices = new Vector.<Number>();
				data.normals = new Vector.<Number>();
				data.uvs = new Vector.<Number>();
				data.indices = new Vector.<uint>();
				data.material = material;
			}
			
			return data;
		}
		
		private function parseContainer(object:ObjectContainer3D):void
		{
			var child:ObjectContainer3D;
			var i:uint;
			
			if(object is Mesh)
				collect(Mesh(object));
			
			for(i = 0;i<object.numChildren;++i){
				child = object.getChildAt(i);
				parseContainer(child);
			}
		}
	}
}

import away3d.materials.MaterialBase;

class GeometryVO {
	public var uvs:Vector.<Number>;
	public var vertices:Vector.<Number>;
	public var normals:Vector.<Number>;
	public var indices:Vector.<uint>;
	public var material:MaterialBase;
}