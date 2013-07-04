package away3d.tools.commands
{
	import away3d.containers.*;
	import away3d.core.base.*;
	import away3d.entities.*;
	import away3d.materials.*;
	import away3d.tools.utils.*;
	
	/**
	 *  Class Merge merges two or more static meshes into one.<code>Merge</code>
	 */
	public class Merge
	{
		
		//private const LIMIT:uint = 196605;
		private var _objectSpace:Boolean;
		private var _keepMaterial:Boolean;
		private var _disposeSources:Boolean;
		private var _geomVOs:Vector.<GeometryVO>;
		private var _toDispose:Vector.<Mesh>;
		
		/**
		 * @param    keepMaterial    [optional]    Determines if the merged object uses the recevier mesh material information or keeps its source material(s). Defaults to false.
		 * If false and receiver object has multiple materials, the last material found in receiver submeshes is applied to the merged submesh(es).
		 * @param    disposeSources  [optional]    Determines if the mesh and geometry source(s) used for the merging are disposed. Defaults to false.
		 * If true, only receiver geometry and resulting mesh are kept in  memory.
		 * @param    objectSpace     [optional]    Determines if source mesh(es) is/are merged using objectSpace or worldspace. Defaults to false.
		 */
		function Merge(keepMaterial:Boolean = false, disposeSources:Boolean = false, objectSpace:Boolean = false):void
		{
			_keepMaterial = keepMaterial;
			_disposeSources = disposeSources;
			_objectSpace = objectSpace;
		}
		
		/**
		 * Determines if the mesh and geometry source(s) used for the merging are disposed. Defaults to false.
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
		 * Determines if the material source(s) used for the merging are disposed. Defaults to false.
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
		 * Determines if source mesh(es) is/are merged using objectSpace or worldspace. Defaults to false.
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
		 * Merges all the children of a container into a single Mesh. If no Mesh object is found, method returns the receiver without modification.
		 *
		 * @param    receiver           The Mesh to receive the merged contents of the container.
		 * @param    objectContainer    The ObjectContainer3D holding the meshes to be mergd.
		 *
		 * @return The merged Mesh instance.
		 */
		public function applyToContainer(receiver:Mesh, objectContainer:ObjectContainer3D):void
		{
			reset();
			
			//collect container meshes
			parseContainer(receiver, objectContainer);
			
			//collect receiver
			collect(receiver, false);
			
			//merge to receiver
			merge(receiver, _disposeSources);
		}
		
		/**
		 * Merges all the meshes found in the Vector.&lt;Mesh&gt; into a single Mesh.
		 *
		 * @param    receiver    The Mesh to receive the merged contents of the meshes.
		 * @param    meshes      A series of Meshes to be merged with the reciever mesh.
		 */
		public function applyToMeshes(receiver:Mesh, meshes:Vector.<Mesh>):void
		{
			reset();
			
			if (!meshes.length)
				return;
			
			//collect meshes in vector
			for (var i:uint = 0; i < meshes.length; i++)
				if (meshes[i] != receiver)
					collect(meshes[i], _disposeSources);
			
			//collect receiver
			collect(receiver, false);
			
			//merge to receiver
			merge(receiver, _disposeSources);
		}
		
		/**
		 *  Merges 2 meshes into one. It is recommand to use apply when 2 meshes are to be merged. If more need to be merged, use either applyToMeshes or applyToContainer methods.
		 *
		 * @param    receiver    The Mesh to receive the merged contents of both meshes.
		 * @param    mesh        The Mesh to be merged with the receiver mesh
		 */
		public function apply(receiver:Mesh, mesh:Mesh):void
		{
			reset();
			
			//collect mesh
			collect(mesh, _disposeSources);
			
			//collect receiver
			collect(receiver, false);
			
			//merge to receiver
			merge(receiver, _disposeSources);
		}
		
		private function reset():void
		{
			_toDispose  = new Vector.<Mesh>();
			_geomVOs = new Vector.<GeometryVO>();
		}
		
		private function merge(destMesh:Mesh, dispose:Boolean):void
		{
			var i:uint;
			var subIdx:uint;
			var oldGeom:Geometry
			var destGeom:Geometry;
			var useSubMaterials:Boolean;
			
			oldGeom = destMesh.geometry;
			destGeom = destMesh.geometry = new Geometry();
			subIdx = destMesh.subMeshes.length;
			
			// Only apply materials directly to sub-meshes if necessary,
			// i.e. if there is more than one material available.
			useSubMaterials = (_geomVOs.length > 1);
			
			for (i = 0; i < _geomVOs.length; i++) {
				var s:uint;
				var data:GeometryVO;
				var subs:Vector.<ISubGeometry>;
				
				data = _geomVOs[i];
				subs = GeomUtil.fromVectors(data.vertices, data.indices, data.uvs, data.normals, null, null, null);
				
				for (s = 0; s < subs.length; s++) {
					destGeom.addSubGeometry(subs[s]);
					
					if (_keepMaterial && useSubMaterials)
						destMesh.subMeshes[subIdx].material = data.material;
					
					subIdx++;
				}
			}
			
			if (_keepMaterial && !useSubMaterials && _geomVOs.length)
				destMesh.material = _geomVOs[0].material;
				
			if (dispose) {
				for each (var m:Mesh in _toDispose) {
					m.geometry.dispose();
					m.dispose();
				}
				
				//dispose of the original receiver geometry
				oldGeom.dispose();
			}
			
			_toDispose = null;
		}
		
		private function collect(mesh:Mesh, dispose:Boolean):void
		{
			if (mesh.geometry) {
				var subIdx:uint;
				var subGeometries:Vector.<ISubGeometry> = mesh.geometry.subGeometries;
				var calc:uint;
				for (subIdx = 0; subIdx < subGeometries.length; subIdx++) {
					var i:uint;
					var len:uint;
					var iIdx:uint, vIdx:uint, nIdx:uint, uIdx:uint;
					var indexOffset:uint;
					var subGeom:ISubGeometry;
					var vo:GeometryVO;
					var vertices:Vector.<Number>;
					var normals:Vector.<Number>;
					var vStride:uint, nStride:uint, uStride:uint;
					var vOffs:uint, nOffs:uint, uOffs:uint;
					var vd:Vector.<Number>, nd:Vector.<Number>, ud:Vector.<Number>;
					
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
					for (i = 0; i < len; i++) {
						// Position
						calc = vOffs + i*vStride;
						vertices[vIdx++] = vd[calc];
						vertices[vIdx++] = vd[calc + 1];
						vertices[vIdx++] = vd[calc + 2];
						
						// Normal
						calc = nOffs + i*nStride;
						normals[nIdx++] = nd[calc];
						normals[nIdx++] = nd[calc + 1];
						normals[nIdx++] = nd[calc + 2];
						
						// UV
						calc = uOffs + i*uStride;
						vo.uvs[uIdx++] = ud[calc];
						vo.uvs[uIdx++] = ud[calc + 1];
					}
					
					// Copy over triangle indices
					indexOffset = (!_objectSpace)? vo.vertices.length/3 :0;
					iIdx = vo.indices.length;
					len = subGeom.numTriangles;
					for (i = 0; i < len; i++) {
						calc = i*3;
						vo.indices[iIdx++] = subGeom.indexData[calc] + indexOffset;
						vo.indices[iIdx++] = subGeom.indexData[calc + 1] + indexOffset;
						vo.indices[iIdx++] = subGeom.indexData[calc + 2] + indexOffset;
					}
					
					if (!_objectSpace) {
						mesh.sceneTransform.transformVectors(vertices, vertices);
						mesh.sceneTransform.transformVectors(normals, normals);
						
						// Copy vertex data from temporary (transformed) vectors
						vIdx = vo.vertices.length;
						nIdx = vo.normals.length;
						len = vertices.length;
						for (i = 0; i < len; i++) {
							vo.vertices[vIdx++] = vertices[i];
							vo.normals[nIdx++] = normals[i];
						}
					}
				}
				
				if (dispose)
					_toDispose.push(mesh);
			}
		}
		
		private function getSubGeomData(material:MaterialBase):GeometryVO
		{
			var data:GeometryVO;
			
			if (_keepMaterial) {
				var i:uint;
				var len:uint;
				
				len = _geomVOs.length;
				for (i = 0; i < len; i++) {
					if (_geomVOs[i].material == material) {
						data = _geomVOs[i];
						break;
					}
				}
			} else if (_geomVOs.length) {
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
				
				_geomVOs.push(data);
			}
			
			return data;
		}
		
		private function parseContainer(receiver:Mesh, object:ObjectContainer3D):void
		{
			var child:ObjectContainer3D;
			var i:uint;
			
			if (object is Mesh && object != receiver)
				collect(Mesh(object), _disposeSources);
			
			for (i = 0; i < object.numChildren; ++i) {
				child = object.getChildAt(i);
				parseContainer(receiver, child);
			}
		}
	}
}

import away3d.materials.MaterialBase;

class GeometryVO
{
	public var uvs:Vector.<Number>;
	public var vertices:Vector.<Number>;
	public var normals:Vector.<Number>;
	public var indices:Vector.<uint>;
	public var material:MaterialBase;
	
	public function GeometryVO()
	{
	}
}
