package away3d.tools.helpers.data
{
	import away3d.core.base.Geometry;
	import away3d.core.base.ISubGeometry;
	import away3d.core.base.SubGeometryBase;
	import away3d.entities.Mesh;
	import away3d.entities.SegmentSet;
	import away3d.primitives.LineSegment;
	
	import flash.geom.Vector3D;
	
	/**
	 * MeshDebug, holds the data for the MeshDebugger class
	 */
	
	public class MeshDebug extends SegmentSet
	{
		
		private var _normal:Vector3D = new Vector3D();
		private const VERTEXNORMALS:uint = 1;
		private const TANGENTS:uint = 2;
		
		function MeshDebug()
		{
		}
		
		public function clearAll():void
		{
			super.removeAllSegments();
		}
		
		public function displayNormals(mesh:Mesh, color:uint = 0xFF3399, length:Number = 30):void
		{
			var geometry:Geometry = mesh.geometry;
			var geometries:Vector.<ISubGeometry> = geometry.subGeometries;
			var numSubGeoms:uint = geometries.length;
			
			var vertices:Vector.<Number>;
			var indices:Vector.<uint>;
			var index:uint;
			var j:uint;
			
			var v0:Vector3D = new Vector3D();
			var v1:Vector3D = new Vector3D();
			var v2:Vector3D = new Vector3D();
			
			var l0:Vector3D = new Vector3D();
			var l1:Vector3D = new Vector3D();
			
			var subGeom:SubGeometryBase;
			var stride:uint;
			var offset:uint;
			var normalOffset:uint;
			var tangentOffset:uint;
			
			for (var i:uint = 0; i < numSubGeoms; ++i) {
				subGeom = SubGeometryBase(geometries[i]);
				stride = subGeom.vertexStride;
				offset = subGeom.vertexOffset;
				normalOffset = subGeom.vertexNormalOffset;
				tangentOffset = subGeom.vertexTangentOffset;
				vertices = subGeom.vertexData;
				indices = subGeom.indexData;
				
				for (j = 0; j < indices.length; j += 3) {
					
					index = offset + indices[j]*stride;
					v0.x = vertices[index];
					v0.y = vertices[index + 1];
					v0.z = vertices[index + 2];
					
					index = offset + indices[j + 1]*stride;
					
					v1.x = vertices[index];
					v1.y = vertices[index + 1];
					v1.z = vertices[index + 2];
					
					index = offset + indices[j + 2]*stride;
					
					v2.x = vertices[index];
					v2.y = vertices[index + 1];
					v2.z = vertices[index + 2];
					
					calcNormal(v0, v1, v2);
					
					l0.x = (v0.x + v1.x + v2.x)/3;
					l0.y = (v0.y + v1.y + v2.y)/3;
					l0.z = (v0.z + v1.z + v2.z)/3;
					
					l1.x = l0.x + (_normal.x*length);
					l1.y = l0.y + (_normal.y*length);
					l1.z = l0.z + (_normal.z*length);
					
					addSegment(new LineSegment(l0, l1, color, color, 1));
					
				}
			}
		}
		
		public function displayVertexNormals(mesh:Mesh, color:uint = 0x66CCFF, length:Number = 30):void
		{
			build(mesh, VERTEXNORMALS, color, length);
		}
		
		public function displayTangents(mesh:Mesh, color:uint = 0xFFCC00, length:Number = 30):void
		{
			build(mesh, TANGENTS, color, length);
		}
		
		private function build(mesh:Mesh, type:uint, color:uint = 0x66CCFF, length:Number = 30):void
		{
			var geometry:Geometry = mesh.geometry;
			var geometries:Vector.<ISubGeometry> = geometry.subGeometries;
			var numSubGeoms:uint = geometries.length;
			
			var vertices:Vector.<Number>;
			var vectorTarget:Vector.<Number>;
			
			var indices:Vector.<uint>;
			var index:uint;
			var j:uint;
			
			var v0:Vector3D = new Vector3D();
			var v1:Vector3D = new Vector3D();
			var v2:Vector3D = new Vector3D();
			var l0:Vector3D = new Vector3D();
			var subGeom:SubGeometryBase;
			var stride:uint;
			var offset:uint;
			var offsettarget:uint;
			
			for (var i:uint = 0; i < numSubGeoms; ++i) {
				subGeom = SubGeometryBase(geometries[i]);
				stride = subGeom.vertexStride;
				offset = subGeom.vertexOffset;
				vertices = subGeom.vertexData;
				offsettarget = subGeom.vertexNormalOffset;
				
				if (type == 2)
					offsettarget = subGeom.vertexTangentOffset;
				
				try {
					vectorTarget = (type == 1)? subGeom.vertexNormalData : subGeom.vertexTangentData;
				} catch (e:Error) {
					continue;
				}
				
				indices = subGeom.indexData;
				
				for (j = 0; j < indices.length; j += 3) {
					
					index = offset + indices[j]*stride;
					v0.x = vertices[index];
					v0.y = vertices[index + 1];
					v0.z = vertices[index + 2];
					
					index = offsettarget + indices[j]*stride;
					
					_normal.x = vectorTarget[index];
					_normal.y = vectorTarget[index + 1];
					_normal.z = vectorTarget[index + 2];
					_normal.normalize();
					
					l0.x = v0.x + (_normal.x*length);
					l0.y = v0.y + (_normal.y*length);
					l0.z = v0.z + (_normal.z*length);
					
					addSegment(new LineSegment(v0, l0, color, color, 1));
					
					index = offset + indices[j + 1]*stride;
					
					v1.x = vertices[index];
					v1.y = vertices[index + 1];
					v1.z = vertices[index + 2];
					
					index = offsettarget + indices[j + 1]*stride;
					
					_normal.x = vectorTarget[index];
					_normal.y = vectorTarget[index + 1];
					_normal.z = vectorTarget[index + 2];
					_normal.normalize();
					
					l0.x = v1.x + (_normal.x*length);
					l0.y = v1.y + (_normal.y*length);
					l0.z = v1.z + (_normal.z*length);
					
					addSegment(new LineSegment(v1, l0, color, color, 1));
					
					index = offset + indices[j + 2]*stride;
					
					v2.x = vertices[index];
					v2.y = vertices[index + 1];
					v2.z = vertices[index + 2];
					
					index = offsettarget + indices[j + 2]*stride;
					
					_normal.x = vectorTarget[index];
					_normal.y = vectorTarget[index + 1];
					_normal.z = vectorTarget[index + 2];
					_normal.normalize();
					
					l0.x = v2.x + (_normal.x*length);
					l0.y = v2.y + (_normal.y*length);
					l0.z = v2.z + (_normal.z*length);
					
					addSegment(new LineSegment(v2, l0, color, color, 1));
					
				}
			}
		}
		
		private function calcNormal(v0:Vector3D, v1:Vector3D, v2:Vector3D):void
		{
			var dx1:Number = v2.x - v0.x;
			var dy1:Number = v2.y - v0.y;
			var dz1:Number = v2.z - v0.z;
			var dx2:Number = v1.x - v0.x;
			var dy2:Number = v1.y - v0.y;
			var dz2:Number = v1.z - v0.z;
			
			var cx:Number = dz1*dy2 - dy1*dz2;
			var cy:Number = dx1*dz2 - dz1*dx2;
			var cz:Number = dy1*dx2 - dx1*dy2;
			var d:Number = 1/Math.sqrt(cx*cx + cy*cy + cz*cz);
			
			_normal.x = cx*d;
			_normal.y = cy*d;
			_normal.z = cz*d;
		}
	
	}
}
