package away3d.animators.data
{
	import away3d.core.managers.Stage3DProxy;
	import flash.display3D.Context3D;
	import flash.display3D.VertexBuffer3D;
	/**
	 * ...
	 */
	public class FollowStorage
	{
		public var previousTime:Number;
		protected var _itemList:Vector.<ParticleFollowingItem> = new Vector.<ParticleFollowingItem>;
		protected var _vertexData:Vector.<Number>;
		protected var _numVertices:uint;
		protected var _dataLength:int;
		
		protected var _vertexBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _bufferContext : Vector.<Context3D> = new Vector.<Context3D>(8);
		protected var _bufferDirty : Vector.<Boolean> = new Vector.<Boolean>(8);
		
		public function FollowStorage()
		{
			for (var i:int = 0; i < 8; i++)
			{
				_bufferDirty[i] = true;
			}
		}
		
		public function initData(numVertices:uint,dataLength:int):void
		{
			_numVertices = numVertices;
			_dataLength = dataLength;
			_vertexData = new Vector.<Number>(_numVertices * _dataLength, true);
		}
		
		public function activateVertexBuffer(index : int, bufferOffset:int, stage3DProxy : Stage3DProxy, format:String) : void
		{
			var contextIndex : int = stage3DProxy.stage3DIndex;
			var context : Context3D = stage3DProxy.context3D;
			
			var buffer:VertexBuffer3D = _vertexBuffer[contextIndex];
			if (!buffer || _bufferContext[contextIndex] != context)
			{
				buffer = _vertexBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _dataLength);
				_bufferContext[contextIndex] = context;
			}
			if (_bufferDirty[contextIndex])
			{
				buffer.uploadFromVector(_vertexData, 0, _numVertices);
				_bufferDirty[contextIndex] = false;
			}
			context.setVertexBufferAt(index, buffer, bufferOffset, format);
		}
		
		public function invalidateBuffer():void
		{
			for (var i:int = 0; i < 8; i++)
			{
				_bufferDirty[i] = true;
			}
		}
		
		public function get vertexData():Vector.<Number>
		{
			return _vertexData;
		}
		
		public function get numVertices():uint
		{
			return _numVertices;
		}
		
		public function get itemList():Vector.<ParticleFollowingItem>
		{
			return _itemList;
		}
	}

}