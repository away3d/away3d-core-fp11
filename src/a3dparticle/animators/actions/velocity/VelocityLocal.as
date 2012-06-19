package a3dparticle.animators.actions.velocity 
{
	import a3dparticle.animators.actions.PerParticleAction;
	import a3dparticle.core.SubContainer;
	import a3dparticle.particle.ParticleParam;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Vector3D;
	/**
	 * ...
	 * @author ...
	 */
	public class VelocityLocal extends PerParticleAction
	{
		private var _velFun:Function;
		
		private var _tempVelocity:Vector3D;
		
		private var velocityAttribute:ShaderRegisterElement;
		/**
		 * 
		 * @param	fun Function.The fun should return a Vector3D whick (x,y,z) is the velocity.
		 */
		public function VelocityLocal(fun:Function=null) 
		{
			dataLenght = 3;
			_velFun = fun;
			_name = "VelocityLocal";
		}
		
		override public function genOne(param:ParticleParam):void
		{
			if (_velFun != null)
			{
				_tempVelocity = _velFun(param);
			}
			else
			{
				if (!param[_name]) throw new Error("there is no " + _name + " in param!");
				_tempVelocity = param[_name];
			}
		}
		
		override public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			getExtraData(subContainer).push(_tempVelocity.x);
			getExtraData(subContainer).push(_tempVelocity.y);
			getExtraData(subContainer).push(_tempVelocity.z);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			
			var distance:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			distance = new ShaderRegisterElement(distance.regName, distance.index, "xyz");
			velocityAttribute = shaderRegisterCache.getFreeVertexAttribute();
			var code:String = "";
			code += "mul " + distance.toString() + "," + _animation.vertexTime.toString() + "," + velocityAttribute.toString() + "\n";
			code += "add " + _animation.offsetTarget.toString() +"," + distance.toString() + "," + _animation.offsetTarget.toString() + "\n";
			if (_animation.needVelocity)
			{
				code += "add " + _animation.velocityTarget.toString() + ".xyz," + velocityAttribute.toString() + ".xyz," + _animation.velocityTarget.toString() + "\n";
			}
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			stage3DProxy.setSimpleVertexBuffer(velocityAttribute.index, getExtraBuffer(stage3DProxy, SubContainer(renderable)), Context3DVertexBufferFormat.FLOAT_3, 0);
		}
		
	}

}