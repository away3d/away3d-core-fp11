package away3d.tools.commands
{
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.SubGeometryBase;
	import away3d.core.base.TriangleSubGeometry;
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
				explodeSubGeom(geom.subGeometries[i] as TriangleSubGeometry, geom);
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
				child = object.getChildAt(i) as ObjectContainer3D;
				parse(child);
			}
		}
		
		private function explodeSubGeom(subGeom:TriangleSubGeometry, geom:Geometry):void
		{
			if(!subGeom) return;
			var i:uint;
			var len:uint;
			var inIndices:Vector.<uint>;
			var outIndices:Vector.<uint>;
			var positions:Vector.<Number>;
			var normals:Vector.<Number>;
			var uvs:Vector.<Number>;
			var vIdx:uint, uIdx:uint;
			var outSubGeoms:Vector.<SubGeometryBase>;
			
			var vStride:uint, nStride:uint, uStride:uint;
			var vOffs:uint, nOffs:uint, uOffs:uint;
			var vd:Vector.<Number>, nd:Vector.<Number>, ud:Vector.<Number>;
			
			vd = subGeom.positions;
			vStride = subGeom.getStride(TriangleSubGeometry.POSITION_DATA);
			vOffs = subGeom.getOffset(TriangleSubGeometry.POSITION_DATA);

			nd = subGeom.vertexNormals;
			nStride = subGeom.getStride(TriangleSubGeometry.NORMAL_DATA);
			nOffs = subGeom.getOffset(TriangleSubGeometry.NORMAL_DATA);

			ud = subGeom.uvs;
			uStride = subGeom.getStride(TriangleSubGeometry.UV_DATA);
			uOffs = subGeom.getOffset(TriangleSubGeometry.UV_DATA);

			inIndices = subGeom.indices;
			outIndices = new Vector.<uint>(inIndices.length, true);
			positions = new Vector.<Number>(inIndices.length*3, true);
			normals = new Vector.<Number>(inIndices.length*3, true);
			uvs = new Vector.<Number>(inIndices.length*2, true);
			
			vIdx = 0;
			uIdx = 0;
			len = inIndices.length;
			for (i = 0; i < len; i++) {
				var index:int;
				
				index = inIndices[i];
				positions[vIdx + 0] = vd[vOffs + index*vStride + 0];
				positions[vIdx + 1] = vd[vOffs + index*vStride + 1];
				positions[vIdx + 2] = vd[vOffs + index*vStride + 2];
				
				if (_keepNormals) {
					normals[vIdx + 0] = nd[nOffs + index*nStride + 0];
					normals[vIdx + 1] = nd[nOffs + index*nStride + 1];
					normals[vIdx + 2] = nd[nOffs + index*nStride + 2];
				} else
					normals[vIdx + 0] = normals[vIdx + 1] = normals[vIdx + 2] = 0;
				
				uvs[uIdx++] = ud[uOffs + index*uStride + 0];
				uvs[uIdx++] = ud[uOffs + index*uStride + 1];
				
				vIdx += 3;
				
				outIndices[i] = i;
			}
			
			outSubGeoms = GeomUtil.fromVectors(positions, outIndices, uvs, normals, null, null, null);
			geom.removeSubGeometry(subGeom);
			for (i = 0; i < outSubGeoms.length; i++) {
				subGeom = outSubGeoms[i] as TriangleSubGeometry;
				subGeom.autoDeriveNormals = !_keepNormals;
				geom.addSubGeometry(subGeom);
			}
		}
	}
}
