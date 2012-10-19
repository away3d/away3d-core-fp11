package away3d.animators.nodes
{
	import away3d.animators.data.ParticleParamter;
	import flash.display3D.Context3D;
	import flash.display3D.VertexBuffer3D;
	
	/**
	 * ...
	 * @author ...
	 */
	public class LocalParticleNodeBase extends ParticleNodeBase
	{
		
		protected var _vertexBuffer : VertexBuffer3D;
		protected var _vertices : Vector.<Number> = new Vector.<Number>();
		
		protected var context3D:Context3D;
		
		protected var _oneData:Vector.<Number>;
		
		public function LocalParticleNodeBase(name:String, priority:int = 1)
		{
			super(name, ParticleNodeBase.LOCAL, priority);
		}
		
		public function generatePorpertyOfOneParticle(param:ParticleParamter):void
		{
			
		}
		
		public function get oneData():Vector.<Number>
		{
			return _oneData;
		}
		
		
		protected function initOneData():void
		{
			_oneData = new Vector.<Number>(_dataLenght, true);
		}
		
		
	}

}