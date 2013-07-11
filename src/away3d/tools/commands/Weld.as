package away3d.tools.commands
{
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.CompactSubGeometry;
	import away3d.core.base.Geometry;
	import away3d.core.base.ISubGeometry;
	import away3d.core.math.MathConsts;
	import away3d.entities.Mesh;
	
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	use namespace arcane;
	
	/**
	 * Class Weld removes the vertices that can be shared from one or more meshes (smoothes the mesh surface when lighted).
	 */
	public class Weld
	{
		
		public static const USE_VERTEXNORMALS:String = "UseVertexNormals";
		public static const USE_FACENORMALS:String = "UseFaceNormals";
		
		private var _keepUvs:Boolean;
		private var _normalThreshold:Number;
		private var _useNormalMode:String;
		private var _smoothNormals:Boolean;
		private var _vertCnt:int;
		
		function Weld()
		{
		}
		
		/**
		 * Perfoms a weld operation on a specified mesh geometry.
		 *
		 * @param mesh            The mesh to weld
		 * @param keepUVs            If the uvs should be kept as defined. Default is true.
		 * @param normalAngleDegree    Threshold to compair the normals. Default is 180.
		 * @param useNormalMode        If the face normals or vertex normals are used for comparison. VERTEXNORMALS keeps intact the original data. Default uses USE_FACENORMALS.
		 * @param smoothNormals        Smooth. Default is true.
		 */
		public function apply(mesh:Mesh, keepUvs:Boolean = true, normalAngleDegree:Number = 180, useNormalMode:String = USE_FACENORMALS, smoothNormals:Boolean = true):void
		{
			_keepUvs = keepUvs;
			_useNormalMode = useNormalMode;
			_smoothNormals = smoothNormals;
			_normalThreshold = normalAngleDegree*MathConsts.DEGREES_TO_RADIANS;
			_vertCnt = applyToGeom(mesh.geometry);
		}
		
		/**
		 * Perfoms a weld operation on all children Mesh object geometries of the specified ObjectContainer3D.
		 *
		 * @param obj                The ObjectContainer3D to weld
		 * @param keepUVs            If the uvs should be kept as defined. Default is true.
		 * @param normalAngleDegree    Threshold to compair the normals. Default is 180.
		 * @param useNormalMode        If the face normals or vertex normals are used for comparison. VERTEXNORMALS keeps intact the original data. Default uses USE_FACENORMALS.
		 * @param smoothNormals        Smooth. Default is true.
		 */
		public function applyToContainer(obj:ObjectContainer3D, keepUVs:Boolean = true, normalAngleDegree:Number = 180, useNormalMode:String = USE_FACENORMALS, smoothNormals:Boolean = true):void
		{
			_keepUvs = keepUVs;
			_useNormalMode = useNormalMode;
			_smoothNormals = smoothNormals;
			_normalThreshold = normalAngleDegree*MathConsts.DEGREES_TO_RADIANS;
			_vertCnt = parse(obj);
		}
		
		/**
		 * returns howmany vertices were deleted during the welding operation.
		 */
		public function get verticesRemovedCount():uint
		{
			if (isNaN(_vertCnt))
				return 0;
			
			return (_vertCnt > 0)? _vertCnt : 0;
		}
		
		/**
		 * returns howmany vertices were added during the welding operation.
		 */
		public function get verticesAddedCount():uint
		{
			if (isNaN(_vertCnt))
				return 0;
			
			return (_vertCnt < 0)? Math.abs(_vertCnt) : 0;
		}
		
		private function parse(obj:ObjectContainer3D):int
		{
			var removedVertCnt:int = 0;
			var child:ObjectContainer3D;
			if (obj is Mesh && obj.numChildren == 0)
				removedVertCnt += applyToGeom(Mesh(obj).geometry);
			
			for (var i:uint = 0; i < obj.numChildren; ++i) {
				child = obj.getChildAt(i);
				removedVertCnt += parse(child);
			}
			
			return removedVertCnt;
		}
		
		private function applyToGeom(geom:Geometry):int
		{
			var removedVertsCnt:int = 0;
			var outSubGeom:CompactSubGeometry;
			
			for (var i:uint = 0; i < geom.subGeometries.length; i++) {
				var subGeom:ISubGeometry = geom.subGeometries[i];
				
				// TODO: Remove this check when ISubGeometry can always
				// be updated using a single unified method (from vectors.)
				if (subGeom is CompactSubGeometry)
					removedVertsCnt += applyToSubGeom(subGeom, CompactSubGeometry(subGeom));
				
				else {
					
					outSubGeom = new CompactSubGeometry();
					removedVertsCnt += applyToSubGeom(subGeom, outSubGeom);
					
					geom.removeSubGeometry(subGeom);
					geom.addSubGeometry(outSubGeom);
				}
			}
			
			return removedVertsCnt;
		}
		
		private function applyToSubGeom(subGeom:ISubGeometry, outSubGeom:CompactSubGeometry):int
		{
			var maxNormalIdx:int = 0;
			var oldVerticleCount:uint = subGeom.numVertices;
			var i:uint;
			var numOutIndices:uint = 0;
			var searchStringFinal:String;
			
			var vStride:uint, nStride:uint, uStride:uint;
			var vOffs:uint, nOffs:uint, uOffs:uint, sn:uint;
			var vd:Vector.<Number>, nd:Vector.<Number>, ud:Vector.<Number>;
			var sharedNormalsDic:Dictionary = new Dictionary();
			var outnormal:Vector3D = new Vector3D();
			
			vd = subGeom.vertexData;
			vStride = subGeom.vertexStride;
			vOffs = subGeom.vertexOffset;
			nd = subGeom.vertexNormalData;
			nStride = subGeom.vertexNormalStride;
			nOffs = subGeom.vertexNormalOffset;
			ud = subGeom.UVData;
			uStride = subGeom.UVStride;
			uOffs = subGeom.UVOffset;
			
			var sharedNormalIndices:Vector.<int> = new Vector.<int>();
			var outVertices:Vector.<Number> = new Vector.<Number>();
			var outNormals:Vector.<Number> = new Vector.<Number>();
			var outUvs:Vector.<Number> = new Vector.<Number>();
			var inIndices:Vector.<uint> = subGeom.indexData;
			var outIndices:Vector.<uint> = new Vector.<uint>();
			var oldTargetNormals:Vector.<Vector3D> = new Vector.<Vector3D>();
			var sharedPointNormals:Vector.<Vector.<Vector3D>> = new Vector.<Vector.<Vector3D>>();
			
			var usedVertices:Dictionary = new Dictionary();
			var searchString:String = "";
			var inLen:uint = inIndices.length;
			var faceNormals:Vector.<Number> = subGeom.faceNormals;
			var faceIdx:uint = 0;
			var faceIdxCnt:uint = 3;
			var targetNormal:Vector3D;
			var storedFaceNormal:Vector3D;
			var sharedNormalIndex:int;
			var origIndex:uint;
			var foundNormalsCnt:uint = 0;
			var searchforNormal:Boolean = true;
			//var searchIndex : uint;
			//var searchLen : uint;
			var outIndex:int;
			var curangle:Number;
			var dp:Number;
			var px:Number, py:Number, pz:Number;
			var nx:Number, ny:Number, nz:Number;
			var u:Number, v:Number;
			var difUvs:Boolean;
			
			for (i = 0; i < inLen; i++) {
				origIndex = inIndices[i];
				sharedNormalIndex = -1;
				px = vd[vOffs + origIndex*vStride + 0];
				py = vd[vOffs + origIndex*vStride + 1];
				pz = vd[vOffs + origIndex*vStride + 2];
				nx = nd[nOffs + origIndex*nStride + 0];
				ny = nd[nOffs + origIndex*nStride + 1];
				nz = nd[nOffs + origIndex*nStride + 2];
				u = ud[uOffs + origIndex*uStride + 0];
				v = ud[uOffs + origIndex*uStride + 1];
				
				// set the targetNormalVector, dependend on the "_useNormalMode" (use vertexNormals or FaceNormals for calculation of the angle between two vertices)
				// USE_VERTEXNORMALS allows to keep intact the old VertexNormal-Data
				// USE_FACENORMALS allow to use the weld function not only for reducing the vertex-count, but will modify the mesh, so it will display phong-breaks, even if the vertex-count will increase.
				if (_useNormalMode == USE_VERTEXNORMALS)
					targetNormal = new Vector3D(nx, ny, nz);
				
				if (_useNormalMode == USE_FACENORMALS) {
					if (faceIdxCnt >= 3) { //on each thrird iteration, we store  the facenormal of the current face into targetNormal
						faceIdxCnt = 0;
						targetNormal = new Vector3D(faceNormals[faceIdx], faceNormals[faceIdx + 1], faceNormals[faceIdx + 2]);
						faceIdx += 3;
					}
					
					faceIdxCnt += 1;
				}
				
				searchString = "#" + px + "#" + py + "#" + pz + "#";
				searchStringFinal = searchString + "0";
				outIndex = -1;
				
				if (usedVertices[searchStringFinal] != undefined) {
					
					outIndex = usedVertices[searchStringFinal];
					foundNormalsCnt = 0;
					searchforNormal = true;
					difUvs = false;
					
					while (searchforNormal) {
						// if this is not the first iteration over the while-loopm, reset the "outIndex" and create searchString for new Dictionary-lookup.
						if (foundNormalsCnt > 0) {
							outIndex = -1;
							searchStringFinal = searchString + String(foundNormalsCnt);
						}
						
						if (usedVertices[searchStringFinal] != undefined) {
							outIndex = usedVertices[searchStringFinal];
							storedFaceNormal = oldTargetNormals[outIndex]; // get the Normal-Vector of this allready-existing vertex. (if _useNormalMode==USE_FACENORMALS, this Normal is the Facenormal off the face, the vertex is used by) 
							// calculate the angle between the normals of the two vertices.
							dp = storedFaceNormal.x*targetNormal.x + storedFaceNormal.y*targetNormal.y + storedFaceNormal.z*targetNormal.z;
							curangle = (Math.acos(dp));
							difUvs = false;
							
							//if uv should kept intact, check if this must be a new vertex or can be shared (because of uv)
							if (_keepUvs && (u != outUvs[outIndex*2 + 0]) || (v != outUvs[outIndex*2 + 1]))
								difUvs = true;
							
							if (curangle < _normalThreshold) {
								
								// if the angle is smaller than the threshold, but has different uv, the vertex cannot be merged, 
								// but the normals should have the same values, so we set he "normalIndex" of this vertex to be the "normalIndex" of the vertex it would get merged with, if uv would not differ.
								if (difUvs)
									sharedNormalIndex = outIndex;
								else {
									// if the angle is smaller than the threshold and uv is the same, the vertex can be merged, stop the while loop by setting searchforNormal to false
									searchforNormal = false;
								}
								sharedPointNormals[outIndex].push(targetNormal); //add the normal to the sharedPointNormals-list (to calculate the shared normal later)
								
									// if the angle is bigger than our treshold, the verticles will not be merged, and the normals for both verticles should have their own unique values too.
									// we do nothing, but keep searching for another allready parsed point, thats on the same position (increment "foundNormalsCnt", add it to the searchstring, and check if this exists)  
									// if no other vertex at the same scene-position exists, the outindex will have been put back to -1, so a new verticle will be created.
									//if (curangle >= _normalThreshold) {}
							}
						}
						if (outIndex < 0)
							searchforNormal = false;
						
						foundNormalsCnt++;
					}
				}
				// No vertex found, so create it
				if (outIndex < 0) {
					outIndex = outVertices.length/3;
					
					if (sharedNormalIndex < 0) {
						sharedNormalIndex = outIndex;
						maxNormalIdx = outIndex;
					}
					
					oldTargetNormals[outIndex] = targetNormal;
					sharedPointNormals[outIndex] = new Vector.<Vector3D>;
					sharedPointNormals[outIndex][0] = targetNormal;
					usedVertices[searchStringFinal] = outIndex;
					sharedNormalIndices[outIndex] = sharedNormalIndex;
					outVertices[outIndex*3 + 0] = px;
					outVertices[outIndex*3 + 1] = py;
					outVertices[outIndex*3 + 2] = pz;
					outNormals[outIndex*3 + 0] = targetNormal.x;
					outNormals[outIndex*3 + 1] = targetNormal.y;
					outNormals[outIndex*3 + 2] = targetNormal.z;
					outUvs[outIndex*2 + 0] = u;
					outUvs[outIndex*2 + 1] = v;
				}
				
				outIndices[numOutIndices++] = outIndex;
			}
			
			// calculated (and apply) the shared Normals:
			if (_normalThreshold > 0 && _smoothNormals) {
				
				var sharedPointsfinalDic:Dictionary = new Dictionary();
				//stores all Normal-vectors that have already been calculated
				var sharedPointsfinalVectors:Vector.<Vector3D> = new Vector.<Vector3D>();
				var foundVector:int;
				var curIdx:int;
				inLen = outVertices.length/3;
				
				for (i = 0; i < inLen; i++) {
					outnormal = new Vector3D();
					foundVector = -1;
					curIdx = sharedNormalIndices[i];
					// the curIdx could point to list-position, thats pointing to another shared-Normal again, 
					//so we need to make shure, we follow the redirection until we get a normal-index smaller than maxNormalIdx
					while (curIdx > maxNormalIdx)
						curIdx = sharedNormalIndices[curIdx];
					if (sharedPointsfinalDic[curIdx.toString()] != undefined) {
						foundVector = sharedPointsfinalDic[curIdx.toString()];
						outnormal = sharedPointsfinalVectors[foundVector];
					}
					
					if (foundVector < 0) {
						
						sharedNormalsDic = new Dictionary();
						foundNormalsCnt = 0;
						
						for (sn = 0; sn < sharedPointNormals[curIdx].length; sn++) {
							
							if (sharedNormalsDic[sharedPointNormals[curIdx][sn].toString()] != undefined)
								continue;
							
							foundNormalsCnt++;
							sharedNormalsDic[sharedPointNormals[curIdx][sn].toString()] = 1;
							outnormal.x += sharedPointNormals[curIdx][sn].x;
							outnormal.y += sharedPointNormals[curIdx][sn].y;
							outnormal.z += sharedPointNormals[curIdx][sn].z;
						}
						
						outnormal.x /= foundNormalsCnt;
						outnormal.y /= foundNormalsCnt;
						outnormal.z /= foundNormalsCnt;
						
						sharedPointsfinalDic[curIdx.toString()] = sharedPointsfinalVectors.length;
						sharedPointsfinalVectors[sharedPointsfinalVectors.length] = outnormal;
					}
					
					outNormals[i*3] = outnormal.x;
					outNormals[i*3 + 1] = outnormal.y;
					outNormals[i*3 + 2] = outnormal.z;
				}
			}
			
			outSubGeom.fromVectors(outVertices, outUvs, outNormals, null);
			outSubGeom.updateIndexData(outIndices);
			
			return int(oldVerticleCount - outSubGeom.numVertices);
		}
	
	}
}
