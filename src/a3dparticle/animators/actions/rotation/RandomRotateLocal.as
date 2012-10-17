package a3dparticle.animators.actions.rotation
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
	public class RandomRotateLocal extends PerParticleAction
	{
		private var _genFun:Function;
		
		private var _tempRotateAxis:Vector3D;
		
		private var _tempRotateRate:Number;
		
		
		/**
		 *
		 * @param	fun Function.the function return a Vector3D. (Vector3d.x,Vector3d.y,Vector3d.z) is roatate axis,Vector3d.w is cycle time
		 */
		public function RandomRotateLocal(fun:Function=null)
		{
			priority = 3;
			dataLenght = 4;
			_name = "RandomRotateLocal";
			_genFun = fun;
		}
		
		override public function genOne(param:ParticleParam):void
		{
			var temp:Vector3D;
			if (_genFun != null)
			{
				temp = _genFun(param);
			}
			else
			{
				if (!param[_name]) throw new Error("there is no " + _name + " in param!");
				temp = param[_name];
			}
			_tempRotateAxis = new Vector3D(temp.x, temp.y, temp.z);
			_tempRotateAxis.normalize();
			_tempRotateRate = Math.PI/temp.w;
		}
		
		override public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			getExtraData(subContainer).push(_tempRotateAxis.x, _tempRotateAxis.y, _tempRotateAxis.z, _tempRotateRate);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			var roatateAttribute:ShaderRegisterElement = shaderRegisterCache.getFreeVertexAttribute();
			saveRegisterIndex("roatateAttribute", roatateAttribute.index);
			
			var nrmVel:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(nrmVel, 1);
			
			var xAxis:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(xAxis, 1);
			
			
			
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(temp, 1);
			var R:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "xyz");
			var R_rev:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			R_rev = new ShaderRegisterElement(R_rev.regName, R_rev.index, "xyz");
			
			var cos:ShaderRegisterElement = new ShaderRegisterElement(R.regName, R.index, "w");
			var sin:ShaderRegisterElement = new ShaderRegisterElement(R_rev.regName, R_rev.index, "w");
			
			shaderRegisterCache.removeVertexTempUsage(nrmVel);
			shaderRegisterCache.removeVertexTempUsage(xAxis);
			shaderRegisterCache.removeVertexTempUsage(temp);
			
			var code:String = "";
			code += "mov " + nrmVel.toString() + ".xyz," + roatateAttribute.toString() + ".xyz\n";
			code += "mov " + nrmVel.toString() + ".w," + animationRegistersManager.vertexZeroConst.toString() + "\n";
			
			code += "mul " + cos.toString() + "," + animationRegistersManager.vertexTime.toString() + "," + roatateAttribute.toString() + ".w\n";
			
			code += "sin " + sin.toString() + "," + cos.toString() + "\n";
			code += "cos " + cos.toString() + "," + cos.toString() + "\n";
			
			code += "mul " + R.toString() + "," + sin.toString() +"," + nrmVel.toString() + ".xyz\n";
			
			code += "mul " + R_rev.toString() + "," + sin.toString() + "," + nrmVel.toString() + ".xyz\n";
			code += "neg " + R_rev.toString() + "," + R_rev.toString() + "\n";
			
			//nrmVel and xAxis are used as temp register
			code += "crs " + nrmVel.toString() + ".xyz," + R.toString() + ".xyz," +animationRegistersManager.scaleAndRotateTarget.toString() + ".xyz\n";

			code += "mul " + xAxis.toString() + ".xyz," + cos.toString() +"," + animationRegistersManager.scaleAndRotateTarget.toString() + "\n";
			code += "add " + nrmVel.toString() + ".xyz," + nrmVel.toString() +".xyz," + xAxis.toString() + ".xyz\n";
			code += "dp3 " + xAxis.toString() + ".w," + R.toString() + "," +animationRegistersManager.scaleAndRotateTarget.toString() + "\n";
			code += "neg " + nrmVel.toString() + ".w," + xAxis.toString() + ".w\n";
			
			
			code += "crs " + R.toString() + "," + nrmVel.toString() + ".xyz," +R_rev.toString() + "\n";

			//use cos as R_rev.w
			code += "mul " + xAxis.toString() + ".xyzw," + nrmVel.toString() + ".xyzw," +cos.toString() + "\n";
			code += "add " + R.toString() + "," + R.toString() + "," + xAxis.toString() + ".xyz\n";
			code += "mul " + xAxis.toString() + ".xyz," + nrmVel.toString() + ".w," +R_rev.toString() + "\n";
			
			code += "add " + animationRegistersManager.scaleAndRotateTarget.toString() + "," + R.toString() + "," + xAxis.toString() + ".xyz\n";
			
			var len:int = animationRegistersManager.rotationRegisters.length;
			for (var i:int = 0; i < len; i++)
			{
				code += "mov " + nrmVel.toString() + ".xyz," + roatateAttribute.toString() + ".xyz\n";
				code += "mov " + nrmVel.toString() + ".w," + animationRegistersManager.vertexZeroConst.toString() + "\n";
				code += "mul " + cos.toString() + "," + animationRegistersManager.vertexTime.toString() + "," + roatateAttribute.toString() + ".w\n";
				code += "sin " + sin.toString() + "," + cos.toString() + "\n";
				code += "cos " + cos.toString() + "," + cos.toString() + "\n";
				code += "mul " + R.toString() + "," + sin.toString() +"," + nrmVel.toString() + ".xyz\n";
				code += "mul " + R_rev.toString() + "," + sin.toString() + "," + nrmVel.toString() + ".xyz\n";
				code += "neg " + R_rev.toString() + "," + R_rev.toString() + "\n";
				code += "crs " + nrmVel.toString() + ".xyz," + R.toString() + ".xyz," +animationRegistersManager.rotationRegisters[i].toString() + ".xyz\n";
				code += "mul " + xAxis.toString() + ".xyz," + cos.toString() +"," + animationRegistersManager.rotationRegisters[i].toString() + "\n";
				code += "add " + nrmVel.toString() + ".xyz," + nrmVel.toString() +".xyz," + xAxis.toString() + ".xyz\n";
				code += "dp3 " + xAxis.toString() + ".w," + R.toString() + "," +animationRegistersManager.rotationRegisters[i].toString() + "\n";
				code += "neg " + nrmVel.toString() + ".w," + xAxis.toString() + ".w\n";
				code += "crs " + R.toString() + "," + nrmVel.toString() + ".xyz," +R_rev.toString() + "\n";
				code += "mul " + xAxis.toString() + ".xyzw," + nrmVel.toString() + ".xyzw," +cos.toString() + "\n";
				code += "add " + R.toString() + "," + R.toString() + "," + xAxis.toString() + ".xyz\n";
				code += "mul " + xAxis.toString() + ".xyz," + nrmVel.toString() + ".w," +R_rev.toString() + "\n";
				code += "add " + animationRegistersManager.rotationRegisters[i].toString() + "," + R.toString() + "," + xAxis.toString() + ".xyz\n";
			}
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			stage3DProxy.context3D.setVertexBufferAt(getRegisterIndex("roatateAttribute"), getExtraBuffer(stage3DProxy, SubContainer(renderable)), 0, Context3DVertexBufferFormat.FLOAT_4);
		}
		
	}

}