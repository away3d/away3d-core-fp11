package away3d.extrusions.utils
{
	import away3d.extrusions.utils.IPath;

	import flash.geom.Vector3D;

	/**
	 * Geometry handlers for classes using Path objects
	 */
	public class PathUtils {
    	 
		 public static function step( startVal:Vector3D, endVal:Vector3D, subdivision:int):Vector.<Vector3D>
		 {
			var vTween:Vector.<Vector3D> = new Vector.<Vector3D>();
			
			var stepx:Number =  (endVal.x-startVal.x) / subdivision;
			var stepy:Number =  (endVal.y-startVal.y) / subdivision;
			var stepz:Number =  (endVal.z-startVal.z) / subdivision;
			
			var step:int = 1;
			var scalestep:Vector3D;
			
			while (step < subdivision) { 
				scalestep = new Vector3D();
				scalestep.x = startVal.x+(stepx*step);
				scalestep.y = startVal.y+(stepy*step);
				scalestep.z = startVal.z+(stepz*step);
				vTween.push(scalestep);
				
				step ++;
			}
			
			vTween.push(endVal);
			
			return vTween;
		}
		
		public static function rotatePoint(aPoint:Vector3D, rotation:Vector3D):Vector3D
		{
			if(rotation.x != 0 || rotation.y != 0 || rotation.z != 0){

				var x1:Number;
				var y1:Number;

				var rad:Number = Math.PI / 180;
				var rotx:Number = rotation.x * rad;
				var roty:Number = rotation.y * rad;
				var rotz:Number = rotation.z * rad;

				var sinx:Number = Math.sin(rotx);
				var cosx:Number = Math.cos(rotx);
				var siny:Number = Math.sin(roty);
				var cosy:Number = Math.cos(roty);
				var sinz:Number = Math.sin(rotz);
				var cosz:Number = Math.cos(rotz);
	
				var x:Number = aPoint.x;
				var y:Number = aPoint.y;
				var z:Number = aPoint.z;
	
				y1 = y;
				y = y1*cosx+z*-sinx;
				z = y1*sinx+z*cosx;
				
				x1 = x;
				x = x1*cosy+z*siny;
				z = x1*-siny+z*cosy;
			
				x1 = x;
				x = x1*cosz+y*-sinz;
				y = x1*sinz+y*cosz;
	
				aPoint.x = x;
				aPoint.y = y;
				aPoint.z = z;
			}
			
			return aPoint;
		}
		
		public static function getPointsOnCurve(path:IPath, subdivision:uint):Vector.<Vector.<Vector3D>>
		{
			var segPts:Vector.<Vector.<Vector3D>> = new Vector.<Vector.<Vector3D>>();

			if(path is QuadraticPath)
			 	getPointsOnQuadraticCurve(segPts, path as QuadraticPath, subdivision);
			else if (path is CubicPath)
				getPointsOnCubicCurve(segPts, path as CubicPath, subdivision);

			return segPts;
		}

		public static function getPointsOnQuadraticCurve(output:Vector.<Vector.<Vector3D>>, path:QuadraticPath, subdivision:uint):void
		{
			var segment:QuadraticPathSegment;
			for (var i:uint = 0, len:uint = path.length; i < len; ++i){
				segment = path.segments[i] as QuadraticPathSegment;
				output[i] = getQuadraticSegmentPoints(segment.pStart, segment.pControl, segment.pEnd, subdivision, (i == path.length - 1));
			}
		}

		public static function getPointsOnCubicCurve(output:Vector.<Vector.<Vector3D>>, path:CubicPath, subdivision:uint):void
		{
			var segment:CubicPathSegment;
			for (var i:uint = 0, len:uint = path.length; i < len; ++i){
				segment = path.segments[i] as CubicPathSegment;
				output[i] = getCubicSegmentPoints(segment.start, segment.control1, segment.control2, segment.end, subdivision, (i == path.length - 1));
			}
		}
		
		public static function getQuadraticSegmentPoints(pStart:Vector3D, pControl:Vector3D, pEnd:Vector3D, n:uint, last:Boolean):Vector.<Vector3D>
		{
			var aPts:Vector.<Vector3D> = new Vector.<Vector3D>();
			
			for (var i:uint = 0; i < n+((last)? 1 : 0); ++i)
				aPts[i] = PathUtils.getNewQuadraticPoint(pStart.x, pStart.y, pStart.z, pControl.x, pControl.y, pControl.z, pEnd.x, pEnd.y, pEnd.z, i / n);
			
			return aPts;
		}
		
		public static function getNewQuadraticPoint(x0:Number = 0, y0:Number = 0, z0:Number=0, aX:Number = 0, aY:Number = 0, aZ:Number=0, x1:Number = 0, y1:Number = 0, z1:Number=0, t:Number = 0):Vector3D
		{
			return new Vector3D(
					x0 + t * (2 * (1 - t) * (aX - x0) + t * (x1 - x0)),
					y0 + t * (2 * (1 - t) * (aY - y0) + t * (y1 - y0)),
					z0 + t * (2 * (1 - t) * (aZ - z0) + t * (z1 - z0)));
		}

		public static function getCubicSegmentPoints(start:Vector3D, control1:Vector3D, control2:Vector3D, end:Vector3D, n:uint, last:Boolean):Vector.<Vector3D>
		{
			var aPts:Vector.<Vector3D> = new Vector.<Vector3D>();

			for (var i:uint = 0; i < n+((last)? 1 : 0); ++i)
				aPts[i] = getNewCubicPoint(start.x, start.y, start.z, control1.x, control1.y, control1.z, control2.x, control2.y, control2.z, end.x, end.y, end.z, i / n);

			return aPts;
		}

		public static function getNewCubicPoint(sx:Number, sy:Number, sz:Number, c1x:Number, c1y:Number, c1z:Number, c2x:Number, c2y:Number, c2z:Number, ex:Number, ey:Number, ez:Number, t:Number):Vector3D
		{
			var v:Vector3D = new Vector3D();

			const td:Number = 1 - t;
			const a:Number = td*td*td;
			const b:Number = 3*t*td*td;
			const c:Number = 3*t*t*td;
			const d:Number = t*t*t;

			v.x = a*sx + b*c1x + c*c2x + d*ex;
			v.y = a*sy + b*c1y + c*c2y + d*ey;
			v.z = a*sz + b*c1z + c*c2z + d*ez;

			return v;
		}

		public static function calcPosition(t:Number, ps:IPathSegment, out:Vector3D):Vector3D
		{
			var v:Vector3D = out || new Vector3D();

			if(ps is QuadraticPathSegment)
				calcQuadraticPosition(t, ps as QuadraticPathSegment, v);
			else if (ps is CubicPathSegment)
				calcCubicPosition(t, ps as CubicPathSegment, v);

			return v;
		}

		public static function calcQuadraticPosition(t:Number, ps:QuadraticPathSegment, out:Vector3D):Vector3D
		{
			var dt:Number = 2 * (1 - t);
			var v:Vector3D = out || new Vector3D();
			v.x = ps.pStart.x + t * (dt * (ps.pControl.x - ps.pStart.x) + t * (ps.pEnd.x - ps.pStart.x));
			v.y = ps.pStart.y + t * (dt * (ps.pControl.y - ps.pStart.y) + t * (ps.pEnd.y - ps.pStart.y));
			v.z = ps.pStart.z + t * (dt * (ps.pControl.z - ps.pStart.z) + t * (ps.pEnd.z - ps.pStart.z));

			return v;
		}

		public static function calcCubicPosition(t:Number, ps:CubicPathSegment, out:Vector3D):Vector3D
		{
			// (1 - t)^3*start + 3*t*(1 - t)^2*control1 + 3*t^2*(1 - t)*control2 + t^3*end
			var v:Vector3D = out || new Vector3D();

			const td:Number = 1 - t;
			const a:Number = td*td*td;
			const b:Number = 3*t*td*td;
			const c:Number = 3*t*t*td;
			const d:Number = t*t*t;

			v.x = a*ps.start.x + b*ps.control1.x + c*ps.control2.x + d*ps.end.x;
			v.y = a*ps.start.y + b*ps.control1.y + c*ps.control2.y + d*ps.end.y;
			v.z = a*ps.start.z + b*ps.control1.z + c*ps.control2.z + d*ps.end.z;

			return v;
		}
		
    }
}