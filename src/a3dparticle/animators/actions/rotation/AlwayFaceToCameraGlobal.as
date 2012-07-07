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
	public class AlwayFaceToCameraGlobal extends AllParticleAction
	{
		
		public function AlwayFaceToCameraGlobal() 
		{
			priority = 2;
		}
		
		override public function set animation(value:ParticleAnimation):void
		{
			value.needCameraPosition = true;
			super.animation = value;
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			var nrmVel:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(nrmVel, 1);
			
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(temp,1);
			var cos:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
			var sin:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
			var o_temp:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "z");
			var tempSingle:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "w");
			
			var R:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(R,1);
			
			shaderRegisterCache.removeVertexTempUsage(nrmVel);
			shaderRegisterCache.removeVertexTempUsage(temp);
			shaderRegisterCache.removeVertexTempUsage(R);
			
			var o_x:ShaderRegisterElement = new ShaderRegisterElement(_animation.scaleAndRotateTarget.regName, _animation.scaleAndRotateTarget.index, "x");
			var o_y:ShaderRegisterElement = new ShaderRegisterElement(_animation.scaleAndRotateTarget.regName, _animation.scaleAndRotateTarget.index, "y");
			var o_z:ShaderRegisterElement = new ShaderRegisterElement(_animation.scaleAndRotateTarget.regName, _animation.scaleAndRotateTarget.index, "z");
			
			var code:String = "";
			
			code += "sub " + nrmVel.toString() + ".xyz," + _animation.cameraPosConst.toString() + ".xyz," + _animation.offsetTarget.toString() + "\n";
			code += "nrm " + nrmVel.toString() + ".xyz," + nrmVel.toString() + ".xyz\n";			
						
			
			code += "mov " + sin.toString() + "," + nrmVel.toString() + ".y\n";
			code += "mul " + cos.toString() + "," + sin.toString() + "," + sin.toString() + "\n";
			code += "sub " + cos.toString() + "," + _animation.OneConst.toString() + "," + cos.toString() + "\n";
			code += "sqt " + cos.toString() + "," + cos.toString() + "\n";
			
			code += "mul " + R.toString() + ".x," + cos.toString() + "," + o_y.toString() + "\n";
			code += "mul " + R.toString() + ".y," + sin.toString() + "," + o_z.toString() + "\n";
			code += "mul " + R.toString() + ".z," + sin.toString() + "," + o_y.toString() + "\n";
			code += "mul " + R.toString() + ".w," + cos.toString() + "," + o_z.toString() + ".z\n";

			code += "sub " + o_y.toString() + "," + R.toString() + ".x," + R.toString() + ".y\n";
			code += "add " + o_z.toString() + "," + R.toString() + ".z," + R.toString() + ".w\n";
			
			
			code += "abs " + R.toString() + ".y," + nrmVel.toString() + ".y\n";
			code += "sge " + R.toString() + ".z," + R.toString() + ".y," + _animation.OneConst.toString() + "\n";
			code += "mul " + R.toString() + ".x," + R.toString() + ".y," + nrmVel.toString() + ".y\n";
			
			
			//judgu if nrmVel=(0,1,0);
			code += "mov " + nrmVel.toString() + ".y," + _animation.zeroConst.toString() + "\n";
			code += "dp3 " + sin.toString() + "," + nrmVel.toString() + ".xyz," + nrmVel.toString() + ".xyz\n";
			code += "sge " + tempSingle.toString() + "," + _animation.zeroConst.toString() +"," + sin.toString() + "\n";
			
			code += "mov " + nrmVel.toString() + ".y," + _animation.zeroConst.toString() + "\n";
			code += "nrm " + nrmVel.toString() + ".xyz," + nrmVel.toString() + ".xyz\n";
				

			code += "sub " + sin.toString() + "," +  _animation.OneConst.toString() + "," + tempSingle.toString() + "\n";
			code += "mul " + sin.toString() + "," +  sin.toString() + "," + nrmVel.toString() + ".x\n";
			
			code += "mov " + cos.toString() + "," + nrmVel.toString() + ".z\n";
			code += "neg " + cos.toString() + "," + cos.toString() + "\n";
			code += "sub " + o_temp.toString() + "," +  _animation.OneConst.toString() + "," + cos.toString() + "\n";
			code += "mul " + o_temp.toString() + "," +  R.toString() + ".x," + tempSingle.toString() + "\n";
			code += "add " + cos.toString() + "," +  cos.toString() + "," + o_temp.toString() + "\n";

			
			code += "mul " + R.toString() + ".x," + cos.toString() + "," + o_x.toString() + "\n";
			code += "mul " + R.toString() + ".y," + sin.toString() + "," + o_z.toString() + "\n";
			code += "mul " + R.toString() + ".z," + sin.toString() + "," + o_x.toString() + "\n";
			code += "mul " + R.toString() + ".w," + cos.toString() + "," + o_z.toString() + "\n";
			
			code += "sub " + o_x.toString() + "," + R.toString() + ".x," + R.toString() + ".y\n";
			code += "add " + o_z.toString() + "," + R.toString() + ".z," + R.toString() + ".w\n";
			
			return code;
		}
		
	}

}