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
		private var _subVertexTransform:Vector.<Matrix3D> = new Vector.<Matrix3D>;
		private var _subInvVertexTransform:Vector.<Matrix3D> = new Vector.<Matrix3D>;
		private var _subUVTransform:Vector.<Matrix> = new Vector.<Matrix>;
		
		public function setDefaultVertexTransform(value:Matrix3D):void
		{
			_defaultVertexTransform = value;
			_defaultInvVertexTransform = value.clone();
			_defaultInvVertexTransform.invert();
			_defaultInvVertexTransform.transpose();
		}
		
		public function setDefaultUVTransform(value:Matrix):void
		{
			_defaultUVTransform = value;
		}
		
		public function getSubVertexTransform(index:int):Matrix3D
		{
			if (_subVertexTransform.length > index && _subVertexTransform[index])
				return _subVertexTransform[index];
			else
				return _defaultVertexTransform;
		}
		
		public function getSubInvVertexTransform(index:int):Matrix3D
		{
			if (_subInvVertexTransform.length > index && _subInvVertexTransform[index])
				return _subInvVertexTransform[index];
			else
				return _defaultInvVertexTransform;
		}
		
		public function setSubVertexTransform(index:int, value:Matrix3D):void
		{
			if (_subVertexTransform.length <= index)
			{
				_subInvVertexTransform.length = _subVertexTransform.length = index + 1;
			}
			_subVertexTransform[index] = value;
			_subInvVertexTransform[index] = value.clone();
			_subInvVertexTransform[index].invert();
			_subInvVertexTransform[index].transpose();
		}
		
		public function getSubUVTransform(index:int):Matrix
		{
			if (_subUVTransform.length > index && _subUVTransform[index])
				return _subUVTransform[index];
			else
				return _defaultUVTransform;
		}
		
		public function setSubUVTransform(index:int, value:Matrix):void
		{
			if (_subUVTransform.length <= index)
			{
				_subUVTransform.length = index + 1;
			}
			_subUVTransform[index] = value;
		}
		
		
		public function get subVertexTransform():Vector.<Matrix3D>
		{
			return _subVertexTransform;
		}
		
		public function get subUVTransform():Vector.<Matrix>
		{
			return _subUVTransform;
		}
	}

}