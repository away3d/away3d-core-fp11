package away3d.animators.data
{
	import away3d.core.managers.Stage3DProxy;
	import flash.display3D.Context3D;
	import flash.display3D.VertexBuffer3D;
	/**
	 * ...
	 */
	public class ParticleFollowStream
	{
		public var previousTime:Number;
		private var _storage:ParticleFollowStorage;
		
		protected var _vertexData:Vector.<Number>;
		
		protected var _vertexBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _bufferContext : Vector.<Context3D> = new Vector.<Context3D>(8);
		protected var _bufferDirty : Vector.<Boolean> = new Vector.<Boolean>(8);
		
		public function ParticleFollowStream(stroage:ParticleFollowStorage)
		{
			_storage = stroage;
			_vertexData = new Vector.<Number>(_storage.numVertices * _storage.dataLength, true);
			for (var i:int = 0; i < 8; i++)
			{
				_bufferDirty[i] = true;
			}
		}
		
		public function activateVertexBuffer(index : int, bufferOffset:int, stage3DProxy : Stage3DProxy, format:String) : void
		{
			var contextIndex : int = stage3DProxy.stage3DIndex;
			var context : Context3D = stage3DProxy.context3D;
			
			var buffer:VertexBuffer3D = _vertexBuffer[contextIndex];
			if (!buffer || _bufferContext[contextIndex] != context)
			{
				buffer = _vertexBuffer[contextIndex] = context.createVertexBuffer(_storage.numVertices, _storage.dataLength);
				_bufferContext[contextIndex] = context;
			}
			if (_bufferDirty[contextIndex])
			{
				buffer.uploadFromVector(_vertexData, 0, _storage.numVertices);
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
		
		public function get itemList():Vector.<ParticleFollowingItem>
		{
			return _storage.itemList;
		}
	}

}