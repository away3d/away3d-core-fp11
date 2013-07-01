package away3d.tools.utils
{
	import away3d.lights.LightBase;
	import flash.utils.Dictionary;
	
	import away3d.entities.Entity;
	
	import flash.geom.Matrix3D;
	
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.entities.Mesh;
	
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * Helper Class to retrieve objects bounds <code>Bounds</code>
	 */
	
	public class Bounds
	{
		
		private static var _minX:Number;
		private static var _minY:Number;
		private static var _minZ:Number;
		private static var _maxX:Number;
		private static var _maxY:Number;
		private static var _maxZ:Number;
		private static var _defaultPosition:Vector3D = new Vector3D(0.0, 0.0, 0.0);
		private static var _containers:Dictionary;
		
		/**
		 * Calculate the bounds of a Mesh object
		 * @param mesh        Mesh. The Mesh to get the bounds from.
		 * Use the getters of this class to retrieve the results
		 */
		public static function getMeshBounds(mesh:Mesh):void
		{
			getObjectContainerBounds(mesh);
		}
		
		/**
		 * Calculate the bounds of an ObjectContainer3D object
		 * @param container        ObjectContainer3D. The ObjectContainer3D to get the bounds from.
		 * Use the getters of this class to retrieve the results
		 */
		public static function getObjectContainerBounds(container:ObjectContainer3D, worldBased:Boolean = true):void
		{
			reset();
			parseObjectContainerBounds(container);
			
			if (isInfinite(_minX) || isInfinite(_minY) || isInfinite(_minZ) ||
				isInfinite(_maxX) || isInfinite(_maxY) || isInfinite(_maxZ)) {
				return;
			}
			
			// Transform min/max values to the scene if required
			if (worldBased) {
				var b:Vector.<Number> = Vector.<Number>([Infinity, Infinity, Infinity, -Infinity, -Infinity, -Infinity]);
				var c:Vector.<Number> = getBoundsCorners(_minX, _minY, _minZ, _maxX, _maxY, _maxZ);
				transformContainer(b, c, container.sceneTransform);
				_minX = b[0];
				_minY = b[1];
				_minZ = b[2];
				_maxX = b[3];
				_maxY = b[4];
				_maxZ = b[5];
			}
		}
		
		/**
		 * Calculate the bounds from a vector of number representing the vertices. &lt;x,y,z,x,y,z.....&gt;
		 * @param vertices        Vector.&lt;Number&gt;. The vertices to get the bounds from.
		 * Use the getters of this class to retrieve the results
		 */
		public static function getVerticesVectorBounds(vertices:Vector.<Number>):void
		{
			reset();
			var l:uint = vertices.length;
			if (l%3 != 0)
				return;
			
			var x:Number;
			var y:Number;
			var z:Number;
			
			for (var i:uint = 0; i < l; i += 3) {
				x = vertices[i];
				y = vertices[i + 1];
				z = vertices[i + 2];
				
				if (x < _minX)
					_minX = x;
				if (x > _maxX)
					_maxX = x;
				
				if (y < _minY)
					_minY = y;
				if (y > _maxY)
					_maxY = y;
				
				if (z < _minZ)
					_minZ = z;
				if (z > _maxZ)
					_maxZ = z;
			}
		}
		
		/**
		 * @param outCenter        Vector3D. Optional Vector3D, if provided the same Vector3D is returned with the bounds center.
		 * @return the center of the bound
		 */
		public static function getCenter(outCenter:Vector3D = null):Vector3D
		{
			var center:Vector3D = outCenter || new Vector3D();
			center.x = _minX + (_maxX - _minX)*.5;
			center.y = _minY + (_maxY - _minY)*.5;
			center.z = _minZ + (_maxZ - _minZ)*.5;
			
			return center;
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
			_containers = new Dictionary();
			_minX = _minY = _minZ = Infinity;
			_maxX = _maxY = _maxZ = -Infinity;
			_defaultPosition.x = 0.0;
			_defaultPosition.y = 0.0;
			_defaultPosition.z = 0.0;
		}
		
		private static function parseObjectContainerBounds(obj:ObjectContainer3D, parentTransform:Matrix3D = null):void
		{
			if (!obj.visible)
				return;
			
			var containerBounds:Vector.<Number> = _containers[obj] ||= Vector.<Number>([Infinity, Infinity, Infinity, -Infinity, -Infinity, -Infinity]);
			
			var child:ObjectContainer3D;
			var isEntity:Entity = obj as Entity;
			var containerTransform:Matrix3D = new Matrix3D();
			
			if (isEntity && parentTransform) {
				parseObjectBounds(obj, parentTransform);
				
				containerTransform = obj.transform.clone();
				if (parentTransform)
					containerTransform.append(parentTransform);
			} else if (isEntity && !parentTransform) {
				var mat:Matrix3D = obj.transform.clone();
				mat.invert();
				parseObjectBounds(obj, mat);
			}
			
			for (var i:uint = 0; i < obj.numChildren; ++i) {
				child = obj.getChildAt(i);
				parseObjectContainerBounds(child, containerTransform);
			}
			
			var parentBounds:Vector.<Number> = _containers[obj.parent];
			if (!isEntity && parentTransform)
				parseObjectBounds(obj, parentTransform, true);
			
			if (parentBounds) {
				parentBounds[0] = Math.min(parentBounds[0], containerBounds[0]);
				parentBounds[1] = Math.min(parentBounds[1], containerBounds[1]);
				parentBounds[2] = Math.min(parentBounds[2], containerBounds[2]);
				parentBounds[3] = Math.max(parentBounds[3], containerBounds[3]);
				parentBounds[4] = Math.max(parentBounds[4], containerBounds[4]);
				parentBounds[5] = Math.max(parentBounds[5], containerBounds[5]);
			} else {
				_minX = containerBounds[0];
				_minY = containerBounds[1];
				_minZ = containerBounds[2];
				_maxX = containerBounds[3];
				_maxY = containerBounds[4];
				_maxZ = containerBounds[5];
			}
		}
		
		private static function isInfinite(value:Number):Boolean
		{
			return value == Number.POSITIVE_INFINITY || value == Number.NEGATIVE_INFINITY;
		}
		
		private static function parseObjectBounds(oC:ObjectContainer3D, parentTransform:Matrix3D = null, resetBounds:Boolean = false):void
		{
			if (oC is LightBase) return; 
			
			var e:Entity = oC as Entity;
			var corners:Vector.<Number>;
			var mat:Matrix3D = oC.transform.clone();
			var cB:Vector.<Number> = _containers[oC];
			if (e) {
				if (isInfinite(e.minX) || isInfinite(e.minY) || isInfinite(e.minZ) ||
					isInfinite(e.maxX) || isInfinite(e.maxY) || isInfinite(e.maxZ)) {
					return;
				}
				
				corners = getBoundsCorners(e.minX, e.minY, e.minZ, e.maxX, e.maxY, e.maxZ);
				if (parentTransform)
					mat.append(parentTransform);
			} else {
				corners = getBoundsCorners(cB[0], cB[1], cB[2], cB[3], cB[4], cB[5]);
				if (parentTransform)
					mat.prepend(parentTransform);
			}
			
			if (resetBounds) {
				cB[0] = cB[1] = cB[2] = Infinity;
				cB[3] = cB[4] = cB[5] = -Infinity;
			}
			
			transformContainer(cB, corners, mat);
		}
		
		private static function getBoundsCorners(minX:Number, minY:Number, minZ:Number, maxX:Number, maxY:Number, maxZ:Number):Vector.<Number>
		{
			return Vector.<Number>([
				minX, minY, minZ,
				minX, minY, maxZ,
				minX, maxY, minZ,
				minX, maxY, maxZ,
				maxX, minY, minZ,
				maxX, minY, maxZ,
				maxX, maxY, minZ,
				maxX, maxY, maxZ
				]);
		}
		
		private static function transformContainer(bounds:Vector.<Number>, corners:Vector.<Number>, matrix:Matrix3D):void
		{
			
			matrix.transformVectors(corners, corners);
			
			var x:Number;
			var y:Number;
			var z:Number;
			
			var pCtr:int = 0;
			while (pCtr < corners.length) {
				x = corners[pCtr++];
				y = corners[pCtr++];
				z = corners[pCtr++];
				
				if (x < bounds[0])
					bounds[0] = x;
				if (x > bounds[3])
					bounds[3] = x;
				
				if (y < bounds[1])
					bounds[1] = y;
				if (y > bounds[4])
					bounds[4] = y;
				
				if (z < bounds[2])
					bounds[2] = z;
				if (z > bounds[5])
					bounds[5] = z;
			}
		}
	}
}
