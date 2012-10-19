package away3d.animators.data
{
	import away3d.core.managers.Stage3DProxy;
	import flash.display3D.Context3D;
	import flash.display3D.VertexBuffer3D;
	/**
	 * ...
	 */
	public class ParticleStreamManager
	{
		protected var _vertexData:Vector.<Number>;
		protected var _offsetRecord:Vector.<int> = new Vector.<int>;
		
		protected var _vertexBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _bufferContext : Vector.<Context3D> = new Vector.<Context3D>(8);
		
		protected var _numVertices:uint;
		protected var _totalLenOfOneVertex:int;
		
		public var numInitedVertices:int;
		
		
		public function get totalLenOfOneVertex():int
		{
			return _totalLenOfOneVertex;
		}
		
		public function applyData(dataLen:int):int
		{
			var oldLen:int = _offsetRecord.length;
			if (oldLen > 0)
			{
				var offset:int = _totalLenOfOneVertex;
				_totalLenOfOneVertex += dataLen;
				_offsetRecord.push(_totalLenOfOneVertex);
				return offset;
			}
			else
			{
				_totalLenOfOneVertex = dataLen;
				_offsetRecord.push(_totalLenOfOneVertex);
				return 0;
			}
		}
		
		public function setVertexNum(value:uint):void
		{
			_numVertices = value;
			_vertexData = new Vector.<Number>(value * _totalLenOfOneVertex, true);
		}
		
		public function activateVertexBuffer(index : int, bufferOffset:int, stage3DProxy : Stage3DProxy, format:String) : void
		{
			var contextIndex : int = stage3DProxy.stage3DIndex;
			var context : Context3D = stage3DProxy.context3D;
			
			var buffer:VertexBuffer3D = _vertexBuffer[contextIndex];
			if (!buffer || _bufferContext[contextIndex] != context)
			{
				buffer = _vertexBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _totalLenOfOneVertex);
				buffer.uploadFromVector(vertexData, 0, _numVertices);
				_bufferContext[contextIndex] = context;
			}
			context.setVertexBufferAt(index, buffer, bufferOffset, format);
		}
		
		public function get vertexData():Vector.<Number>
		{
			return _vertexData;
		}
		
	}

}