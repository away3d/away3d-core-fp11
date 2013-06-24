package away3d.lights.shadowmaps
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	
	use namespace arcane;
	
	public class NearDirectionalShadowMapper extends DirectionalShadowMapper
	{
		private var _coverageRatio:Number;
		
		public function NearDirectionalShadowMapper(coverageRatio:Number = .5)
		{
			super();
			this.coverageRatio = coverageRatio;
		}
		
		/**
		 * A value between 0 and 1 to indicate the ratio of the view frustum that needs to be covered by the shadow map.
		 */
		public function get coverageRatio():Number
		{
			return _coverageRatio;
		}
		
		public function set coverageRatio(value:Number):void
		{
			if (value > 1)
				value = 1;
			else if (value < 0)
				value = 0;
			
			_coverageRatio = value;
		}
		
		override protected function updateDepthProjection(viewCamera:Camera3D):void
		{
			var corners:Vector.<Number> = viewCamera.lens.frustumCorners;
			
			for (var i:int = 0; i < 12; ++i) {
				var v:Number = corners[i];
				_localFrustum[i] = v;
				_localFrustum[uint(i + 12)] = v + (corners[uint(i + 12)] - v)*_coverageRatio;
			}
			
			updateProjectionFromFrustumCorners(viewCamera, _localFrustum, _matrix);
			_overallDepthLens.matrix = _matrix;
		}
	}
}
