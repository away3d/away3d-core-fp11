package away3d.primitives
{
	import away3d.core.base.CompactSubGeometry;
	import away3d.arcane;
	import away3d.primitives.data.NURBSVertex;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * A NURBS primitive geometry.
	 */
	public class NURBSGeometry extends PrimitiveBase
	{
		private var _controlNet:Vector.<NURBSVertex>;
		private var _uOrder:Number;
		private var _vOrder:Number;
		private var _numVContolPoints:int;
		private var _numUContolPoints:int;
		private var _uSegments:int;
		private var _vSegments:int;
		private var _uKnotSequence:Vector.<Number>;
		private var _vKnotSequence:Vector.<Number>;
		private var _mbasis:Vector.<Number> = new Vector.<Number>();
		private var _nbasis:Vector.<Number> = new Vector.<Number>();
		private var _nplusc:int;
		private var _mplusc:int;
		private var _uRange:Number;
		private var _vRange:Number;
		private var _autoGenKnotSeq:Boolean = false;
		private var _invert:Boolean;
		private var _tmpPM:Vector3D = new Vector3D();
		private var _tmpP1:Vector3D = new Vector3D();
		private var _tmpP2:Vector3D = new Vector3D();
		private var _tmpN1:Vector3D = new Vector3D();
		private var _tmpN2:Vector3D = new Vector3D();
		private var _rebuildUVs : Boolean;

		/**
		 * Defines the control point net to describe the NURBS surface
		 */
		public function get controlNet():Vector.<NURBSVertex> {
			return _controlNet;
		}

		public function set controlNet(value:Vector.<NURBSVertex>):void {
			if (_controlNet == value)
				return;

			_controlNet = value;
			invalidateGeometry();
			invalidateUVs();
		}

		/**
		 * Defines the number of control points along the U splines that influence any given point on the curve
		 */
		public function get uOrder():int {
			return _uOrder;
		}

		public function set uOrder(value:int):void {
			if (_uOrder == value)
				return;

			_uOrder = value;
			invalidateGeometry();
			invalidateUVs();
		}

		/**
		 * Defines the number of control points along the V splines that influence any given point on the curve
		 */
		public function get vOrder():int {
			return _vOrder;
		}

		public function set vOrder(value:int):void {
			if (_vOrder == value)
				return;

			_vOrder = value;
			invalidateGeometry();
			invalidateUVs();
		}

		/**
		 * Defines the number of control points along the U splines
		 */
		public function get uControlPoints():int {
			return _numUContolPoints;
		}

		public function set uControlPoints(value:int):void {
			if (_numUContolPoints == value)
				return;

			_numUContolPoints = value;
			invalidateGeometry();
			invalidateUVs();
		}

		/**
		 * Defines the number of control points along the V splines
		 */
		public function get vControlPoints():int {
			return _numVContolPoints;
		}

		public function set vControlPoints(value:int):void {
			if (_numVContolPoints == value)
				return;

			_numVContolPoints = value;
			invalidateGeometry();
			invalidateUVs();
		}

		/**
		 * Defines the knot sequence in the U direction that determines where and how the control points
		 * affect the NURBS curve.
		 */
		public function get uKnot():Vector.<Number> {
			return _uKnotSequence;
		}

		public function set uKnot(value:Vector.<Number>):void {
			if (_uKnotSequence == value)
				return;

			_uKnotSequence = value;

			_autoGenKnotSeq = ((!_uKnotSequence || _uKnotSequence.length==0) || (!_vKnotSequence || _vKnotSequence.length==0));

			invalidateGeometry();
			invalidateUVs();
		}

		/**
		 * Defines the knot sequence in the V direction that determines where and how the control points
		 * affect the NURBS curve.
		 */
		public function get vKnot():Vector.<Number> {
			return _vKnotSequence;
		}

		public function set vKnot(value:Vector.<Number>):void {
			if (_vKnotSequence == value)
				return;

			_vKnotSequence = value;

			_autoGenKnotSeq = ((!_uKnotSequence || _uKnotSequence.length==0) || (!_vKnotSequence || _vKnotSequence.length==0));

			invalidateGeometry();
			invalidateUVs();
		}

		/**
		 * Defines the number segments (triangle pair) the final curve will be divided into in the U direction
		 */
		public function get uSegments():int {
			return _uSegments;
		}

		public function set uSegments(value:int):void {
			if (_uSegments == value)
				return;

			_uSegments = value;
			invalidateGeometry();
			invalidateUVs();
		}

		/**
		 * Defines the number segments (triangle pair) the final curve will be divided into in the V direction
		 */
		public function get vSegments():int {
			return _vSegments;
		}

		public function set vSegments(value:int):void {
			if (_vSegments == value)
				return;

			_vSegments = value;
			invalidateGeometry();
			invalidateUVs();
		}

		/**
		 * NURBS primitive generates a segmented mesh that fits the curved surface defined by the specified
		 * control points based on weighting, order influence and knot sequence
		 *
		 * @param cNet Array of control points (WeightedVertex array)
		 * @param uCtrlPnts Number of control points in the U direction
		 * @param vCtrlPnts Number of control points in the V direction
		 * @param init Init object for the mesh
		 *
		 */
		public function NURBSGeometry(cNet:Vector.<NURBSVertex>, uCtrlPnts:int, vCtrlPnts:int, uOrder:int = 4, vOrder:int = 4, uSegments:int = 10, vSegments:int = 10, uKnot:Vector.<Number> = null, vKnot:Vector.<Number> = null) {

			super();

			_controlNet = cNet;
			_numUContolPoints = uCtrlPnts;
			_numVContolPoints = vCtrlPnts;
			_uOrder = uOrder;
			_vOrder = vOrder;
			_uKnotSequence = uKnot;
			_vKnotSequence = vKnot;
			_uSegments = uSegments;
			_vSegments = vSegments;
			_nplusc = uCtrlPnts + _uOrder;
			_mplusc = vCtrlPnts + _vOrder;

			// Generate the open uniform knot vectors if not already defined
			_autoGenKnotSeq = ((!_uKnotSequence || _uKnotSequence.length==0) || (!_vKnotSequence || _vKnotSequence.length==0));

			_rebuildUVs = true;
			invalidateGeometry();
			invalidateUVs();
		}

		/** @private */
		private function nurbPoint(nU:Number, nV:Number, target:Vector3D = null) : Vector3D {
			var pbasis:Number;
			var jbas:int;
			var j1:int;
			var u:Number = _uKnotSequence[1] + (_uRange * nU);
			var v:Number = _vKnotSequence[1] + (_vRange * nV);

			if (target)
				target.setTo(0, 0, 0);
			else
				target = new Vector3D();

			if (_vKnotSequence[_mplusc] - v < 0.00005) v = _vKnotSequence[_mplusc];
			_mbasis = basis(_vOrder, v, _numVContolPoints, _vKnotSequence);    /* basis function for this value of w */
			if (_uKnotSequence[_nplusc] - u < 0.00005) u = _uKnotSequence[_nplusc];
			_nbasis = basis(_uOrder, u, _numUContolPoints, _uKnotSequence);    /* basis function for this value of u */

			var sum:Number = sumrbas();
			for (var i:int = 1; i <= _numVContolPoints; i++) {
				if (_mbasis[i] != 0) {
					jbas = _numUContolPoints * (i - 1);
					for (var j:int = 1; j <= _numUContolPoints; j++) {
						if (_nbasis[j] != 0) {
							j1 = jbas + j - 1;
							pbasis = _controlNet[j1].w * _mbasis[i] * _nbasis[j] / sum;
							target.x += _controlNet[j1].x * pbasis;  /* calculate surface point */
							target.y += _controlNet[j1].y * pbasis;
							target.z += _controlNet[j1].z * pbasis;
						}
					}
				}
			}

			return target;
		}

		/**
		 * Return a 3d point representing the surface point at the required U(0-1) and V(0-1) across the
		 * NURBS curved surface.
		 *
		 * @param uS				U position on the surface
		 * @param vS				V position on the surface
		 * @param vecOffset			Offset the point on the surface by this vector
		 * @param scale				Scale of the surface point - should match the Mesh scaling
		 * @param uTol				U tolerance for adjacent surface sample to calculate normal
		 * @param vTol				V tolerance for adjacent surface sample to calculate normal
		 * @return					The offset surface point being returned
		 *
		 */
		public function getSurfacePoint(uS:Number, vS:Number, vecOffset:Number = 0, scale:Number = 1, uTol:Number = 0.01, vTol:Number = 0.01):Vector3D {
			_tmpPM = nurbPoint(uS, vS);
			_tmpP1 = uS+uTol >= 1 ? nurbPoint(uS-uTol, vS) : nurbPoint(uS+uTol, vS);
			_tmpP2 = vS+vTol >= 1 ? nurbPoint(uS, vS-vTol) : nurbPoint(uS, vS+vTol);

			_tmpN1 = new Vector3D(_tmpP1.x - _tmpPM.x, _tmpP1.y - _tmpPM.y, _tmpP1.z - _tmpPM.z);
			_tmpN2 = new Vector3D(_tmpP2.x - _tmpPM.x, _tmpP2.y - _tmpPM.y, _tmpP2.z - _tmpPM.z);
			var sP:Vector3D = _tmpN2.crossProduct(_tmpN1);
			sP.normalize();
			sP.scaleBy(vecOffset);

			sP.x += _tmpPM.x * scale;
			sP.y += _tmpPM.y * scale;
			sP.z += _tmpPM.z * scale;

			return sP;

		}

		/** @private */
		private function sumrbas():Number {
			var i:int;
			var j:int;
			var jbas:int = 0;
			var j1:int = 0;
			var sum:Number;

			sum = 0;

			for (i = 1; i <= _numVContolPoints; i++) {
				if (_mbasis[i] != 0) {
					jbas = _numUContolPoints * (i - 1);
					for (j = 1; j <= _numUContolPoints; j++) {
						if (_nbasis[j] != 0) {
							j1 = jbas + j - 1;
							sum = sum + _controlNet[j1].w * _mbasis[i] * _nbasis[j];
						}
					}
				}
			}
			return sum;
		}

		/** @private */
		private function knot(n:int, c:int):Vector.<Number> {
			var nplusc:int = n + c;
			var nplus2:int = n + 2;
			var x:Vector.<Number> = new Vector.<Number>(36);

			x[1] = 0;
			for (var i:int = 2; i <= nplusc; i++) {
				if ((i > c) && (i < nplus2)) {
					x[i] = x[i - 1] + 1;
				} else {
					x[i] = x[i - 1];
				}
			}
			return x;
		}

		/** @private */
		private function basis(nurbOrder:int, t:Number, numPoints:int, knot:Vector.<Number>):Vector.<Number> {
			var nPlusO:int;
			var i:int;
			var k:int;
			var d:Number;
			var e:Number;
			var temp:Vector.<Number> = new Vector.<Number>(36);

			nPlusO = numPoints + nurbOrder;

			// calculate the first order basis functions n[i][1]
			for (i = 1; i<= nPlusO-1; i++)
				temp[i] = (( t >= knot[i]) && (t < knot[i+1])) ? 1 : 0;

			// calculate the higher order basis functions 
			for (k = 2; k <= nurbOrder; k++) {
				for (i = 1; i <= nPlusO-k; i++) {
					// if the lower order basis function is zero skip the calculation
					d = (temp[i] != 0) ? ((t - knot[i]) * temp[i]) / (knot[i + k - 1] - knot[i]) : 0;

					// if the lower order basis function is zero skip the calculation
					e=  (temp[i+1] != 0) ? ((knot[i + k] - t) * temp[i + 1]) / (knot[i + k] - knot[i + 1]) : 0;

					temp[i] = d + e;
				}
			}

			// pick up last point
			if (t == knot[nPlusO])
				temp[numPoints] = 1;

			return temp;
		}

		/**
		 *  Rebuild the mesh as there is significant change to the structural parameters
		 *
		 */
		override protected function buildGeometry(target : CompactSubGeometry):void
		{
			var data : Vector.<Number>;
			var stride : int = target.vertexStride;

			_nplusc = _numUContolPoints + _uOrder;
			_mplusc = _numVContolPoints + _vOrder;

			target.autoDeriveVertexNormals = true;
			target.autoDeriveVertexTangents = true;

			// Generate the open uniform knot vectors if not already defined
			if (_autoGenKnotSeq) _uKnotSequence = knot(_numUContolPoints, _uOrder);
			if (_autoGenKnotSeq) _vKnotSequence = knot(_numVContolPoints, _vOrder);
			_uRange = (_uKnotSequence[_nplusc] - _uKnotSequence[1]);
			_vRange = (_vKnotSequence[_mplusc] - _uKnotSequence[1]);

			// Define presets
			var numVertices:int = (_uSegments+1) * (_vSegments+1);
			var i:int;
			//var icount:int = 0;
			var j:int;

			var indices : Vector.<uint>;
			var numIndices : uint = target.vertexOffset;

			if (numVertices == target.numVertices) {
				data = target.vertexData;
				indices = target.indexData;
			} else {
				data = new Vector.<Number>(numVertices * stride, true);
				numIndices = (_uSegments) * (_vSegments) * 6;
				indices = new Vector.<uint>(numIndices, true);
				invalidateUVs();
			}

			// Iterate through the surface points (u=>0-1, v=>0-1)
			var stepuinc:Number = 1 / _uSegments;
			var stepvinc:Number = 1 / _vSegments;

			var vBase:int = 0;
			var nV:Vector3D;
			for (var vinc:Number = 0; vinc < (1+(stepvinc/2)); vinc+=stepvinc) {
				for (var uinc:Number = 0; uinc < (1+(stepuinc/2)); uinc+=stepuinc) {
					nV = nurbPoint(uinc, vinc);

					data[vBase] = nV.x;
					data[uint(vBase+1)] = nV.y;
					data[uint(vBase+2)] = nV.z;
					vBase += stride;
				}
			}

			// Render the mesh faces
			var vPos:int = 0;
			var iBase:int;

			for (i = 1; i <= _vSegments; i++) {
				for (j = 1; j <= _uSegments; j++) {
					if (_invert) {
						indices[iBase++] = vPos;
						indices[iBase++] = vPos+1;
						indices[iBase++] = vPos+_uSegments+1;

						indices[iBase++] = vPos+_uSegments+1;
						indices[iBase++] = vPos+1;
						indices[iBase++] = vPos+_uSegments+2;
					} else {
						indices[iBase++] = vPos+1;
						indices[iBase++] = vPos;
						indices[iBase++] = vPos+_uSegments+1;

						indices[iBase++] = vPos+1;
						indices[iBase++] = vPos+_uSegments+1;
						indices[iBase++] = vPos+_uSegments+2;
					}
					vPos++;
				}
				vPos++;
			}
			target.updateData(data);
			target.updateIndexData(indices);
		}

		/**
		 *  Rebuild the UV coordinates as there is significant change to the structural parameters
		 *
		 */
		override protected function buildUVs(target : CompactSubGeometry) : void
		{
			// Define presets
			var data : Vector.<Number>;
			var stride:uint = target.UVStride;
			var numVertices:int = (_uSegments+1) * (_vSegments+1);
			var uvLen:int = numVertices*stride;
			var i:int;
			var j:int;

			if (target.UVData && uvLen == target.UVData.length)
				data = target.UVData;
			else {
				data = new Vector.<Number>(uvLen, true);
				invalidateGeometry();
			}

			var uvBase:int = target.UVOffset;
			for (i = _vSegments; i >= 0; i--) {
				for (j = _uSegments; j >= 0; j--) {
					data[uint(uvBase)] = j/_uSegments;
					data[uint(uvBase+1)] = i/_vSegments;
					uvBase += stride;
				}
			}
			target.updateData(data);
			_rebuildUVs = false;
		}

		/**
		 *  Refresh the mesh without reconstructing all the supporting data. This should be used only
		 *  when the control point positions change.
		 *
		 */
		public function refreshNURBS():void {
			var nV:Vector3D = new Vector3D();
			var subGeom : CompactSubGeometry = CompactSubGeometry(subGeometries[0]);
			var data : Vector.<Number> = subGeom.vertexData;
			var len:int = data.length;
			var vertexStride : int = subGeom.vertexStride;
			var uvIndex : int = subGeom.UVOffset;
			var uvStride : int = subGeom.UVStride;

			for (var vBase:uint = subGeom.vertexOffset; vBase < len; vBase += vertexStride) {
				nurbPoint(data[uvIndex], data[uint(uvIndex + 1)], nV);
				data[vBase] = nV.x;
				data[uint(vBase+1)] = nV.y;
				data[uint(vBase+2)] = nV.z;
				uvIndex += uvStride;
			}

			subGeom.updateData(data);
		}
	}
}