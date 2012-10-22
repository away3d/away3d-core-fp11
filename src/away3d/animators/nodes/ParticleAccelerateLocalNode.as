package away3d.animators.nodes
{
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.data.ParticleParamter;
	import away3d.animators.states.ParticleAccelerateLocalState;
	import away3d.animators.utils.ParticleAnimationCompiler;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Vector3D;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleAccelerateLocalNode extends LocalParticleNodeBase
	{
		public static const NAME:String = "ParticleAccelerateLocalNode";
		public static const ACCELERATELOCAL_STREAM_REGISTER:int = 0;
		
		public function ParticleAccelerateLocalNode()
		{
			super(NAME);
			_stateClass = ParticleAccelerateLocalState;
			_dataLenght = 3;
			initOneData();
		}
		
		override public function generatePorpertyOfOneParticle(param:ParticleParamter):void
		{
			var _tempAccelerate:Vector3D = param[NAME];
			if (!_tempAccelerate)
				throw new Error("there is no " + NAME + " in param!");
			
			_oneData[0] = _tempAccelerate.x / 2;
			_oneData[1] = _tempAccelerate.y / 2;
			_oneData[2] = _tempAccelerate.z / 2;
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, activatedCompiler:ParticleAnimationCompiler) : String
		{
			var accAttribute:ShaderRegisterElement = activatedCompiler.getFreeVertexAttribute();
			activatedCompiler.setRegisterIndex(this, ACCELERATELOCAL_STREAM_REGISTER, accAttribute.index);
			
			var temp:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
			activatedCompiler.addVertexTempUsages(temp,1);
			
			
			var code:String = "mul " + temp.toString() +"," + activatedCompiler.vertexTime.toString() + "," + accAttribute.toString() + "\n";
			
			if (sharedSetting.needVelocity)
			{
				var temp2:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
				code += "mul " + temp2.toString() + "," + temp.toString() + "," + activatedCompiler.vertexTwoConst.toString() + "\n";
				code += "add " + activatedCompiler.velocityTarget.toString() + ".xyz," + temp2.toString() + ".xyz," + activatedCompiler.velocityTarget.toString() + "\n";
			}
			activatedCompiler.removeVertexTempUsage(temp);
			
			code += "mul " + temp.toString() +"," + temp.toString() + "," + activatedCompiler.vertexTime.toString() + "\n";
			code += "add " + activatedCompiler.offsetTarget.toString() +".xyz," + temp.toString() + "," + activatedCompiler.offsetTarget.toString() + ".xyz\n";
			return code;
		}
		
	}

}