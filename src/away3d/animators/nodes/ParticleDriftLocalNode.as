package away3d.animators.nodes
{
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.data.ParticleParamter;
	import away3d.animators.states.ParticleDriftLocalState;
	import away3d.animators.utils.ParticleAnimationCompiler;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Vector3D;
	/**
	 * ...
	 */
	public class ParticleDriftLocalNode extends LocalParticleNodeBase
	{
		public static const NAME:String = "ParticleDriftLocalNode";
		public static const DRIFT_STREAM_REGISTER:int = 0;
		
		
		public function ParticleDriftLocalNode()
		{
			super(NAME, 0);
			_stateClass = ParticleDriftLocalState;
			_dataLenght = 4;
			initOneData();
		}
		
		override public function generatePorpertyOfOneParticle(param:ParticleParamter):void
		{
			//(Vector3D.x,Vector3D.y,Vector3D.z) is drift position,Vector3D.w is drift cycle
			var drift:Vector3D = param[NAME];
			if (!drift)
				throw(new Error("there is no " + NAME + " in param!"));
			
			_oneData[0] = drift.x;
			_oneData[1] = drift.y;
			_oneData[2] = drift.z;
			_oneData[3] = Math.PI * 2 / drift.w;
		}
		
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, activatedCompiler:ParticleAnimationCompiler) : String
		{
			var driftAttribute:ShaderRegisterElement = activatedCompiler.getFreeVertexAttribute();
			activatedCompiler.setRegisterIndex(this, DRIFT_STREAM_REGISTER, driftAttribute.index);
			var temp:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
			var dgree:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
			var sin:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
			var cos:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "z");
			activatedCompiler.addVertexTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "xyz");
			activatedCompiler.removeVertexTempUsage(temp);
			
			var code:String = "";
			code += "mul " + dgree.toString() + "," + activatedCompiler.vertexTime.toString() + "," + driftAttribute.toString() + ".w\n";
			code += "sin " + sin.toString() + "," + dgree.toString() + "\n";
			code += "mul " + distance.toString() + "," + sin.toString() + "," + driftAttribute.toString() + ".xyz\n";
			code += "add " + activatedCompiler.offsetTarget.toString() +"," + distance.toString() + "," + activatedCompiler.offsetTarget.toString() + "\n";
			
			if (sharedSetting.needVelocity)
			{	code += "cos " + cos.toString() + "," + dgree.toString() + "\n";
				code += "mul " + distance.toString() + "," + cos.toString() + "," + driftAttribute.toString() + ".xyz\n";
				code += "add " + activatedCompiler.velocityTarget.toString() + ".xyz," + distance.toString() + "," + activatedCompiler.velocityTarget.toString() + ".xyz\n";
			}
			
			return code;
		}
	}

}