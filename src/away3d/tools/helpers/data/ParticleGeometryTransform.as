package away3d.tools.helpers.data
{
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	
	/**
	 * ...
	 */
	public class ParticleGeometryTransform
	{
		private var _defaultVertexTransform:Matrix3D;
		private var _defaultInvVertexTransform:Matrix3D;
		private var _defaultUVTransform:Matrix;
		
		public function ParticleGeometryTransform() {
		}
		
		public function set vertexTransform(value:Matrix3D):void
		{
			_defaultVertexTransform = value;
			_defaultInvVertexTransform = value.clone();
			_defaultInvVertexTransform.invert();
			_defaultInvVertexTransform.transpose();
		}
		
		public function set UVTransform(value:Matrix):void
		{
			_defaultUVTransform = value;
		}
		
		public function get UVTransform():Matrix
		{
			return _defaultUVTransform;
		}
		
		public function get vertexTransform():Matrix3D
		{
			return _defaultVertexTransform;
		}
		
		public function get invVertexTransform():Matrix3D
		{
			return _defaultInvVertexTransform;
		}
	}

}