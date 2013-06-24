package away3d.tools.commands
{
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.ISubGeometry;
	import away3d.entities.Mesh;
	import away3d.tools.utils.GeomUtil;
	
	use namespace arcane;
	
	/**
	 * Class Explode make all vertices and uv's of a mesh unic<code>Explode</code>
	 */
	public class Explode
	{
		
		private var _keepNormals:Boolean;
		
		public function Explode()
		{
		}
		
		/**
		 *  Apply the explode code to a given ObjectContainer3D.
		 * @param     object                ObjectContainer3D. The target Object3d object.
		 * @param     keepNormals        Boolean. If the vertexNormals of the object are preserved. Default is true.
		 */
		public function applyToContainer(ctr:ObjectContainer3D, keepNormals:Boolean = true):void
		{
			_keepNormals = keepNormals;
			parse(ctr);
		}
		
		public function apply(geom:Geometry, keepNormals:Boolean = true):void
		{
			var i:uint;
			
			_keepNormals = keepNormals;
			
			for (i = 0; i < geom.subGeometries.length; i++)
				explodeSubGeom(geom.subGeometries[i], geom);
		}
		
		/**
		 * recursive parsing of a container.
		 */
		private function parse(object:ObjectContainer3D):void
		{
			var child:ObjectContainer3D;
			if (object is Mesh && object.numChildren == 0)
				apply(Mesh(object).geometry, _keepNormals);
			
			for (var i:uint = 0; i < object.numChildren; ++i) {
				child = object.getChildAt(i);
				parse(child);
			}
		}
		
		private function explodeSubGeom(subGeom:ISubGeometry, geom:Geometry):void
		{
			var i:uint;
			var len:uint;
			var inIndices:Vector.<uint>;
			var outIndices:Vector.<uint>;
			var vertices:Vector.<Number>;
			var normals:Vector.<Number>;
			var uvs:Vector.<Number>;
			var vIdx:uint, uIdx:uint;
			var outSubGeoms:Vector.<ISubGeometry>;
			
			var vStride:uint, nStride:uint, uStride:uint;
			var vOffs:uint, nOffs:uint, uOffs:uint;
			var vd:Vector.<Number>, nd:Vector.<Number>, ud:Vector.<Number>;
			
			vd = subGeom.vertexData;
			vStride = subGeom.vertexStride;
			vOffs = subGeom.vertexOffset;
			nd = subGeom.vertexNormalData;
			nStride = subGeom.vertexNormalStride;
			nOffs = subGeom.vertexNormalOffset;
			ud = subGeom.UVData;
			uStride = subGeom.UVStride;
			uOffs = subGeom.UVOffset;
			
			inIndices = subGeom.indexData;
			outIndices = new Vector.<uint>(inIndices.length, true);
			vertices = new Vector.<Number>(inIndices.length*3, true);
			normals = new Vector.<Number>(inIndices.length*3, true);
			uvs = new Vector.<Number>(inIndices.length*2, true);
			
			vIdx = 0;
			uIdx = 0;
			len = inIndices.length;
			for (i = 0; i < len; i++) {
				var index:int;
				
				index = inIndices[i];
				vertices[vIdx + 0] = vd[vOffs + index*vStride + 0];
				vertices[vIdx + 1] = vd[vOffs + index*vStride + 1];
				vertices[vIdx + 2] = vd[vOffs + index*vStride + 2];
				
				if (_keepNormals) {
					normals[vIdx + 0] = vd[nOffs + index*nStride + 0];
					normals[vIdx + 1] = vd[nOffs + index*nStride + 1];
					normals[vIdx + 2] = vd[nOffs + index*nStride + 2];
				} else
					normals[vIdx + 0] = normals[vIdx + 1] = normals[vIdx + 2] = 0;
				
				uvs[uIdx++] = ud[uOffs + index*uStride + 0];
				uvs[uIdx++] = ud[uOffs + index*uStride + 1];
				
				vIdx += 3;
				
				outIndices[i] = i;
			}
			
			outSubGeoms = GeomUtil.fromVectors(vertices, outIndices, uvs, normals, null, null, null);
			geom.removeSubGeometry(subGeom);
			for (i = 0; i < outSubGeoms.length; i++) {
				outSubGeoms[i].autoDeriveVertexNormals = !_keepNormals;
				geom.addSubGeometry(outSubGeoms[i]);
			}
		}
	}
}
