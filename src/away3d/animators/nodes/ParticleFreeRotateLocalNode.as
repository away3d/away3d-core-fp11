package away3d.animators.nodes
{
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.data.ParticleParamter;
	import away3d.animators.states.ParticleFreeRotateLocalState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Vector3D;

	/**
	 * ...
	 */
	public class ParticleFreeRotateLocalNode extends LocalParticleNodeBase
	{
		public static const NAME:String = "ParticleFreeRotateLocalNode";
		public static const ROTATE_STREAM_REGISTER:int = 0;
		
		public function ParticleFreeRotateLocalNode()
		{
			super(NAME, 3);
			_stateClass = ParticleFreeRotateLocalState;
			_dataLenght = 4;
			initOneData();
		}
		
		override public function generatePorpertyOfOneParticle(param:ParticleParamter):void
		{
			//(Vector3d.x,Vector3d.y,Vector3d.z) is rotation axis,Vector3d.w is cycle time
			var rotate:Vector3D = param[NAME];
			if (!rotate)
				throw(new Error("there is no " + NAME + " in param!"));
			
			_oneData[0] = rotate.x;
			_oneData[1] = rotate.y;
			_oneData[2] = rotate.z;
			_oneData[3] = Math.PI / rotate.w;
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, animationRegisterCache:AnimationRegisterCache) : String
		{
			var roatateAttribute:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
			animationRegisterCache.setRegisterIndex(this, ROTATE_STREAM_REGISTER, roatateAttribute.index);
			
			var nrmVel:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			animationRegisterCache.addVertexTempUsages(nrmVel, 1);
			
			var xAxis:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			animationRegisterCache.addVertexTempUsages(xAxis, 1);
			
			
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			animationRegisterCache.addVertexTempUsages(temp, 1);
			var R:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "xyz");
			var R_rev:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			R_rev = new ShaderRegisterElement(R_rev.regName, R_rev.index, "xyz");
			
			var cos:ShaderRegisterElement = new ShaderRegisterElement(R.regName, R.index, "w");
			var sin:ShaderRegisterElement = new ShaderRegisterElement(R_rev.regName, R_rev.index, "w");
			
			animationRegisterCache.removeVertexTempUsage(nrmVel);
			animationRegisterCache.removeVertexTempUsage(xAxis);
			animationRegisterCache.removeVertexTempUsage(temp);
			
			var code:String = "";
			code += "mov " + nrmVel.toString() + ".xyz," + roatateAttribute.toString() + ".xyz\n";
			code += "mov " + nrmVel.toString() + ".w," + animationRegisterCache.vertexZeroConst.toString() + "\n";
			
			code += "mul " + cos.toString() + "," + animationRegisterCache.vertexTime.toString() + "," + roatateAttribute.toString() + ".w\n";
			
			code += "sin " + sin.toString() + "," + cos.toString() + "\n";
			code += "cos " + cos.toString() + "," + cos.toString() + "\n";
			
			code += "mul " + R.toString() + "," + sin.toString() +"," + nrmVel.toString() + ".xyz\n";
			
			code += "mul " + R_rev.toString() + "," + sin.toString() + "," + nrmVel.toString() + ".xyz\n";
			code += "neg " + R_rev.toString() + "," + R_rev.toString() + "\n";
			
			//nrmVel and xAxis are used as temp register
			code += "crs " + nrmVel.toString() + ".xyz," + R.toString() + ".xyz," +animationRegisterCache.scaleAndRotateTarget.toString() + ".xyz\n";

			code += "mul " + xAxis.toString() + ".xyz," + cos.toString() +"," + animationRegisterCache.scaleAndRotateTarget.toString() + "\n";
			code += "add " + nrmVel.toString() + ".xyz," + nrmVel.toString() +".xyz," + xAxis.toString() + ".xyz\n";
			code += "dp3 " + xAxis.toString() + ".w," + R.toString() + "," +animationRegisterCache.scaleAndRotateTarget.toString() + "\n";
			code += "neg " + nrmVel.toString() + ".w," + xAxis.toString() + ".w\n";
			
			
			code += "crs " + R.toString() + "," + nrmVel.toString() + ".xyz," +R_rev.toString() + "\n";

			//use cos as R_rev.w
			code += "mul " + xAxis.toString() + ".xyzw," + nrmVel.toString() + ".xyzw," +cos.toString() + "\n";
			code += "add " + R.toString() + "," + R.toString() + "," + xAxis.toString() + ".xyz\n";
			code += "mul " + xAxis.toString() + ".xyz," + nrmVel.toString() + ".w," +R_rev.toString() + "\n";
			
			code += "add " + animationRegisterCache.scaleAndRotateTarget.toString() + "," + R.toString() + "," + xAxis.toString() + ".xyz\n";
			
			var len:int = animationRegisterCache.rotationRegisters.length;
			for (var i:int = 0; i < len; i++)
			{
				code += "mov " + nrmVel.toString() + ".xyz," + roatateAttribute.toString() + ".xyz\n";
				code += "mov " + nrmVel.toString() + ".w," + animationRegisterCache.vertexZeroConst.toString() + "\n";
				code += "mul " + cos.toString() + "," + animationRegisterCache.vertexTime.toString() + "," + roatateAttribute.toString() + ".w\n";
				code += "sin " + sin.toString() + "," + cos.toString() + "\n";
				code += "cos " + cos.toString() + "," + cos.toString() + "\n";
				code += "mul " + R.toString() + "," + sin.toString() +"," + nrmVel.toString() + ".xyz\n";
				code += "mul " + R_rev.toString() + "," + sin.toString() + "," + nrmVel.toString() + ".xyz\n";
				code += "neg " + R_rev.toString() + "," + R_rev.toString() + "\n";
				code += "crs " + nrmVel.toString() + ".xyz," + R.toString() + ".xyz," +animationRegisterCache.rotationRegisters[i].toString() + ".xyz\n";
				code += "mul " + xAxis.toString() + ".xyz," + cos.toString() +"," + animationRegisterCache.rotationRegisters[i].toString() + "\n";
				code += "add " + nrmVel.toString() + ".xyz," + nrmVel.toString() +".xyz," + xAxis.toString() + ".xyz\n";
				code += "dp3 " + xAxis.toString() + ".w," + R.toString() + "," +animationRegisterCache.rotationRegisters[i].toString() + "\n";
				code += "neg " + nrmVel.toString() + ".w," + xAxis.toString() + ".w\n";
				code += "crs " + R.toString() + "," + nrmVel.toString() + ".xyz," +R_rev.toString() + "\n";
				code += "mul " + xAxis.toString() + ".xyzw," + nrmVel.toString() + ".xyzw," +cos.toString() + "\n";
				code += "add " + R.toString() + "," + R.toString() + "," + xAxis.toString() + ".xyz\n";
				code += "mul " + xAxis.toString() + ".xyz," + nrmVel.toString() + ".w," +R_rev.toString() + "\n";
				code += "add " + animationRegisterCache.rotationRegisters[i].toString() + "," + R.toString() + "," + xAxis.toString() + ".xyz\n";
			}
			return code;
		}
		
	}

}