package a3dparticle.animators.actions.velocity
{
	import a3dparticle.animators.actions.PerParticleAction;
	import a3dparticle.core.SubContainer;
	import a3dparticle.particle.ParticleParam;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.compilation.ShaderRegisterElement;
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
			getExtraData(subContainer).push(_tempVelocity.x,_tempVelocity.y,_tempVelocity.z);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			
			var distance:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			distance = new ShaderRegisterElement(distance.regName, distance.index, "xyz");
			var velocityAttribute:ShaderRegisterElement = shaderRegisterCache.getFreeVertexAttribute();
			saveRegisterIndex("velocityAttribute", velocityAttribute.index);
			var code:String = "";
			code += "mul " + distance.toString() + "," + animationRegistersManager.vertexTime.toString() + "," + velocityAttribute.toString() + "\n";
			code += "add " + animationRegistersManager.offsetTarget.toString() +"," + distance.toString() + "," + animationRegistersManager.offsetTarget.toString() + "\n";
			if (_animation.needVelocity)
			{
				code += "add " + animationRegistersManager.velocityTarget.toString() + ".xyz," + velocityAttribute.toString() + ".xyz," + animationRegistersManager.velocityTarget.toString() + "\n";
			}
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			stage3DProxy.context3D.setVertexBufferAt(getRegisterIndex("velocityAttribute"), getExtraBuffer(stage3DProxy, SubContainer(renderable)), 0, Context3DVertexBufferFormat.FLOAT_3);
		}
		
	}

}