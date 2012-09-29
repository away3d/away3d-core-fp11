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
			return subContainer.getExtraData(_name);
		}
		
		public function getExtraBuffer(stage3DProxy : Stage3DProxy,subContainer:SubContainer) : VertexBuffer3D
		{
			return subContainer.getExtraBuffer(stage3DProxy, _name, dataLenght);
		}
		
	}

}