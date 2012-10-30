package away3d.animators.data
{
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.core.managers.Stage3DProxy;
	import flash.display3D.Context3D;
	import flash.display3D.VertexBuffer3D;
	import flash.utils.Dictionary;
	/**
	 * ...
	 */
	public class ParticleStreamManager
	{
		protected var _vertexData:Vector.<Number>;
		
		protected var _vertexBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _bufferContext : Vector.<Context3D> = new Vector.<Context3D>(8);
		
		protected var _numVertices:uint;
		protected var _totalLenOfOneVertex:int;
		
		public var numInitedVertices:int;
		
		private var _recorder:Dictionary = new Dictionary(true);
		
		public var extraStorage:Dictionary = new Dictionary(true);
		
		public function get totalLenOfOneVertex():int
		{
			return _totalLenOfOneVertex;
		}
		
		public function getNodeDataOffset(node:ParticleNodeBase):int
		{
			return _recorder[node];
		}
		
		public function applyData(dataLen:int,node:ParticleNodeBase):void
		{
			if (_totalLenOfOneVertex > 0)
			{
				_recorder[node] = _totalLenOfOneVertex;
				_totalLenOfOneVertex += dataLen;
			}
			else
			{
				_recorder[node] = 0;
				_totalLenOfOneVertex = dataLen;
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
		
		public function get numVertices():uint
		{
			return _numVertices;
		}
		
	}

}