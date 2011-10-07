package a3dparticle.animators.actions 
{
	import away3d.core.managers.Stage3DProxy;
	import flash.display3D.VertexBuffer3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class PerParticleAction extends ActionBase
	{
		
		protected var _vertexBuffer : VertexBuffer3D;
		protected var _vertices : Vector.<Number> = new Vector.<Number>();
		
		protected var dataLenght:uint = 1;
		
		public function PerParticleAction()
		{

		}
		
		public function genOne(index:uint):void
		{
			
		}
		
		public function distributeOne(index:int, verticeIndex:uint):void
		{
			
		}
		
		public function getVertexBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			if (!_vertexBuffer) {
				_vertexBuffer = stage3DProxy._context3D.createVertexBuffer(_vertices.length/dataLenght,dataLenght);
				_vertexBuffer.uploadFromVector(_vertices, 0, _vertices.length/dataLenght);
			}
			return _vertexBuffer;
		}
		
	}

}