package a3dparticle.animators.actions.rotation 
{
	import a3dparticle.animators.actions.AllParticleAction;
	import a3dparticle.animators.ParticleAnimation;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
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
			priority = 2;
		}
		
		override public function set animation(value:ParticleAnimation):void
		{
			value.needVelocity = true;
			super.animation = value;
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			var nrmVel:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(nrmVel, 1);
			
			var xAxis:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(xAxis, 1);
			
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(temp,1);
			var cos:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
			var sin:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
			var cos2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "z");
			var tempSingle:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "w");
			
			var R:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(R,1);
			var R_rev:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			
			shaderRegisterCache.removeVertexTempUsage(nrmVel);
			shaderRegisterCache.removeVertexTempUsage(xAxis);
			shaderRegisterCache.removeVertexTempUsage(temp);
			shaderRegisterCache.removeVertexTempUsage(R);
			
			var code:String = "";
			code += "mov " + xAxis.toString() + ".x," + _animation.OneConst.toString() + ".x\n";
			code += "mov " + xAxis.toString() + ".yz," + _animation.zeroConst.toString() + ".xy\n";
			
			
			code += "nrm " + nrmVel.toString() + ".xyz," + _animation.velocityTarget.toString() + ".xyz\n";
			code += "dp3 " + cos2.toString() + "," + nrmVel.toString() + ".xyz," + xAxis.toString() + ".xyz\n";
			code += "crs " + nrmVel.toString() + ".xyz," + xAxis.toString() + ".xyz," + nrmVel.toString() + ".xyz\n";
			code += "nrm " + nrmVel.toString() + ".xyz," + nrmVel.toString() + ".xyz\n";
			//use R as temp to judge if nrm is (0,0,0).
			//if nrm is (0,0,0) ,change it to (0,0,1).
			code += "dp3 " + R.toString() + ".x," + nrmVel.toString() + ".xyz," + nrmVel.toString() + ".xyz\n";
			code += "sge " + R.toString() + ".x," + _animation.zeroConst.toString() + ".x," + R.toString() + ".x\n";
			code += "add " +nrmVel.toString() + ".z," + R.toString() + ".x," + nrmVel.toString() + ".z\n";
			
			
			code += "add " + tempSingle.toString() + "," + cos2.toString() + "," + _animation.OneConst.toString() + "\n";
			code += "div " + tempSingle.toString() + "," + tempSingle.toString() + "," + _animation.TwoConst.toString() + "\n";
			code += "sqt " + cos.toString() + "," + tempSingle.toString() + "\n";
			
			code += "sub " + tempSingle.toString() + "," + _animation.OneConst.toString() + "," + cos2.toString() + "\n";
			code += "div " + tempSingle.toString() + "," + tempSingle.toString() + "," + _animation.TwoConst.toString() + "\n";
			code += "sqt " + sin.toString() + "," + tempSingle.toString() + "\n";
			
			
			code += "mul " + R.toString() + ".xyz," + sin.toString() +"," + nrmVel.toString() + ".xyz\n";
			//code += "mov " + R.toString() + ".w," + cos.toString() + "\n";
			//use cos as R.w
			
			code += "mul " + R_rev.toString() + ".xyz," + sin.toString() + "," + nrmVel.toString() + ".xyz\n";
			code += "neg " + R_rev.toString() + ".xyz," + R_rev.toString() + ".xyz\n";
			//code += "mov " + R_rev.toString() + ".w," + cos.toString() + "\n";
			//use cos as R_rev.w
			
			//nrmVel and xAxis are used as temp register
			code += "crs " + nrmVel.toString() + ".xyz," + R.toString() + ".xyz," +_animation.scaleAndRotateTarget.toString() + ".xyz\n";
			//code += "mul " + xAxis.toString() + ".xyz," + R.toString() +".w," + _animation.scaleAndRotateTarget.toString() + ".xyz\n";
			//use cos as R.w
			code += "mul " + xAxis.toString() + ".xyz," + cos.toString() +"," + _animation.scaleAndRotateTarget.toString() + ".xyz\n";
			code += "add " + nrmVel.toString() + ".xyz," + nrmVel.toString() +".xyz," + xAxis.toString() + ".xyz\n";
			code += "dp3 " + xAxis.toString() + ".w," + R.toString() + ".xyz," +_animation.scaleAndRotateTarget.toString() + ".xyz\n";
			code += "neg " + nrmVel.toString() + ".w," + xAxis.toString() + ".w\n";
			
			
			code += "crs " + R.toString() + ".xyz," + nrmVel.toString() + ".xyz," +R_rev.toString() + ".xyz\n";
			//code += "mul " + xAxis.toString() + ".xyzw," + nrmVel.toString() + ".xyzw," +R_rev.toString() + ".w\n";
			code += "mul " + xAxis.toString() + ".xyzw," + nrmVel.toString() + ".xyzw," +cos.toString() + "\n";
			code += "add " + R.toString() + ".xyz," + R.toString() + ".xyz," + xAxis.toString() + ".xyz\n";
			code += "mul " + xAxis.toString() + ".xyz," + nrmVel.toString() + ".w," +R_rev.toString() + ".xyz\n";
			
			code += "add " + _animation.scaleAndRotateTarget.toString() + ".xyz," + R.toString() + ".xyz," + xAxis.toString() + ".xyz\n";
			
			return code;
		}
		
	}

}