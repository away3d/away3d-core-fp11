package away3d.tools.commands
{
	import away3d.arcane;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.ISubGeometry;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.data.UV;
	import away3d.core.base.data.Vertex;
	import away3d.entities.Mesh;
	import away3d.tools.utils.Bounds;
	
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	use namespace arcane;
	
	/**
	 * Class SphereMaker transforms a Mesh into a Sphere unic<code>SphereMaker</code>
	 */
	public class SphereMaker
	{
		
		public static const RADIUS:int = 1;
		public static const USE_BOUNDS_MAX:int = 2;
		private var _weight:Number;
		private var _radius:Number;
		private var _radiusMode:int;
		
		public function SphereMaker()
		{
		}
		
		/**
		 *  Apply the SphereMaker code to a given ObjectContainer3D.
		 * @param     container            Mesh. The target ObjectContainer3D.
		 * @param     weight                Number. The Strength of the effect between 0 and 1. Default is 1.
		 * @param     radiusMode            int. Defines which radius will be used. Can be RADIUS or USE_BOUNDS_MAX. Default is RADIUS
		 * @param     radius                Number. The Radius to use if radiusMode is RADIUS. Default is 100.
		 */
		public function applyToContainer(ctr:ObjectContainer3D, weight:Number = 1, radiusMode:int = RADIUS, radius:Number = 100):void
		{
			_weight = weight;
			_radiusMode = radiusMode;
			_radius = radius;
			parse(ctr);
		}
		
		/**
		 *  Apply the SphereMaker code to a given Mesh.
		 * @param     mesh                Mesh. The target Mesh object.
		 * @param     weight                Number. The Strength of the effect between 0 and 1. Default is 1.
		 * @param     radiusMode            int. Defines which radius will be used. Can be RADIUS or USE_BOUNDS_MAX. Default is RADIUS
		 * @param     radius                Number. The Radius to use if radiusMode is RADIUS. Default is 100.
		 */
		public function apply(mesh:Mesh, weight:Number = 1, radiusMode:int = RADIUS, radius:Number = 100):void
		{
			var i:uint;
			
			_weight = weight;
			_radiusMode = radiusMode;
			_radius = radius;
			
			if (_weight < 0)
				_weight = 0;
			if (_weight > 1)
				_weight = 1;
			if (_radiusMode == USE_BOUNDS_MAX) {
				var meshBounds:BoundingVolumeBase = mesh.bounds;
				var vectorMax:Vector3D = new Vector3D(meshBounds.max.x, meshBounds.max.y, meshBounds.max.z);
				var vectorMin:Vector3D = new Vector3D(meshBounds.min.x, meshBounds.min.y, meshBounds.min.z);
				var vectorMaxlength:Number = vectorMax.length;
				var vectorMinlength:Number = vectorMin.length;
				_radius = vectorMaxlength;
				if (_radius < vectorMinlength)
					_radius = vectorMinlength;
			}
			for (i = 0; i < mesh.geometry.subGeometries.length; i++)
				spherizeSubGeom(mesh.geometry.subGeometries[i]);
		}
		
		private function parse(object:ObjectContainer3D):void
		{
			var child:ObjectContainer3D;
			if (object is Mesh)
				apply(Mesh(object), _weight, _radiusMode, _radius);
			
			for (var i:uint = 0; i < object.numChildren; ++i) {
				child = object.getChildAt(i);
				parse(child);
			}
		}
		
		private function spherizeSubGeom(subGeom:ISubGeometry):void
		{
			var i:uint;
			var len:uint;
			var vectorVert:Vector3D;
			var vectorVertLength:Number;
			var vectorNormal:Vector3D;
			var vectordifference:Number;
			var vd:Vector.<Number> = subGeom.vertexData;
			var vStride:uint = subGeom.vertexStride;
			var vOffs:uint = subGeom.vertexOffset;
			var nd:Vector.<Number> = subGeom.vertexNormalData;
			var nStride:uint = subGeom.vertexNormalStride;
			var nOffs:uint = subGeom.vertexNormalOffset;
			len = subGeom.numVertices;
			for (i = 0; i < len; i++) {
				vectorVert = new Vector3D(vd[vOffs + i*vStride + 0], vd[vOffs + i*vStride + 1], vd[vOffs + i*vStride + 2]);
				vectorVertLength = vectorVert.length;
				vectorNormal = vectorVert.clone();
				vectordifference = Number(_radius) - Number(vectorVertLength);
				vectorNormal.normalize();
				
				vd[vOffs + i*vStride + 0] = vectorVert.x + ((vectorNormal.x*vectordifference)*_weight);
				vd[vOffs + i*vStride + 1] = vectorVert.y + ((vectorNormal.y*vectordifference)*_weight);
				vd[vOffs + i*vStride + 2] = vectorVert.z + ((vectorNormal.z*vectordifference)*_weight);
				nd[nOffs + i*nStride + 0] = 0 + (nd[nOffs + i*nStride + 0]*(1 - _weight) + (vectorNormal.x*_weight));
				nd[nOffs + i*nStride + 1] = 0 + (nd[nOffs + i*nStride + 1]*(1 - _weight) + (vectorNormal.y*_weight));
				nd[nOffs + i*nStride + 2] = 0 + (nd[nOffs + i*nStride + 2]*(1 - _weight) + (vectorNormal.z*_weight));
			}
		}
	}
}
