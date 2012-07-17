package away3d.tools.utils
{
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.SubGeometry;
	import away3d.entities.Mesh;

	import flash.geom.Vector3D;

	use namespace arcane;
	
	/**
	* Helper Class to retrieve objects bounds <code>Bounds</code>
	*/
	 
	public class Bounds {
		 
		private static var _minX:Number;
		private static var _minY:Number;
		private static var _minZ:Number;
		private static var _maxX:Number;
		private static var _maxY:Number;
		private static var _maxZ:Number;
		private static var _defaultPosition:Vector3D = new Vector3D(0.0,0.0,0.0);
		 
		/**
		* Calculate the bounds of a Mesh object
		* @param mesh		Mesh. The Mesh to get the bounds from.
		* Use the getters of this class to retrieve the results
		*/
		public static function getMeshBounds(mesh:Mesh):void
		{
			reset();
			parseMeshBounds(mesh);
		}
		/**
		* Calculate the bounds of an ObjectContainer3D object
		* @param container		ObjectContainer3D. The ObjectContainer3D to get the bounds from.
		* Use the getters of this class to retrieve the results
		*/
		public static function getObjectContainerBounds(container : ObjectContainer3D):void
		{
			reset();
			parseObjectContainerBounds(container);
		}
		
		/**
		* Calculate the bounds from a vector of number representing the vertices. &lt;x,y,z,x,y,z.....&gt;
		* @param vertices		Vector.&lt;Number&gt;. The vertices to get the bounds from.
		* Use the getters of this class to retrieve the results
		*/
		public static function getVerticesVectorBounds(vertices:Vector.<Number>):void
		{
			reset();
			var l:uint = vertices.length;
			if(l%3 != 0) return;
			
			var x:Number;
			var y:Number;
			var z:Number;
			
			for (var i:uint = 0; i < l; i+=3){
				x = vertices[i];
				y = vertices[i+1];
				z = vertices[i+2];
				
				if(x < _minX) _minX = x;
				if(x > _maxX) _maxX = x;
				
				if(y < _minY) _minY = y;
				if(y > _maxY) _maxY = y;
				
				if(z < _minZ) _minZ = z;
				if(z > _maxZ) _maxZ = z;
			}
		}
		
		/**
		* @return the smalest x value
		*/
		public static function get minX():Number
		{
			return _minX;
		}
		/**
		* @return the smalest y value
		*/
		public static function get minY():Number
		{
			return _minY;
		}
		/**
		* @return the smalest z value
		*/
		public static function get minZ():Number
		{
			return _minZ;
		}
		/**
		* @return the biggest x value
		*/
		public static function get maxX():Number
		{
			return _maxX;
		}
		/**
		* @return the biggest y value
		*/
		public static function get maxY():Number
		{
			return _maxY;
		}
		/**
		* @return the biggest z value
		*/
		public static function get maxZ():Number
		{
			return _maxZ;
		}
		
		/**
		* @return the width value from the bounds
		*/
		public static function get width():Number
		{
			return _maxX - _minX;
		}
		/**
		* @return the height value from the bounds
		*/
		public static function get height():Number
		{
			return _maxY - _minY;
		}
		/**
		* @return the depth value from the bounds
		*/
		public static function get depth():Number
		{
			return _maxZ - _minZ;
		}
		
		private static function reset():void
		{
			_minX = _minY = _minZ = Infinity;
			_maxX = _maxY = _maxZ = -Infinity;
			_defaultPosition.x = 0.0;
			_defaultPosition.y = 0.0;
			_defaultPosition.z = 0.0;
		}
		
		private static function parseObjectContainerBounds(obj:ObjectContainer3D):void
		{
			var child:ObjectContainer3D;
			
			if(obj is Mesh && obj.numChildren == 0)
				parseMeshBounds(Mesh(obj), obj.position);
				 
			for(var i:uint = 0;i<obj.numChildren;++i){
				child = obj.getChildAt(i);
				parseObjectContainerBounds(ObjectContainer3D(child));
			}
		}
		
		private static function parseMeshBounds(m:Mesh, position:Vector3D = null):void
		{
			var offsetPosition:Vector3D = position || _defaultPosition;
			var x:Number;
			var y:Number;
			var z:Number;
			
			try{
					x = offsetPosition.x;
					y = offsetPosition.y;
					z = offsetPosition.z;
					
					if(x + m.minX < _minX) _minX = x+ m.minX;
					if(x + m.maxX > _maxX) _maxX = x+ m.maxX;
					
					if(y + m.minY < _minY) _minY = y+m.minY;
					if(y +m.maxY > _maxY) _maxY = y+m.maxY;
					
					if(z +m.minZ < _minZ) _minZ = z+m.minZ;
					if(z +m.maxZ > _maxZ) _maxZ = z+m.maxZ;
					
					if(m.scaleX != 1){
						_minX *= m.scaleX;
						_maxX *= m.scaleX;
					}
					if(m.scaleY != 1){
						_minY *= m.scaleY;
						_maxY *= m.scaleY;
					}
					if(m.scaleZ != 1){
						_minZ *= m.scaleZ;
						_maxZ*= m.scaleZ;
					}
 
			} catch(e:Error){
				
				var geometries:Vector.<SubGeometry> = m.geometry.subGeometries;
				var numSubGeoms:int = geometries.length;
				
				var subGeom:SubGeometry;
				var vertices:Vector.<Number>;
	
				var j : uint;
				var vecLength : uint;
				
				for (var i : uint = 0; i < numSubGeoms; ++i){
					subGeom = geometries[i];
					vertices = subGeom.vertexData;
					vecLength = vertices.length;
					for (j = 0; j < vecLength; j+=3){
						//not using Math.min or max to go faster
						x = (vertices[j]*m.scaleX)+offsetPosition.x;
						y = (vertices[j+1]*m.scaleY)+offsetPosition.y;
						z = (vertices[j+2]*m.scaleZ)+offsetPosition.z;
						
						if(x < _minX) _minX = x;
						if(x > _maxX) _maxX = x;
						
						if(y < _minY) _minY = y;
						if(y > _maxY) _maxY = y;
						
						if(z < _minZ) _minZ = z;
						if(z > _maxZ) _maxZ = z;
					}
				}
			}
		}
		
	}
}