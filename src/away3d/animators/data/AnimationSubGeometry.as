package away3d.animators.data
{
	import away3d.core.managers.Stage3DProxy;
	
	import flash.display3D.Context3D;
	import flash.display3D.VertexBuffer3D;
	
	/**
	 * ...
	 */
	public class AnimationSubGeometry
	{
		protected var _vertexData:Vector.<Number>;
		
		protected var _vertexBuffer:Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _bufferContext:Vector.<Context3D> = new Vector.<Context3D>(8);
		protected var _bufferDirty:Vector.<Boolean> = new Vector.<Boolean>(8);
		
		private var _numVertices:uint;
		
		private var _totalLenOfOneVertex:uint;
		
		public var numProcessedVertices:int = 0;
		
		public var previousTime:Number = Number.NEGATIVE_INFINITY;
		
		public var animationParticles:Vector.<ParticleAnimationData> = new Vector.<ParticleAnimationData>();
		
		public function AnimationSubGeometry()
		{
			for (var i:int = 0; i < 8; i++)
				_bufferDirty[i] = true;
		}
		
		public function createVertexData(numVertices:uint, totalLenOfOneVertex:uint):void
		{
			_numVertices = numVertices;
			_totalLenOfOneVertex = totalLenOfOneVertex;
			_vertexData = new Vector.<Number>(numVertices*totalLenOfOneVertex, true);
		}
		
		public function activateVertexBuffer(index:int, bufferOffset:int, stage3DProxy:Stage3DProxy, format:String):void
		{
			var contextIndex:int = stage3DProxy.stage3DIndex;
			var context:Context3D = stage3DProxy.context3D;
			
			var buffer:VertexBuffer3D = _vertexBuffer[contextIndex];
			if (!buffer || _bufferContext[contextIndex] != context) {
				buffer = _vertexBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _totalLenOfOneVertex);
				_bufferContext[contextIndex] = context;
				_bufferDirty[contextIndex] = true;
			}
			if (_bufferDirty[contextIndex]) {
				buffer.uploadFromVector(_vertexData, 0, _numVertices);
				_bufferDirty[contextIndex] = false;
			}
			context.setVertexBufferAt(index, buffer, bufferOffset, format);
		}
		
		public function dispose():void
		{
			while (_vertexBuffer.length) {
				var vertexBuffer:VertexBuffer3D = _vertexBuffer.pop()
				
				if (vertexBuffer)
					vertexBuffer.dispose();
			}
		}
		
		public function invalidateBuffer():void
		{
			for (var i:int = 0; i < 8; i++)
				_bufferDirty[i] = true;
		}
		
		public function get vertexData():Vector.<Number>
		{
			return _vertexData;
		}
		
		public function get numVertices():uint
		{
			return _numVertices;
		}
		
		public function get totalLenOfOneVertex():uint
		{
			return _totalLenOfOneVertex;
		}
	}
}
