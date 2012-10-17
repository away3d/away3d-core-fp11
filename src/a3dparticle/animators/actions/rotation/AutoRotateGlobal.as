package a3dparticle.animators.actions.rotation
{
	import a3dparticle.animators.actions.AllParticleAction;
	import a3dparticle.animators.ParticleAnimation;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.compilation.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Vector3D;
	/**
	 * ...
	 * @author ...
	 */
	public class AutoRotateGlobal extends AllParticleAction
	{
		
		public function AutoRotateGlobal()
		{
			priority = 3;
		}
		
		override public function reset(value:ParticleAnimation):void
		{
			value._animation.needVelocity = true;
			super.reset(value);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			var nrmVel:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(nrmVel, 1);
			
			var xAxis:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(xAxis, 1);
			
			var R:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(R,1);
			var R_rev:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var cos:ShaderRegisterElement = new ShaderRegisterElement(R.regName, R.index, "w");
			var sin:ShaderRegisterElement = new ShaderRegisterElement(R_rev.regName, R_rev.index, "w");
			var cos2:ShaderRegisterElement = new ShaderRegisterElement(nrmVel.regName, nrmVel.index, "w");
			var tempSingle:ShaderRegisterElement = sin;
			
			
			shaderRegisterCache.removeVertexTempUsage(nrmVel);
			shaderRegisterCache.removeVertexTempUsage(xAxis);
			shaderRegisterCache.removeVertexTempUsage(R);
			
			var code:String = "";
			code += "mov " + xAxis.toString() + ".x," + animationRegistersManager.vertexOneConst.toString() + ".x\n";
			code += "mov " + xAxis.toString() + ".yz," + animationRegistersManager.vertexZeroConst.toString() + ".xy\n";
			
			
			code += "nrm " + nrmVel.toString() + ".xyz," + animationRegistersManager.velocityTarget.toString() + ".xyz\n";
			code += "dp3 " + cos2.toString() + "," + nrmVel.toString() + ".xyz," + xAxis.toString() + ".xyz\n";
			code += "crs " + nrmVel.toString() + ".xyz," + xAxis.toString() + ".xyz," + nrmVel.toString() + ".xyz\n";
			code += "nrm " + nrmVel.toString() + ".xyz," + nrmVel.toString() + ".xyz\n";
			//use R as temp to judge if nrm is (0,0,0).
			//if nrm is (0,0,0) ,change it to (0,0,1).
			code += "dp3 " + R.toString() + ".x," + nrmVel.toString() + ".xyz," + nrmVel.toString() + ".xyz\n";
			code += "sge " + R.toString() + ".x," + animationRegistersManager.vertexZeroConst.toString() + ".x," + R.toString() + ".x\n";
			code += "add " +nrmVel.toString() + ".z," + R.toString() + ".x," + nrmVel.toString() + ".z\n";
			
			
			code += "add " + tempSingle.toString() + "," + cos2.toString() + "," + animationRegistersManager.vertexOneConst.toString() + "\n";
			code += "div " + tempSingle.toString() + "," + tempSingle.toString() + "," + animationRegistersManager.vertexTwoConst.toString() + "\n";
			code += "sqt " + cos.toString() + "," + tempSingle.toString() + "\n";
			
			code += "sub " + tempSingle.toString() + "," + animationRegistersManager.vertexOneConst.toString() + "," + cos2.toString() + "\n";
			code += "div " + tempSingle.toString() + "," + tempSingle.toString() + "," + animationRegistersManager.vertexTwoConst.toString() + "\n";
			code += "sqt " + sin.toString() + "," + tempSingle.toString() + "\n";
			
			
			code += "mul " + R.toString() + ".xyz," + sin.toString() +"," + nrmVel.toString() + ".xyz\n";
			//code += "mov " + R.toString() + ".w," + cos.toString() + "\n";
			//use cos as R.w
			
			code += "mul " + R_rev.toString() + ".xyz," + sin.toString() + "," + nrmVel.toString() + ".xyz\n";
			code += "neg " + R_rev.toString() + ".xyz," + R_rev.toString() + ".xyz\n";
			//code += "mov " + R_rev.toString() + ".w," + cos.toString() + "\n";
			//use cos as R_rev.w
			
			//nrmVel and xAxis are used as temp register
			code += "crs " + nrmVel.toString() + ".xyz," + R.toString() + ".xyz," +animationRegistersManager.scaleAndRotateTarget.toString() + ".xyz\n";
			//code += "mul " + xAxis.toString() + ".xyz," + R.toString() +".w," + animationRegistersManager.scaleAndRotateTarget.toString() + ".xyz\n";
			//use cos as R.w
			code += "mul " + xAxis.toString() + ".xyz," + cos.toString() +"," + animationRegistersManager.scaleAndRotateTarget.toString() + ".xyz\n";
			code += "add " + nrmVel.toString() + ".xyz," + nrmVel.toString() +".xyz," + xAxis.toString() + ".xyz\n";
			code += "dp3 " + xAxis.toString() + ".w," + R.toString() + ".xyz," +animationRegistersManager.scaleAndRotateTarget.toString() + ".xyz\n";
			code += "neg " + nrmVel.toString() + ".w," + xAxis.toString() + ".w\n";
			
			
			code += "crs " + R.toString() + ".xyz," + nrmVel.toString() + ".xyz," +R_rev.toString() + ".xyz\n";
			//code += "mul " + xAxis.toString() + ".xyzw," + nrmVel.toString() + ".xyzw," +R_rev.toString() + ".w\n";
			code += "mul " + xAxis.toString() + ".xyzw," + nrmVel.toString() + ".xyzw," +cos.toString() + "\n";
			code += "add " + R.toString() + ".xyz," + R.toString() + ".xyz," + xAxis.toString() + ".xyz\n";
			code += "mul " + xAxis.toString() + ".xyz," + nrmVel.toString() + ".w," +R_rev.toString() + ".xyz\n";
			
			code += "add " + animationRegistersManager.scaleAndRotateTarget.toString() + ".xyz," + R.toString() + ".xyz," + xAxis.toString() + ".xyz\n";
			
			var len:int = animationRegistersManager.rotationRegisters.length;
			for (var i:int = 0; i < len; i++)
			{
				//just repeat the calculate above
				//because of the limited registers, no need to optimise
				code += "mov " + xAxis.toString() + ".x," + animationRegistersManager.vertexOneConst.toString() + ".x\n";
				code += "mov " + xAxis.toString() + ".yz," + animationRegistersManager.vertexZeroConst.toString() + ".xy\n";
				code += "nrm " + nrmVel.toString() + ".xyz," + animationRegistersManager.velocityTarget.toString() + ".xyz\n";
				code += "dp3 " + cos2.toString() + "," + nrmVel.toString() + ".xyz," + xAxis.toString() + ".xyz\n";
				code += "crs " + nrmVel.toString() + ".xyz," + xAxis.toString() + ".xyz," + nrmVel.toString() + ".xyz\n";
				code += "nrm " + nrmVel.toString() + ".xyz," + nrmVel.toString() + ".xyz\n";
				code += "dp3 " + R.toString() + ".x," + nrmVel.toString() + ".xyz," + nrmVel.toString() + ".xyz\n";
				code += "sge " + R.toString() + ".x," + animationRegistersManager.vertexZeroConst.toString() + ".x," + R.toString() + ".x\n";
				code += "add " +nrmVel.toString() + ".z," + R.toString() + ".x," + nrmVel.toString() + ".z\n";
				code += "add " + tempSingle.toString() + "," + cos2.toString() + "," + animationRegistersManager.vertexOneConst.toString() + "\n";
				code += "div " + tempSingle.toString() + "," + tempSingle.toString() + "," + animationRegistersManager.vertexTwoConst.toString() + "\n";
				code += "sqt " + cos.toString() + "," + tempSingle.toString() + "\n";
				code += "sub " + tempSingle.toString() + "," + animationRegistersManager.vertexOneConst.toString() + "," + cos2.toString() + "\n";
				code += "div " + tempSingle.toString() + "," + tempSingle.toString() + "," + animationRegistersManager.vertexTwoConst.toString() + "\n";
				code += "sqt " + sin.toString() + "," + tempSingle.toString() + "\n";
				code += "mul " + R.toString() + ".xyz," + sin.toString() +"," + nrmVel.toString() + ".xyz\n";
				code += "mul " + R_rev.toString() + ".xyz," + sin.toString() + "," + nrmVel.toString() + ".xyz\n";
				code += "neg " + R_rev.toString() + ".xyz," + R_rev.toString() + ".xyz\n";
				code += "crs " + nrmVel.toString() + ".xyz," + R.toString() + ".xyz," +animationRegistersManager.rotationRegisters[i].toString() + ".xyz\n";
				code += "mul " + xAxis.toString() + ".xyz," + cos.toString() +"," + animationRegistersManager.rotationRegisters[i].toString() + ".xyz\n";
				code += "add " + nrmVel.toString() + ".xyz," + nrmVel.toString() +".xyz," + xAxis.toString() + ".xyz\n";
				code += "dp3 " + xAxis.toString() + ".w," + R.toString() + ".xyz," +animationRegistersManager.rotationRegisters[i].toString() + ".xyz\n";
				code += "neg " + nrmVel.toString() + ".w," + xAxis.toString() + ".w\n";
				code += "crs " + R.toString() + ".xyz," + nrmVel.toString() + ".xyz," +R_rev.toString() + ".xyz\n";
				code += "mul " + xAxis.toString() + ".xyzw," + nrmVel.toString() + ".xyzw," +cos.toString() + "\n";
				code += "add " + R.toString() + ".xyz," + R.toString() + ".xyz," + xAxis.toString() + ".xyz\n";
				code += "mul " + xAxis.toString() + ".xyz," + nrmVel.toString() + ".w," +R_rev.toString() + ".xyz\n";
				code += "add " + animationRegistersManager.rotationRegisters[i].toString() + ".xyz," + R.toString() + ".xyz," + xAxis.toString() + ".xyz\n";
			}
			
			return code;
		}
		
	}

}