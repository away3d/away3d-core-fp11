package a3dparticle.animators.actions.acceleration
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
	public class AccelerateLocal extends PerParticleAction
	{
		private var _accFun:Function;
		
		private var _tempAcc:Vector3D;
		
		
		/**
		 *
		 * @param	fun Function.The fun return a Vector3D that (x,y,z) is a acceleration.
		 */
		public function AccelerateLocal(fun:Function=null)
		{
			dataLenght = 3;
			_name = "AccelerateLocal";
			_accFun = fun;
		}
		
		override public function genOne(param:ParticleParam):void
		{
			if (_accFun != null)
			{
				_tempAcc = _accFun(param);
			}
			else
			{
				if (!param[_name]) throw(Error("there is no " + _name + " in param!"));
				_tempAcc = param[_name];
			}
		}
		
		override public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			getExtraData(subContainer).push(_tempAcc.x, _tempAcc.y, _tempAcc.z);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			var accAttribute:ShaderRegisterElement = shaderRegisterCache.getFreeVertexAttribute();
			saveRegisterIndex("accAttribute", accAttribute.index);
			
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(temp,1);
			
			var code:String = "";
			
			code += "mul " + temp.toString() +"," + animationRegistersManager.vertexTime.toString() + "," + accAttribute.toString() + "\n";
			
			if (_animation.needVelocity)
			{
				var temp2:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
				code += "mul " + temp2.toString() + "," + temp.toString() + "," + animationRegistersManager.vertexTwoConst.toString() + "\n";
				code += "add " + animationRegistersManager.velocityTarget.toString() + ".xyz," + temp2.toString() + ".xyz," + animationRegistersManager.velocityTarget.toString() + "\n";
			}
			shaderRegisterCache.removeVertexTempUsage(temp);
			
			code += "mul " + temp.toString() +"," + temp.toString() + "," + animationRegistersManager.vertexTime.toString() + "\n";
			code += "add " + animationRegistersManager.offsetTarget.toString() +".xyz," + temp.toString() + "," + animationRegistersManager.offsetTarget.toString() + ".xyz\n";
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			stage3DProxy.context3D.setVertexBufferAt(getRegisterIndex("accAttribute"), getExtraBuffer(stage3DProxy, SubContainer(renderable)), 0, Context3DVertexBufferFormat.FLOAT_3);
		}
		
	}

}