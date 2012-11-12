package away3d.tools.commands
{
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.CompactSubGeometry;
	import away3d.core.base.Geometry;
	import away3d.core.base.ISubGeometry;
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
		
		//private static var _delv:uint;
		
		private var _keepUvs : Boolean;
		private var _normalThreshold : Number;
		
		public function Weld()
		{
		}
		
		
		public function apply(geom : Geometry, keepUvs : Boolean = true, normalAngleThresholdRadians : Number = 0) : void
		{
			_keepUvs = keepUvs;
			_normalThreshold = normalAngleThresholdRadians;
			applyToGeom(geom);
		}
		
		
		public function applyToContainer(obj : ObjectContainer3D, keepUVs : Boolean = true, normalThreshold : Number = 0):void
		{
			//_delv = 0;
			_keepUvs = keepUVs;
			_normalThreshold = normalThreshold;
			parse(obj);
		}
		
		/**
		* returns howmany vertices were deleted during the welding operation.
		*/
		/*
		public static function get verticesRemovedCount():uint
		{
			return _delv;
		}
		*/
		 
		private function parse(obj:ObjectContainer3D):void
		{
			var child:ObjectContainer3D;
			if(obj is Mesh && obj.numChildren == 0)
				applyToGeom(Mesh(obj).geometry);
				 
			for(var i:uint = 0;i<obj.numChildren;++i){
				child = obj.getChildAt(i);
				parse(child);
			}
		}
		
		
		private function applyToGeom(geom : Geometry) : void
		{
			var i : uint;
			
			for (i=0; i<geom.subGeometries.length; i++) {
				var subGeom : ISubGeometry = geom.subGeometries[i];
				
				// TODO: Remove this check when ISubGeometry can always
				// be updated using a single unified method (from vectors.)
				if (subGeom is CompactSubGeometry) {
					applyToSubGeom(subGeom, CompactSubGeometry(subGeom));
				}
				else {
					var outSubGeom : CompactSubGeometry;
					
					outSubGeom = new CompactSubGeometry();
					applyToSubGeom(subGeom, outSubGeom);
					
					geom.removeSubGeometry(subGeom);
					geom.addSubGeometry(outSubGeom);
				}
			}
		}
		
		
		private function applyToSubGeom(subGeom : ISubGeometry, outSubGeom : CompactSubGeometry) : void
		{
			var i : uint;
			var inLen : uint;
			var outVertices : Vector.<Number>;
			var outNormals : Vector.<Number>;
			var outUvs : Vector.<Number>;
			var inIndices : Vector.<uint>;
			var outIndices : Vector.<uint>;
			var numOutIndices : uint;
			
			var vStride : uint, nStride : uint, uStride : uint;
			var vOffs : uint, nOffs : uint, uOffs : uint;
			var vd : Vector.<Number>, nd : Vector.<Number>, ud : Vector.<Number>;
			
			vd = subGeom.vertexData;
			vStride = subGeom.vertexStride;
			vOffs = subGeom.vertexOffset;
			nd = subGeom.vertexNormalData;
			nStride = subGeom.vertexNormalStride;
			nOffs = subGeom.vertexNormalOffset;
			ud = subGeom.UVData;
			uStride = subGeom.UVStride;
			uOffs = subGeom.UVOffset;
			
			outIndices = new Vector.<uint>();
			outVertices = new Vector.<Number>();
			outNormals = new Vector.<Number>();
			outUvs = new Vector.<Number>();
			
			numOutIndices = 0;
			inIndices = subGeom.indexData;
			inLen = inIndices.length;
			for (i=0; i<inLen; i++) {
				var origIndex : uint;
				var searchIndex : uint;
				var searchLen : uint;
				var outIndex : int;
				var px : Number, py : Number, pz : Number;
				var nx : Number, ny : Number, nz : Number;
				var u : Number, v : Number;
				
				origIndex = inIndices[i];
				px = vd[vOffs + origIndex*vStride + 0];
				py = vd[vOffs + origIndex*vStride + 1];
				pz = vd[vOffs + origIndex*vStride + 2];
				nx = nd[nOffs + origIndex*nStride + 0];
				ny = nd[nOffs + origIndex*nStride + 1];
				nz = nd[nOffs + origIndex*nStride + 2];
				u = ud[uOffs + origIndex*uStride + 0];
				v = ud[uOffs + origIndex*uStride + 1];
				
				outIndex = -1;
				searchLen = outVertices.length / 3;
				for (searchIndex=0; searchIndex<searchLen; searchIndex++) {
					// Skip if position doesn't match
					if (px != outVertices[searchIndex*3+0] || py != outVertices[searchIndex*3+1] || pz != outVertices[searchIndex*3+2])
						continue;
					
					// Skip if UVs don't match (but only if UVs are to be respected at all)
					if (_keepUvs && (u != outUvs[searchIndex*2+0] || v != outUvs[searchIndex*2+1]))
						continue;
					
					if (_normalThreshold>0) {
						var dp : Number;
						var angle : Number;
						
						// Calculate dot product, assuming normalized vector
						dp = nx * outNormals[searchIndex*3+0] + ny * outNormals[searchIndex*3+1] + nz * outNormals[searchIndex*3+2];
						angle = Math.acos(dp);
						if (angle > _normalThreshold)
							continue;
					}
					else if (nx != outNormals[searchIndex*3+0] || ny != outNormals[searchIndex*3+1] || nz != outNormals[searchIndex*3+2]) {
						// No threshold for normals, i.e. they have to be identical. Since they
						// are not identical, skip this
						continue;
					}
					
					// If this far, the vertices match
					outIndex = searchIndex;
					break;
				}
				
				// No vertex found, so create it
				if (outIndex < 0) {
					outIndex = outVertices.length/3;
					outVertices[outIndex*3+0] = px;
					outVertices[outIndex*3+1] = py;
					outVertices[outIndex*3+2] = pz;
					outNormals[outIndex*3+0] = nx;
					outNormals[outIndex*3+1] = ny;
					outNormals[outIndex*3+2] = nz;
					outUvs[outIndex*2+0] = u;
					outUvs[outIndex*2+1] = v;
				}
				
				outIndices[numOutIndices++] = outIndex;
			}
			
			outSubGeom.fromVectors(outVertices, outUvs, outNormals, null);
			outSubGeom.updateIndexData(outIndices);
		}
	}
}