package away3d.projections
{
	import away3d.arcane;
	import away3d.core.math.Matrix3DUtils;
	import away3d.core.math.Plane3D;
	import away3d.events.ProjectionEvent;
	
	import flash.geom.Matrix3D;
	
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	public class ObliqueNearPlaneLens extends ProjectionBase
	{
		private var _baseProjection:IProjection;
		private var _plane:Plane3D;
		
		public function ObliqueNearPlaneLens(baseProjection:IProjection, plane:Plane3D)
		{
			this.baseProjection = baseProjection;
			this.plane = plane;
		}
		
		override public function get frustumCorners():Vector.<Number>
		{
			return _baseProjection.frustumCorners;
		}
		
		override public function get near():Number
		{
			return _baseProjection.near;
		}
		
		override public function set near(value:Number):void
		{
			_baseProjection.near = value;
		}
		
		override public function get far():Number
		{
			return _baseProjection.far;
		}
		
		override public function set far(value:Number):void
		{
			_baseProjection.far = value;
		}
		
		override public function get aspectRatio():Number
		{
			return _baseProjection.aspectRatio;
		}
		
		override public function set aspectRatio(value:Number):void
		{
			_baseProjection.aspectRatio = value;
		}
		
		public function get plane():Plane3D
		{
			return _plane;
		}
		
		public function set plane(value:Plane3D):void
		{
			_plane = value;
			invalidateMatrix();
		}
		
		public function set baseProjection(value:IProjection):void
		{
			if (_baseProjection)
				_baseProjection.removeEventListener(ProjectionEvent.MATRIX_CHANGED, onLensMatrixChanged);
			
			_baseProjection = value;
			
			if (_baseProjection)
				_baseProjection.addEventListener(ProjectionEvent.MATRIX_CHANGED, onLensMatrixChanged);
			
			invalidateMatrix();
		}
		
		private function onLensMatrixChanged(event:ProjectionEvent):void
		{
			invalidateMatrix();
		}

		private static const signCalculationVector:Vector3D = new Vector3D();
		override protected function updateMatrix():void
		{
			_matrix.copyFrom(_baseProjection.matrix);
			var cx:Number = _plane.a;
			var cy:Number = _plane.b;
			var cz:Number = _plane.c;
			var cw:Number = -_plane.d + .05;
			var signX:Number = cx >= 0? 1 : -1;
			var signY:Number = cy >= 0? 1 : -1;
			var p:Vector3D = signCalculationVector;
			p.x = signX;
			p.y = signY;
			p.z = 1;
			p.w = 1;
			var inverse:Matrix3D = Matrix3DUtils.CALCULATION_MATRIX;
			inverse.copyFrom(_matrix);
			inverse.invert();
			var q:Vector3D = Matrix3DUtils.transformVector(inverse,p,Matrix3DUtils.CALCULATION_VECTOR3D);
			_matrix.copyRowTo(3, p);
			var a:Number = (q.x*p.x + q.y*p.y + q.z*p.z + q.w*p.w)/(cx*q.x + cy*q.y + cz*q.z + cw*q.w);
			p.x = cx*a;
			p.y = cy*a;
			p.z = cz*a;
			p.w = cw*a;
			_matrix.copyRowFrom(2, p);
		}
	}
}
