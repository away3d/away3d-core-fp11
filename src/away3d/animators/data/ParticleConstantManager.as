package away3d.animators.data
{
	import flash.geom.Matrix3D;
	/**
	 * ...
	 */
	public class ParticleConstantManager
	{
		
		public var vertexConstantData : Vector.<Number> = new Vector.<Number>();
		public var fragmentConstantData : Vector.<Number> = new Vector.<Number>();
		
		private var _usedVertexConstant:int;
		private var _usedFragmentConstant:int;
		private var _fragmentConstantOffset:int;
		private var _vertexConstantOffset:int;
		
		public function get usedVertexConstant():int
		{
			return _usedVertexConstant;
		}
		public function get usedFragmentConstant():int
		{
			return _usedFragmentConstant;
		}
		public function get vertexConstantOffset():int
		{
			return _vertexConstantOffset;
		}
		public function get fragmentConstantOffset():int
		{
			return _fragmentConstantOffset;
		}
		
		
		public function setDataLength(vertexTotal:int, vertexOffset:int, fragmentTotal:int, fragmentOffset:int):void
		{
			_vertexConstantOffset = vertexOffset;
			_fragmentConstantOffset = fragmentOffset;
			_usedVertexConstant = vertexTotal - vertexOffset;
			_usedFragmentConstant = fragmentTotal - fragmentOffset;
			vertexConstantData.length = _usedVertexConstant * 4;
			fragmentConstantData.length = _usedFragmentConstant * 4;
		}
		
		public function setVertexConst(index:int, x:Number = 0, y:Number = 0, z:Number = 0, w:Number = 0):void
		{
			var _index:int = (index - _vertexConstantOffset) * 4;
			vertexConstantData[_index++] = x;
			vertexConstantData[_index++] = y;
			vertexConstantData[_index++] = z;
			vertexConstantData[_index] = w;
		}
		
		public function setVertexConstFromMatrix(index:int, matrix:Matrix3D):void
		{
			var rawData:Vector.<Number> = matrix.rawData;
			var _index:int = (index - _vertexConstantOffset) * 4;
			vertexConstantData[_index++] = rawData[0];
			vertexConstantData[_index++] = rawData[4];
			vertexConstantData[_index++] = rawData[8];
			vertexConstantData[_index++] = rawData[12];
			vertexConstantData[_index++] = rawData[1];
			vertexConstantData[_index++] = rawData[5];
			vertexConstantData[_index++] = rawData[9];
			vertexConstantData[_index++] = rawData[13];
			vertexConstantData[_index++] = rawData[2];
			vertexConstantData[_index++] = rawData[6];
			vertexConstantData[_index++] = rawData[10];
			vertexConstantData[_index++] = rawData[14];
			vertexConstantData[_index++] = rawData[3];
			vertexConstantData[_index++] = rawData[7];
			vertexConstantData[_index++] = rawData[11];
			vertexConstantData[_index] = rawData[15];
			
		}
		public function setFragmentConst(index:int, x:Number = 0, y:Number = 0, z:Number = 0, w:Number = 0):void
		{
			var _index:int = (index - _fragmentConstantOffset) * 4;
			fragmentConstantData[_index++] = x;
			fragmentConstantData[_index++] = y;
			fragmentConstantData[_index++] = z;
			fragmentConstantData[_index] = w;
		}
		
	}

}