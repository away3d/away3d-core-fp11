package a3dparticle.animators.actions 
{
	import a3dparticle.core.SubContainer;
	import a3dparticle.particle.ParticleParam;
	import away3d.core.managers.Stage3DProxy;
	import flash.display3D.Context3D;
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
		protected var _name:String = "PerParticleAction";
		
		protected var context3D:Context3D;
		
		public function PerParticleAction()
		{

		}
		
		public function genOne(param:ParticleParam):void
		{
			
		}
		
		public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			
		}
		
		public function getExtraData(subContainer:SubContainer):Vector.<Number>
		{
			if (!subContainer.extraDatas[_name])
			{
				subContainer.extraDatas[_name] = new Vector.<Number>;
			}
			return subContainer.extraDatas[_name];
		}
		
		public function getExtraBuffer(stage3DProxy : Stage3DProxy,subContainer:SubContainer) : VertexBuffer3D
		{
			if (!subContainer.extraBuffers[_name] || context3D != stage3DProxy.context3D)
			{
				subContainer.extraBuffers[_name] = stage3DProxy._context3D.createVertexBuffer(subContainer.extraDatas[_name].length / dataLenght, dataLenght);
				subContainer.extraBuffers[_name].uploadFromVector(subContainer.extraDatas[_name], 0, subContainer.extraDatas[_name].length / dataLenght);
				context3D = stage3DProxy.context3D;
			}
			return subContainer.extraBuffers[_name];
		}
		
	}

}