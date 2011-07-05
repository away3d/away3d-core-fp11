package away3d.tools.utils
{
	import flash.geom.Vector3D;

	public class Ray{
		
		private var _orig:Vector3D = new Vector3D();
		private var _dir:Vector3D = new Vector3D();
		private var _intersect:Vector3D = new Vector3D();
		private var _tu:Vector3D = new Vector3D();
		private var _tv:Vector3D = new Vector3D();
		private var _w:Vector3D = new Vector3D();
		private var _pn:Vector3D = new Vector3D();
		private var _npn:Vector3D = new Vector3D();
		
		function Ray(){}
		
		/**
		* Defines the origin point of the Ray object
		* @return	Vector3D		The origin point of the Ray object
		*/
		public function set orig(o:Vector3D):void
		{
			_orig.x = o.x;
			_orig.y = o.y;
			_orig.z = o.z;
		}
		public function get orig():Vector3D
		{
			return _orig;
		}
		
		/**
		* Defines the directional vector of the Ray object
		* @return	Vector3D		The directional vector
		*/
		public function set dir(n:Vector3D):void
		{
			_dir.x = n.x;
			_dir.y = n.y;
			_dir.z = n.z;
		}
		
		public function get dir():Vector3D
		{
			return _dir;
		}
		
		/**
		* Defines the directional normal of the Ray object
		* @return	Vector3D		The normal of the plane
		*/
		public function get planeNormal():Vector3D
		{
			return _pn;
		}
		
		/**
		* Checks ray intersection by mesh.boundingRadius
		* @return	Boolean		If the ray intersect the mesh boundery
		*/
    	public function intersectBoundingRadius(pos:Vector3D, radius:Number):Boolean
		{
			var rsx:Number = _orig.x - pos.x;
			var rsy:Number = _orig.y - pos.y;
			var rsz:Number = _orig.z - pos.z;
			var B:Number = rsx*_dir.x + rsy*_dir.y + rsz*_dir.z;
			var C:Number = rsx*rsx + rsy*rsy + rsz*rsz - (radius*radius);
			
			return (B * B - C) > 0;
		}
		
		/**
		* Returns a Vector3D where the ray intersects a plane inside a triangle
		* Returns null if no hit is found.
		* @return	Vector3D	The intersection point
		*/
		public function getIntersect(p0:Vector3D, p1:Vector3D, v0:Vector3D, v1:Vector3D, v2:Vector3D):Vector3D
		{
			_tu.x = v1.x - v0.x;
			_tu.y = v1.y - v0.y;
			_tu.z = v1.z - v0.z;
			_tv.x = v2.x - v0.x;
			_tv.y = v2.y - v0.y;
			_tv.z = v2.z - v0.z;
			
			_pn.x =  _tu.y*_tv.z - _tu.z*_tv.y;
			_pn.y =  _tu.z*_tv.x - _tu.x*_tv.z;
			_pn.z =  _tu.x*_tv.y - _tu.y*_tv.x;
			 
			if (_pn.length == 0)
				return null;

			_dir.x = p1.x - p0.x;
			_dir.y = p1.y - p0.y;
			_dir.z = p1.z - p0.z;
			_orig.x = p0.x - v0.x;
			_orig.y = p0.y - v0.y;
			_orig.z = p0.z - v0.z;
			 
			_npn.x = -_pn.x;
			_npn.y = -_pn.y;
			_npn.z = -_pn.z;
			
			var a:Number = _npn.x * _orig.x + _npn.y * _orig.y + _npn.z * _orig.z;
			
			if (a ==0)
				return null;
				
			var b:Number = _pn.x * _dir.x + _pn.y * _dir.y + _pn.z * _dir.z;
			var r:Number = a / b;
			
			if (r < 0 || r > 1)
				return null;
			
			_intersect.x = p0.x+(_dir.x*r);
			_intersect.y = p0.y+(_dir.y*r);
			_intersect.z = p0.z+(_dir.z*r);
 
			var uu:Number = _tu.x * _tu.x + _tu.y * _tu.y + _tu.z * _tu.z;
			var uv:Number = _tu.x * _tv.x + _tu.y * _tv.y + _tu.z * _tv.z;
			var vv:Number = _tv.x * _tv.x + _tv.y * _tv.y + _tv.z * _tv.z;

			_w.x = _intersect.x - v0.x;
			_w.y = _intersect.y - v0.y;
			_w.z = _intersect.z - v0.z;
			
			var wu:Number = _w.x * _tu.x + _w.y * _tu.y + _w.z * _tu.z;
			var wv:Number = _w.x * _tv.x + _w.y * _tv.y + _w.z * _tv.z;
			var d:Number = uv * uv - uu * vv;

			var v:Number = (uv * wv - vv * wu) / d;
			if (v < 0 || v > 1)
				return null;
			 
			var t:Number = (uv * wu - uu * wv) / d;
			if (t < 0 || (v + t) > 1.0)
				return null;
			
			return _intersect;
		}
	}
}