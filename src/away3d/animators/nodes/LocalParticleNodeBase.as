package away3d.animators.nodes
{
	import away3d.animators.data.ParticleParameter;
	import away3d.animators.data.AnimationSubGeometry;
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
		
		public function generatePropertyOfOneParticle(param:ParticleParameter):void
		{
			
		}
		
		public function get oneData():Vector.<Number>
		{
			return _oneData;
		}
		
		//give a chance to lookup paramters other nodes generated
		public function processExtraData(param:ParticleParameter, animationSubGeometry:AnimationSubGeometry, numVertex:int):void
		{
			
		}
		
		
		protected function initOneData():void
		{
			_oneData = new Vector.<Number>(_dataLength, true);
		}
		
		
	}

}